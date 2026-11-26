import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_note/src/note/io/markup/fake_note_pdf_text_layer.dart';
import 'package:open_note/src/note/io/markup/note_pdf_text_run.dart';
import 'package:open_note/src/note/io/markup/note_text_markup_builder.dart';
import 'package:open_note/src/note/io/markup/note_text_markup_kind.dart';
import 'package:open_note/src/note/io/pdf/note_stroke_vectorizer.dart';

const _yellow = Color(0xFFFFEB3B);

NotePdfTextRun _run(double x, double y, double w, [double h = 12]) =>
    NotePdfTextRun(text: 'word', rect: Rect.fromLTWH(x, y, w, h));

List<Stroke> _build(
  List<NotePdfTextRun> runs,
  NoteTextMarkupKind kind, {
  Color color = _yellow,
  bool mergeLines = true,
}) {
  var next = 0;

  return NoteTextMarkupBuilder.build(
    runs,
    kind,
    color,
    idFactory: () => 'id${next++}',
    clock: () => DateTime.utc(2026, 1, 2, 3, 4, 5),
    mergeLines: mergeLines,
  );
}

List<(double, double)> _points(Stroke stroke) => [
  for (final point in stroke.points) (point.x, point.y),
];

/// What the engine paints for [stroke]: the vector path grown by half the
/// painted width.
Rect _painted(Stroke stroke) {
  final shape = NoteStrokeVectorizer.vectorize(stroke)!;
  final bounds = shape.path.toPath().getBounds();

  return shape.filled ? bounds : bounds.inflate(shape.strokeWidth / 2);
}

void _expectRect(Rect actual, Rect expected, [double tolerance = 0.2]) {
  expect(actual.left, closeTo(expected.left, tolerance));
  expect(actual.top, closeTo(expected.top, tolerance));
  expect(actual.right, closeTo(expected.right, tolerance));
  expect(actual.bottom, closeTo(expected.bottom, tolerance));
}

void main() {
  group('highlight', () {
    test('is a marker covering exactly the run', () {
      final stroke = _build([
        _run(10, 20, 100),
      ], NoteTextMarkupKind.highlight).single;

      expect(stroke.ink, 'marker');
      expect(stroke.options.size, 6);
      expect(stroke.width, 6);
      expect(_points(stroke), [(16, 26), (104, 26)]);
      _expectRect(_painted(stroke), const Rect.fromLTWH(10, 20, 100, 12));
    });

    test('makes an opaque colour translucent and keeps others', () {
      final opaque = _build([
        _run(0, 0, 40),
      ], NoteTextMarkupKind.highlight).single;
      final translucent = _build(
        [_run(0, 0, 40)],
        NoteTextMarkupKind.highlight,
        color: const Color(0x33FF0000),
      ).single;

      expect(Color(opaque.color).a, closeTo(0.4, 0.01));
      expect(Color(opaque.color).r, closeTo(_yellow.r, 0.01));
      expect(translucent.color, 0x33FF0000);
    });

    test('has a custom opacity', () {
      final stroke = NoteTextMarkupBuilder.build(
        [_run(0, 0, 40)],
        NoteTextMarkupKind.highlight,
        _yellow,
        highlightOpacity: 0.7,
      ).single;

      expect(Color(stroke.color).a, closeTo(0.7, 0.01));
      expect(stroke.id, isNotEmpty);
      expect(DateTime.tryParse(stroke.createdAt), isNotNull);
    });

    test('a run narrower than it is tall becomes a dot', () {
      final stroke = _build([
        _run(10, 20, 4),
      ], NoteTextMarkupKind.highlight).single;

      expect(_points(stroke), [(12, 26), (12, 26)]);
    });
  });

  group('underline and strikeout', () {
    test('underline sits on the bottom edge in the given colour', () {
      final stroke = _build(
        [_run(10, 20, 100, 20)],
        NoteTextMarkupKind.underline,
        color: const Color(0xFF1565C0),
      ).single;

      expect(stroke.ink, 'pen');
      expect(stroke.color, 0xFF1565C0);
      expect(stroke.options.size, closeTo(1.4, 1e-9));
      expect(stroke.options.thinning, 0);
      expect(stroke.options.simulatePressure, isFalse);
      expect(stroke.options.isComplete, isTrue);
      expect(stroke.points.first.y, closeTo(40 - 0.7, 1e-9));
      _expectRect(
        _painted(stroke),
        const Rect.fromLTRB(10, 38.6, 110, 40),
        0.4,
      );
    });

    test('strikeout runs through the middle', () {
      final stroke = _build([
        _run(0, 100, 50, 10),
      ], NoteTextMarkupKind.strikeout).single;

      expect(stroke.points.map((p) => p.y).toSet(), {105});
      expect(stroke.options.size, 0.75, reason: 'minimum width');
    });

    test('line width is clamped for huge text', () {
      final stroke = _build([
        _run(0, 0, 500, 200),
      ], NoteTextMarkupKind.underline).single;

      expect(stroke.options.size, 4);
    });
  });

  group('runs', () {
    test('words on one line merge into one stroke', () {
      final strokes = _build([
        _run(60, 20.5, 30),
        _run(10, 20, 40),
      ], NoteTextMarkupKind.highlight);

      expect(strokes, hasLength(1));
      _expectRect(
        _painted(strokes.single),
        const Rect.fromLTRB(10, 20, 90, 32.5),
        0.6,
      );
    });

    test('separate columns and lines stay separate, in reading order', () {
      final strokes = _build([
        _run(10, 60, 40),
        _run(300, 20, 40),
        _run(10, 20, 40),
        _run(55, 60, 40),
      ], NoteTextMarkupKind.underline);

      expect(
        strokes.map(
          (s) => (s.points.first.x.round(), s.points.first.y.round()),
        ),
        [(10, 32), (300, 32), (10, 72)],
      );
      expect(strokes.map((s) => s.id), ['id0', 'id1', 'id2']);
      expect(strokes.map((s) => s.createdAt).toSet(), {
        '2026-01-02T03:04:05.000Z',
      });
    });

    test('can keep one stroke per run in the given order', () {
      final strokes = _build(
        [_run(60, 20, 30), _run(10, 20, 40)],
        NoteTextMarkupKind.highlight,
        mergeLines: false,
      );

      expect(strokes.map((s) => s.points.first.x), [66, 16]);
    });

    test('ignores empty and non-finite boxes', () {
      expect(
        _build([
          _run(0, 0, 0),
          _run(0, 0, 10, 0),
          _run(double.nan, 0, 10),
          _run(0, 0, double.infinity),
        ], NoteTextMarkupKind.highlight),
        isEmpty,
      );
      expect(_build([], NoteTextMarkupKind.underline), isEmpty);
    });
  });

  group('models', () {
    test('text runs round trip through JSON', () {
      const run = NotePdfTextRun(text: 'a', rect: Rect.fromLTWH(1, 2, 3, 4));

      expect(NotePdfTextRun.fromJson(run.toJson()), run);
      expect(run.hashCode, run.copyWith().hashCode);
      expect(run.copyWith(text: 'b'), isNot(run));
      expect('$run', contains('NotePdfTextRun(a'));
    });

    test('text run JSON is lenient', () {
      final run = NotePdfTextRun.fromJson({'text': 3, 'rect': 'no'});

      expect(run, const NotePdfTextRun(text: '', rect: Rect.zero));
      expect(NotePdfTextRun.fromJson(null).rect, Rect.zero);
    });

    test('the fake text layer answers per page', () async {
      final layer = FakeNotePdfTextLayer({
        1: [_run(0, 0, 10)],
      });

      expect(await layer.runs(1), hasLength(1));
      expect(await layer.runs(0), isEmpty);
    });
  });
}

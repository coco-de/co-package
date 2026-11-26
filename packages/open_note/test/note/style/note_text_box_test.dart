import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/style/style.dart';

void main() {
  const background = Color(0xFFFFF59D);
  const border = Color(0xFF333333);
  const text = Rect.fromLTWH(50, 60, 120, 30);

  List<Symbol> recorded(NoteTextBoxStyle style) {
    final canvas = TestRecordingCanvas();
    NoteTextBoxDecoration.paint(canvas, text, style);

    return [for (final c in canvas.invocations) c.invocation.memberName];
  }

  group('NoteTextBoxStyle', () {
    test('has plain defaults', () {
      final style = NoteTextBoxStyle();
      expect(style, NoteTextBoxStyle.plain);
      expect(style.padding, const EdgeInsets.all(4));
      expect(style.borderWidth, 1);
      expect(style.borderLineStyle, NoteTextBoxBorderStyle.solid);
      expect(style.opacity, 1);
      expect(style.lineHeight, 0);
      expect(style.textHeight, isNull);
      expect(style.isVisible, isFalse);
      expect(style.encode(), '{}');
    });

    test('clamps numbers and ignores non-finite ones', () {
      final style = NoteTextBoxStyle(
        borderWidth: 99,
        cornerRadius: -3,
        padding: const EdgeInsets.fromLTRB(-1, 500, double.nan, 7),
        opacity: 5,
        lineHeight: 99,
      );
      expect(style.borderWidth, 20);
      expect(style.cornerRadius, 0);
      expect(style.padding, const EdgeInsets.fromLTRB(0, 200, 4, 7));
      expect(style.opacity, 1);
      expect(style.lineHeight, 4);
      expect(NoteTextBoxStyle(lineHeight: -1).lineHeight, 0);
      expect(NoteTextBoxStyle(lineHeight: 0.1).lineHeight, 0.5);
      expect(NoteTextBoxStyle(lineHeight: double.nan).lineHeight, 0);
      expect(NoteTextBoxStyle(lineHeight: 1.5).textHeight, 1.5);
    });

    test('decode(encode(x)) == x', () {
      for (final bg in <Color?>[null, background]) {
        for (final stroke in <Color?>[null, border]) {
          for (final line in NoteTextBoxBorderStyle.values) {
            for (final n in [0.0, 1 / 3, 1.0, 3.7]) {
              final style = NoteTextBoxStyle(
                backgroundColor: bg,
                borderColor: stroke,
                borderWidth: n,
                borderLineStyle: line,
                cornerRadius: n * 3,
                padding: EdgeInsets.fromLTRB(n, 2 * n, 3 * n, 4),
                opacity: n / 4,
                lineHeight: n,
              );
              expect(NoteTextBoxStyle.decode(style.encode()), style);
              expect(NoteTextBoxStyle.fromJson(style.toJson()), style);
            }
          }
        }
      }
    });

    test('malformed strings read as the default and never throw', () {
      final inputs = <String?>[
        null,
        '',
        '{',
        '[]',
        'abc',
        '{"padding":4}',
        '{"padding":[1,2,3]}',
        '{"padding":[1,2,3,"x"]}',
        '{"borderLineStyle":"wavy"}',
        '{"backgroundColor":"red","lineHeight":{}}',
        '[' * 100000,
      ];
      for (final input in inputs) {
        expect(
          NoteTextBoxStyle.decode(input),
          NoteTextBoxStyle.plain,
          reason: '$input',
        );
      }
      expect(
        NoteTextBoxStyle.decode('{"padding":[1,2,3,4]}').padding,
        const EdgeInsets.fromLTRB(1, 2, 3, 4),
      );
    });

    test('copyWith replaces and clears colours', () {
      final style = NoteTextBoxStyle(
        backgroundColor: background,
        borderColor: border,
      );
      expect(style.copyWith(), style);
      expect(
        style.copyWith(clearBackgroundColor: true).backgroundColor,
        isNull,
      );
      expect(style.copyWith(clearBorderColor: true).borderColor, isNull);
      expect(style.copyWith(cornerRadius: 8).cornerRadius, 8);
      expect(style.hashCode, style.copyWith().hashCode);
    });
  });

  group('NoteTextBoxDecoration', () {
    test('outerRect inflates the text bounds by the padding', () {
      final style = NoteTextBoxStyle(
        padding: const EdgeInsets.fromLTRB(1, 2, 3, 4),
      );
      expect(
        NoteTextBoxDecoration.outerRect(text, style),
        const Rect.fromLTRB(49, 58, 173, 94),
      );
    });

    test('paints background then a border inside the box', () {
      final style = NoteTextBoxStyle(
        backgroundColor: background,
        borderColor: border,
        borderWidth: 2,
        cornerRadius: 6,
      );
      final box = NoteTextBoxDecoration.outerRect(text, style);
      expect(
        (Canvas canvas) => NoteTextBoxDecoration.paint(canvas, text, style),
        paints
          ..rrect(
            rrect: RRect.fromRectAndRadius(box, const Radius.circular(6)),
            color: background,
          )
          ..rrect(
            rrect: RRect.fromRectAndRadius(
              box.deflate(1),
              const Radius.circular(5),
            ),
            color: border,
            strokeWidth: 2,
            style: PaintingStyle.stroke,
          ),
      );
    });

    test('a dashed border is a dashed path', () {
      final style = NoteTextBoxStyle(
        borderColor: border,
        borderLineStyle: NoteTextBoxBorderStyle.dashed,
      );
      expect(
        (Canvas canvas) => NoteTextBoxDecoration.paint(canvas, text, style),
        paints..path(color: border, strokeWidth: 1),
      );
      expect(recorded(style), isNot(contains(#drawRRect)));
    });

    test('draws nothing when there is nothing visible', () {
      for (final style in [
        NoteTextBoxStyle.plain,
        NoteTextBoxStyle(borderColor: border, borderWidth: 0),
        NoteTextBoxStyle(backgroundColor: background, opacity: 0),
      ]) {
        expect(recorded(style), isEmpty);
      }
      final canvas = TestRecordingCanvas();
      NoteTextBoxDecoration.paint(
        canvas,
        Rect.zero,
        NoteTextBoxStyle(backgroundColor: background, padding: EdgeInsets.zero),
      );
      expect(canvas.invocations, isEmpty);
    });

    test('a translucent box is composited as one layer', () {
      final calls = recorded(
        NoteTextBoxStyle(
          backgroundColor: background,
          borderColor: border,
          opacity: 0.5,
        ),
      );
      expect(calls.first, #saveLayer);
      expect(calls.last, #restore);
    });

    test('non-finite text bounds draw nothing', () {
      final canvas = TestRecordingCanvas();
      NoteTextBoxDecoration.paint(
        canvas,
        const Rect.fromLTWH(0, double.nan, 10, 10),
        NoteTextBoxStyle(backgroundColor: background, opacity: 0.5),
      );
      expect(canvas.invocations, isEmpty);
    });

    test('a border wider than the box stays inside it', () {
      const tiny = Rect.fromLTWH(0, 0, 4, 4);
      final canvas = TestRecordingCanvas();
      NoteTextBoxDecoration.paint(
        canvas,
        tiny,
        NoteTextBoxStyle(
          borderColor: border,
          borderWidth: 20,
          cornerRadius: 200,
          padding: EdgeInsets.zero,
        ),
      );
      final line =
          canvas.invocations.single.invocation.positionalArguments.first
              as RRect;
      expect(line.outerRect.width, greaterThan(0));
      expect(tiny.inflate(0.001).contains(line.outerRect.topLeft), isTrue);
    });
  });
}

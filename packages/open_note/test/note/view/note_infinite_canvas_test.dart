import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/view/view.dart';

void main() {
  const canvas = NoteInfiniteCanvas(
    size: Size(1000, 1000),
    growthStep: 500,
    margin: 100,
  );

  group('ensureRoom', () {
    test('keeps the size while ink stays inside the margin', () {
      final growth = canvas.ensureRoom(const Rect.fromLTRB(100, 100, 900, 900));

      expect(growth.grew, isFalse);
      expect(growth.size, const Size(1000, 1000));
      expect(growth.shift, Offset.zero);
      expect(
        growth.canvas.contentBounds,
        const Rect.fromLTRB(100, 100, 900, 900),
      );
    });

    test('grows to the right and down without shifting', () {
      final growth = canvas.ensureRoom(
        const Rect.fromLTRB(950, 950, 1400, 1000),
      );

      expect(growth.grew, isTrue);
      // right: 1400 + 100 - 1000 = 500 → one step; bottom: 100 → one step.
      expect(growth.size, const Size(1500, 1500));
      expect(growth.shift, Offset.zero);
      expect(
        growth.canvas.contentBounds,
        const Rect.fromLTRB(950, 950, 1400, 1000),
      );
    });

    test('grows to the left and reports the shift of old content', () {
      final growth = canvas.ensureRoom(const Rect.fromLTRB(50, 400, 150, 500));

      expect(growth.size, const Size(1500, 1000));
      expect(growth.shift, const Offset(500, 0));
      expect(
        growth.canvas.contentBounds,
        const Rect.fromLTRB(550, 400, 650, 500),
      );
      expect(growth.canvas.size, growth.size);
    });

    test('takes as many steps as the shortfall needs', () {
      final growth = canvas.ensureRoom(
        const Rect.fromLTRB(-1200, -10, -1100, 20),
      );

      // left: 100 + 1200 = 1300 → 3 steps; top: 110 → 1 step.
      expect(growth.shift, const Offset(1500, 500));
      expect(growth.size, const Size(2500, 1500));
      expect(
        growth.canvas.contentBounds,
        const Rect.fromLTRB(300, 490, 400, 520),
      );
    });

    test('an exact multiple of the step needs no extra step', () {
      final growth = canvas.ensureRoom(
        const Rect.fromLTRB(-400, 100, -300, 200),
      );

      expect(growth.shift, const Offset(500, 0));
      expect(growth.canvas.contentBounds!.left, 100);
    });

    test('shifts the earlier content together with the new stroke', () {
      final first = canvas
          .ensureRoom(const Rect.fromLTRB(600, 600, 700, 700))
          .canvas;

      final growth = first.ensureRoom(const Rect.fromLTRB(0, 300, 10, 310));

      expect(growth.shift, const Offset(500, 0));
      expect(
        growth.canvas.contentBounds,
        const Rect.fromLTRB(500, 300, 1200, 700),
      );
    });

    test('accepts inverted and zero-size rectangles', () {
      final dot = canvas.ensureRoom(const Rect.fromLTWH(500, 500, 0, 0));
      expect(dot.canvas.contentBounds, const Rect.fromLTWH(500, 500, 0, 0));

      final inverted = canvas.ensureRoom(
        const Rect.fromLTRB(200, 200, 150, 150),
      );
      expect(
        inverted.canvas.contentBounds,
        const Rect.fromLTRB(150, 150, 200, 200),
      );
    });

    test('ignores non-finite rectangles', () {
      final growth = canvas.ensureRoom(
        const Rect.fromLTRB(double.negativeInfinity, 0, 1, 1),
      );

      expect(growth.grew, isFalse);
      expect(growth.canvas, canvas);
      expect(
        canvas.ensureRoom(const Rect.fromLTRB(0, 0, double.nan, 1)).canvas,
        canvas,
      );
    });
  });

  group('move to content', () {
    const left = Rect.fromLTWH(0, 0, 10, 10);
    const right = Rect.fromLTWH(500, 500, 100, 100);

    test('contentCenter is null until something is added', () {
      expect(canvas.isEmpty, isTrue);
      expect(canvas.contentCenter, isNull);
      expect(canvas.nearestContent(Offset.zero), isNull);
      expect(
        canvas.isContentVisible(const Rect.fromLTWH(0, 0, 99, 99)),
        isFalse,
      );
      final added = canvas
          .ensureRoom(const Rect.fromLTRB(200, 300, 400, 500))
          .canvas;
      expect(added.isEmpty, isFalse);
      expect(added.contentCenter, const Offset(300, 400));
    });

    test('nearestContent picks the closest item', () {
      expect(
        canvas.nearestContent(const Offset(450, 450), items: [left, right]),
        right,
      );
      expect(
        canvas.nearestContent(const Offset(20, 20), items: [left, right]),
        left,
      );
    });

    test('a point inside an item has distance zero and ties go first', () {
      const wide = Rect.fromLTWH(0, 0, 1000, 1000);

      expect(
        canvas.nearestContent(const Offset(550, 550), items: [wide, right]),
        wide,
      );
    });

    test('falls back to the content bounds', () {
      final added = canvas.ensureRoom(left.translate(200, 200)).canvas;

      expect(added.nearestContent(const Offset(900, 900)), added.contentBounds);
    });

    test('tells whether content is on screen', () {
      final added = canvas
          .ensureRoom(const Rect.fromLTRB(200, 200, 300, 300))
          .canvas;

      expect(
        added.isContentVisible(const Rect.fromLTWH(250, 250, 100, 100)),
        isTrue,
      );
      expect(
        added.isContentVisible(const Rect.fromLTWH(600, 600, 100, 100)),
        isFalse,
      );
    });

    test('withContent recomputes after erasing and never shrinks', () {
      final grown = canvas
          .ensureRoom(const Rect.fromLTRB(2000, 0, 2100, 10))
          .canvas;

      final erased = grown.withContent([
        left,
        const Rect.fromLTRB(double.nan, 0, 1, 1),
        right,
      ]);

      expect(erased.size, grown.size);
      expect(erased.contentBounds, const Rect.fromLTRB(0, 0, 600, 600));
      expect(grown.withContent(const []).contentBounds, isNull);
    });
  });

  group('json', () {
    test('round-trips', () {
      final value = canvas.ensureRoom(const Rect.fromLTRB(1, 2, 3, 4)).canvas;

      final restored = NoteInfiniteCanvas.fromJson(value.toJson());

      expect(restored, value);
      expect(restored.hashCode, value.hashCode);
    });

    test('omits empty content', () {
      expect(canvas.toJson().containsKey('content'), isFalse);
      expect(NoteInfiniteCanvas.fromJson(canvas.toJson()), canvas);
    });

    test('drops unreadable content', () {
      for (final content in <Object?>[
        <String, Object?>{},
        {'x': 1},
        {'x': 0, 'y': 0, 'w': -2, 'h': 1},
        'rect',
      ]) {
        final restored = NoteInfiniteCanvas.fromJson({'content': content});

        expect(restored.contentBounds, isNull, reason: '$content');
      }
    });

    test('survives junk', () {
      for (final junk in <Object?>[null, 'x', 7, <String, Object?>{}]) {
        expect(NoteInfiniteCanvas.fromJson(junk), const NoteInfiniteCanvas());
      }
      final repaired = NoteInfiniteCanvas.fromJson({
        'size': {'w': -5, 'h': 0},
        'content': 'nope',
        'growthStep': 0,
        'margin': -3,
      });

      expect(repaired.size, NoteInfiniteCanvas.defaultSize);
      expect(repaired.contentBounds, isNull);
      expect(repaired.growthStep, 1);
      expect(repaired.margin, 0);
    });
  });

  test('value equality and copyWith', () {
    expect(canvas.copyWith(), canvas);
    expect(canvas.copyWith(margin: 5), isNot(canvas));
    final a = canvas.ensureRoom(const Rect.fromLTRB(1, 1, 2, 2));
    final b = canvas.ensureRoom(const Rect.fromLTRB(1, 1, 2, 2));
    expect(a, b);
    expect(a.hashCode, b.hashCode);
  });
}

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/view/view.dart';

void expectTransform(Matrix4 matrix, double scale, Offset translation) {
  expect(NoteZoomMath.scaleOf(matrix), closeTo(scale, 1e-9), reason: 'scale');
  final moved = NoteZoomMath.translationOf(matrix);
  expect(moved.dx, closeTo(translation.dx, 1e-9), reason: 'tx');
  expect(moved.dy, closeTo(translation.dy, 1e-9), reason: 'ty');
}

void expectOffset(Offset actual, Offset expected) {
  expect(actual.dx, closeTo(expected.dx, 1e-9), reason: '$actual');
  expect(actual.dy, closeTo(expected.dy, 1e-9), reason: '$actual');
}

void main() {
  const a4 = Rect.fromLTWH(0, 0, 595, 842);

  group('matrix basics', () {
    test('maps content to viewport and back', () {
      final matrix = NoteZoomMath.matrix(2, const Offset(10, 20));

      expectOffset(
        NoteZoomMath.toViewport(matrix, const Offset(3, 4)),
        const Offset(16, 28),
      );
      expectOffset(
        NoteZoomMath.toContent(matrix, const Offset(16, 28)),
        const Offset(3, 4),
      );
      expectTransform(matrix, 2, const Offset(10, 20));
    });

    test('keeps InteractiveViewer happy below 100 %', () {
      final matrix = NoteZoomMath.matrix(0.5);

      expect(matrix.getMaxScaleOnAxis(), 0.5);
    });

    test('a singular matrix maps to zero', () {
      expect(
        NoteZoomMath.toContent(Matrix4.zero(), const Offset(5, 5)),
        Offset.zero,
      );
    });

    test('clampZoom keeps the range', () {
      expect(NoteZoomMath.clampZoom(100), 8);
      expect(NoteZoomMath.clampZoom(0.01), 0.25);
      expect(NoteZoomMath.clampZoom(double.nan), 0.25);
      expect(NoteZoomMath.clampZoom(3, max: 2), 2);
    });
  });

  group('fitWidth', () {
    test('fills the width and centres a short page vertically', () {
      final matrix = NoteZoomMath.fitWidth(a4, const Size(1190, 2000));

      expectTransform(matrix, 2, const Offset(0, 158));
    });

    test('starts a tall page at the top', () {
      final matrix = NoteZoomMath.fitWidth(a4, const Size(1190, 800));

      expectTransform(matrix, 2, Offset.zero);
    });

    test('keeps the padding around a tall page', () {
      final matrix = NoteZoomMath.fitWidth(
        const Rect.fromLTWH(0, 0, 100, 1000),
        const Size(220, 300),
        padding: 10,
      );

      expectTransform(matrix, 2, const Offset(10, 10));
    });

    test('honours the content origin', () {
      final matrix = NoteZoomMath.fitWidth(
        const Rect.fromLTWH(100, 200, 100, 100),
        const Size(400, 600),
      );

      expectTransform(matrix, 4, const Offset(-400, -700));
      expectOffset(
        NoteZoomMath.toViewport(matrix, const Offset(150, 250)),
        const Offset(200, 300),
      );
    });

    test('clamps the zoom and still centres', () {
      final matrix = NoteZoomMath.fitWidth(
        const Rect.fromLTWH(0, 0, 10, 10),
        const Size(800, 600),
      );

      expectTransform(matrix, 8, const Offset(360, 260));
      expect(
        NoteZoomMath.fitWidthScale(
          const Rect.fromLTWH(0, 0, 10, 10),
          const Size(800, 600),
          max: 20,
        ),
        20,
      );
    });
  });

  group('fitPage', () {
    test('shows the whole page centred', () {
      final matrix = NoteZoomMath.fitPage(
        const Rect.fromLTWH(0, 0, 100, 200),
        const Size(400, 400),
      );

      expectTransform(matrix, 2, const Offset(100, 0));
    });

    test('uses the tighter axis and the padding', () {
      final scale = NoteZoomMath.fitPageScale(
        const Rect.fromLTWH(0, 0, 100, 100),
        const Size(300, 500),
        padding: 50,
      );

      expect(scale, 2);
    });

    test('honours the content origin', () {
      final matrix = NoteZoomMath.fitPage(
        const Rect.fromLTWH(100, 100, 100, 200),
        const Size(400, 400),
      );

      expectTransform(matrix, 2, const Offset(-100, -200));
      expectOffset(
        NoteZoomMath.toViewport(matrix, const Offset(100, 100)),
        const Offset(100, 0),
      );
    });
  });

  group('centerOn', () {
    test('puts the content centre in the middle of the viewport', () {
      final matrix = NoteZoomMath.centerOn(
        const Rect.fromLTWH(100, 100, 50, 50),
        const Size(800, 600),
        2,
      );

      expectTransform(matrix, 2, const Offset(150, 50));
      expect(matrix, NoteZoomMath.matrix(2, const Offset(150, 50)));
    });

    test('treats a bad scale as 1', () {
      for (final scale in [0.0, -1.0, double.nan]) {
        final matrix = NoteZoomMath.centerOn(
          const Rect.fromLTWH(0, 0, 100, 100),
          const Size(300, 300),
          scale,
        );

        expectTransform(matrix, 1, const Offset(100, 100));
      }
    });
  });

  group('zoomAround', () {
    test('keeps the content under the focal point in place', () {
      const focal = Offset(100, 50);

      final matrix = NoteZoomMath.zoomAround(Matrix4.identity(), focal, 2);

      expectTransform(matrix, 2, const Offset(-100, -50));
      expectOffset(NoteZoomMath.toViewport(matrix, focal), focal);
    });

    test('takes an absolute scale from any starting matrix', () {
      final start = NoteZoomMath.matrix(2, const Offset(-100, -50));

      final matrix = NoteZoomMath.zoomAround(start, Offset.zero, 1);

      expectTransform(matrix, 1, const Offset(-50, -25));
    });

    test('keeps any point under the focus', () {
      final start = NoteZoomMath.matrix(0.5, const Offset(31, -7));
      const focal = Offset(213, 144);
      final under = NoteZoomMath.toContent(start, focal);

      final matrix = NoteZoomMath.zoomAround(start, focal, 3.5);

      expectOffset(NoteZoomMath.toViewport(matrix, under), focal);
      expect(matrix.getMaxScaleOnAxis(), closeTo(3.5, 1e-9));
    });

    test('clamps the target scale', () {
      final identity = Matrix4.identity();

      expect(
        NoteZoomMath.scaleOf(
          NoteZoomMath.zoomAround(identity, Offset.zero, 100),
        ),
        8,
      );
      expect(
        NoteZoomMath.scaleOf(
          NoteZoomMath.zoomAround(identity, Offset.zero, 0.01),
        ),
        0.25,
      );
      expect(
        NoteZoomMath.scaleOf(
          NoteZoomMath.zoomAround(identity, Offset.zero, 100, max: 20),
        ),
        20,
      );
    });

    test('returns a copy for a bad scale or matrix', () {
      final start = NoteZoomMath.matrix(2, const Offset(1, 2));

      final same = NoteZoomMath.zoomAround(start, Offset.zero, -1);

      expect(same, start);
      expect(identical(same, start), isFalse);
      expect(
        NoteZoomMath.zoomAround(Matrix4.zero(), Offset.zero, 2),
        Matrix4.zero(),
      );
    });

    test('scaleAround multiplies the current zoom', () {
      final start = NoteZoomMath.matrix(2, const Offset(-100, -50));

      final matrix = NoteZoomMath.scaleAround(start, Offset.zero, 0.5);

      expectTransform(matrix, 1, const Offset(-50, -25));
    });

    test('does not modify the input', () {
      final start = NoteZoomMath.matrix(2);

      NoteZoomMath.zoomAround(start, const Offset(10, 10), 4);

      expect(start, NoteZoomMath.matrix(2));
    });
  });

  test('degenerate input gives the identity and scale 1', () {
    const viewport = Size(100, 100);
    const empty = Rect.fromLTWH(0, 0, 0, 10);

    expect(NoteZoomMath.fitWidth(empty, viewport), Matrix4.identity());
    expect(NoteZoomMath.fitPage(empty, viewport), Matrix4.identity());
    expect(NoteZoomMath.fitWidth(a4, Size.zero), Matrix4.identity());
    expect(NoteZoomMath.fitPage(a4, Size.zero), Matrix4.identity());
    expect(
      NoteZoomMath.fitWidth(a4, viewport, padding: 60),
      Matrix4.identity(),
    );
    expect(NoteZoomMath.fitPage(a4, viewport, padding: 60), Matrix4.identity());
    expect(NoteZoomMath.fitWidthScale(empty, viewport), 1);
    expect(NoteZoomMath.fitPageScale(a4, Size.zero), 1);
  });
}

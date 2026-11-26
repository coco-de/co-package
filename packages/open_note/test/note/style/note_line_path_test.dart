import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/style/style.dart';

import 'support/path_probe.dart';

void main() {
  const line = [Offset.zero, Offset(100, 0)];

  List<NoteStyledPath> render(
    NoteLineStyle style, {
    List<Offset> points = line,
    double width = 2,
    bool closed = false,
  }) => NoteLinePath.renderPaths(points, width, style, closed: closed);

  NoteLineStyle of(NoteLineStyleKind kind) => NoteLineStyle.of(kind);

  group('NoteLinePath.smooth', () {
    test('keeps both end points exactly', () {
      final points = [
        const Offset(1.25, 2.5),
        const Offset(10, 8),
        const Offset(22, 3),
        const Offset(31.5, 9.75),
      ];
      final smoothed = NoteLinePath.smooth(points);
      expect(smoothed.first, points.first);
      expect(smoothed.last, points.last);
    });

    test('passes short inputs through and drops non-finite points', () {
      expect(NoteLinePath.smooth(const []), isEmpty);
      expect(NoteLinePath.smooth(const [Offset(1, 1)]), const [Offset(1, 1)]);
      expect(NoteLinePath.smooth(line), line);
      expect(
        NoteLinePath.smooth([
          Offset.zero,
          const Offset(double.nan, 4),
          const Offset(5, double.infinity),
          const Offset(100, 0),
        ]),
        line,
      );
    });

    test('removes alternating jitter', () {
      final noisy = [
        for (var i = 0; i < 100; i++) Offset(i * 2.0, i.isEven ? 1 : -1),
      ];
      final smoothed = NoteLinePath.smooth(noisy);
      final middle = smoothed.where((p) => p.dx > 10 && p.dx < 180);
      expect(middle, isNotEmpty);
      expect(middle.every((p) => p.dy.abs() < 0.1), isTrue);
    });

    test('keeps the corner of a sparse polyline', () {
      final smoothed = NoteLinePath.smooth(const [
        Offset.zero,
        Offset(100, 0),
        Offset(100, 100),
      ]);
      expect(
        smoothed.any((p) => (p - const Offset(100, 0)).distance <= 1.5001),
        isTrue,
      );
    });

    test('resamples about every sampleSpacing units', () {
      const points = [Offset.zero, Offset(50, 0), Offset(100, 0)];
      expect(NoteLinePath.smooth(points).length, greaterThan(30));
      final coarse = NoteLinePath.smooth(points, sampleSpacing: 25);
      expect(coarse.length, 5);
      expect(
        NoteLinePath.smooth(points, sampleSpacing: -1).length,
        NoteLinePath.smooth(points).length,
      );
    });

    test('survives repeated and closed input', () {
      final same = List.filled(20, const Offset(3, 3));
      expect(NoteLinePath.smooth(same), isNotEmpty);
      final loop = NoteLinePath.smooth(const [
        Offset.zero,
        Offset(20, 0),
        Offset(20, 20),
        Offset(0, 20),
        Offset.zero,
      ]);
      expect(loop.first, Offset.zero);
      expect(loop.last, Offset.zero);
      expect(loop.every((p) => p.isFinite), isTrue);
    });
  });

  group('NoteLinePath.renderPaths', () {
    test('draws nothing for no points or a non-positive width', () {
      final solid = NoteLineStyle.solid;
      expect(render(solid, points: const []), isEmpty);
      expect(render(solid, width: 0), isEmpty);
      expect(render(solid, width: -2), isEmpty);
      expect(render(solid, width: double.nan), isEmpty);
    });

    test('draws a single point as a round dot in every style', () {
      for (final kind in NoteLineStyleKind.values) {
        final dot = render(of(kind), points: const [Offset(4, 5)]);
        expect(dot, hasLength(1), reason: kind.name);
        expect(dot.single.cap, StrokeCap.round);
        expect(dot.single.path.getBounds().center.dx, closeTo(4, 0.1));
        final zero = render(of(kind), points: List.filled(3, Offset.zero));
        expect(zero, hasLength(1));
      }
    });

    test('solid is one round stroke along the polyline', () {
      final strokes = render(NoteLineStyle.solid);
      expect(strokes, hasLength(1));
      expect(strokes.single.strokeWidth, 2);
      expect(strokes.single.cap, StrokeCap.round);
      expect(pathLength(strokes.single.path), closeTo(100, 1e-3));
    });

    test('dashed cuts butt dashes of dashLength × width', () {
      final style = NoteLineStyle(
        kind: NoteLineStyleKind.dashed,
        dashLength: 2,
        gap: 3,
      );
      final stroke = render(style, width: 5).single;
      expect(stroke.cap, StrokeCap.butt);
      expect(contourCount(stroke.path), 4);
      expect(pathLength(stroke.path), closeTo(40, 1e-3));
      expect(stroke.path.computeMetrics().first.length, closeTo(10, 1e-3));
    });

    test('dotted uses round caps and very short dashes', () {
      final stroke = render(of(NoteLineStyleKind.dotted), width: 4).single;
      expect(stroke.cap, StrokeCap.round);
      expect(contourCount(stroke.path), 15);
      expect(stroke.path.computeMetrics().first.length, closeTo(0.4, 1e-3));
    });

    test('the pattern scales with the width', () {
      final thin = render(of(NoteLineStyleKind.dashed), width: 1).single;
      final thick = render(of(NoteLineStyleKind.dashed), width: 4).single;
      expect(contourCount(thin.path), greaterThan(contourCount(thick.path)));
    });

    test('wavy swings amplitude × width and ends on the end points', () {
      final stroke = render(of(NoteLineStyleKind.wavy)).single;
      final bounds = sampledBounds(stroke.path);
      expect(bounds.top, closeTo(-3, 0.05));
      expect(bounds.bottom, closeTo(3, 0.05));
      final metric = stroke.path.computeMetrics().single;
      expect(
        metric.getTangentForOffset(0)!.position,
        closeToOffset(Offset.zero),
      );
      expect(
        metric.getTangentForOffset(metric.length)!.position,
        closeToOffset(const Offset(100, 0)),
      );
      expect(metric.length, greaterThan(110));
    });

    test('zigzag has straight teeth that reach the amplitude', () {
      final stroke = render(of(NoteLineStyleKind.zigzag)).single;
      final bounds = sampledBounds(stroke.path);
      expect(bounds.top, closeTo(-3, 0.3));
      expect(bounds.bottom, closeTo(3, 0.3));
      expect(bounds.left, closeTo(0, 1e-3));
      expect(bounds.right, closeTo(100, 1e-3));
      expect(pathLength(stroke.path), greaterThan(110));
    });

    test('double draws two parallel lines doubleGap × width apart', () {
      final strokes = render(of(NoteLineStyleKind.double));
      expect(strokes, hasLength(2));
      expect(strokes.every((s) => s.strokeWidth == 2), isTrue);
      final ys = [for (final s in strokes) s.path.getBounds().top];
      ys.sort();
      expect(ys.first, closeTo(-2.2, 1e-3));
      expect(ys.last, closeTo(2.2, 1e-3));
      // The clear space between the two 2 wide lines is 1.2 × 2.
      expect(ys.last - ys.first - 2, closeTo(2.4, 1e-3));
    });

    test('a closed polyline stays closed in every continuous style', () {
      const square = [
        Offset.zero,
        Offset(60, 0),
        Offset(60, 60),
        Offset(0, 60),
        Offset.zero,
      ];
      for (final kind in [
        NoteLineStyleKind.solid,
        NoteLineStyleKind.wavy,
        NoteLineStyleKind.zigzag,
        NoteLineStyleKind.double,
      ]) {
        final strokes = render(of(kind), points: square, closed: true);
        for (final stroke in strokes) {
          final metrics = stroke.path.computeMetrics().toList();
          expect(metrics, hasLength(1), reason: kind.name);
          expect(metrics.single.isClosed, isTrue, reason: kind.name);
        }
      }
      final dashes = render(
        of(NoteLineStyleKind.dashed),
        points: square,
        closed: true,
      );
      expect(pathLength(dashes.single.path), lessThan(240));
    });

    test('hostile input stays bounded', () {
      final huge = [Offset.zero, const Offset(2e6, 0)];
      for (final kind in NoteLineStyleKind.values) {
        final strokes = render(of(kind), points: huge, width: 0.25);
        for (final stroke in strokes) {
          expect(
            contourCount(stroke.path),
            lessThanOrEqualTo(NoteLinePath.maxSegments + 1),
            reason: kind.name,
          );
        }
      }
      expect(
        render(
          of(NoteLineStyleKind.wavy),
          points: const [Offset.zero, Offset(double.nan, 1), Offset(9, 0)],
        ).single.path.getBounds().isFinite,
        isTrue,
      );
    });
  });

  group('NoteLinePath extreme widths', () {
    test('a vanishing or enormous width never throws', () {
      for (final kind in NoteLineStyleKind.values) {
        for (final width in [5e-324, 1e-12, 1e9]) {
          expect(
            () => NoteLinePath.renderPaths(
              const [Offset.zero, Offset(100, 0)],
              width,
              NoteLineStyle.of(kind),
            ),
            returnsNormally,
            reason: '${kind.name} $width',
          );
        }
      }
    });
  });

  group('NoteLinePath helpers', () {
    test('polylinePath is open unless closed', () {
      const points = [Offset.zero, Offset(10, 0), Offset(10, 10)];
      expect(
        NoteLinePath.polylinePath(points).computeMetrics().single.isClosed,
        isFalse,
      );
      expect(
        NoteLinePath.polylinePath(
          points,
          closed: true,
        ).computeMetrics().single.isClosed,
        isTrue,
      );
      expect(contourCount(NoteLinePath.polylinePath(const [])), 0);
    });

    test('dashPath keeps curves and ignores non-positive lengths', () {
      final circle = Path()..addOval(const Rect.fromLTWH(0, 0, 100, 100));
      final dashes = NoteLinePath.dashPath(circle, 5, 5);
      expect(contourCount(dashes), closeTo(314 / 10, 1));
      expectInside(dashes, const Rect.fromLTWH(0, 0, 100, 100));
      final untouched = NoteLinePath.dashPath(circle, 0, 5);
      expect(pathLength(untouched), closeTo(pathLength(circle), 1e-6));
      expect(contourCount(NoteLinePath.dashPath(Path(), 2, 2)), 0);
    });

    test('offsetPolyline mitres corners', () {
      final offset = NoteLinePath.offsetPolyline(const [
        Offset.zero,
        Offset(10, 0),
        Offset(10, 10),
      ], 1);
      expect(offset, hasLength(3));
      expect(offset[0], closeToOffset(const Offset(0, 1)));
      expect(offset[1], closeToOffset(const Offset(9, 1)));
      expect(offset[2], closeToOffset(const Offset(9, 10)));
    });

    test('offsetPolyline caps very sharp mitres', () {
      final spike = NoteLinePath.offsetPolyline(const [
        Offset.zero,
        Offset(100, 0),
        Offset(0, 1),
      ], 2);
      expect(spike.every((p) => p.isFinite), isTrue);
      expect(
        (spike[1] - const Offset(100, 0)).distance,
        lessThanOrEqualTo(2 / 0.35 + 1e-6),
      );
      expect(NoteLinePath.offsetPolyline(const [Offset(1, 1)], 3), const [
        Offset(1, 1),
      ]);
    });
  });
}

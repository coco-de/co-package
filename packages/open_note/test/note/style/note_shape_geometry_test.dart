import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/style/style.dart';

import 'support/path_probe.dart';

void main() {
  const rect = Rect.fromLTWH(10, 20, 200, 120);
  const rects = [
    rect,
    Rect.fromLTWH(0, 0, 100, 100),
    Rect.fromLTWH(5, 5, 400, 24),
    Rect.fromLTWH(5, 5, 24, 400),
    Rect.fromLTWH(0, 0, 3, 3),
  ];
  const closedKinds = [
    NoteShapeKind.rectangle,
    NoteShapeKind.roundedRectangle,
    NoteShapeKind.ellipse,
    NoteShapeKind.triangle,
    NoteShapeKind.rightTriangle,
    NoteShapeKind.diamond,
    NoteShapeKind.pentagon,
    NoteShapeKind.hexagon,
    NoteShapeKind.star,
    NoteShapeKind.cube,
    NoteShapeKind.cylinder,
    NoteShapeKind.cone,
    NoteShapeKind.pyramid,
    NoteShapeKind.sphere,
  ];
  const solidKinds = [
    NoteShapeKind.cube,
    NoteShapeKind.cylinder,
    NoteShapeKind.cone,
    NoteShapeKind.pyramid,
    NoteShapeKind.sphere,
  ];

  Iterable<Path> pathsOf(NoteShapePaths paths) => [
    paths.outline,
    ?paths.inner,
    ?paths.hidden,
  ];

  group('NoteShapeKind', () {
    test('knows which kinds are linear and which are 3-D', () {
      expect(NoteShapeKind.values.where((k) => k.isLinear), [
        NoteShapeKind.line,
        NoteShapeKind.arrow,
        NoteShapeKind.doubleArrow,
      ]);
      expect(
        NoteShapeKind.values.where((k) => k.isThreeDimensional),
        solidKinds,
      );
      expect({
        ...closedKinds,
        ...NoteShapeKind.values.where((k) => k.isLinear),
      }, NoteShapeKind.values.toSet());
    });
  });

  group('NoteShapeGeometry closed shapes', () {
    for (final kind in NoteShapeKind.values) {
      test('${kind.name} stays inside its rectangle', () {
        for (final box in rects) {
          for (final radius in [0.0, 8.0, 500.0]) {
            final paths = NoteShapeGeometry.pathsFor(
              kind,
              box,
              cornerRadius: radius,
            );
            // An arrow in a rectangle thinner than its head cannot fit; the
            // arrow group below covers that case.
            if (kind.isLinear && box.shortestSide < 24) continue;
            for (final path in pathsOf(paths)) {
              expectInside(path, box, reason: '${kind.name} $box r$radius');
              expectInside(
                Path()..addRect(path.getBounds()),
                box,
                tolerance: 0.02,
                reason: 'bounds of ${kind.name} $box r$radius',
              );
            }
          }
        }
      });
    }

    for (final kind in closedKinds) {
      test('${kind.name} has one closed outline that fills the box', () {
        final outline = NoteShapeGeometry.pathsFor(kind, rect).outline;
        final metrics = outline.computeMetrics().toList();
        expect(metrics, hasLength(1));
        expect(metrics.single.isClosed, isTrue);
        final bounds = sampledBounds(outline);
        if (kind == NoteShapeKind.roundedRectangle) {
          expect(bounds.width, closeTo(rect.width, 0.1));
          expect(bounds.height, closeTo(rect.height, 0.1));
        } else {
          expect(bounds.left, closeTo(rect.left, 0.5));
          expect(bounds.top, closeTo(rect.top, 0.5));
          expect(bounds.right, closeTo(rect.right, 0.5));
          expect(bounds.bottom, closeTo(rect.bottom, 0.5));
        }
        expect(outline.contains(rect.center), isTrue);
      });
    }

    test('flat shapes have no interior or hidden edges', () {
      for (final kind in closedKinds.where((k) => !solidKinds.contains(k))) {
        final paths = NoteShapeGeometry.pathsFor(kind, rect);
        expect(paths.inner, isNull, reason: kind.name);
        expect(paths.hidden, isNull, reason: kind.name);
      }
    });

    test(
      '3-D shapes have hidden edges and, except the cone, interior ones',
      () {
        for (final kind in solidKinds) {
          final paths = NoteShapeGeometry.pathsFor(kind, rect);
          expect(pathLength(paths.hidden!), greaterThan(50), reason: kind.name);
          expect(
            paths.inner,
            kind == NoteShapeKind.cone ? isNull : isNotNull,
            reason: kind.name,
          );
        }
      },
    );

    test('a cube has three visible and three hidden edges from its centre', () {
      final drawing = NoteShapeGeometry.drawingFor(NoteShapeKind.cube, rect);
      int edges(NoteShapePart part) =>
          part.contours.fold(0, (sum, c) => sum + c.points.length - 1);
      expect(edges(drawing.inner!), 3);
      expect(edges(drawing.hidden!), 3);
      expect(drawing.outline.contours.single.points, hasLength(6));
      for (final part in [drawing.inner!, drawing.hidden!]) {
        for (final contour in part.contours) {
          expect(contour.points, contains(rect.center));
        }
      }
    });

    test('the cone sides are tangent to its base', () {
      final drawing = NoteShapeGeometry.drawingFor(NoteShapeKind.cone, rect);
      final height = rect.height / 3;
      final base = Rect.fromLTRB(
        rect.left,
        rect.bottom - height,
        rect.right,
        rect.bottom,
      );
      final tangent = drawing.outline.contours.single.points[1];
      final dx = (tangent.dx - base.center.dx) / (base.width / 2);
      final dy = (tangent.dy - base.center.dy) / (base.height / 2);
      expect(dx * dx + dy * dy, closeTo(1, 1e-6));
      // The tangent of the ellipse there passes through the apex.
      final apex = rect.topCenter;
      final slopeX = -dy / (base.height / 2);
      final slopeY = dx / (base.width / 2);
      final toApex = apex - tangent;
      expect((slopeX * toApex.dy - slopeY * toApex.dx).abs(), lessThan(1e-6));
    });

    test('normalises reversed rectangles of closed shapes', () {
      final reversed = Rect.fromLTRB(
        rect.right,
        rect.bottom,
        rect.left,
        rect.top,
      );
      for (final kind in closedKinds) {
        expect(
          NoteShapeGeometry.drawingFor(kind, reversed).outline.contours,
          NoteShapeGeometry.drawingFor(kind, rect).outline.contours,
          reason: kind.name,
        );
      }
    });

    test('corner radius rounds rectangles and polygons', () {
      final sharp = NoteShapeGeometry.pathsFor(
        NoteShapeKind.rectangle,
        rect,
      ).outline;
      final round = NoteShapeGeometry.pathsFor(
        NoteShapeKind.rectangle,
        rect,
        cornerRadius: 20,
      ).outline;
      final corner = rect.topLeft + const Offset(2, 2);
      expect(sharp.contains(corner), isTrue);
      expect(round.contains(corner), isFalse);
      expect(pathLength(sharp), closeTo(640, 1e-3));
      // Skia measures conic arcs slightly short.
      expect(pathLength(round), closeTo(640 - 8 * 20 + 2 * 3.14159 * 20, 1.5));

      final rounded = NoteShapeGeometry.pathsFor(
        NoteShapeKind.roundedRectangle,
        rect,
      ).outline;
      expect(rounded.contains(corner), isFalse);

      final triangle = NoteShapeGeometry.pathsFor(
        NoteShapeKind.triangle,
        rect,
        cornerRadius: 30,
      ).outline;
      expect(triangle.contains(rect.topCenter + const Offset(0, 3)), isFalse);
      expect(
        pathLength(triangle),
        lessThan(
          pathLength(
            NoteShapeGeometry.pathsFor(NoteShapeKind.triangle, rect).outline,
          ),
        ),
      );
    });

    test('an ellipse is a true oval and its contour lies on it', () {
      final drawing = NoteShapeGeometry.drawingFor(NoteShapeKind.ellipse, rect);
      expect(drawing.outline.path.getBounds(), rect);
      final contour = drawing.outline.contours.single;
      expect(contour.closed, isTrue);
      for (final point in contour.points) {
        final x = (point.dx - rect.center.dx) / (rect.width / 2);
        final y = (point.dy - rect.center.dy) / (rect.height / 2);
        expect(x * x + y * y, closeTo(1, 1e-9));
      }
    });

    test('degenerate and non-finite rectangles do not throw', () {
      for (final kind in NoteShapeKind.values) {
        for (final box in const [
          Rect.zero,
          Rect.fromLTWH(3, 3, 0, 40),
          Rect.fromLTWH(3, 3, 40, 0),
        ]) {
          final paths = NoteShapeGeometry.pathsFor(kind, box, cornerRadius: 4);
          for (final path in pathsOf(paths)) {
            expect(path.getBounds().isFinite, isTrue, reason: kind.name);
          }
        }
        final broken = NoteShapeGeometry.pathsFor(
          kind,
          const Rect.fromLTRB(0, double.nan, 10, 10),
        );
        expect(contourCount(broken.outline), 0, reason: kind.name);
      }
    });
  });

  group('NoteShapeGeometry arrows', () {
    const start = Offset(180, 30);
    const end = Offset(20, 110);
    final leftward = Rect.fromLTRB(start.dx, start.dy, end.dx, end.dy);

    NoteShapeDrawing draw(
      NoteShapeKind kind, {
      Rect? box,
      NoteShapeHeadStyle head = NoteShapeHeadStyle.triangle,
      double? length,
      bool contain = false,
    }) => NoteShapeGeometry.drawingFor(
      kind,
      box ?? leftward,
      headStyle: head,
      headLength: length,
      containHeads: contain,
    );

    test('a line runs from the first corner to the opposite one', () {
      final shaft = draw(NoteShapeKind.line).outline.contours.single;
      expect(shaft.points, [start, end]);
      expect(shaft.closed, isFalse);
      expect(draw(NoteShapeKind.line).heads, isNull);
      final metric = NoteShapeGeometry.pathsFor(
        NoteShapeKind.line,
        leftward,
      ).outline.computeMetrics().single;
      expect(metric.isClosed, isFalse);
      expect(metric.getTangentForOffset(0)!.position, closeToOffset(start));
    });

    test('an arrow has a filled head whose tip is the end point', () {
      final drawing = draw(NoteShapeKind.arrow);
      final head = drawing.heads!.contours.single;
      expect(drawing.fillHeads, isTrue);
      expect(head.closed, isTrue);
      expect(head.points, contains(closeToOffset(end)));
      final shaft = drawing.outline.contours.single.points;
      expect(shaft.first, start);
      // The shaft stops at the base of the triangle.
      expect((shaft.last - end).distance, closeTo(24, 1e-6));
    });

    test('a double arrow has a head at each end', () {
      final drawing = draw(NoteShapeKind.doubleArrow);
      expect(drawing.heads!.contours, hasLength(2));
      expect(
        drawing.heads!.contours.last.points,
        contains(closeToOffset(start)),
      );
      final shaft = drawing.outline.contours.single.points;
      expect((shaft.first - start).distance, closeTo(24, 1e-6));
      expect((shaft.last - end).distance, closeTo(24, 1e-6));
    });

    test('head styles: open, dot and none', () {
      final open = draw(NoteShapeKind.arrow, head: NoteShapeHeadStyle.open);
      expect(open.fillHeads, isFalse);
      expect(open.heads!.contours.single.closed, isFalse);
      expect(open.outline.contours.single.points.last, closeToOffset(end));

      final dot = draw(NoteShapeKind.arrow, head: NoteShapeHeadStyle.dot);
      expect(dot.fillHeads, isTrue);
      final circle = dot.heads!.path.getBounds();
      expect(circle.width, closeTo(2 * 24 * 0.35, 1e-3));
      expect((circle.center - end).distance, closeTo(24 * 0.35, 1e-3));

      final none = draw(NoteShapeKind.arrow, head: NoteShapeHeadStyle.none);
      expect(none.heads, isNull);
      expect(none.outline.contours.single.points, [start, end]);
    });

    test('the head length follows the arrow and is capped', () {
      double headOf(NoteShapeDrawing drawing) =>
          (drawing.outline.contours.single.points.last - end).distance;
      final short = Rect.fromLTRB(end.dx + 40, end.dy, end.dx, end.dy);
      expect(headOf(draw(NoteShapeKind.arrow, box: short)), closeTo(10, 1e-6));
      expect(headOf(draw(NoteShapeKind.arrow)), closeTo(24, 1e-6));
      final capped = draw(NoteShapeKind.arrow, box: short, length: 999);
      expect(headOf(capped), closeTo(24, 1e-6));
      expect(draw(NoteShapeKind.arrow, length: 0).heads, isNull);
      expect(draw(NoteShapeKind.arrow, length: double.nan).heads, isNull);
    });

    test('contained heads stay inside a flat rectangle that can fit them', () {
      const flat = [
        Rect.fromLTWH(0, 0, 200, 35),
        Rect.fromLTWH(0, 0, 35, 200),
        Rect.fromLTRB(200, 35, 0, 0),
        Rect.fromLTRB(0, 60, 200, 0),
      ];
      for (final box in flat) {
        for (final kind in [NoteShapeKind.arrow, NoteShapeKind.doubleArrow]) {
          for (final head in NoteShapeHeadStyle.values) {
            final paths = NoteShapeGeometry.pathsFor(
              kind,
              box,
              headStyle: head,
            );
            expectInside(
              paths.outline,
              Rect.fromPoints(box.topLeft, box.bottomRight),
              reason: '${kind.name} ${head.name} $box',
            );
          }
        }
      }
    });

    test('a horizontal arrow keeps its tip and overflows by half a head', () {
      const box = Rect.fromLTRB(0, 50, 200, 50);
      final paths = NoteShapeGeometry.pathsFor(NoteShapeKind.arrow, box);
      final bounds = paths.outline.getBounds();
      expect(bounds.left, 0);
      expect(bounds.right, closeTo(200, 1e-3));
      expect(bounds.top, closeTo(50 - 12, 1e-3));
      expect(bounds.bottom, closeTo(50 + 12, 1e-3));
    });

    test('without containment the tips are exactly on the end points', () {
      const box = Rect.fromLTRB(0, 0, 200, 35);
      final exact = draw(NoteShapeKind.arrow, box: box);
      expect(
        exact.heads!.contours.single.points,
        contains(closeToOffset(box.bottomRight)),
      );
      final contained = draw(NoteShapeKind.arrow, box: box, contain: true);
      expect(
        contained.heads!.contours.single.points,
        isNot(contains(closeToOffset(box.bottomRight))),
      );
    });

    test('pathsFor merges the heads into the outline', () {
      final merged = NoteShapeGeometry.pathsFor(NoteShapeKind.arrow, leftward);
      expect(contourCount(merged.outline), 2);
      expect(merged.inner, isNull);
      expect(merged.hidden, isNull);
    });

    test('a zero length arrow has no head', () {
      final point = NoteShapeGeometry.drawingFor(
        NoteShapeKind.arrow,
        const Rect.fromLTRB(5, 5, 5, 5),
      );
      expect(point.heads, isNull);
    });
  });

  group('NoteContour', () {
    test('copies its points and compares by value', () {
      final source = [Offset.zero, const Offset(1, 1)];
      final contour = NoteContour(source, closed: true);
      source.add(const Offset(2, 2));
      expect(contour.points, hasLength(2));
      expect(() => contour.points.add(Offset.zero), throwsUnsupportedError);
      expect(
        contour,
        NoteContour(const [Offset.zero, Offset(1, 1)], closed: true),
      );
      expect(contour, isNot(NoteContour(contour.points)));
    });
  });
}

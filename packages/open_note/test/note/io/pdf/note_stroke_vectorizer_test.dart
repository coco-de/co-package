import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/core/const.dart';
import 'package:open_note/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_note/src/module/painters/sketch_line_painter.dart';
import 'package:open_note/src/note/io/pdf/note_stroke_vectorizer.dart';
import 'package:open_note/src/note/io/pdf/note_vector_path.dart';
import 'package:open_note/src/note/io/pdf/note_vector_segment.dart';

import '../support/io_test_support.dart';

class _EnginePaths with SketchLinePainter {}

/// Asserts two paths trace the same geometry: equal contour lengths and equal
/// points at equal fractions of each contour.
void _expectSameGeometry(Path actual, Path expected) {
  final actualMetrics = actual.computeMetrics().toList();
  final expectedMetrics = expected.computeMetrics().toList();
  expect(actualMetrics, hasLength(expectedMetrics.length));
  for (var i = 0; i < actualMetrics.length; i++) {
    final a = actualMetrics[i];
    final e = expectedMetrics[i];
    expect(a.length, closeTo(e.length, e.length * 0.002 + 0.01));
    for (var step = 0; step <= 40; step++) {
      final fraction = step / 40;
      final from = a.getTangentForOffset(a.length * fraction)!.position;
      final to = e.getTangentForOffset(e.length * fraction)!.position;
      expect((from - to).distance, lessThan(0.15), reason: 'at $fraction');
    }
  }
}

/// The bounds of the curve itself; [Path.getBounds] includes Bezier control
/// points.
Rect _tightBounds(NoteVectorPath path) {
  var bounds = Rect.zero;
  var first = true;
  for (final metric in path.toPath().computeMetrics()) {
    for (var step = 0; step <= 200; step++) {
      final point = metric
          .getTangentForOffset(metric.length * step / 200)!
          .position;
      final dot = Rect.fromLTWH(point.dx, point.dy, 0, 0);
      bounds = first ? dot : bounds.expandToInclude(dot);
      first = false;
    }
  }

  return bounds;
}

void main() {
  final engine = _EnginePaths();

  group('ink strokes match the engine paths', () {
    for (final ink in ['pen', 'shape']) {
      test('$ink ink fills the perfect_freehand outline', () {
        final stroke = testStroke(ink: ink, size: 8);

        final shape = NoteStrokeVectorizer.vectorize(stroke)!;

        expect(shape.filled, isTrue);
        expect(shape.color, const Color(0xFF000000));
        _expectSameGeometry(
          shape.path.toPath(),
          engine.getPathForStrokeOld(stroke)!,
        );
      });
    }

    test('pencil strokes the smoothing curve at the stroke size', () {
      final stroke = testStroke(ink: 'pencil', size: 3);

      final shape = NoteStrokeVectorizer.vectorize(stroke)!;

      expect(shape.filled, isFalse);
      expect(shape.strokeWidth, 3);
      _expectSameGeometry(
        shape.path.toPath(),
        engine.getSimplePathForStroke(stroke)!,
      );
    });

    test('marker is twice as wide and keeps translucent colours', () {
      final stroke = testStroke(ink: 'marker', color: 0x80FFEB3B, size: 7);

      final shape = NoteStrokeVectorizer.vectorize(stroke)!;

      expect(shape.strokeWidth, 14);
      expect(shape.color.toARGB32(), 0x80FFEB3B);
      _expectSameGeometry(
        shape.path.toPath(),
        engine.getSimplePathForStroke(stroke)!,
      );
    });

    test('marker pastels get the engine transparency', () {
      const pastel = 0xFFDAD9FF;

      final shape = NoteStrokeVectorizer.vectorize(
        testStroke(ink: 'marker', color: pastel),
      )!;

      expect(
        shape.color.toARGB32(),
        applyTransparencyToMarkerColorValue(pastel),
      );
      expect(shape.color.a, closeTo(0.5, 0.01));
    });

    for (final ink in ['fixedPen', 'uniformPen']) {
      test('$ink strokes the centre line of the uniform outline', () {
        final stroke = testStroke(ink: ink, size: 6);

        final shape = NoteStrokeVectorizer.vectorize(stroke)!;

        expect(shape.filled, isFalse);
        expect(shape.strokeWidth, 6);
        final outline = engine
            .getPathForStrokeOld(
              stroke.deepCopy()
                ..options.thinning = 0
                ..options.simulatePressure = false,
            )!
            .getBounds();
        final painted = shape.path.toPath().getBounds().inflate(3);
        expect(painted.left, closeTo(outline.left, 1.5));
        expect(painted.top, closeTo(outline.top, 1.5));
        expect(painted.right, closeTo(outline.right, 1.5));
        expect(painted.bottom, closeTo(outline.bottom, 1.5));
      });
    }

    test('a sparse uniform stroke bends like the on-screen outline', () {
      const size = 14.0;
      final stroke = testStroke(
        ink: 'uniformPen',
        size: size,
        simulatePressure: false,
        thinning: 0,
        points: testPoints([
          [30, 300],
          [150, 320],
          [260, 290],
        ]),
      );
      final outline = engine.getPathForStrokeOld(stroke)!;

      final metric = NoteStrokeVectorizer.vectorize(
        stroke,
      )!.path.toPath().computeMetrics().single;

      // How far the filled outline reaches from [from] towards [direction].
      double reach(Offset from, Offset direction) {
        var distance = 0.0;
        while (distance < size * 2 &&
            outline.contains(from + direction * (distance + 0.25))) {
          distance += 0.25;
        }

        return distance;
      }

      // Away from the end caps the stroked line stays in the middle of the
      // filled band (a straight polyline strays over 4 units at the bend).
      for (var at = size; at < metric.length - size; at += 4) {
        final tangent = metric.getTangentForOffset(at)!;
        final normal = Offset(-tangent.vector.dy, tangent.vector.dx);
        final one = reach(tangent.position, normal);
        final other = reach(tangent.position, -normal);
        expect(one, greaterThan(size / 4), reason: 'inside at $at');
        expect(other, greaterThan(size / 4), reason: 'inside at $at');
        expect((one - other).abs() / 2, lessThan(1.5), reason: 'at $at');
      }
    });

    test('single points draw dots', () {
      final points = testPoints([
        [10, 10],
      ]);

      final pencil = NoteStrokeVectorizer.vectorize(
        testStroke(ink: 'pencil', points: points),
      )!;
      final pen = NoteStrokeVectorizer.vectorize(testStroke(points: points))!;
      final fixed = NoteStrokeVectorizer.vectorize(
        testStroke(ink: 'fixedPen', points: points),
      )!;

      expect(pencil.path.toPath().getBounds().center, const Offset(10, 10));
      expect(pen.path.isEmpty, isFalse);
      expect(fixed.path.isEmpty, isFalse);
    });

    test('nothing is drawn for lasso, eraser, unknown inks and no points', () {
      for (final ink in ['lasso', 'erase', '', 'laser']) {
        expect(
          NoteStrokeVectorizer.vectorize(testStroke(ink: ink)),
          isNull,
          reason: ink,
        );
      }
      expect(
        NoteStrokeVectorizer.vectorize(
          testStroke(ink: 'lasso', shapeType: 'line'),
        ),
        isNull,
      );
      for (final ink in ['pen', 'pencil', 'marker', 'fixedPen']) {
        expect(
          NoteStrokeVectorizer.vectorize(testStroke(ink: ink, points: [])),
          isNull,
          reason: ink,
        );
      }
    });

    test('non-finite strokes are skipped', () {
      final bad = testStroke(
        points: testPoints([
          [0, 0],
          [double.nan, 4],
        ]),
      );

      expect(NoteStrokeVectorizer.vectorize(bad), isNull);
      expect(
        NoteStrokeVectorizer.vectorize(
          testStroke(size: double.infinity, ink: 'pencil'),
        ),
        isNull,
      );
    });

    test('the input stroke is never modified', () {
      for (final ink in ['pen', 'pencil', 'marker', 'fixedPen']) {
        final stroke = testStroke(ink: ink, color: 0xFFDAD9FF);
        final before = stroke.deepCopy();

        NoteStrokeVectorizer.vectorize(stroke);

        expect(stroke, before, reason: ink);
      }
    });
  });

  group('shape strokes', () {
    List<NoteVectorSegment> segmentsOf(Stroke stroke) =>
        NoteStrokeVectorizer.vectorize(stroke)!.path.segments;

    Stroke shapeStroke(
      String type,
      List<List<num>> points, {
      List<Segment> segments = const [],
    }) => testStroke(
      ink: 'shape',
      shapeType: type,
      points: testPoints(points),
      segments: segments,
      size: 2,
    );

    Segment segment(num x1, num y1, num x2, num y2) => Segment(
      start: Point(x: x1.toDouble(), y: y1.toDouble()),
      end: Point(x: x2.toDouble(), y: y2.toDouble()),
    );

    test('a line is stroked from first to last point', () {
      final shape = NoteStrokeVectorizer.vectorize(
        shapeStroke('line', [
          [1, 2],
          [30, 40],
          [50, 60],
        ]),
      )!;

      expect(shape.filled, isFalse);
      expect(shape.strokeWidth, 2);
      expect(shape.path.segments, [
        const NoteVectorMove(Offset(1, 2)),
        const NoteVectorLine(Offset(50, 60)),
      ]);
    });

    test('a two point rectangle is normalised and closed', () {
      for (final type in ['rectangle', 'square']) {
        final path = NoteStrokeVectorizer.vectorize(
          shapeStroke(type, [
            [40, 30],
            [10, 5],
          ]),
        )!.path;

        expect(path.toPath().getBounds(), const Rect.fromLTRB(10, 5, 40, 30));
        expect(path.segments.last, const NoteVectorClose());
      }
    });

    test('a recognised rectangle follows its segments', () {
      final stroke = shapeStroke(
        'rectangle',
        [
          [0, 0],
          [9, 9],
          [3, 3],
        ],
        segments: [segment(0, 0, 10, 0), segment(10, 0, 10, 8)],
      );

      expect(segmentsOf(stroke), const [
        NoteVectorMove(Offset.zero),
        NoteVectorLine(Offset(10, 0)),
        NoteVectorLine(Offset(10, 8)),
      ]);
    });

    test('a three point rectangle without segments draws nothing', () {
      expect(
        NoteStrokeVectorizer.vectorize(
          shapeStroke('rectangle', [
            [0, 0],
            [9, 9],
            [3, 3],
          ]),
        ),
        isNull,
      );
    });

    test('a two point ellipse fills its bounding box', () {
      for (final type in ['circle', 'ellipse']) {
        final bounds = NoteStrokeVectorizer.vectorize(
          shapeStroke(type, [
            [10, 20],
            [50, 40],
          ]),
        )!.path.toPath().getBounds();

        expect(bounds.left, closeTo(10, 0.01));
        expect(bounds.top, closeTo(20, 0.01));
        expect(bounds.width, closeTo(40, 0.01));
        expect(bounds.height, closeTo(20, 0.01));
      }
    });

    test('a recognised ellipse is fitted to its points', () {
      const tilt = math.pi / 6;
      final stroke = shapeStroke('ellipse', [
        for (var i = 0; i < 64; i++)
          [
            100 +
                40 * math.cos(i / 64 * 2 * math.pi) * math.cos(tilt) -
                15 * math.sin(i / 64 * 2 * math.pi) * math.sin(tilt),
            80 +
                40 * math.cos(i / 64 * 2 * math.pi) * math.sin(tilt) +
                15 * math.sin(i / 64 * 2 * math.pi) * math.cos(tilt),
          ],
      ]);

      final bounds = _tightBounds(NoteStrokeVectorizer.vectorize(stroke)!.path);
      // The tilted ellipse spans about 70.6 x 46.9 around (100, 80); the
      // engine's fit keeps about that size.
      expect(bounds.center.dx, closeTo(100, 0.5));
      expect(bounds.center.dy, closeTo(80, 0.5));
      expect(bounds.width, closeTo(70.6, 5));
      expect(bounds.height, closeTo(46.9, 8));
    });

    test('an exactly round cloud of points gives a finite circle', () {
      // Isotropic covariance: the case where rounding can make the engine's
      // discriminant negative.
      final stroke = shapeStroke('circle', [
        for (var i = 0; i < 8; i++)
          [10 * math.cos(i * math.pi / 4), 10 * math.sin(i * math.pi / 4)],
      ]);

      final bounds = _tightBounds(NoteStrokeVectorizer.vectorize(stroke)!.path);

      expect(bounds.isFinite, isTrue);
      expect(bounds.width, closeTo(bounds.height, 0.01));
      expect(bounds.width, inInclusiveRange(18, 20.5));
    });

    test('a circle with under five points is a polyline', () {
      expect(
        segmentsOf(
          shapeStroke('circle', [
            [0, 0],
            [5, 5],
            [10, 0],
          ]),
        ),
        const [
          NoteVectorMove(Offset.zero),
          NoteVectorLine(Offset(5, 5)),
          NoteVectorLine(Offset(10, 0)),
        ],
      );
    });

    test('polylines are open, other shapes follow their segment ring', () {
      expect(
        segmentsOf(
          shapeStroke('polyline', [
            [0, 0],
            [5, 5],
          ]),
        ),
        hasLength(2),
      );
      expect(
        segmentsOf(
          shapeStroke(
            'triangle',
            [
              [0, 0],
              [10, 0],
              [5, 8],
            ],
            segments: [
              segment(0, 0, 10, 0),
              segment(10, 0, 5, 8),
              segment(5, 8, 0, 0),
            ],
          ),
        ),
        hasLength(4),
      );
    });

    test('unrecognised and one point shapes draw nothing', () {
      expect(
        NoteStrokeVectorizer.vectorize(
          shapeStroke('pending', [
            [0, 0],
            [5, 5],
          ]),
        ),
        isNull,
      );
      expect(
        NoteStrokeVectorizer.vectorize(
          shapeStroke('line', [
            [0, 0],
          ]),
        ),
        isNull,
      );
    });
  });

  group('NoteVectorPath', () {
    test('needs a current point and tracks it through close', () {
      final path = NoteVectorPath();
      expect(() => path.lineTo(Offset.zero), throwsStateError);
      expect(path.close, throwsStateError);
      path
        ..moveTo(const Offset(1, 1))
        ..lineTo(const Offset(5, 1))
        ..close()
        ..quadraticTo(const Offset(1, 4), const Offset(4, 4));
      expect(path.segments, hasLength(4));
      expect(
        () => path.segments.add(const NoteVectorClose()),
        throwsUnsupportedError,
      );
    });

    test('ovals can be rotated', () {
      final bounds =
          (NoteVectorPath()..addOval(
                const Rect.fromLTWH(0, 0, 40, 10),
                rotation: math.pi / 2,
              ))
              .toPath()
              .getBounds();

      expect(bounds.width, closeTo(10, 0.01));
      expect(bounds.height, closeTo(40, 0.01));
      expect(bounds.center.dx, closeTo(20, 0.01));
      expect(bounds.center.dy, closeTo(5, 0.01));
    });

    test('segments compare by value', () {
      expect(
        const NoteVectorCubic(Offset(1, 1), Offset(2, 2), Offset(3, 3)),
        const NoteVectorCubic(Offset(1, 1), Offset(2, 2), Offset(3, 3)),
      );
      expect(
        const NoteVectorMove(Offset.zero),
        isNot(const NoteVectorLine(Offset.zero)),
      );
      expect(const NoteVectorClose().toString(), 'Z');
    });
  });
}

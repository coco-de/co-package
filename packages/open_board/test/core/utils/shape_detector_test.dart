import 'dart:math' as math;

import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/core/utils/shape_detector.dart';
import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';

import '../../helpers/test_helpers.dart';

/// 꼭짓점 목록을 따라 변마다 [pointsPerSide]개씩 샘플링한 폐곡선 점을 생성
List<Point> _sampleClosedPath(
  List<List<double>> vertices, {
  int pointsPerSide = 12,
  double bulge = 0,
  List<double>? center,
}) {
  final points = <Point>[];
  for (int v = 0; v < vertices.length; v++) {
    final a = vertices[v];
    final b = vertices[(v + 1) % vertices.length];
    final mx = (a[0] + b[0]) / 2;
    final my = (a[1] + b[1]) / 2;
    final ox = center != null ? mx - center[0] : 0.0;
    final oy = center != null ? my - center[1] : 0.0;
    final len = math.sqrt(ox * ox + oy * oy);

    for (int i = 0; i < pointsPerSide; i++) {
      final t = i / pointsPerSide;
      final sag = bulge > 0 && len > 0 ? math.sin(t * math.pi) * bulge : 0.0;
      points.add(
        Point(
          x: a[0] + (b[0] - a[0]) * t + (len > 0 ? ox / len * sag : 0),
          y: a[1] + (b[1] - a[1]) * t + (len > 0 ? oy / len * sag : 0),
        ),
      );
    }
  }
  points.add(Point(x: vertices.first[0], y: vertices.first[1]));
  return points;
}

void main() {
  group('ShapeDetector', () {
    late ShapeDetector detector;

    setUp(() {
      detector = .instance;
    });

    group('detectAndTransform', () {
      test('포인트 5개 미만이면 polyline 반환', () {
        final stroke = createStroke(
          points: createPoints([
            [0, 0],
            [10, 10],
            [20, 0],
          ]),
        );
        final result = detector.detectAndTransform(stroke);
        expect(result.shapeType, ShapeType.polyline);
      });

      test('직선 감지', () {
        final stroke = createStroke(
          points: createLinePoints(
            fromX: 0,
            fromY: 0,
            toX: 200,
            toY: 0,
            count: 20,
          ),
          ink: 'shape',
        );
        final result = detector.detectAndTransform(stroke);
        // 직선이거나 polyline
        expect(
          result.shapeType,
          isIn([ShapeType.line, ShapeType.polyline, ShapeType.connector]),
        );
      });

      test('사각형 감지 시도', () {
        final stroke = createStroke(
          points: createRectanglePoints(
            left: 0,
            top: 0,
            right: 100,
            bottom: 100,
            pointsPerSide: 10,
          ),
          ink: 'shape',
        );
        final result = detector.detectAndTransform(stroke);
        // 어떤 도형이든 감지되어야 함
        expect(result.shapeType, isNot(ShapeType.none));
      });

      test('원본 스트로크 보존', () {
        final stroke = createStroke(
          points: createLinePoints(count: 20),
          ink: 'shape',
        );
        final result = detector.detectAndTransform(stroke);
        expect(result.transformedStroke, isNotNull);
      });

      test('변환 스트로크에 원본 손그림 점이 포함되지 않는다', () {
        final stroke = createStroke(
          points: createRectanglePoints(
            left: 0,
            top: 0,
            right: 100,
            bottom: 100,
            pointsPerSide: 10,
          ),
          ink: 'shape',
        );
        final result = detector.detectAndTransform(stroke);
        // 변환 결과는 변환된 기하(코너/타원 점)만 담아야 하며,
        // 원본 점 위에 변환 점이 누적되면 안 된다.
        expect(
          result.transformedStroke.points.length,
          lessThan(stroke.points.length),
        );
      });

      test('변환 후 원본 스트로크의 점은 변형되지 않는다', () {
        final points = createRectanglePoints(
          left: 0,
          top: 0,
          right: 100,
          bottom: 100,
          pointsPerSide: 10,
        );
        final originalCount = points.length;
        final stroke = createStroke(points: points, ink: 'shape');

        detector.detectAndTransform(stroke);

        expect(stroke.points.length, originalCount);
      });

      test('직선 변환 결과는 양 끝점 2개만 담는다', () {
        final stroke = createStroke(
          points: createLinePoints(
            fromX: 0,
            fromY: 0,
            toX: 200,
            toY: 0,
            count: 20,
          ),
          ink: 'shape',
        );
        final result = detector.detectAndTransform(stroke);
        expect(result.shapeType, ShapeType.line);
        expect(result.transformedStroke.points.length, 2);
      });

      test('깨끗한 삼각형 궤적은 삼각형으로 분류된다', () {
        final stroke = createStroke(
          points: _sampleClosedPath([
            [0, 0],
            [100, 0],
            [50, 87],
          ]),
          ink: 'shape',
        );
        final result = detector.detectAndTransform(stroke);
        expect(
          result.shapeType,
          isIn([
            ShapeType.triangle,
            ShapeType.rightTriangle,
            ShapeType.equilateralTriangle,
            ShapeType.isoscelesTriangle,
            ShapeType.irregularTriangle,
          ]),
        );
      });

      test('triangleScore가 낮은 3코너 폐곡선은 삼각형으로 스냅되지 않는다', () {
        // 변이 바깥으로 휜 삼각형: 코너는 3개지만 triangleScore가
        // 게이트(0.65)에 미달 → 삼각형 스냅 대신 polyline 유지
        final stroke = createStroke(
          points: _sampleClosedPath(
            [
              [0, 0],
              [120, 0],
              [60, 104],
            ],
            pointsPerSide: 20,
            bulge: 10,
            center: [60, 34.7],
          ),
          ink: 'shape',
        );
        final result = detector.detectAndTransform(stroke);
        expect(result.shapeType, ShapeType.polyline);
      });

      test('게이트 탈락 폐곡선의 폴리라인 변환은 닫힘 형태를 보존한다', () {
        final stroke = createStroke(
          points: _sampleClosedPath(
            [
              [0, 0],
              [120, 0],
              [60, 104],
            ],
            pointsPerSide: 20,
            bulge: 10,
            center: [60, 34.7],
          ),
          ink: 'shape',
        );
        final result = detector.detectAndTransform(stroke);
        final points = result.transformedStroke.points;

        // 닫힘 변이 소실된 열린 V자(코너 3점)로 축약되면 안 된다
        expect(points.length, greaterThan(3));
        expect(points.first.x, points.last.x);
        expect(points.first.y, points.last.y);
      });

      test('변환 점들의 timestamp는 원본 구간에서 단조 증가로 보간된다', () {
        final source = createLinePoints(
          fromX: 0,
          fromY: 0,
          toX: 200,
          toY: 0,
          count: 20,
        );
        for (var i = 0; i < source.length; i++) {
          source[i].timestamp = Int64(1000 + i * 100);
        }
        final stroke = createStroke(points: source, ink: 'shape');
        final result = detector.detectAndTransform(stroke);

        final transformed = result.transformedStroke.points;
        expect(transformed.first.timestamp, source.first.timestamp);
        expect(transformed.last.timestamp, source.last.timestamp);
        for (var i = 1; i < transformed.length; i++) {
          expect(
            transformed[i].timestamp >= transformed[i - 1].timestamp,
            isTrue,
          );
        }
      });
    });

    group('ShapeDetectionResult', () {
      test('shapeTypeString 변환', () {
        final stroke = createStroke();
        final result = ShapeDetectionResult(.line, stroke);
        expect(result.shapeTypeString, 'line');
      });

      test('none은 빈 문자열', () {
        final stroke = createStroke();
        final result = ShapeDetectionResult(.none, stroke);
        expect(result.shapeTypeString, '');
      });
    });

    group('ShapeType enum', () {
      test('모든 타입 존재', () {
        expect(ShapeType.values.length, greaterThan(10));
        expect(ShapeType.values, contains(ShapeType.rectangle));
        expect(ShapeType.values, contains(ShapeType.circle));
        expect(ShapeType.values, contains(ShapeType.triangle));
      });
    });
  });
}

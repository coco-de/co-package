  // 🎯 Dart imports:
  import 'dart:math' as math;

  // 🐦 Flutter imports:

  // 🌎 Project imports:
  import 'package:flutter/material.dart';
  import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
  import 'geometry_utils.dart';
  import 'point_simplifier.dart';
  import 'corner_detector.dart';
  import 'convex_hull_calculator.dart';

  /// 도형 타입을 나타내는 열거형
  enum ShapeType {
    none,
    line,
    rectangle,
    square,
    diamond,
    parallelogram,
    trapezoid,
    irregularQuadrilateral,
    triangle,
    rightTriangle,
    equilateralTriangle,
    isoscelesTriangle,
    irregularTriangle,
    polygon,
    pentagon,
    hexagon,
    circle,
    ellipse,
    arrow,
    doubleArrow,
    blockArrow,
    connector,
    polyline,
    pending,
  }

  /// 도형 특성을 나타내는 클래스 - 알고리즘 계산에 사용
  class ShapeCharacteristics {
    final Rect boundingBox;
    final Point centroid;
    final double aspectRatio;
    final List<Point> convexHull;

    const ShapeCharacteristics({
      required this.boundingBox,
      required this.centroid,
      required this.aspectRatio,
      required this.convexHull,
    });
  }

  /// 도형 인식 결과를 담는 클래스
  class ShapeDetectionResult {
    final ShapeType shapeType;
    final Stroke transformedStroke;

    const ShapeDetectionResult(this.shapeType, this.transformedStroke);

    /// 문자열 형태의 shapeType 반환
    String get shapeTypeString {
      switch (shapeType) {
        case .line:
          return 'line';
        case .rectangle:
          return 'rectangle';
        case .square:
          return 'square';
        case .diamond:
          return 'diamond';
        case .parallelogram:
          return 'parallelogram';
        case .trapezoid:
          return 'trapezoid';
        case .irregularQuadrilateral:
          return 'irregular_quadrilateral';
        case .triangle:
          return 'triangle';
        case .rightTriangle:
          return 'right_triangle';
        case .equilateralTriangle:
          return 'equilateral_triangle';
        case .isoscelesTriangle:
          return 'isosceles_triangle';
        case .irregularTriangle:
          return 'irregular_triangle';
        case .polygon:
          return 'polygon';
        case .pentagon:
          return 'pentagon';
        case .hexagon:
          return 'hexagon';
        case .circle:
          return 'circle';
        case .ellipse:
          return 'ellipse';
        case .arrow:
          return 'arrow';
        case .doubleArrow:
          return 'double_arrow';
        case .blockArrow:
          return 'block_arrow';
        case .connector:
          return 'connector';
        case .polyline:
          return 'polyline';
        case .pending:
          return 'pending';
        case .none:
          return '';
      }
    }
  }

  /// 도형 인식 및 변환을 담당하는 메인 클래스
  class ShapeDetector {
    /// 싱글턴 인스턴스
    static final ShapeDetector instance = ShapeDetector._();

    // 폐곡선 인식 임계값 (시작점과 끝점 사이 거리가 둘레의 15% 미만이면 폐곡선)
    static const double _closedThreshold = 0.15;

    /// 인스턴스 생성을 제한하는 private 생성자
    const ShapeDetector._();

    /// 도형 인식 및 변환 - 메인 진입점
    ShapeDetectionResult detectAndTransform(Stroke stroke) {
      // 원본 점이 너무 적으면 그대로 사용
      if (stroke.points.length < 5) {
        return ShapeDetectionResult(.polyline, stroke);
      }

      // 1. 기본 정보 계산
      final perimeter = GeometryUtils.calculatePolygonPerimeter(stroke.points);
      final isClosed = _isClosedShape(stroke.points, perimeter);
      final almostClosed = _isAlmostClosed(stroke.points, perimeter);

      // 2. 포인트 단순화
      final simplifiedPoints = _performPointSimplification(
        stroke.points,
        perimeter,
      );

      // 3. 변환된 스트로크 생성
      final transformedStroke = _createTransformedStroke(stroke);

      // 4. 원/타원 감지 시도
      if (isClosed || almostClosed) {
        final circleResult = _tryDetectCircleOrEllipse(
          simplifiedPoints,
          transformedStroke,
        );
        if (circleResult != null) return circleResult;
      }

      // 5. 코너 기반 도형 감지
      return _detectPolygonalShapes(
        simplifiedPoints,
        transformedStroke,
        isClosed,
        almostClosed,
      );
    }

    /// 포인트 단순화 수행
    List<Point> _performPointSimplification(
      List<Point> points,
      double perimeter,
    ) {
      double simplificationFactor = 0.01;

      // 포인트가 많을수록 단순화 강도 증가
      if (points.length > 200) {
        simplificationFactor = 0.01 * (1 + (points.length - 200) / 300);
      }

      final simplifiedPoints = PointSimplifier.simplifyPoints(
        points,
        perimeter * simplificationFactor,
      );

      return simplifiedPoints;
    }

    /// 변환된 스트로크 생성
    Stroke _createTransformedStroke(Stroke stroke) {
      return Stroke(
        color: stroke.color,
        ink: "shape",
        width: stroke.width,
        points: stroke.points,
        createdAt: stroke.createdAt,
        options: stroke.options,
      );
    }

    /// 원/타원 감지 시도
    ShapeDetectionResult? _tryDetectCircleOrEllipse(
      List<Point> points,
      Stroke transformedStroke,
    ) {
      if (_isCircleOrEllipse(points)) {
        _createEllipse(transformedStroke, points);

        final ellipseType = _determineEllipseType(points);
        return ShapeDetectionResult(ellipseType, transformedStroke);
      }
      return null;
    }

    /// 다각형 모양 감지
    ShapeDetectionResult _detectPolygonalShapes(
      List<Point> simplifiedPoints,
      Stroke transformedStroke,
      bool isClosed,
      bool almostClosed,
    ) {
      // 코너 감지
      final corners = CornerDetector.detectSignificantCorners(simplifiedPoints);

      // 폐곡선이지만 코너가 부족한 경우 코너 생성
      List<Point> finalCorners = corners;
      if (isClosed && corners.length < 3 && simplifiedPoints.length >= 3) {
        finalCorners = CornerDetector.generateCornersForClosedShape(
          simplifiedPoints,
        );
      }

      return _classifyShapeByCorners(
        finalCorners,
        transformedStroke,
        isClosed,
        almostClosed,
        simplifiedPoints,
      );
    }

    /// 코너 수에 따른 도형 분류
    ShapeDetectionResult _classifyShapeByCorners(
      List<Point> corners,
      Stroke transformedStroke,
      bool isClosed,
      bool almostClosed,
      List<Point> simplifiedPoints,
    ) {
      // 삼각형 확인 (코너가 정확히 3개일 때)
      if (corners.length == 3 && (isClosed || almostClosed)) {
        final triangleScore = CornerDetector.evaluateTriangleShape(
          simplifiedPoints,
        );
        if (triangleScore > 0.65) {
          _createPolygonFromCorners(transformedStroke, corners, true);

          final triangleType = _determineTriangleType(corners);
          return ShapeDetectionResult(triangleType, transformedStroke);
        }
      }

      // 사각형 확인
      if (corners.length == 4 && isClosed) {
        _createPolygonFromCorners(transformedStroke, corners, true);

        final quadType = _determineQuadrilateralType(corners);
        return ShapeDetectionResult(quadType, transformedStroke);
      }

      // 삼각형 확인 (코너가 3개인 경우)
      if (corners.length == 3 && (isClosed || almostClosed)) {
        _createPolygonFromCorners(transformedStroke, corners, true);

        final triangleType = _determineTriangleType(corners);
        return ShapeDetectionResult(triangleType, transformedStroke);
      }

      // 다각형 확인
      if (corners.length >= 5 && isClosed) {
        _createPolygonFromCorners(transformedStroke, corners, true);

        final polygonType = _determinePolygonType(corners);
        return ShapeDetectionResult(polygonType, transformedStroke);
      }

      // 직선 확인
      if (corners.length == 2) {
        transformedStroke.points.add(corners[0]);
        transformedStroke.points.add(corners[1]);
        return ShapeDetectionResult(.line, transformedStroke);
      }

      // 기본값: 폴리라인
      _createPolylineFromCorners(
        transformedStroke,
        corners.isEmpty ? simplifiedPoints : corners,
      );
      return ShapeDetectionResult(.polyline, transformedStroke);
    }

    /// 원/타원 여부 판별
    bool _isCircleOrEllipse(List<Point> points) {
      if (points.length < 8) return false;

      final characteristics = _calculateShapeCharacteristics(points);
      final center = characteristics.centroid;

      // 중심에서 각 점까지의 거리 분석
      final distances = points
          .map((point) => GeometryUtils.calculateDistance(center, point))
          .toList();

      final avgDistance = distances.reduce((a, b) => a + b) / distances.length;
      final variance =
          distances
              .map((dist) => math.pow(dist - avgDistance, 2))
              .reduce((a, b) => a + b) /
          distances.length;
      final stdDev = math.sqrt(variance);
      final stdDevRatio = stdDev / avgDistance;

      // 컨벡스 헐 점 비율
      final hullRatio = characteristics.convexHull.length / points.length;

      // 종횡비
      final aspectRatio = characteristics.aspectRatio;
      final adjustedAspectRatio = aspectRatio > 1
          ? 1 / aspectRatio
          : aspectRatio;

      // 예리한 모서리 수 확인
      int sharpCorners = _countSharpCorners(points, center);

      // 종합 점수 계산
      double hullScore = (hullRatio < 0.3)
          ? 1.0
          : math.max(0.0, 1.0 - (hullRatio - 0.3) * 2);
      double distanceScore = (stdDevRatio < 0.35)
          ? 1.0
          : math.max(0.0, 1.0 - (stdDevRatio - 0.35) * 2);
      double aspectScore = (adjustedAspectRatio > 0.5)
          ? 1.0
          : adjustedAspectRatio / 0.5;
      double cornerScore = (sharpCorners < 4)
          ? 1.0
          : 1.0 - (sharpCorners / 12.0);

      double circleScore =
          hullScore * 0.3 +
          distanceScore * 0.4 +
          aspectScore * 0.2 +
          cornerScore * 0.1;

      return circleScore > 0.65;
    }

    /// 예리한 모서리 수 계산
    int _countSharpCorners(List<Point> points, Point center) {
      int sharpCorners = 0;
      int step = math.max(1, points.length ~/ 10);

      for (int i = 0; i < points.length; i += step) {
        final prev = points[(i - step + points.length) % points.length];
        final curr = points[i];
        final next = points[(i + step) % points.length];

        final angle = GeometryUtils.calculateCornerAngle(prev, curr, next);
        if (angle < 110) {
          sharpCorners++;
        }
      }

      return sharpCorners;
    }

    /// 타원 생성
    void _createEllipse(Stroke stroke, List<Point> points) {
      final characteristics = _calculateShapeCharacteristics(points);
      final center = characteristics.centroid;
      final boundingBox = characteristics.boundingBox;

      // 회전각 계산
      double rotation = _calculateRotation(points, center);

      // 타원 크기 계산
      double width = boundingBox.width;
      double height = boundingBox.height;

      // 원형에 가까울 경우 조정
      final aspectRatio = characteristics.aspectRatio;
      final isNearlyCircle = aspectRatio > 0.9 && aspectRatio < 1.1;

      if (isNearlyCircle) {
        final radius = math.max(width, height) / 2;
        width = radius * 2;
        height = radius * 2;
        rotation = 0;
      }

      // 타원 점 생성
      final numPoints = isNearlyCircle ? 36 : 48;
      _generateEllipsePoints(
        stroke,
        center,
        width / 2,
        height / 2,
        rotation,
        numPoints,
      );
    }

    /// 회전각 계산
    double _calculateRotation(List<Point> points, Point center) {
      double sumXY = 0, sumXX = 0, sumYY = 0;

      for (final point in points) {
        final dx = point.x - center.x;
        final dy = point.y - center.y;
        sumXX += dx * dx;
        sumYY += dy * dy;
        sumXY += dx * dy;
      }

      if (sumXY != 0) {
        return 0.5 * math.atan2(2 * sumXY, sumXX - sumYY);
      }
      return 0.0;
    }

    /// 타원 점 생성
    void _generateEllipsePoints(
      Stroke stroke,
      Point center,
      double radiusX,
      double radiusY,
      double rotation,
      int numPoints,
    ) {
      for (int i = 0; i <= numPoints; i++) {
        final angle = i * (2 * math.pi / numPoints);

        final cosAngle = math.cos(angle);
        final sinAngle = math.sin(angle);
        final cosRotation = math.cos(rotation);
        final sinRotation = math.sin(rotation);

        final x =
            center.x +
            radiusX * cosAngle * cosRotation -
            radiusY * sinAngle * sinRotation;
        final y =
            center.y +
            radiusX * cosAngle * sinRotation +
            radiusY * sinAngle * cosRotation;

        stroke.points.add(Point(x: x, y: y));
      }
    }

    /// 코너점으로 다각형 생성
    void _createPolygonFromCorners(
      Stroke stroke,
      List<Point> corners,
      bool close,
    ) {
      if (corners.length < 3 && close) {
        return;
      }

      // 원래 그린 순서를 유지하면서 정렬
      if (corners.length >= 3) {
        final orderedCorners = _orderCornersPreservingDirection(corners);
        stroke.points.addAll(orderedCorners);

        // 폐곡선이면 첫 점을 다시 추가하여 닫기
        if (close && orderedCorners.isNotEmpty) {
          stroke.points.add(orderedCorners.first);
        }

        _generateSegments(stroke, orderedCorners, close);
      }
    }

    /// 방향을 보존하며 코너 정렬
    List<Point> _orderCornersPreservingDirection(List<Point> corners) {
      if (corners.length <= 2) return corners;

      final originalCentroid = GeometryUtils.calculateCentroid(corners);

      if (corners.length == 3 || corners.length == 4) {
        final firstPoint = corners.first;
        final startAngle = math.atan2(
          firstPoint.y - originalCentroid.y,
          firstPoint.x - originalCentroid.x,
        );

        corners.sort((a, b) {
          final angleA =
              (math.atan2(a.y - originalCentroid.y, a.x - originalCentroid.x) -
                  startAngle) %
              (2 * math.pi);
          final angleB =
              (math.atan2(b.y - originalCentroid.y, b.x - originalCentroid.x) -
                  startAngle) %
              (2 * math.pi);
          return angleA.compareTo(angleB);
        });
      } else {
        corners.sort((a, b) {
          final angleA = math.atan2(
            a.y - originalCentroid.y,
            a.x - originalCentroid.x,
          );
          final angleB = math.atan2(
            b.y - originalCentroid.y,
            b.x - originalCentroid.x,
          );
          return angleA.compareTo(angleB);
        });
      }

      return corners;
    }

    /// 세그먼트 생성
    void _generateSegments(Stroke stroke, List<Point> corners, bool close) {
      for (int i = 0; i < corners.length; i++) {
        final segment = Segment()
          ..start = corners[i]
          ..end = corners[(i + 1) % corners.length];

        stroke.segments.add(segment);
      }

      if (!close && corners.length > 1) {
        stroke.segments.last.end = corners.last;
      }
    }

    /// 코너점으로 폴리라인 생성
    void _createPolylineFromCorners(Stroke stroke, List<Point> corners) {
      for (int i = 0; i < corners.length - 1; i++) {
        final segment = Segment()
          ..start = corners[i]
          ..end = corners[i + 1];

        stroke.segments.add(segment);
      }

      stroke.points.addAll(corners);
    }

    /// 폐곡선 여부 확인
    bool _isClosedShape(List<Point> points, double perimeter) {
      if (points.length < 3) return false;

      final distance = GeometryUtils.calculateDistance(
        points.first,
        points.last,
      );
      final threshold = perimeter * _closedThreshold;

      // 추가 검증 로직
      if (distance < threshold && points.length > 10) {
        return _validateClosedShape(points, perimeter, distance, threshold);
      }

      return distance < threshold;
    }

    /// 폐곡선 검증
    bool _validateClosedShape(
      List<Point> points,
      double perimeter,
      double distance,
      double threshold,
    ) {
      final tenthOfLength = (points.length ~/ 10).toInt();
      final minSampleSize = math.min(5, tenthOfLength);

      final startVector = GeometryUtils.calculatePathDirection(
        points,
        0,
        minSampleSize,
      );
      final endStartIdx = points.length - minSampleSize - 1;
      final endEndIdx = points.length - 1;
      final endVector = GeometryUtils.calculatePathDirection(
        points,
        endStartIdx,
        endEndIdx,
      );

      final dotProduct =
          startVector.x * endVector.x + startVector.y * endVector.y;
      final magnitudeProduct =
          math.sqrt(
            startVector.x * startVector.x + startVector.y * startVector.y,
          ) *
          math.sqrt(endVector.x * endVector.x + endVector.y * endVector.y);

      if (magnitudeProduct > 0) {
        final cosAngle = (dotProduct / magnitudeProduct).clamp(-1.0, 1.0);
        final angleRad = math.acos(cosAngle);
        final angleDeg = angleRad * 180 / math.pi;

        if (angleDeg < 30 && distance > threshold * 0.5) {
          return false;
        }
      }

      if (perimeter > 500 && distance > threshold * 0.7) {
        return false;
      }

      return true;
    }

    /// 거의 폐곡선에 가까운지 확인
    bool _isAlmostClosed(List<Point> points, double perimeter) {
      if (points.length < 3) return false;

      final distance = GeometryUtils.calculateDistance(
        points.first,
        points.last,
      );
      final threshold = perimeter * 0.25;

      return distance < threshold;
    }

    /// 도형 특성 계산
    ShapeCharacteristics _calculateShapeCharacteristics(List<Point> points) {
      if (points.isEmpty) {
        return ShapeCharacteristics(
          boundingBox: .zero,
          centroid: Point(x: 0, y: 0),
          aspectRatio: 1.0,
          convexHull: [],
        );
      }

      final boundingBox = GeometryUtils.calculateBoundingBox(points);
      final centroid = GeometryUtils.calculateCentroid(points);
      final perimeter = GeometryUtils.calculatePolygonPerimeter(points);
      final aspectRatio = boundingBox.width > 0
          ? boundingBox.height / boundingBox.width
          : 1.0;

      final simplifiedPoints = PointSimplifier.simplifyPoints(
        points,
        perimeter * 0.02,
      );
      final convexHull = ConvexHullCalculator.calculateConvexHull(
        simplifiedPoints,
      );
      return ShapeCharacteristics(
        boundingBox: boundingBox,
        centroid: centroid,
        aspectRatio: aspectRatio,
        convexHull: convexHull,
      );
    }

    /// 사각형 세부 유형 판별
    ShapeType _determineQuadrilateralType(List<Point> corners) {
      if (corners.length != 4) return .irregularQuadrilateral;

      final sides = _calculateSideLengths(corners);
      final angles = _calculateCornerAngles(corners);
      final isRightAngled = _isRightAngled(angles);

      // 변의 길이 비율 검사
      final maxSide = sides.reduce(math.max);
      final minSide = sides.reduce(math.min);
      final sideRatio = minSide / maxSide;

      // 정사각형 검사
      if (sideRatio > 0.9 && isRightAngled) {
        return .square;
      }

      // 다이아몬드 검사
      if (sideRatio > 0.9 && !isRightAngled) {
        final boundingBox = GeometryUtils.calculateBoundingBox(corners);
        final aspectRatio = boundingBox.width / boundingBox.height;

        if (aspectRatio > 0.8 && aspectRatio < 1.2) {
          return .diamond;
        }
      }

      // 직사각형 검사
      if (isRightAngled && _hasParallelSides(sides)) {
        return .rectangle;
      }

      return .irregularQuadrilateral;
    }

    /// 변의 길이 계산
    List<double> _calculateSideLengths(List<Point> corners) {
      final sides = <double>[];
      for (int i = 0; i < corners.length; i++) {
        final next = (i + 1) % corners.length;
        sides.add(GeometryUtils.calculateDistance(corners[i], corners[next]));
      }
      return sides;
    }

    /// 코너 각도 계산
    List<double> _calculateCornerAngles(List<Point> corners) {
      final angles = <double>[];
      for (int i = 0; i < corners.length; i++) {
        final prev = corners[(i - 1 + corners.length) % corners.length];
        final curr = corners[i];
        final next = corners[(i + 1) % corners.length];
        angles.add(GeometryUtils.calculateCornerAngle(prev, curr, next));
      }
      return angles;
    }

    /// 직각인지 확인
    bool _isRightAngled(List<double> angles) {
      return angles.every((angle) => angle >= 75 && angle <= 105);
    }

    /// 평행한 변이 있는지 확인
    bool _hasParallelSides(List<double> sides) {
      return (sides[0] - sides[2]).abs() / math.max(sides[0], sides[2]) < 0.1 &&
          (sides[1] - sides[3]).abs() / math.max(sides[1], sides[3]) < 0.1;
    }

    /// 삼각형 세부 유형 판별
    ShapeType _determineTriangleType(List<Point> corners) {
      if (corners.length != 3) return .irregularTriangle;

      final sides = _calculateSideLengths(corners);
      final angles = _calculateCornerAngles(corners);

      // 직각 삼각형 검사
      if (angles.any((angle) => angle >= 85 && angle <= 95)) {
        return .rightTriangle;
      }

      // 정삼각형 검사
      final maxSide = sides.reduce(math.max);
      final minSide = sides.reduce(math.min);
      final sideRatio = minSide / maxSide;

      if (sideRatio > 0.9) {
        return .equilateralTriangle;
      }

      // 이등변 삼각형 검사
      final sortedSides = List<double>.of(sides)..sort();
      if ((sortedSides[0] / sortedSides[1]) > 0.9 ||
          (sortedSides[1] / sortedSides[2]) > 0.9) {
        return .isoscelesTriangle;
      }

      return .irregularTriangle;
    }

    /// 다각형 세부 유형 판별
    ShapeType _determinePolygonType(List<Point> corners) {
      switch (corners.length) {
        case 5:
          return .pentagon;
        case 6:
          return .hexagon;
        default:
          return .polygon;
      }
    }

    /// 원/타원 세부 유형 판별
    ShapeType _determineEllipseType(List<Point> points) {
      final characteristics = _calculateShapeCharacteristics(points);
      final aspectRatio = characteristics.aspectRatio;

      return aspectRatio >= 0.9 && aspectRatio <= 1.1 ? .circle : .ellipse;
    }
  }

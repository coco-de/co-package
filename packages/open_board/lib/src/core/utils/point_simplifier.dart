import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_board/src/core/algorithm/douglas_peucker.dart' as dp;

/// 포인트 단순화를 담당하는 클래스
class PointSimplifier {
  PointSimplifier._();

  /// Douglas-Peucker 알고리즘을 사용한 포인트 단순화
  static List<Point> simplifyPoints(List<Point> points, double epsilon) {
    if (points.length <= 2) return List.from(points);

    // 입력 포인트 수에 따라 단순화 강도 조정
    double dynamicEpsilon = _calculateDynamicEpsilon(points.length, epsilon);

    // protobuf Point를 douglas_peucker 라이브러리의 Point로 변환
    final dpPoints = points.map((pt) => dp.Point(pt.x, pt.y)).toList();

    // 라이브러리의 단순화 알고리즘 사용
    final simplified = dp.DouglasPeucker.simplify(
      dpPoints,
      tolerance: dynamicEpsilon,
    );

    // 결과를 다시 protobuf Point로 변환
    final result = simplified.map((pt) => Point(x: pt.x, y: pt.y)).toList();

    // 단순화 후 너무 많은 포인트가 남아있으면 추가 단순화 수행
    if (result.length > 20 && points.length > 50) {
      return simplifyPoints(result, dynamicEpsilon * 1.5);
    }

    return result;
  }

  /// 적응형 단순화 - 입력에 따라 적응형 단순화 수행
  static List<Point> adaptiveSimplify(
    List<Point> points,
    double perimeter,
    bool isClosed,
  ) {
    if (points.length <= 5) return List.from(points);

    // 기본 단순화 수행
    final epsilon = perimeter * 0.01; // 기본: 둘레의 1%
    List<Point> simplified = simplifyPoints(points, epsilon);

    // 폐곡선이고 점이 많으면 좀 더 적극적인 단순화 시도
    if (isClosed) {
      simplified = _performClosedShapeSimplification(
        points,
        simplified,
        epsilon,
      );
    }

    return simplified;
  }

  /// 동적 epsilon 값 계산
  static double _calculateDynamicEpsilon(int pointCount, double baseEpsilon) {
    if (pointCount > 100) {
      final multiplier = 1.0 + (pointCount - 100) / 200;
      return baseEpsilon * multiplier;
    }
    return baseEpsilon;
  }

  /// 폐곡선에 대한 단순화 수행
  static List<Point> _performClosedShapeSimplification(
    List<Point> originalPoints,
    List<Point> simplified,
    double epsilon,
  ) {
    const int expectedPoints = 4; // 폐곡선은 최소 4개 포인트 예상

    // 단순화된 포인트가 너무 많으면 더 공격적인 단순화 시도
    if (simplified.length > 10) {
      final aggressiveEpsilon = epsilon * 2.0;

      final aggressiveSimplified = simplifyPoints(
        originalPoints,
        aggressiveEpsilon,
      );

      // 너무 많이 단순화되지 않았으면 공격적 단순화 결과 채택
      if (aggressiveSimplified.length >= expectedPoints &&
          aggressiveSimplified.length <= 10) {
        return aggressiveSimplified;
      }
    }
    // 단순화된 포인트가 너무 적으면 덜 공격적인 단순화 시도
    else if (simplified.length < expectedPoints) {
      final conservativeEpsilon = epsilon * 0.5;

      final conservativeSimplified = simplifyPoints(
        originalPoints,
        conservativeEpsilon,
      );

      // 너무 많이 증가하지 않았으면 보수적 단순화 결과 채택
      if (conservativeSimplified.length >= expectedPoints &&
          conservativeSimplified.length <= 20) {
        return conservativeSimplified;
      }
    }

    return simplified;
  }
}

  import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
  import 'package:open_board/src/core/algorithm/douglas_peucker.dart' as dp;

  /// 포인트 단순화를 담당하는 클래스
  class PointSimplifier {
    const PointSimplifier._();

    /// Douglas-Peucker 알고리즘을 사용한 포인트 단순화
    static List<Point> simplifyPoints(List<Point> points, double epsilon) {
      if (points.length <= 2) return List.of(points);

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

    /// 동적 epsilon 값 계산
    static double _calculateDynamicEpsilon(int pointCount, double baseEpsilon) {
      if (pointCount > 100) {
        final multiplier = 1.0 + (pointCount - 100) / 200;
        return baseEpsilon * multiplier;
      }
      return baseEpsilon;
    }
  }

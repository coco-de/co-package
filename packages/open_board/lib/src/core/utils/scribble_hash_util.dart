import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';

/// Stroke 해시 생성 유틸리티
///
/// 필기 데이터의 고유 식별자(해시)를 생성하여:
/// - 양면 모드에서 좌우 걸친 동일 필기의 중복 제거
/// - 지우개 동기화 시 삭제 대상 필기 식별
///
/// 해시 구성 요소:
/// - Points 개수
/// - 첫/중간/마지막 Point의 X/Y 좌표 (반올림)
/// - color, width, ink
class ScribbleHashUtil {
  const ScribbleHashUtil._();

  /// Stroke의 고유 해시 생성
  static int generateStrokeHash(Stroke stroke) {
    if (stroke.points.isEmpty) return 0;

    final pointCount = stroke.points.length;

    final firstPoint = stroke.points.first;
    final middlePoint = stroke.points[pointCount ~/ 2];
    final lastPoint = stroke.points.last;

    double round(double value) => (value * 10).round() / 10;

    return Object.hashAll([
      pointCount,
      round(firstPoint.x),
      round(firstPoint.y),
      round(middlePoint.x),
      round(middlePoint.y),
      round(lastPoint.x),
      round(lastPoint.y),
      stroke.color,
      round(stroke.width),
      stroke.ink,
    ]);
  }

  /// Stroke 리스트의 모든 해시를 Set으로 생성
  static Set<int> generateStrokeHashSet(List<Stroke> strokes) {
    return strokes.map(generateStrokeHash).toSet();
  }

  /// Stroke 리스트에서 특정 해시에 해당하는 Stroke 제외
  static List<Stroke> excludeByHashes({
    required List<Stroke> strokes,
    required Set<int> excludeHashes,
  }) {
    return strokes.where((stroke) {
      final hash = generateStrokeHash(stroke);
      return !excludeHashes.contains(hash);
    }).toList();
  }
}

import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';

/// Point timestamp 기반 부분 스트로크 생성기
///
/// .bin에서 로드한 원본 [Stroke]를 현재 재생 시각까지만 잘라서
/// 부분적으로 렌더링할 수 있는 [Stroke]를 생성한다.
///
/// 재생 엔진([ScribbleReplayController])에서 프레임마다 호출되어
/// 스트로크가 실시간으로 그려지는 애니메이션 효과를 만든다.
class StrokeAnimator {
  const StrokeAnimator._();

  /// 현재 재생 시각까지의 포인트만 포함한 부분 Stroke 생성
  ///
  /// [stroke] .bin에서 로드한 원본 Stroke
  /// [currentTimeMicros] 현재 재생 시각 (절대 타임스탬프, μs)
  ///
  /// Returns:
  /// - `null`: 아직 시작 전 (첫 포인트 시각 이전)
  /// - 원본 [stroke]: 완료된 스트로크 (마지막 포인트 시각 이후)
  /// - 부분 [Stroke]: 현재 시각까지의 포인트만 포함
  static Stroke? createPartialStroke(Stroke stroke, int currentTimeMicros) {
    if (stroke.points.isEmpty) return null;

    final firstPointTime = stroke.points.first.timestamp.toInt();
    if (currentTimeMicros < firstPointTime) return null;

    final lastPointTime = stroke.points.last.timestamp.toInt();
    if (currentTimeMicros >= lastPointTime) return stroke;

    // 현재 시각까지의 포인트만 추출
    final partialPoints = <Point>[];
    for (final point in stroke.points) {
      if (point.timestamp.toInt() > currentTimeMicros) break;
      partialPoints.add(point);
    }

    if (partialPoints.length < 2) return null;

    return Stroke()
      ..points.addAll(partialPoints)
      ..color = stroke.color
      ..ink = stroke.ink
      ..width = stroke.width
      ..options = (stroke.hasOptions() ? stroke.options : StrokeOptions());
  }

  /// 스트로크의 애니메이션 진행률 (0.0 ~ 1.0)
  ///
  /// [stroke] 원본 Stroke
  /// [currentTimeMicros] 현재 재생 시각
  ///
  /// Returns: 0.0 (시작 전) ~ 1.0 (완료)
  static double getProgress(Stroke stroke, int currentTimeMicros) {
    if (stroke.points.isEmpty) return 0;

    final firstTime = stroke.points.first.timestamp.toInt();
    final lastTime = stroke.points.last.timestamp.toInt();
    final duration = lastTime - firstTime;

    if (duration <= 0) return 1;
    if (currentTimeMicros <= firstTime) return 0;
    if (currentTimeMicros >= lastTime) return 1;

    return (currentTimeMicros - firstTime) / duration;
  }

  /// 스트로크가 주어진 시각에 활성 상태인지 확인
  ///
  /// 첫 포인트 시각 ≤ currentTimeMicros < 마지막 포인트 시각 + tolerance
  static bool isActive(Stroke stroke, int currentTimeMicros) {
    if (stroke.points.isEmpty) return false;

    final firstTime = stroke.points.first.timestamp.toInt();
    final lastTime = stroke.points.last.timestamp.toInt();

    return currentTimeMicros >= firstTime && currentTimeMicros <= lastTime;
  }
}

import 'dart:ui';

import 'package:open_board/src/module/live/domain/model/transport_message.dart';

/// 선생님 뷰포트를 학생 디바이스에 적응 변환하는 계산기
///
/// 선생님과 학생의 디바이스 화면 비율이 다를 때,
/// 선생님이 보는 영역의 중심을 기준으로 학생 디바이스에
/// 최적화된 뷰포트를 계산한다.
///
/// 핵심 원칙:
/// - 선생님의 가시 영역을 모두 포함
/// - 선생님의 중심점이 학생 화면의 중심에 위치
/// - 비율 차이에 따라 좌우/상하 여백 자동 조정
///
/// 예시:
/// ```dart
/// final result = AdaptiveViewportCalculator.calculate(
///   teacherViewport: viewportMessage,
///   studentScreenSize: Size(844, 390), // iPhone 가로모드
/// );
/// // result.center: 선생님과 동일한 중심점
/// // result.scale: 학생 디바이스에 맞춘 배율
/// ```
class AdaptiveViewportCalculator {
  const AdaptiveViewportCalculator._();

  /// 선생님 뷰포트를 학생 디바이스에 적응 변환한다.
  ///
  /// [teacherViewport] 선생님의 현재 뷰포트 상태
  /// [studentScreenSize] 학생 디바이스의 논리 화면 크기 (dp)
  ///
  /// Returns: 학생 디바이스에 적용할 (center, scale) 쌍
  static ({Offset center, double scale}) calculate({
    required ViewportMessage teacherViewport,
    required Size studentScreenSize,
  }) {
    // 1. 선생님의 캔버스 좌표 기준 가시 영역 계산
    final teacherVisibleWidth =
        teacherViewport.viewportWidth / teacherViewport.scale;
    final teacherVisibleHeight =
        teacherViewport.viewportHeight / teacherViewport.scale;

    // 2. 학생 디바이스 비율로 가시 영역 재계산
    //    선생님의 가시 영역을 모두 포함하면서 학생 비율에 맞춤
    final studentAspect =
        studentScreenSize.width / studentScreenSize.height;
    final teacherAspect = teacherVisibleWidth / teacherVisibleHeight;

    double studentVisibleWidth;

    if (studentAspect > teacherAspect) {
      // 학생이 더 넓음 → 높이 기준, 좌우 여백
      studentVisibleWidth = teacherVisibleHeight * studentAspect;
    } else {
      // 학생이 더 좁음 → 너비 기준, 상하 여백
      studentVisibleWidth = teacherVisibleWidth;
    }

    // 3. 학생 scale 계산
    final scale = studentScreenSize.width / studentVisibleWidth;

    // 4. 중심점은 선생님과 동일 (선생님이 가리키는 곳이 화면 중심)
    final center = Offset(
      teacherViewport.centerX,
      teacherViewport.centerY,
    );

    return (center: center, scale: scale);
  }
}

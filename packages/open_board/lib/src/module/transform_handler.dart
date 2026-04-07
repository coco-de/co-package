import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 선택된 요소의 이동/크기조절/회전을 처리하는 공통 핸들러
///
/// LassoSelectionManager와 TextInteractionManager에서 중복되던
/// 변형(Transform) 로직을 통합합니다.
///
/// CoordinateTransformer만 의존하며, 스크린 ↔ 캔버스 좌표 변환을 활용합니다.
class TransformHandler {
  // 이동 관련
  Offset? _moveStartPosition;

  // 크기조절/회전 관련
  Offset? _transformOrigin; // 변형 중심점
  double? _originalDistance; // 시작점에서 중심점까지의 거리
  double? _originalAngle; // 원점 기준 초기 각도
  double _currentRotation = 0.0; // 현재 회전 각도

  // 변형 상태 추적
  bool _isResizeRotating = false;

  TransformHandler();

  /// 현재 크기조절/회전 중인지 여부
  bool get isResizeRotating => _isResizeRotating;

  // ── 이동 관련 ──

  /// 이동 시작
  ///
  /// [startPosition]은 화면(스크린) 좌표 기준 시작 위치입니다.
  void startMove(Offset startPosition) {
    _moveStartPosition = startPosition;
  }

  /// 이동에 사용되는 delta 값을 반환
  ///
  /// [currentPosition]은 현재 화면(스크린) 좌표입니다.
  Offset? getMoveDeleta(Offset currentPosition) {
    if (_moveStartPosition == null) return null;
    return currentPosition - _moveStartPosition!;
  }

  /// 이동 종료
  void endMove() {
    _moveStartPosition = null;
  }

  // ── 크기조절/회전 관련 ──

  /// 크기조절/회전 시작
  ///
  /// [handlePosition]은 변형 핸들의 화면 좌표 위치입니다.
  /// [center]는 변형 중심점(화면 좌표)입니다.
  /// [initialRotation]은 기존 회전 각도입니다 (기본값 0.0).
  void startResizeRotate(
    Offset handlePosition,
    Offset center, {
    double initialRotation = 0.0,
  }) {
    _transformOrigin = center;

    final centerToHandle = handlePosition - center;
    _originalDistance = centerToHandle.distance;
    _originalAngle = math.atan2(centerToHandle.dy, centerToHandle.dx);
    _currentRotation = initialRotation;
    _isResizeRotating = true;
  }

  /// 크기조절/회전 적용 결과를 계산하여 반환
  ///
  /// [currentPosition]은 현재 터치(화면 좌표) 위치입니다.
  /// 반환값은 (scale, deltaAngle, finalRotation) 튜플입니다.
  /// - scale: 원본 대비 크기 비율
  /// - deltaAngle: 시작 각도 대비 회전 변화량
  /// - finalRotation: 초기 회전 + deltaAngle 합계
  ({double scale, double deltaAngle, double finalRotation}) computeResizeRotate(
    Offset currentPosition,
  ) {
    if (_transformOrigin == null ||
        _originalDistance == null ||
        _originalAngle == null) {
      return (scale: 1.0, deltaAngle: 0.0, finalRotation: _currentRotation);
    }

    final centerToCurrent = currentPosition - _transformOrigin!;
    final currentDistance = centerToCurrent.distance;
    final currentAngle = math.atan2(centerToCurrent.dy, centerToCurrent.dx);

    // 스케일 계산
    final scale = _originalDistance! > 0
        ? (currentDistance / _originalDistance!).clamp(0.1, 3.0)
        : 1.0;

    // 회전 각도 계산 (deltaAngle)
    var deltaAngle = currentAngle - _originalAngle!;

    // 각도 차이를 -pi ~ pi 범위로 정규화
    while (deltaAngle > math.pi) {
      deltaAngle -= 2 * math.pi;
    }
    while (deltaAngle < -math.pi) {
      deltaAngle += 2 * math.pi;
    }

    _currentRotation = deltaAngle;

    return (scale: scale, deltaAngle: deltaAngle, finalRotation: deltaAngle);
  }

  /// 원본 포인트 그룹에 스케일/회전 변환을 적용하여 새 포인트 목록 반환
  ///
  /// [pointGroups]은 원본 포인트 그룹 목록입니다.
  /// [center]는 변형 중심점(캔버스 좌표)입니다.
  /// [scale]은 크기 비율입니다.
  /// [rotation]은 최종 회전 각도입니다.
  List<List<Offset>> applyResizeRotate(
    List<List<Offset>> pointGroups, {
    required Offset center,
    required double scale,
    required double rotation,
  }) {
    final cos = math.cos(rotation);
    final sin = math.sin(rotation);

    return pointGroups.map((points) {
      return points.map((point) {
        // 중심점 기준으로 이동
        final relative = point - center;

        // 스케일 적용
        final scaled = relative * scale;

        // 회전 적용
        final rotated = Offset(
          scaled.dx * cos - scaled.dy * sin,
          scaled.dx * sin + scaled.dy * cos,
        );

        // 중심점으로 다시 이동
        return rotated + center;
      }).toList();
    }).toList();
  }

  /// 크기조절/회전 종료
  void endResizeRotate() {
    _transformOrigin = null;
    _originalDistance = null;
    _originalAngle = null;
    _isResizeRotating = false;
  }

  // ── 원본 캐싱 ──

  /// 원본 포인트 그룹 캐싱
  ///
  /// 변형 전 원본 상태를 저장하여, 누적 변형을 방지합니다.
  // ignore: no-empty-block
  void cacheOriginalPoints(List<List<Offset>> pointGroups) {
    // Reserved for future use: caching original points before transform
  }
}

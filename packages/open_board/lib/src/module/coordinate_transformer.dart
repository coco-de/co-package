import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';

/// 스크린 ↔ 캔버스 좌표 변환 유틸리티
///
/// ScribbleNotifier, LassoSelectionManager, TextInteractionManager에서
/// 중복되던 좌표 변환 로직을 통합합니다.
///
/// TransformationController가 null인 경우 identity 변환(좌표 그대로)을 수행합니다.
class CoordinateTransformer {
  final TransformationController? _controller;

  const CoordinateTransformer(TransformationController? controller)
      : _controller = controller;

  /// 현재 스케일 팩터
  ///
  /// TransformationController가 null이면 1.0을 반환합니다.
  double get scale =>
      _controller?.value.getMaxScaleOnAxis() ?? 1.0;

  /// 스크린 좌표 → 캔버스 좌표 변환
  ///
  /// TransformationController.toScene()과 동일한 동작을 수행합니다.
  /// controller가 null이면 좌표를 그대로 반환합니다.
  Offset screenToCanvas(Offset screenPoint) {
    if (_controller == null) return screenPoint;
    return _controller.toScene(screenPoint);
  }

  /// 캔버스 좌표 → 스크린 좌표 변환
  ///
  /// MatrixUtils.transformPoint를 사용하여 캔버스 좌표를
  /// 스크린(뷰포트) 좌표로 변환합니다.
  /// controller가 null이면 좌표를 그대로 반환합니다.
  Offset canvasToScreen(Offset canvasPoint) {
    if (_controller == null) return canvasPoint;
    return MatrixUtils.transformPoint(_controller.value, canvasPoint);
  }

  /// 스크린 거리 → 캔버스 거리 변환
  ///
  /// 스크린상의 거리를 현재 스케일을 고려하여 캔버스 거리로 변환합니다.
  double screenToCanvasDistance(double screenDistance) {
    final s = scale;
    if (s == 0) return screenDistance;
    return screenDistance / s;
  }

  /// 현재 변환 행렬을 반환합니다.
  ///
  /// controller가 null이면 identity 행렬을 반환합니다.
  Matrix4 get matrix =>
      _controller?.value ?? Matrix4.identity();

  /// 현재 변환 행렬의 역행렬을 반환합니다.
  ///
  /// controller가 null이면 identity 행렬을 반환합니다.
  Matrix4 get inverseMatrix {
    if (_controller == null) return Matrix4.identity();
    return Matrix4.inverted(_controller.value);
  }

  /// 캔버스 좌표 → 로컬(위젯) 좌표 변환
  ///
  /// 역행렬을 사용하여 캔버스(scene) 좌표를 로컬 좌표로 변환합니다.
  /// TextInteractionHandler에서 scene → local 변환에 사용됩니다.
  Offset canvasToLocal(Offset canvasPoint) {
    if (_controller == null) return canvasPoint;
    final inv = inverseMatrix;
    final vector = Vector4(canvasPoint.dx, canvasPoint.dy, 0, 1);
    final transformed = inv * vector;
    return Offset(
      transformed.x as double,
      transformed.y as double,
    );
  }
}

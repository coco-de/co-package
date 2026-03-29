import 'package:flutter/material.dart';
import 'package:open_board/src/module/models/oriented_bounding_box.dart';

/// 핸들 위치 열거형
enum HandlePosition {
  none,
  topLeft,
  top,
  topRight,
  right,
  bottomRight,
  bottom,
  bottomLeft,
  left,
  rotation,
}

/// 변환 작업 종류
enum TransformOperation { none, move, rotate, resize }

/// 올가미 선택 상태를 관리하는 클래스
class LassoSelectionState {
  /// 올가미 경로 포인트
  final List<Offset> lassoPoints;

  /// 선택된 스트로크 ID 목록
  final List<int> selectedStrokeIds;

  /// 변환 매트릭스 (확대, 축소, 회전)
  final Matrix4 transformMatrix;

  /// 선택 영역의 경계 상자
  final Rect? boundingBox;

  /// 회전된 바운딩 박스
  final OrientedBoundingBox? orientedBoundingBox;

  /// 선택 모드 여부
  final bool isSelecting;

  /// 변환 모드 여부 (확대, 축소, 회전)
  final bool isTransforming;

  /// 현재 변환 작업 (이동, 회전, 크기 조절)
  final TransformOperation operation;

  LassoSelectionState({
    this.lassoPoints = const [],
    this.selectedStrokeIds = const [],
    Matrix4? transformMatrix,
    this.boundingBox,
    this.orientedBoundingBox,
    this.isSelecting = false,
    this.isTransforming = false,
    this.operation = TransformOperation.none,
  }) : transformMatrix = transformMatrix ?? Matrix4.identity();

  /// 새로운 상태를 생성하는 복사 메서드
  LassoSelectionState copyWith({
    List<Offset>? lassoPoints,
    List<int>? selectedStrokeIds,
    Matrix4? transformMatrix,
    Rect? boundingBox,
    OrientedBoundingBox? orientedBoundingBox,
    bool? isSelecting,
    bool? isTransforming,
    TransformOperation? operation,
  }) {
    return LassoSelectionState(
      lassoPoints: lassoPoints ?? this.lassoPoints,
      selectedStrokeIds: selectedStrokeIds ?? this.selectedStrokeIds,
      transformMatrix: transformMatrix ?? this.transformMatrix,
      boundingBox: boundingBox ?? this.boundingBox,
      orientedBoundingBox: orientedBoundingBox ?? this.orientedBoundingBox,
      isSelecting: isSelecting ?? this.isSelecting,
      isTransforming: isTransforming ?? this.isTransforming,
      operation: operation ?? this.operation,
    );
  }
}

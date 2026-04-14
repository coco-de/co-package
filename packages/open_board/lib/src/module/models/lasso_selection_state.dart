  import 'package:flutter/material.dart';
  import 'package:open_board/src/module/models/oriented_bounding_box.dart';

  /// 핸들 위치 열거형
  enum HandlePosition { none }

  /// 변환 작업 종류
  enum TransformOperation { none, move }

  /// 올가미 선택 상태를 관리하는 클래스
  @immutable
  class LassoSelectionState {
    /// 변환 매트릭스 (확대, 축소, 회전)
    final Matrix4 transformMatrix;

    /// 선택 영역의 경계 상자
    final Rect? boundingBox;

    /// 회전된 바운딩 박스
    final OrientedBoundingBox? orientedBoundingBox;

    LassoSelectionState({
      Matrix4? transformMatrix,
      this.boundingBox,
      this.orientedBoundingBox,
    }) : transformMatrix = transformMatrix ?? Matrix4.identity();

    /// 새로운 상태를 생성하는 복사 메서드
    LassoSelectionState copyWith({
      Rect? boundingBox,
      OrientedBoundingBox? orientedBoundingBox,
      bool? isTransforming,
      TransformOperation? operation,
    }) {
      return LassoSelectionState(
        transformMatrix: transformMatrix,
        boundingBox: boundingBox ?? this.boundingBox,
        orientedBoundingBox: orientedBoundingBox ?? this.orientedBoundingBox,
      );
    }
  }

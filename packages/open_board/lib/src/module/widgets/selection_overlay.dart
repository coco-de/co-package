import 'package:flutter/material.dart';

/// 선택 오버레이 타입
enum SelectionOverlayType { text }

/// 통합 선택 오버레이를 구성하는 위젯들 (드래그 핸들러만 제공)
/// 시각적 요소는 각각의 페인터에서 처리됨:
/// - 올가미: ScribblePainter에서 처리
/// - 텍스트: TextDrawablePainter에서 처리
///
/// [deleteButtonPosition]/[transformButtonPosition]을 명시적으로 전달하면
/// 축 정렬 boundingBox 모서리 대신 그 위치에 핸들 GestureDetector를 배치합니다.
/// (회전된 텍스트처럼 시각적 핸들과 축 정렬 모서리가 어긋나는 경우 사용)
List<Widget> buildSelectionOverlay({
  required SelectionOverlayType type,
  required Rect boundingBox,
  required VoidCallback onDelete,
  required Function(DragStartDetails) onTransformStart,
  required Function(DragUpdateDetails) onTransformUpdate,
  required Function(DragEndDetails) onTransformEnd,
  required Function(DragStartDetails) onMoveStart,
  required Function(DragUpdateDetails) onMoveUpdate,
  required Function(DragEndDetails) onMoveEnd,
  Offset? deleteButtonPosition,
  Offset? transformButtonPosition,
}) {
  const handleSize = 28.0; // 버튼 터치 영역 크기 (시각 버튼 35px + 여유)

  final finalBoundingBox = boundingBox;

  if (finalBoundingBox == Rect.zero) {
    return [];
  }

  // 버튼 위치 계산 (override 우선)
  final resolvedDeleteButtonPosition =
      deleteButtonPosition ??
      Offset(finalBoundingBox.right, finalBoundingBox.top);
  final resolvedTransformButtonPosition =
      transformButtonPosition ??
      Offset(finalBoundingBox.left, finalBoundingBox.bottom);

  return [
    // 전체 영역 드래그 (이동)
    Positioned(
      left: finalBoundingBox.left,
      top: finalBoundingBox.top,
      width: finalBoundingBox.width,
      height: finalBoundingBox.height,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanStart: onMoveStart,
        onPanUpdate: onMoveUpdate,
        onPanEnd: onMoveEnd,
        child: Container(
          // 투명한 컨테이너로 터치 영역만 제공
          color: Colors.transparent,
        ),
      ),
    ),

    // 삭제 버튼 터치 영역 (우상단)
    Positioned(
      left: resolvedDeleteButtonPosition.dx - handleSize / 2,
      top: resolvedDeleteButtonPosition.dy - handleSize / 2,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onDelete,
        child: Container(
          width: handleSize,
          height: handleSize,
          // 투명한 컨테이너로 터치 영역만 제공 (시각적 버튼은 페인터에서 그림)
          color: Colors.transparent,
        ),
      ),
    ),

    // 크기조절/회전 버튼 터치 영역 (좌하단)
    Positioned(
      left: resolvedTransformButtonPosition.dx - handleSize / 2,
      top: resolvedTransformButtonPosition.dy - handleSize / 2,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (details) {
          onTransformStart(details);
        },
        onPanUpdate: (details) {
          onTransformUpdate(details);
        },
        onPanEnd: (details) {
          onTransformEnd(details);
        },
        child: Container(
          width: handleSize,
          height: handleSize,
          // 투명한 컨테이너로 터치 영역만 제공 (시각적 버튼은 페인터에서 그림)
          color: Colors.transparent,
        ),
      ),
    ),
  ];
}

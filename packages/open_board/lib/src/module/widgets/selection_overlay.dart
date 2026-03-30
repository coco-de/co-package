import 'package:flutter/material.dart';

/// 선택 오버레이 타입
enum SelectionOverlayType { text }

/// 통합 선택 오버레이를 구성하는 위젯들 (드래그 핸들러만 제공)
/// 시각적 요소는 각각의 페인터에서 처리됨:
/// - 올가미: ScribblePainter에서 처리
/// - 텍스트: TextDrawablePainter에서 처리
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
}) {
  const handleSize = 40.0; // 버튼 시각적 크기

  final finalBoundingBox = boundingBox;

  if (finalBoundingBox == Rect.zero) {
    return [];
  }

  // 버튼 위치 계산
  final deleteButtonPosition = Offset(finalBoundingBox.right, finalBoundingBox.top);
  final transformButtonPosition = Offset(
    finalBoundingBox.left,
    finalBoundingBox.bottom,
  );

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
      left: deleteButtonPosition.dx - handleSize / 2,
      top: deleteButtonPosition.dy - handleSize / 2,
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
      left: transformButtonPosition.dx - handleSize / 2,
      top: transformButtonPosition.dy - handleSize / 2,
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

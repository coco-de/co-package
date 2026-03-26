// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import 'package:open_board/src/module/scribble_painter.dart'
    show OrientedBoundingBox;
import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_board/src/module/text/text_drawable_extensions.dart';
import 'package:open_board/src/module/state/text_settings.dart';

/// 선택 오버레이 타입
enum SelectionOverlayType { lasso, text }

/// 통합 선택 오버레이를 구성하는 위젯들 (드래그 핸들러만 제공)
/// 시각적 요소는 각각의 페인터에서 처리됨:
/// - 올가미: ScribblePainter에서 처리
/// - 텍스트: TextDrawablePainter에서 처리
List<Widget> buildSelectionOverlay({
  required SelectionOverlayType type,
  Rect? boundingBox,
  OrientedBoundingBox? orientedBoundingBox,
  TextDrawable? textDrawable,
  required VoidCallback onDelete,
  required Function(DragStartDetails) onTransformStart,
  required Function(DragUpdateDetails) onTransformUpdate,
  required Function(DragEndDetails) onTransformEnd,
  required Function(DragStartDetails) onMoveStart,
  required Function(DragUpdateDetails) onMoveUpdate,
  required Function(DragEndDetails) onMoveEnd,
}) {
  //
  //
  //
  //
  //

  const handleSize = 40.0; // 버튼 시각적 크기

  // 타입에 따라 바운딩 박스 계산
  late Rect finalBoundingBox;

  switch (type) {
    case SelectionOverlayType.lasso:
      finalBoundingBox = boundingBox ?? Rect.zero;
      break;
    case SelectionOverlayType.text:
      if (textDrawable != null) {
        finalBoundingBox = _calculateTextBoundingBox(textDrawable);
      } else {
        finalBoundingBox = Rect.zero;
      }
      break;
  }

  if (finalBoundingBox == Rect.zero) {
    //
    return [];
  }

  // 버튼 위치 계산
  Offset deleteButtonPosition;
  Offset transformButtonPosition;

  if (type == SelectionOverlayType.lasso &&
      orientedBoundingBox?.corners != null &&
      orientedBoundingBox!.corners.length >= 4) {
    // 회전된 올가미 박스의 경우: 실제 모서리 위치 사용
    final corners = orientedBoundingBox.corners;
    deleteButtonPosition = corners[1]; // 우상단
    transformButtonPosition = corners[3]; // 좌하단
  } else {
    // 일반 박스의 경우: 기존 방식
    deleteButtonPosition = Offset(finalBoundingBox.right, finalBoundingBox.top);
    transformButtonPosition = Offset(
      finalBoundingBox.left,
      finalBoundingBox.bottom,
    );
  }

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

/// 텍스트의 바운딩 박스 계산
Rect _calculateTextBoundingBox(TextDrawable textDrawable) {
  final textSpan = TextSpan(text: textDrawable.text, style: textDrawable.style);

  final textPainter = TextPainter(
    text: textSpan,
    textAlign: textDrawable.alignment.textAlign,
    textDirection: TextDirection.ltr,
  );
  textPainter.layout();

  // 텍스트 렌더링 위치 계산 (정렬에 따라)
  Offset renderPosition = textDrawable.position;
  switch (textDrawable.alignment) {
    case TextAlignment.center:
      renderPosition = Offset(
        textDrawable.position.dx - textPainter.width / 2,
        textDrawable.position.dy - textPainter.height / 2,
      );
      break;
    case TextAlignment.right:
      renderPosition = Offset(
        textDrawable.position.dx - textPainter.width,
        textDrawable.position.dy - textPainter.height / 2,
      );
      break;
    case TextAlignment.left:
      renderPosition = Offset(
        textDrawable.position.dx,
        textDrawable.position.dy - textPainter.height / 2,
      );
      break;
  }

  // 바운딩 박스 생성 (패딩 포함)
  const padding = 8.0;
  return Rect.fromLTWH(
    renderPosition.dx - padding,
    renderPosition.dy - padding,
    textPainter.width + padding * 2,
    textPainter.height + padding * 2,
  );
}

/// 통합 선택 바운딩 박스를 그리는 CustomPainter (필요한 경우에만 사용)
class _SelectionBoundingBoxPainter extends CustomPainter {
  final Rect boundingBox;
  final Color borderColor;
  final SelectionOverlayType type;
  final OrientedBoundingBox? orientedBoundingBox;

  _SelectionBoundingBoxPainter({
    required this.boundingBox,
    required this.borderColor,
    required this.type,
    required this.orientedBoundingBox,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = borderColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // 배경 채우기 (올가미의 경우만)
    if (type == SelectionOverlayType.lasso) {
      final fillPaint = Paint()
        ..color = borderColor.withValues(alpha: 0.1)
        ..style = PaintingStyle.fill;

      if (orientedBoundingBox != null) {
        // 회전된 바운딩 박스 배경 채우기
        final corners = orientedBoundingBox!.corners;
        if (corners.length >= 4) {
          final path = Path()
            ..moveTo(corners[0].dx, corners[0].dy)
            ..lineTo(corners[1].dx, corners[1].dy)
            ..lineTo(corners[2].dx, corners[2].dy)
            ..lineTo(corners[3].dx, corners[3].dy)
            ..close();
          canvas.drawPath(path, fillPaint);
        }
      } else {
        // 일반 바운딩 박스 배경 채우기
        canvas.drawRect(boundingBox, fillPaint);
      }
    }

    // 테두리 그리기
    if (type == SelectionOverlayType.lasso && orientedBoundingBox != null) {
      // 회전된 바운딩 박스 테두리 그리기
      final corners = orientedBoundingBox!.corners;
      if (corners.length >= 4) {
        final path = Path()
          ..moveTo(corners[0].dx, corners[0].dy)
          ..lineTo(corners[1].dx, corners[1].dy)
          ..lineTo(corners[2].dx, corners[2].dy)
          ..lineTo(corners[3].dx, corners[3].dy)
          ..close();
        canvas.drawPath(path, paint);
      }
    } else {
      // 일반 바운딩 박스 테두리 그리기
      canvas.drawRect(boundingBox, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is! _SelectionBoundingBoxPainter) return true;
    return oldDelegate.boundingBox != boundingBox ||
        oldDelegate.orientedBoundingBox != orientedBoundingBox ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.type != type;
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:open_note/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_note/src/note/style/note_text_box_decoration.dart';
import 'package:open_note/src/note/style/note_text_box_style.dart';
import 'package:open_note/src/module/text/text_box_typography.dart';
import 'package:open_note/src/module/text/text_drawable_extensions.dart';
import 'package:open_note/src/module/text/text_span_builder.dart';
import 'package:open_note/src/module/state/text_settings.dart';

const double defaultTextSelectionPadding = 4;

/// Selection bounds in text-local coordinates, projected onto the canvas.
final class TextSelectionGeometry {
  const TextSelectionGeometry(
    this.textBounds,
    this.localBounds,
    this.center,
    this.rotation,
  );

  final Rect textBounds;
  final Rect localBounds;
  final Offset center;
  final double rotation;

  Offset _rotate(Offset point, double angle) {
    final cos = math.cos(angle);
    final sin = math.sin(angle);
    return Offset(
      point.dx * cos - point.dy * sin,
      point.dx * sin + point.dy * cos,
    );
  }

  Offset get deleteHandle => center + _rotate(localBounds.topRight, rotation);
  Offset get transformHandle =>
      center + _rotate(localBounds.bottomLeft, rotation);

  Rect get canvasBounds => MatrixUtils.transformRect(
    Matrix4.identity()
      ..translateByDouble(center.dx, center.dy, 0, 1)
      ..rotateZ(rotation),
    localBounds,
  );

  bool contains(Offset point) =>
      localBounds.contains(_rotate(point - center, -rotation));
}

/// Custom painter for rendering text drawables
class TextDrawablePainter extends CustomPainter {
  final List<TextDrawable> textDrawables;
  final TextDrawable? selectedTextDrawable;
  final bool isTransforming;
  final String? editingTextId;
  final TextBoxTypography textBoxTypography;
  final double textSelectionPadding;

  const TextDrawablePainter({
    required this.textDrawables,
    required this.selectedTextDrawable,
    required this.isTransforming,
    required this.editingTextId,
    this.textBoxTypography = defaultTextBoxTypography,
    this.textSelectionPadding = defaultTextSelectionPadding,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final textDrawable in textDrawables) {
      // Skip hidden text drawables
      if (textDrawable.hidden) {
        continue;
      }

      // 편집 중인 텍스트는 렌더링하지 않음
      if (editingTextId != null && textDrawable.id == editingTextId) {
        continue;
      }

      _paintWithBoxStyle(canvas, textDrawable);

      // Draw selection indicator if this text is selected
      if (selectedTextDrawable == textDrawable) {
        _paintSelectionIndicator(canvas, textDrawable);
      }
    }
  }

  /// open_note: 텍스트 상자 스타일(배경 · 테두리 · 여백 · 불투명도)을 입혀
  /// 그린다. 줄 높이는 [buildLinkAwareTextSpan] 이 적용한다.
  void _paintWithBoxStyle(Canvas canvas, TextDrawable textDrawable) {
    if (textDrawable.boxStyle.isEmpty) {
      _paintTextDrawable(canvas, textDrawable);
      return;
    }
    final style = NoteTextBoxStyle.decode(textDrawable.boxStyle);
    _paintBox(canvas, textDrawable, style);
    final layered = style.opacity < 1;
    if (layered) {
      canvas.saveLayer(
        null,
        Paint()
          ..color = const Color(0xFF000000).withValues(alpha: style.opacity),
      );
    }
    _paintTextDrawable(canvas, textDrawable);
    if (layered) canvas.restore();
  }

  void _paintBox(
    Canvas canvas,
    TextDrawable textDrawable,
    NoteTextBoxStyle style,
  ) {
    final bounds = getTextBounds(
      textDrawable,
      textBoxTypography: textBoxTypography,
    );
    if (textDrawable.rotation == 0) {
      NoteTextBoxDecoration.paint(canvas, bounds, style);
      return;
    }
    // 회전한 텍스트는 (x, y) 를 중심으로 그려진다.
    canvas
      ..save()
      ..translate(textDrawable.x, textDrawable.y)
      ..rotate(textDrawable.rotation);
    NoteTextBoxDecoration.paint(
      canvas,
      Rect.fromCenter(
        center: Offset.zero,
        width: bounds.width,
        height: bounds.height,
      ),
      style,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant TextDrawablePainter oldDelegate) {
    return textDrawables != oldDelegate.textDrawables ||
        selectedTextDrawable != oldDelegate.selectedTextDrawable ||
        isTransforming != oldDelegate.isTransforming ||
        editingTextId != oldDelegate.editingTextId ||
        textBoxTypography != oldDelegate.textBoxTypography ||
        textSelectionPadding != oldDelegate.textSelectionPadding;
  }

  /// Get the bounding rect of a text drawable
  static Rect getTextBounds(
    TextDrawable textDrawable, {
    TextBoxTypography textBoxTypography = defaultTextBoxTypography,
  }) {
    final textSpan = buildLinkAwareTextSpan(
      textDrawable,
      textBoxTypography: textBoxTypography,
    );

    final textPainter = TextPainter(
      text: textSpan,
      textAlign: textDrawable.alignment.textAlign,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout(maxWidth: textDrawable.layoutMaxWidth);

    // Calculate position based on alignment
    Offset position = textDrawable.position;
    switch (textDrawable.alignment) {
      case TextAlignment.center:
        position = Offset(
          textDrawable.position.dx - textPainter.width / 2,
          textDrawable.position.dy - textPainter.height / 2,
        );
        break;
      case TextAlignment.right:
        position = Offset(
          textDrawable.position.dx - textPainter.width,
          textDrawable.position.dy - textPainter.height / 2,
        );
        break;
      case TextAlignment.left:
        position = Offset(
          textDrawable.position.dx,
          textDrawable.position.dy - textPainter.height / 2,
        );
        break;
    }

    final bounds = position & textPainter.size;
    textPainter.dispose();
    return bounds;
  }

  static TextSelectionGeometry getSelectionGeometry(
    TextDrawable textDrawable, {
    TextBoxTypography textBoxTypography = defaultTextBoxTypography,
    double padding = defaultTextSelectionPadding,
  }) {
    final textBounds = getTextBounds(
      textDrawable,
      textBoxTypography: textBoxTypography,
    );
    final rotation = textDrawable.rotation;
    return TextSelectionGeometry(
      textBounds,
      Rect.fromCenter(
        center: Offset.zero,
        width: textBounds.width,
        height: textBounds.height,
      ).inflate(padding),
      // Legacy boxes anchor the handles at the stored position.
      rotation == 0 && padding != defaultTextSelectionPadding
          ? textBounds.center
          : textDrawable.position,
      rotation,
    );
  }

  /// 텍스트 오버레이 버튼 클릭 감지 (회전 지원)
  static String? getButtonType(
    TextDrawable textDrawable,
    Offset point, {
    TextBoxTypography textBoxTypography = defaultTextBoxTypography,
    double padding = defaultTextSelectionPadding,
  }) {
    final geometry = getSelectionGeometry(
      textDrawable,
      textBoxTypography: textBoxTypography,
      padding: padding,
    );
    return _buttonAt(geometry, point);
  }

  static String? _buttonAt(TextSelectionGeometry geometry, Offset point) {
    const buttonRadius = 14.0;
    if ((point - geometry.deleteHandle).distance <= buttonRadius) {
      return 'delete';
    }
    if ((point - geometry.transformHandle).distance <= buttonRadius) {
      return 'transform';
    }
    return null;
  }

  /// 텍스트 영역 내부 클릭 감지 (버튼 제외, 회전 지원)
  static bool isPointInTextArea(
    TextDrawable textDrawable,
    Offset point, {
    TextBoxTypography textBoxTypography = defaultTextBoxTypography,
    double padding = defaultTextSelectionPadding,
  }) {
    final geometry = getSelectionGeometry(
      textDrawable,
      textBoxTypography: textBoxTypography,
      padding: padding,
    );
    final contains =
        padding == defaultTextSelectionPadding && geometry.rotation == 0
        ? geometry.textBounds.inflate(padding).contains(point)
        : geometry.contains(point);
    return contains && _buttonAt(geometry, point) == null;
  }

  void _paintTextDrawable(Canvas canvas, TextDrawable textDrawable) {
    final textSpan = buildLinkAwareTextSpan(
      textDrawable,
      textBoxTypography: textBoxTypography,
    );

    final textPainter = TextPainter(
      text: textSpan,
      textAlign: textDrawable.alignment.textAlign,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout(maxWidth: textDrawable.layoutMaxWidth);

    // Calculate position based on alignment
    Offset position = textDrawable.position;
    switch (textDrawable.alignment) {
      case TextAlignment.center:
        position = Offset(
          textDrawable.position.dx - textPainter.width / 2,
          textDrawable.position.dy - textPainter.height / 2,
        );
        break;
      case TextAlignment.right:
        position = Offset(
          textDrawable.position.dx - textPainter.width,
          textDrawable.position.dy - textPainter.height / 2,
        );
        break;
      case TextAlignment.left:
        position = Offset(
          textDrawable.position.dx,
          textDrawable.position.dy - textPainter.height / 2,
        );
        break;
    }

    // 회전이 있는 경우 변환 적용 (안전한 접근)
    double rotation = 0.0;
    try {
      rotation = textDrawable.rotation;
    } on Exception catch (error, stackTrace) {
      debugPrintStack(stackTrace: stackTrace);
      debugPrint(error.toString());
      // rotation 필드가 없거나 접근할 수 없는 경우 기본값 사용
      rotation = 0.0;
    }
    if (rotation != 0.0) {
      canvas.save();

      // 텍스트 중심점으로 이동
      final textCenter = Offset(
        textDrawable.position.dx,
        textDrawable.position.dy,
      );
      canvas.translate(textCenter.dx, textCenter.dy);

      // 회전 적용
      canvas.rotate(rotation);

      // 텍스트 렌더링 위치를 중심점 기준으로 조정
      final adjustedPosition = Offset(
        -textPainter.width / 2,
        -textPainter.height / 2,
      );

      try {
        textPainter.paint(canvas, adjustedPosition);
      } on Exception catch (error) {
        debugPrint('텍스트 렌더링 오류 (회전됨): $error');
      }
      canvas.restore();
    } else {
      // 회전이 없는 경우 기존 방식
      try {
        textPainter.paint(canvas, position);
      } on Exception catch (error) {
        debugPrint('텍스트 렌더링 오류: $error');
      }
    }
  }

  void _paintSelectionIndicator(Canvas canvas, TextDrawable textDrawable) {
    final geometry = getSelectionGeometry(
      textDrawable,
      textBoxTypography: textBoxTypography,
      padding: textSelectionPadding,
    );

    canvas.save();
    canvas.translate(geometry.center.dx, geometry.center.dy);
    canvas.rotate(geometry.rotation);
    final borderPaint = Paint()
      ..color = isTransforming ? Colors.green : Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = isTransforming ? 3.0 : 2.0;
    canvas.drawRect(geometry.localBounds, borderPaint);

    if (isTransforming) {
      final backgroundPaint = Paint()
        ..color = Colors.blue.withValues(alpha: 0.1);
      canvas.drawRect(geometry.localBounds, backgroundPaint);
    }
    canvas.restore();

    _paintOverlayButtons(
      canvas,
      geometry.deleteHandle,
      geometry.transformHandle,
    );
  }

  void _paintOverlayButtons(
    Canvas canvas,
    Offset deleteButtonCenter,
    Offset transformButtonCenter,
  ) {
    const buttonSize = 35.0; // 시각 버튼 크기 (기존 50의 70%)
    const buttonRadius = buttonSize / 2;

    // 삭제 버튼 (우상단)
    final deleteButtonPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    // 삭제 버튼 배경 원
    try {
      canvas.drawCircle(deleteButtonCenter, buttonRadius, deleteButtonPaint);
    } on Exception catch (error) {
      debugPrint('삭제 버튼 배경 렌더링 오류: $error');
    }

    // 삭제 버튼 테두리
    final deleteButtonBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    try {
      canvas.drawCircle(
        deleteButtonCenter,
        buttonRadius,
        deleteButtonBorderPaint,
      );
    } on Exception catch (error) {
      debugPrint('삭제 버튼 테두리 렌더링 오류: $error');
    }

    // 삭제 아이콘 (X)
    final deleteIconPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    const iconSize = 8.0; // 70% 축소
    try {
      canvas.drawLine(
        deleteButtonCenter + const Offset(-iconSize / 2, -iconSize / 2),
        deleteButtonCenter + const Offset(iconSize / 2, iconSize / 2),
        deleteIconPaint,
      );
      canvas.drawLine(
        deleteButtonCenter + const Offset(iconSize / 2, -iconSize / 2),
        deleteButtonCenter + const Offset(-iconSize / 2, iconSize / 2),
        deleteIconPaint,
      );
    } on Exception catch (error) {
      debugPrint('삭제 아이콘 렌더링 오류: $error');
    }

    // 변형 버튼 (좌하단)
    final transformButtonPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    // 변형 버튼 배경 원
    try {
      canvas.drawCircle(
        transformButtonCenter,
        buttonRadius,
        transformButtonPaint,
      );
    } on Exception catch (error) {
      debugPrint('변형 버튼 배경 렌더링 오류: $error');
    }

    // 변형 버튼 테두리
    final transformButtonBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    try {
      canvas.drawCircle(
        transformButtonCenter,
        buttonRadius,
        transformButtonBorderPaint,
      );
    } on Exception catch (error) {
      debugPrint('변형 버튼 테두리 렌더링 오류: $error');
    }

    // 변형 아이콘 (크기조절 화살표)
    final transformIconPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    const arrowSize = 7.0; // 70% 축소
    // 대각선 화살표 (↗)
    try {
      canvas.drawLine(
        transformButtonCenter + const Offset(-arrowSize / 2, arrowSize / 2),
        transformButtonCenter + const Offset(arrowSize / 2, -arrowSize / 2),
        transformIconPaint,
      );
    } on Exception catch (error) {
      debugPrint('변형 아이콘 대각선 화살표 렌더링 오류: $error');
    }
    // 화살표 머리 (→)
    try {
      canvas.drawLine(
        transformButtonCenter + const Offset(arrowSize / 2, -arrowSize / 2),
        transformButtonCenter +
            const Offset(arrowSize / 2 - 4, -arrowSize / 2 + 2),
        transformIconPaint,
      );
      canvas.drawLine(
        transformButtonCenter + const Offset(arrowSize / 2, -arrowSize / 2),
        transformButtonCenter +
            const Offset(arrowSize / 2 - 2, -arrowSize / 2 + 4),
        transformIconPaint,
      );
    } on Exception catch (error) {
      debugPrint('변형 아이콘 화살표 머리 렌더링 오류: $error');
    }
  }
}

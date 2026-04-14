  import 'package:flutter/material.dart';
  import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
  import 'package:open_board/src/module/text/text_drawable_extensions.dart';
  import 'package:open_board/src/module/state/text_settings.dart';
  import 'dart:math' as math;

  /// Custom painter for rendering text drawables
  class TextDrawablePainter extends CustomPainter {
    final List<TextDrawable> textDrawables;
    final TextDrawable? selectedTextDrawable;
    final bool isTransforming;
    final String? editingTextId;

    const TextDrawablePainter({
      required this.textDrawables,
      required this.selectedTextDrawable,
      required this.isTransforming,
      required this.editingTextId,
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

        _paintTextDrawable(canvas, textDrawable);

        // Draw selection indicator if this text is selected
        if (selectedTextDrawable == textDrawable) {
          _paintSelectionIndicator(canvas, textDrawable);
        }
      }
    }

    @override
    bool shouldRepaint(covariant TextDrawablePainter oldDelegate) {
      return textDrawables != oldDelegate.textDrawables ||
          selectedTextDrawable != oldDelegate.selectedTextDrawable ||
          isTransforming != oldDelegate.isTransforming ||
          editingTextId != oldDelegate.editingTextId;
    }

    /// Get the bounding rect of a text drawable
    static Rect getTextBounds(TextDrawable textDrawable) {
      final textSpan = TextSpan(
        text: textDrawable.text,
        style: textDrawable.style,
      );

      final textPainter = TextPainter(
        text: textSpan,
        textAlign: textDrawable.alignment.textAlign,
        textDirection: .ltr,
      );

      textPainter.layout();

      // Calculate position based on alignment
      Offset position = textDrawable.position;
      switch (textDrawable.alignment) {
        case .center:
          position = Offset(
            textDrawable.position.dx - textPainter.width / 2,
            textDrawable.position.dy - textPainter.height / 2,
          );
          break;
        case .right:
          position = Offset(
            textDrawable.position.dx - textPainter.width,
            textDrawable.position.dy - textPainter.height / 2,
          );
          break;
        case .left:
          position = Offset(
            textDrawable.position.dx,
            textDrawable.position.dy - textPainter.height / 2,
          );
          break;
      }

      return Rect.fromLTWH(
        position.dx,
        position.dy,
        textPainter.width,
        textPainter.height,
      );
    }

    /// 텍스트 오버레이 버튼 클릭 감지 (회전 지원)
    static String? getButtonType(TextDrawable textDrawable, Offset point) {
      const buttonSize = 40.0; // 페인터와 동일한 크기
      const buttonRadius = buttonSize / 2;

      // 회전된 텍스트의 정확한 버튼 위치 계산
      final buttonPositions = _getStaticRotatedButtonPositions(textDrawable);

      // 삭제 버튼 (우상단)
      final deleteButtonCenter = buttonPositions['delete']!;
      if ((point - deleteButtonCenter).distance <= buttonRadius) {
        return 'delete';
      }

      // 변형 버튼 (좌하단)
      final transformButtonCenter = buttonPositions['transform']!;
      if ((point - transformButtonCenter).distance <= buttonRadius) {
        return 'transform';
      }

      return null;
    }

    /// 텍스트 영역 내부 클릭 감지 (버튼 제외, 회전 지원)
    static bool isPointInTextArea(TextDrawable textDrawable, Offset point) {
      // 회전된 텍스트의 경우 점이 회전된 영역 내부에 있는지 확인
      double rotation = 0.0;
      try {
        rotation = textDrawable.rotation;
      } on Exception catch (error, stackTrace) {
        debugPrintStack(stackTrace: stackTrace);
        debugPrint(error.toString());
        // rotation 필드가 없거나 접근할 수 없는 경우 기본값 사용
        rotation = 0.0;
      }

      if (rotation == 0.0) {
        // 회전이 없는 경우 기존 방식
        final bounds = getTextBounds(textDrawable);
        final rect = Rect.fromLTWH(
          bounds.left - 4,
          bounds.top - 4,
          bounds.width + 8,
          bounds.height + 8,
        );

        // 전체 영역에 포함되는지 확인
        if (!rect.contains(point)) return false;
      } else {
        // 회전된 텍스트의 경우 역변환을 통해 점이 영역 내부에 있는지 확인
        final textSpan = TextSpan(
          text: textDrawable.text,
          style: textDrawable.style,
        );

        final textPainter = TextPainter(
          text: textSpan,
          textAlign: textDrawable.alignment.textAlign,
          textDirection: .ltr,
        );
        textPainter.layout();

        final center = textDrawable.position;
        final halfWidth = textPainter.width / 2;
        final halfHeight = textPainter.height / 2;

        // 점을 텍스트 중심 기준으로 이동
        final relativePoint = point - center;

        // 역회전 적용 (-rotation)
        final cos = math.cos(-rotation);
        final sin = math.sin(-rotation);
        final rotatedPoint = Offset(
          relativePoint.dx * cos - relativePoint.dy * sin,
          relativePoint.dx * sin + relativePoint.dy * cos,
        );

        // 회전되지 않은 상태에서 영역 내부에 있는지 확인
        final rect = Rect.fromLTWH(
          -halfWidth - 4,
          -halfHeight - 4,
          textPainter.width + 8,
          textPainter.height + 8,
        );

        if (!rect.contains(rotatedPoint)) return false;
      }

      // 버튼 영역 제외
      const buttonSize = 40.0; // 페인터와 동일한 크기
      const buttonRadius = buttonSize / 2;

      // 회전된 텍스트의 정확한 버튼 위치 계산
      final buttonPositions = _getStaticRotatedButtonPositions(textDrawable);

      // 삭제 버튼 영역 제외
      final deleteButtonCenter = buttonPositions['delete']!;
      if ((point - deleteButtonCenter).distance <= buttonRadius) {
        return false;
      }

      // 변형 버튼 영역 제외
      final transformButtonCenter = buttonPositions['transform']!;
      if ((point - transformButtonCenter).distance <= buttonRadius) {
        return false;
      }

      return true;
    }

    void _paintTextDrawable(Canvas canvas, TextDrawable textDrawable) {
      final textSpan = TextSpan(
        text: textDrawable.text,
        style: textDrawable.style,
      );

      final textPainter = TextPainter(
        text: textSpan,
        textAlign: textDrawable.alignment.textAlign,
        textDirection: .ltr,
      );

      textPainter.layout();

      // Calculate position based on alignment
      Offset position = textDrawable.position;
      switch (textDrawable.alignment) {
        case .center:
          position = Offset(
            textDrawable.position.dx - textPainter.width / 2,
            textDrawable.position.dy - textPainter.height / 2,
          );
          break;
        case .right:
          position = Offset(
            textDrawable.position.dx - textPainter.width,
            textDrawable.position.dy - textPainter.height / 2,
          );
          break;
        case .left:
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
      final textSpan = TextSpan(
        text: textDrawable.text,
        style: textDrawable.style,
      );

      final textPainter = TextPainter(
        text: textSpan,
        textAlign: textDrawable.alignment.textAlign,
        textDirection: .ltr,
      );

      textPainter.layout();

      // 회전이 있는 경우와 없는 경우 모두 중심점 기준으로 처리
      final textCenter = textDrawable.position;
      final halfWidth = textPainter.width / 2;
      final halfHeight = textPainter.height / 2;

      // 회전을 고려한 사각형 그리기
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
        canvas.translate(textCenter.dx, textCenter.dy);
        canvas.rotate(rotation);

        // 회전된 상태에서 사각형 그리기
        final rect = Rect.fromLTWH(
          -halfWidth - 4,
          -halfHeight - 4,
          textPainter.width + 8,
          textPainter.height + 8,
        );

        final paint = Paint()
          ..color = isTransforming ? Colors.green : Colors.blue
          ..style = .stroke
          ..strokeWidth = isTransforming ? 3.0 : 2.0;

        try {
          canvas.drawRect(rect, paint);
        } on Exception {
          //
        }

        // 드래그 중일 때 배경 표시
        if (isTransforming) {
          final backgroundPaint = Paint()
            ..color = Colors.blue.withValues(alpha: 0.1)
            ..style = .fill;
          try {
            canvas.drawRect(rect, backgroundPaint);
          } on Exception catch (error) {
            debugPrint('배경 사각형 렌더링 오류 (회전됨): $error');
          }
        }

        canvas.restore();

        // 회전된 텍스트의 정확한 버튼 위치 계산
        final buttonPositions = _getRotatedButtonPositions(
          textDrawable,
          textPainter,
        );
        _paintOverlayButtonsAtPositions(canvas, buttonPositions);
      } else {
        // 회전이 없는 경우 기존 방식
        final position = Offset(
          textCenter.dx - halfWidth,
          textCenter.dy - halfHeight,
        );

        final rect = Rect.fromLTWH(
          position.dx - 4,
          position.dy - 4,
          textPainter.width + 8,
          textPainter.height + 8,
        );

        final paint = Paint()
          ..color = isTransforming ? Colors.green : Colors.blue
          ..style = .stroke
          ..strokeWidth = isTransforming ? 3.0 : 2.0;

        try {
          canvas.drawRect(rect, paint);
        } on Exception catch (error) {
          debugPrint('선택 표시 사각형 렌더링 오류: $error');
        }

        // 드래그 중일 때 배경 표시
        if (isTransforming) {
          final backgroundPaint = Paint()
            ..color = Colors.blue.withValues(alpha: 0.1)
            ..style = .fill;
          try {
            canvas.drawRect(rect, backgroundPaint);
          } on Exception catch (error) {
            debugPrint('배경 사각형 렌더링 오류: $error');
          }
        }

        _paintOverlayButtons(canvas, rect);
      }
    }

    /// 회전된 텍스트의 정확한 버튼 위치 계산
    Map<String, Offset> _getRotatedButtonPositions(
      TextDrawable textDrawable,
      TextPainter textPainter,
    ) {
      final center = textDrawable.position;
      final halfWidth = textPainter.width / 2;
      final halfHeight = textPainter.height / 2;
      double rotation = 0.0;
      try {
        rotation = textDrawable.rotation;
      } on Exception catch (error, stackTrace) {
        debugPrintStack(stackTrace: stackTrace);
        debugPrint(error.toString());
        // rotation 필드가 없거나 접근할 수 없는 경우 기본값 사용
        rotation = 0.0;
      }

      if (rotation == 0.0) {
        // 회전이 없는 경우 기존 방식
        final rect = Rect.fromLTWH(
          center.dx - halfWidth - 4,
          center.dy - halfHeight - 4,
          textPainter.width + 8,
          textPainter.height + 8,
        );
        return {
          'delete': Offset(rect.right, rect.top),
          'transform': Offset(rect.left, rect.bottom),
        };
      }

      // 회전된 텍스트의 네 모서리 계산 (패딩 포함)
      final corners = [
        Offset(-halfWidth - 4, -halfHeight - 4), // 좌상단
        Offset(halfWidth + 4, -halfHeight - 4), // 우상단
        Offset(halfWidth + 4, halfHeight + 4), // 우하단
        Offset(-halfWidth - 4, halfHeight + 4), // 좌하단
      ];

      // 회전 변환 적용
      final cos = math.cos(rotation);
      final sin = math.sin(rotation);

      final rotatedCorners = corners.map((corner) {
        return Offset(
          center.dx + corner.dx * cos - corner.dy * sin,
          center.dy + corner.dx * sin + corner.dy * cos,
        );
      }).toList();

      return {
        'delete': rotatedCorners[1], // 우상단
        'transform': rotatedCorners[3], // 좌하단
      };
    }

    /// 오버레이 버튼 그리기 (변형 모드) - Rect 기반
    void _paintOverlayButtons(Canvas canvas, Rect rect) {
      final buttonPositions = {
        'delete': Offset(rect.right, rect.top),
        'transform': Offset(rect.left, rect.bottom),
      };
      _paintOverlayButtonsAtPositions(canvas, buttonPositions);
    }

    /// 오버레이 버튼 그리기 (변형 모드) - 위치 기반
    void _paintOverlayButtonsAtPositions(
      Canvas canvas,
      Map<String, Offset> positions,
    ) {
      const buttonSize = 50.0; // 더 크게 설정
      const buttonRadius = buttonSize / 2;

      // 삭제 버튼 (우상단)
      final deleteButtonCenter = positions['delete']!;
      final deleteButtonPaint = Paint()
        ..color = Colors.red
        ..style = .fill;

      // 삭제 버튼 배경 원
      try {
        canvas.drawCircle(deleteButtonCenter, buttonRadius, deleteButtonPaint);
      } on Exception catch (error) {
        debugPrint('삭제 버튼 배경 렌더링 오류: $error');
      }

      // 삭제 버튼 테두리
      final deleteButtonBorderPaint = Paint()
        ..color = Colors.white
        ..style = .stroke
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
        ..style = .stroke
        ..strokeWidth = 3.0
        ..strokeCap = .round;

      const iconSize = 12.0;
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
      final transformButtonCenter = positions['transform']!;
      final transformButtonPaint = Paint()
        ..color = Colors.blue
        ..style = .fill;

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
        ..style = .stroke
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
        ..style = .stroke
        ..strokeWidth = 2.5
        ..strokeCap = .round;

      const arrowSize = 10.0;
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

    /// 회전된 텍스트의 정확한 버튼 위치 계산 (정적 메서드용)
    static Map<String, Offset> _getStaticRotatedButtonPositions(
      TextDrawable textDrawable,
    ) {
      // TextPainter로 텍스트 크기 계산
      final textSpan = TextSpan(
        text: textDrawable.text,
        style: textDrawable.style,
      );

      final textPainter = TextPainter(
        text: textSpan,
        textAlign: textDrawable.alignment.textAlign,
        textDirection: .ltr,
      );
      textPainter.layout();

      final center = textDrawable.position;
      final halfWidth = textPainter.width / 2;
      final halfHeight = textPainter.height / 2;

      double rotation = 0.0;
      try {
        rotation = textDrawable.rotation;
      } on Exception catch (error, stackTrace) {
        debugPrintStack(stackTrace: stackTrace);
        debugPrint(error.toString());
        // rotation 필드가 없거나 접근할 수 없는 경우 기본값 사용
        rotation = 0.0;
      }

      if (rotation == 0.0) {
        // 회전이 없는 경우 기존 방식
        final rect = Rect.fromLTWH(
          center.dx - halfWidth - 4,
          center.dy - halfHeight - 4,
          textPainter.width + 8,
          textPainter.height + 8,
        );
        return {
          'delete': Offset(rect.right, rect.top),
          'transform': Offset(rect.left, rect.bottom),
        };
      }

      // 회전된 텍스트의 네 모서리 계산 (패딩 포함)
      final corners = [
        Offset(-halfWidth - 4, -halfHeight - 4), // 좌상단
        Offset(halfWidth + 4, -halfHeight - 4), // 우상단
        Offset(halfWidth + 4, halfHeight + 4), // 우하단
        Offset(-halfWidth - 4, halfHeight + 4), // 좌하단
      ];

      // 회전 변환 적용
      final cos = math.cos(rotation);
      final sin = math.sin(rotation);

      final rotatedCorners = corners.map((corner) {
        return Offset(
          center.dx + corner.dx * cos - corner.dy * sin,
          center.dy + corner.dx * sin + corner.dy * cos,
        );
      }).toList();

      return {
        'delete': rotatedCorners[1], // 우상단
        'transform': rotatedCorners[3], // 좌하단
      };
    }
  }

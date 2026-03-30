// 🐦 Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

// 🌎 Project imports:
import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_board/src/module/state/text_settings.dart';
import 'package:open_board/src/module/text/text_drawable_extensions.dart';

/// 텍스트 CRUD 관리 클래스
///
/// ScribbleNotifier에서 추출된 immutable 방식의 텍스트 관리자로,
/// Scribble을 입력받아 텍스트가 업데이트된 새 Scribble을 반환합니다.
///
/// 이 클래스는 ScribbleNotifier에 대한 의존성을 갖지 않습니다.
class TextDrawableManager {
  const TextDrawableManager();

  /// 텍스트를 추가한 새 Scribble을 반환합니다.
  Scribble add(Scribble scribble, TextDrawable textDrawable) {
    final currentTextDrawables = getAll(scribble);
    final updatedTextDrawables = [...currentTextDrawables, textDrawable];
    return applyToScribble(scribble, updatedTextDrawables);
  }

  /// 텍스트를 수정한 새 Scribble을 반환합니다.
  Scribble update(
    Scribble scribble,
    String id,
    TextDrawable updatedTextDrawable,
  ) {
    final currentTextDrawables = getAll(scribble);
    final updatedTextDrawables = currentTextDrawables.map((textDrawable) {
      return textDrawable.id == id ? updatedTextDrawable : textDrawable;
    }).toList();
    return applyToScribble(scribble, updatedTextDrawables);
  }

  /// 텍스트를 삭제한 새 Scribble을 반환합니다.
  Scribble remove(Scribble scribble, String id) {
    final currentTextDrawables = getAll(scribble);
    final updatedTextDrawables = currentTextDrawables
        .where((textDrawable) => textDrawable.id != id)
        .toList();
    return applyToScribble(scribble, updatedTextDrawables);
  }

  /// 모든 텍스트를 삭제한 새 Scribble을 반환합니다.
  Scribble clearAll(Scribble scribble) {
    return applyToScribble(scribble, []);
  }

  /// 현재 텍스트 목록을 가져옵니다.
  List<TextDrawable> getAll(Scribble scribble) {
    return scribble.textDrawables;
  }

  /// ID로 텍스트를 찾습니다.
  TextDrawable? findById(Scribble scribble, String id) {
    final textDrawables = getAll(scribble);
    for (final textDrawable in textDrawables) {
      if (textDrawable.id == id) return textDrawable;
    }
    return null;
  }

  /// 위치로 텍스트를 찾습니다.
  TextDrawable? findAtPosition(
    Scribble scribble,
    Offset position, {
    double tolerance = 10.0,
  }) {
    final textDrawables = getAll(scribble);

    for (final textDrawable in textDrawables) {
      final textPosition = textDrawable.position;
      final distance = (textPosition - position).distance;

      if (distance <= tolerance) {
        return textDrawable;
      }
    }

    return null;
  }

  /// 텍스트 숨김/표시를 토글한 새 Scribble을 반환합니다.
  Scribble toggleVisibility(Scribble scribble, String id) {
    final textDrawable = findById(scribble, id);
    if (textDrawable != null) {
      final updatedTextDrawable = textDrawable.copyWithHidden(
        !textDrawable.hidden,
      );
      return update(scribble, id, updatedTextDrawable);
    }
    return scribble;
  }

  /// 텍스트 위치를 이동한 새 Scribble을 반환합니다.
  Scribble move(Scribble scribble, String id, Offset newPosition) {
    final textDrawable = findById(scribble, id);
    if (textDrawable != null) {
      final updatedTextDrawable = textDrawable.copyWithPosition(newPosition);
      return update(scribble, id, updatedTextDrawable);
    }
    return scribble;
  }

  /// 선택된 텍스트들을 삭제한 새 Scribble을 반환합니다.
  Scribble deleteSelected(Scribble scribble, List<String> selectedTextIds) {
    final currentTextDrawables = getAll(scribble);
    final updatedTextDrawables = currentTextDrawables
        .where((textDrawable) => !selectedTextIds.contains(textDrawable.id))
        .toList();
    return applyToScribble(scribble, updatedTextDrawables);
  }

  /// 텍스트 스타일을 일괄 변경한 새 Scribble을 반환합니다.
  Scribble updateStyle(
    Scribble scribble,
    String id, {
    String? fontFamily,
    double? fontSize,
    Color? color,
    bool? isBold,
    bool? isItalic,
    bool? isUnderlined,
    TextAlignment? textAlignment,
  }) {
    final textDrawable = findById(scribble, id);
    if (textDrawable != null) {
      final currentStyle = textDrawable.style;
      final updatedStyle = TextStyle(
        fontFamily: fontFamily ?? currentStyle.fontFamily,
        fontSize: fontSize ?? currentStyle.fontSize,
        color: color ?? currentStyle.color,
        fontWeight: isBold != null
            ? (isBold ? FontWeight.bold : FontWeight.normal)
            : currentStyle.fontWeight,
        fontStyle: isItalic != null
            ? (isItalic ? FontStyle.italic : FontStyle.normal)
            : currentStyle.fontStyle,
        decoration: isUnderlined != null
            ? (isUnderlined ? TextDecoration.underline : null)
            : currentStyle.decoration,
      );

      final updatedTextDrawable = textDrawable
          .copyWithStyle(updatedStyle)
          .copyWithAlignment(textAlignment ?? textDrawable.alignment);
      return update(scribble, id, updatedTextDrawable);
    }
    return scribble;
  }

  /// 텍스트 목록을 Scribble에 적용한 새 Scribble을 반환합니다.
  Scribble applyToScribble(
    Scribble scribble,
    List<TextDrawable> textDrawables,
  ) {
    return Scribble(
      x: scribble.x,
      y: scribble.y,
      width: scribble.width,
      height: scribble.height,
      strokes: scribble.strokes,
      textDrawables: textDrawables,
      createdAt: scribble.createdAt,
      updatedAt: DateTime.now().toIso8601String(),
      version: scribble.version,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_board/src/module/state/text_settings.dart';

/// Extensions for protobuf TextDrawable
extension TextDrawableExtensions on TextDrawable {
  /// Get the position as Offset
  Offset get position => .new(x, y);

  /// Get the text style
  TextStyle get style => .new(
    fontFamily: fontFamily.isEmpty ? null : fontFamily,
    fontSize: fontSize == 0 ? 16.0 : fontSize,
    color: Color(color),
    fontWeight: isBold ? .bold : .normal,
    fontStyle: isItalic ? .italic : .normal,
    decoration: isUnderlined ? .underline : null,
  );

  /// Get the text alignment
  TextAlignment get alignment => TextAlignmentExtension.fromString(textAlign);

  /// Create a copy with updated position
  TextDrawable copyWithPosition(Offset newPosition) {
    return TextDrawable()
      ..mergeFromMessage(this)
      ..x = newPosition.dx
      ..y = newPosition.dy
      ..updatedAt = DateTime.now().toIso8601String();
  }

  /// Create a copy with updated text
  TextDrawable copyWithText(String newText) {
    return TextDrawable()
      ..mergeFromMessage(this)
      ..text = newText
      ..updatedAt = DateTime.now().toIso8601String();
  }

  /// Create a copy with updated style
  TextDrawable copyWithStyle(TextStyle newStyle) {
    return TextDrawable()
      ..mergeFromMessage(this)
      ..fontFamily = newStyle.fontFamily ?? ''
      ..fontSize = newStyle.fontSize ?? 16.0
      ..color = (newStyle.color ?? Colors.black).toARGB32()
      ..isBold = newStyle.fontWeight == .bold
      ..isItalic = newStyle.fontStyle == .italic
      ..isUnderlined = newStyle.decoration == .underline
      ..updatedAt = DateTime.now().toIso8601String();
  }

  /// Create a copy with updated alignment
  TextDrawable copyWithAlignment(TextAlignment newAlignment) {
    return TextDrawable()
      ..mergeFromMessage(this)
      ..textAlign = newAlignment.value
      ..updatedAt = DateTime.now().toIso8601String();
  }

  /// Create a copy with updated visibility
  TextDrawable copyWithHidden(bool isHidden) {
    return TextDrawable()
      ..mergeFromMessage(this)
      ..hidden = isHidden
      ..updatedAt = DateTime.now().toIso8601String();
  }

  /// 정적 렌더링·히트테스트에서 쓸 레이아웃 최대 폭.
  ///
  /// 인라인 에디터가 커밋 시점의 실제 줄바꿈 폭을 [maxWidth] 에 기록한다.
  /// 이 값 없이 무제한 폭으로 재레이아웃하면 편집 중 보이던 소프트 줄바꿈이
  /// 확정 순간 전부 풀린다 (kobic unibook#12538/#12548 — UB-627/UB-632).
  /// 0 은 미기록(레거시) 데이터이며 종전과 동일하게 무제한 폭으로 렌더링한다.
  double get layoutMaxWidth => maxWidth > 0 ? maxWidth : double.infinity;

  /// Create a copy with updated soft-wrap layout width
  TextDrawable copyWithMaxWidth(double newMaxWidth) {
    return TextDrawable()
      ..mergeFromMessage(this)
      ..maxWidth = newMaxWidth
      ..updatedAt = DateTime.now().toIso8601String();
  }

  /// Create a copy with updated inline hyperlink spans.
  TextDrawable copyWithLinkSpans(Iterable<TextLinkSpan> newLinkSpans) {
    return TextDrawable()
      ..mergeFromMessage(this)
      ..linkSpans.clear()
      ..linkSpans.addAll(newLinkSpans)
      ..updatedAt = DateTime.now().toIso8601String();
  }
}

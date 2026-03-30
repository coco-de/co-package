import 'package:flutter/material.dart';
import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_board/src/module/state/text_settings.dart';

/// Extensions for protobuf TextDrawable
extension TextDrawableExtensions on TextDrawable {
  /// Get the position as Offset
  Offset get position => Offset(x, y);

  /// Get the text style
  TextStyle get style => TextStyle(
    fontFamily: fontFamily.isEmpty ? null : fontFamily,
    fontSize: fontSize == 0 ? 16.0 : fontSize,
    color: Color(color),
    fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
    fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
    decoration: isUnderlined ? TextDecoration.underline : null,
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
      ..isBold = newStyle.fontWeight == FontWeight.bold
      ..isItalic = newStyle.fontStyle == FontStyle.italic
      ..isUnderlined = newStyle.decoration == TextDecoration.underline
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
}

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

  /// Get creation date
  DateTime get createdAtDateTime =>
      createdAt.isEmpty ? DateTime.now() : DateTime.parse(createdAt);

  /// Get update date
  DateTime? get updatedAtDateTime =>
      updatedAt.isEmpty ? null : DateTime.parse(updatedAt);

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

  /// Create a copy with updated timestamp
  TextDrawable withUpdatedTimestamp() {
    return TextDrawable()
      ..mergeFromMessage(this)
      ..updatedAt = DateTime.now().toIso8601String();
  }

  /// Create a copy with multiple updates
  TextDrawable copyWith({
    String? id,
    String? text,
    Offset? position,
    TextStyle? style,
    TextAlignment? alignment,
    bool? hidden,
    double? rotation,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final result = TextDrawable()..mergeFromMessage(this);

    if (id != null) result.id = id;
    if (text != null) result.text = text;
    if (position != null) {
      result.x = position.dx;
      result.y = position.dy;
    }
    if (style != null) {
      result.fontFamily = style.fontFamily ?? '';
      result.fontSize = style.fontSize ?? 16.0;
      result.color = (style.color ?? Colors.black).toARGB32();
      result.isBold = style.fontWeight == FontWeight.bold;
      result.isItalic = style.fontStyle == FontStyle.italic;
      result.isUnderlined = style.decoration == TextDecoration.underline;
    }
    if (alignment != null) {
      result.textAlign = alignment.value;
    }
    if (hidden != null) {
      result.hidden = hidden;
    }
    if (rotation != null) {
      result.rotation = rotation;
    }
    if (createdAt != null) {
      result.createdAt = createdAt.toIso8601String();
    }
    if (updatedAt != null) {
      result.updatedAt = updatedAt.toIso8601String();
    }

    return result;
  }

  /// Create from JSON (for backward compatibility)
  static TextDrawable fromJsonMap(Map<String, dynamic> json) {
    return TextDrawable(
      id: json['id'] as String? ?? '',
      text: json['text'] as String? ?? '',
      x: (json['x'] as num?)?.toDouble() ?? 0.0,
      y: (json['y'] as num?)?.toDouble() ?? 0.0,
      fontFamily: json['fontFamily'] as String? ?? '',
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 16.0,
      color: json['color'] as int? ?? Colors.black.toARGB32(),
      isBold: json['isBold'] as bool? ?? false,
      isItalic: json['isItalic'] as bool? ?? false,
      isUnderlined: json['isUnderlined'] as bool? ?? false,
      textAlign: json['textAlign'] as String? ?? 'center',
      hidden: json['hidden'] as bool? ?? false,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
      createdAt:
          json['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      updatedAt: json['updatedAt'] as String? ?? '',
    );
  }

  /// Convert to JSON (for backward compatibility)
  Map<String, dynamic> toJsonMap() {
    return {
      'id': id,
      'text': text,
      'x': x,
      'y': y,
      'fontFamily': fontFamily,
      'fontSize': fontSize,
      'color': color,
      'isBold': isBold,
      'isItalic': isItalic,
      'isUnderlined': isUnderlined,
      'textAlign': textAlign,
      'hidden': hidden,
      'rotation': hasRotation() ? rotation : 0.0,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

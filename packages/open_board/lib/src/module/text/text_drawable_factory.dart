import 'package:flutter/material.dart';
import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_board/src/module/state/text_settings.dart';

/// Factory class for creating protobuf TextDrawable instances
class TextDrawableFactory {
  /// Create a new TextDrawable instance
  static TextDrawable create({
    required String id,
    required String text,
    required Offset position,
    required TextStyle style,
    required TextAlignment alignment,
    required bool hidden,
  }) {
    return TextDrawable(
      id: id,
      text: text,
      x: position.dx,
      y: position.dy,
      fontFamily: style.fontFamily ?? '',
      fontSize: style.fontSize ?? 16.0,
      color: (style.color ?? Colors.black).toARGB32(),
      isBold: style.fontWeight == .bold,
      isItalic: style.fontStyle == .italic,
      isUnderlined: style.decoration == .underline,
      textAlign: _convertTextAlignment(alignment),
      hidden: hidden,
      rotation: 0.0, // 기본 회전 각도 설정
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
    );
  }

  /// Convert TextAlignment to string
  static String _convertTextAlignment(TextAlignment alignment) {
    switch (alignment) {
      case .left:
        return 'left';
      case .center:
        return 'center';
      case .right:
        return 'right';
    }
  }
}

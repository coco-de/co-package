import 'package:flutter/painting.dart';

/// Colours and sizes of `NoteStickerManager`.
class NoteStickerManagerStyle {
  const NoteStickerManagerStyle({
    this.textStyle = const TextStyle(
      fontSize: 13,
      color: Color(0xFF1F1F24),
      decoration: TextDecoration.none,
      fontWeight: FontWeight.w400,
    ),
    this.mutedColor = const Color(0xFF8A8A93),
    this.accentColor = const Color(0xFF2962FF),
    this.selectedColor = const Color(0x1F2962FF),
    this.dangerColor = const Color(0xFFC62828),
    this.stickerExtent = 56,
    this.nameFieldWidth = 180,
    this.radius = 8,
    this.spacing = 4,
  });

  final TextStyle textStyle;
  final Color mutedColor;
  final Color accentColor;
  final Color selectedColor;
  final Color dangerColor;
  final double stickerExtent;
  final double nameFieldWidth;
  final double radius;
  final double spacing;
}

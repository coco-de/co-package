import 'dart:ui';

import 'package:open_note/src/note/core/note_json.dart';

/// Internal helpers shared by the style and template codecs. Not exported by the
/// module barrels.
abstract final class NoteStyleValues {
  /// [value] clamped to `[min, max]`; [fallback] when it is `null` or not
  /// finite.
  static double clamped(
    double? value,
    double fallback,
    double min,
    double max,
  ) {
    if (value == null || !value.isFinite) return fallback;

    return value.clamp(min, max);
  }

  /// [color] rounded to 8-bit ARGB, so that a value compares equal to itself
  /// after being written as an integer and read back.
  static Color quantise(Color color) => Color(color.toARGB32());

  /// [quantise] for an optional colour.
  static Color? quantiseOrNull(Color? color) =>
      color == null ? null : quantise(color);

  /// The ARGB integer stored under [key], or `null` when absent or invalid.
  static Color? colorOrNull(JsonMap json, String key) {
    final value = json[key];
    if (value is! num || !value.isFinite) return null;

    return Color(value.toInt() & 0xFFFFFFFF);
  }

  /// The shortest text for [value] (`2`, `0.25`) that parses back exactly.
  static String formatNumber(double value) {
    final text = value.toString();

    return text.endsWith('.0') ? text.substring(0, text.length - 2) : text;
  }
}

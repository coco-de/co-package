import 'package:flutter/painting.dart';

/// Conversion between colours and hex text.
abstract final class NoteColorUtils {
  static final RegExp _hexDigits = RegExp(r'^[0-9a-fA-F]+$');

  /// Parses `#RGB`, `#RRGGBB` or `#AARRGGBB` (the `#` is optional, case is
  /// ignored, surrounding spaces are trimmed). `#RGB` and `#RRGGBB` are
  /// opaque. Returns `null` for anything else.
  static Color? parseHex(String input) {
    var text = input.trim();
    if (text.startsWith('#')) text = text.substring(1);
    if (!_hexDigits.hasMatch(text)) return null;
    final argb = switch (text.length) {
      3 => 'FF${text.split('').map((digit) => '$digit$digit').join()}',
      6 => 'FF$text',
      8 => text,
      _ => null,
    };

    return argb == null ? null : Color(int.parse(argb, radix: 16));
  }

  /// [color] as upper case `#RRGGBB`, or `#AARRGGBB` when [alpha] is true.
  /// Without [alpha] the alpha channel is dropped.
  static String toHex(Color color, {bool alpha = false}) {
    final text = color.toARGB32().toRadixString(16).padLeft(8, '0');
    final digits = alpha ? text : text.substring(2);

    return '#${digits.toUpperCase()}';
  }
}

import 'package:flutter/material.dart';

/// Display typography for text box annotations.
///
/// [fontFamily] is the default family for text boxes with no stored family.
typedef TextBoxTypography = ({
  FontWeight regular,
  FontWeight bold,
  String? fontFamily,
});

/// The standard display typography for a text box.
const TextBoxTypography defaultTextBoxTypography = (
  regular: FontWeight.normal,
  bold: FontWeight.bold,
  fontFamily: null,
);

extension TextBoxTypographyStyle on TextBoxTypography {
  /// Applies display typography without modifying the persisted text style.
  TextStyle applyTo(TextStyle style) {
    if (this == defaultTextBoxTypography) return style;
    final weight = switch (style.fontWeight) {
      null || FontWeight.normal => regular,
      FontWeight.bold => bold,
      final weight => weight,
    };
    final hasStoredFamily = style.fontFamily?.isNotEmpty ?? false;
    return style.copyWith(
      fontWeight: weight,
      fontFamily: hasStoredFamily ? style.fontFamily : fontFamily,
    );
  }
}

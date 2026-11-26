import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// Look and hit-test metrics of masks and tapes, in page units. The fill itself
/// is part of the object (`NoteMaskFill`); this holds what a theme decides.
@immutable
class NoteMaskStyle {
  /// Creates a style; every value has a usable default.
  const NoteMaskStyle({
    this.outlineColor = const Color(0x99757575),
    this.outlineWidth = 1,
    this.cornerRadius = defaultCornerRadius,
    this.stripeSpacing = 10,
    this.stripeWidth = 4,
    this.dotSpacing = 10,
    this.dotRadius = 2,
    this.hitSlop = 6,
  }) : assert(stripeSpacing > 0, 'stripeSpacing must be positive'),
       assert(dotSpacing > 0, 'dotSpacing must be positive');

  /// Corner radius of rectangular masks, also used by export.
  static const double defaultCornerRadius = 2;

  /// Colour of the faint outline that remains when a cover is revealed.
  final Color outlineColor;

  /// Width of that outline.
  final double outlineWidth;

  /// Corner radius of rectangular masks and tapes.
  final double cornerRadius;

  /// Horizontal distance between two stripes.
  final double stripeSpacing;

  /// Thickness of one stripe.
  final double stripeWidth;

  /// Distance between two dots.
  final double dotSpacing;

  /// Radius of one dot.
  final double dotRadius;

  /// How far outside a stroke or a tape a tap still hits it.
  final double hitSlop;

  @override
  bool operator ==(Object other) =>
      other is NoteMaskStyle &&
      other.outlineColor == outlineColor &&
      other.outlineWidth == outlineWidth &&
      other.cornerRadius == cornerRadius &&
      other.stripeSpacing == stripeSpacing &&
      other.stripeWidth == stripeWidth &&
      other.dotSpacing == dotSpacing &&
      other.dotRadius == dotRadius &&
      other.hitSlop == hitSlop;

  @override
  int get hashCode => Object.hash(
    outlineColor,
    outlineWidth,
    cornerRadius,
    stripeSpacing,
    stripeWidth,
    dotSpacing,
    dotRadius,
    hitSlop,
  );
}

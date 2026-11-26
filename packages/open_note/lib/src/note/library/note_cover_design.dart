import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';

/// How a built-in cover or a colour cover is drawn: a [background] colour with a
/// decoration in [accent].
@immutable
class NoteCoverDesign {
  /// Creates a design.
  const NoteCoverDesign({
    required this.background,
    required this.accent,
    this.pattern = NoteCoverPattern.plain,
  });

  /// A plain design in [fill] with a lighter spine and accent.
  factory NoteCoverDesign.solid(Color fill) => NoteCoverDesign(
    background: fill,
    accent: Color.lerp(fill, const Color(0xFFFFFFFF), 0.35) ?? fill,
  );

  /// The main fill of the cover.
  final Color background;

  /// The colour of the [pattern].
  final Color accent;

  /// The decoration drawn over [background].
  final NoteCoverPattern pattern;

  @override
  bool operator ==(Object other) =>
      other is NoteCoverDesign &&
      other.background == background &&
      other.accent == accent &&
      other.pattern == pattern;

  @override
  int get hashCode => Object.hash(background, accent, pattern);

  @override
  String toString() => 'NoteCoverDesign($pattern, $background, $accent)';
}

/// The decorations a [NoteCoverDesign] can carry.
enum NoteCoverPattern {
  /// Nothing but the spine.
  plain,

  /// One wide horizontal band.
  band,

  /// Vertical stripes.
  stripes,

  /// A regular field of dots.
  dots,

  /// A thin square grid.
  grid,

  /// Slanted lines.
  diagonal,

  /// A title label near the top.
  label,

  /// The lower third in the accent colour.
  split,
}

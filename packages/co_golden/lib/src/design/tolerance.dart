import 'package:meta/meta.dart';

/// How far a capture may deviate from its design before the design analysis
/// reports a difference.
///
/// Exact pixel equality is too strict for design review: Figma and Flutter
/// rasterize text and anti-aliased edges differently, so a perfect screen
/// still differs in thousands of pixels. The pixel part therefore uses a
/// perceptual color distance (CIEDE2000), a small positional radius, and
/// anti-aliasing detection, and only then measures the result against a
/// budget. The defaults are the measured defaults of the `visual-verify`
/// skill (`figma_compare.py`), so both tools judge pixels alike.
///
/// The structural part compares what the design specifies — font, size,
/// weight, line height, letter spacing, colors, radii, positions — with what
/// the widget tree actually rendered, using the property tolerances below.
@immutable
final class GoldenDesignTolerance {
  /// Creates tolerances. Every value must be finite and not negative.
  const GoldenDesignTolerance({
    this.pixel = 1,
    this.colorDeltaE = 3,
    this.textPixel = 2,
    this.textDeltaE = 10,
    this.budgetRatio = 0.002,
    this.budgetRegion = 32,
    this.maxMaskRatio = 0.15,
    this.antialias = true,
    this.position = 1,
    this.textPosition = 2,
    this.size = 1,
    this.majorOffset = 4,
    this.fontSize = 0.5,
    this.lineHeight = 1,
    this.letterSpacing = 0.1,
    this.radius = 1,
    this.strokeWidth = 0.5,
    this.propertyDeltaE = 3,
    this.majorDeltaE = 10,
  });

  /// Positional radius of the pixel comparison, in logical pixels.
  final double pixel;

  /// CIEDE2000 below which two pixel colors count as equal.
  final double colorDeltaE;

  /// Horizontal positional radius inside text boxes, in logical pixels.
  /// Glyph advances accumulate differently in Figma and Flutter along a line.
  final double textPixel;

  /// CIEDE2000 below which two pixel colors inside text boxes count as equal.
  final double textDeltaE;

  /// Largest fraction of differing comparable pixels that still passes.
  final double budgetRatio;

  /// Largest differing region, in logical px², that still passes.
  final double budgetRegion;

  /// Largest masked fraction of the frame. Above it the pixel verdict is
  /// `undetermined` — masking must not hide the screen.
  final double maxMaskRatio;

  /// Whether anti-aliased edge pixels are excluded (pixelmatch rule).
  final bool antialias;

  /// Allowed offset of a matched box against its design, in logical pixels.
  final double position;

  /// Allowed offset of a matched text against its design, in logical pixels.
  final double textPosition;

  /// Allowed width or height difference of a matched box, in logical pixels.
  final double size;

  /// Offset or size difference above which a layout finding is an error
  /// instead of a warning, in logical pixels.
  final double majorOffset;

  /// Allowed font size difference, in logical pixels.
  final double fontSize;

  /// Allowed line height difference, in logical pixels.
  final double lineHeight;

  /// Allowed letter spacing difference, in logical pixels.
  final double letterSpacing;

  /// Allowed corner radius difference, in logical pixels.
  final double radius;

  /// Allowed border width difference, in logical pixels.
  final double strokeWidth;

  /// CIEDE2000 above which a fill, text, or border color is reported.
  final double propertyDeltaE;

  /// CIEDE2000 above which a color finding is an error instead of a warning.
  final double majorDeltaE;

  /// Checks that every value is usable; throws an [ArgumentError] otherwise.
  void validate() {
    for (final MapEntry(:key, :value) in _values.entries) {
      if (!value.isFinite || value < 0) {
        throw ArgumentError.value(value, key, 'must be finite and >= 0');
      }
    }
    if (budgetRatio > 1 || maxMaskRatio > 1) {
      throw ArgumentError('budgetRatio and maxMaskRatio must be at most 1');
    }
  }

  Map<String, double> get _values => {
    'pixel': pixel,
    'colorDeltaE': colorDeltaE,
    'textPixel': textPixel,
    'textDeltaE': textDeltaE,
    'budgetRatio': budgetRatio,
    'budgetRegion': budgetRegion,
    'maxMaskRatio': maxMaskRatio,
    'position': position,
    'textPosition': textPosition,
    'size': size,
    'majorOffset': majorOffset,
    'fontSize': fontSize,
    'lineHeight': lineHeight,
    'letterSpacing': letterSpacing,
    'radius': radius,
    'strokeWidth': strokeWidth,
    'propertyDeltaE': propertyDeltaE,
    'majorDeltaE': majorDeltaE,
  };

  /// Names of the values that differ from the defaults, for reviewers.
  List<String> get changed {
    const defaults = GoldenDesignTolerance();
    final base = defaults._values;
    return [
      for (final MapEntry(:key, :value) in _values.entries)
        if (base[key] != value) key,
      if (antialias != defaults.antialias) 'antialias',
    ];
  }

  /// JSON form written to design reports.
  Map<String, Object?> toJson() => {..._values, 'antialias': antialias};
}

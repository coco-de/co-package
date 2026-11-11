import 'ink_raster_evidence.dart';
import 'pixel_diff.dart';
import 'render_node.dart';
import 'spec.dart';
import 'tolerance.dart';

/// Evidence that equal, verified text differs only within the existing
/// positional pixel tolerance. Raw pixel counts and maps are never changed.
final class GoldenTextRasterEvidence {
  const GoldenTextRasterEvidence._(this.coverage, this.massRatio);

  /// Smaller of the two directional ink-support fractions.
  final double coverage;

  /// Rendered ink mass divided by reference ink mass.
  final double massRatio;

  /// Returns evidence only for the same loaded font, full text, style and
  /// solid foreground/background, with >=99.5% bidirectional shape support.
  /// Missing glyphs, color changes, large moves, and undecoded fonts fail
  /// closed. The caller must also require an exact structural text match
  /// without an explaining finding.
  static GoldenTextRasterEvidence? compare({
    required GoldenDesignNode design,
    required GoldenRenderNode render,
    required Map<String, bool> fonts,
    required GoldenRgbImage reference,
    required GoldenRgbImage actual,
    required double logicalWidth,
    required GoldenDesignTolerance tolerance,
  }) {
    final dt = design.text;
    final rt = render.text;
    if (dt == null ||
        rt == null ||
        dt.displayed != rt.text ||
        render.opacity != 1 ||
        design.opacity != 1 ||
        rt.runs.isNotEmpty ||
        dt.runs.isNotEmpty ||
        reference.width != actual.width ||
        reference.height != actual.height ||
        logicalWidth <= 0) {
      return null;
    }
    final ds = dt.typography;
    final rs = rt.style;
    bool equal(double? a, double? b, double allowed) =>
        a != null && b != null && (a - b).abs() <= allowed + 0.000001;
    if (ds.fontFamily == null ||
        ds.fontFamily != rs.fontFamily ||
        fonts[rs.fontFamily] != true ||
        ds.fontWeight != rs.fontWeight ||
        !equal(ds.fontSize, rs.fontSize, tolerance.fontSize) ||
        !equal(ds.lineHeight, rs.lineHeight, tolerance.lineHeight) ||
        !equal(ds.letterSpacing, rs.letterSpacing, tolerance.letterSpacing) ||
        ds.color == null ||
        ds.color != rs.color ||
        ds.color! >> 24 != 255 ||
        rt.truncated && !dt.truncated) {
      return null;
    }
    final ink = GoldenInkRasterEvidence.compare(
      rect: (design.inkRect ?? design.rect).union(rt.contentRect),
      foregroundColor: ds.color!,
      reference: reference,
      actual: actual,
      logicalWidth: logicalWidth,
      horizontalRadius: tolerance.textPixel,
      verticalRadius: tolerance.pixel,
      // Small glyphs have few solid interior pixels; different antialiasing
      // coverage can change total ink appreciably without changing the outline.
      // Content, loaded font, weight, color and 99.5% shape support remain required.
      minMassRatio: 2 / 3,
      maxMassRatio: 1.5,
      backgroundDeltaE: tolerance.propertyDeltaE,
    );
    return ink == null
        ? null
        : GoldenTextRasterEvidence._(ink.coverage, ink.massRatio);
  }
}

import 'package:meta/meta.dart';

import 'design_analysis.dart';

/// Design comparison recorded by co_golden, separate from the capture's
/// Flutter diagnostics or a golden baseline verdict.
///
/// The exact-pixel fields are always present. [analysis] adds the tolerance
/// based verdict and the structural findings when co_golden recorded them.
@immutable
final class GalleryDesignComparison {
  /// Creates the metadata for a captured variant's design reference.
  const GalleryDesignComparison({
    required this.reference,
    required this.label,
    required this.status,
    required this.referenceWidth,
    required this.referenceHeight,
    required this.renderWidth,
    required this.renderHeight,
    this.sourceUrl,
    this.diff,
    this.differentPixels,
    this.totalPixels,
    this.differenceRatio,
    this.analysis,
  });

  /// Reference image path relative to the capture root.
  final String reference;

  /// Name of the design source, usually Figma.
  final String label;

  /// `matched`, `different`, or `sizeMismatch`.
  final String status;

  /// Pixel width of the reference.
  final int referenceWidth;

  /// Pixel height of the reference.
  final int referenceHeight;

  /// Pixel width of the implementation capture.
  final int renderWidth;

  /// Pixel height of the implementation capture.
  final int renderHeight;

  /// Original design's http(s) link, when supplied.
  final String? sourceUrl;

  /// Exact-pixel difference image path, absent when dimensions differ.
  final String? diff;

  /// Number of unequal RGBA pixels; absent when dimensions differ.
  final int? differentPixels;

  /// Compared pixel count; absent when dimensions differ.
  final int? totalPixels;

  /// Fraction of unequal pixels in [0, 1]; absent when dimensions differ.
  final double? differenceRatio;

  /// Tolerance-based verdict and findings, when co_golden recorded them.
  final GalleryDesignAnalysis? analysis;

  /// Whether images can share a pixel coordinate system without resizing.
  bool get sameSize =>
      referenceWidth == renderWidth && referenceHeight == renderHeight;

  /// Short label which never confuses capture success with design agreement.
  String get summary {
    if (status == 'sizeMismatch') return '디자인 크기 다름';
    if (status == 'matched') return '디자인 픽셀 일치';
    final percent = differenceRatio! * 100;
    return '디자인 차이 ${percent < .001 ? '<0.001' : percent.toStringAsFixed(3)}%';
  }

  /// Status that filters and flags use: the analysis verdict (`pass`,
  /// `fail`, `undetermined`) when present, else the exact status.
  String get designStatus => analysis?.verdict ?? status;

  /// Whether the variant needs a design look: an analysis verdict other than
  /// `pass`, or — without analysis — unequal or differently sized pixels.
  bool get hasDifference => analysis?.hasDifference ?? status != 'matched';

  /// Thumbnail label: the analysis summary when present, else [summary].
  String get flag => analysis?.summary ?? summary;
}

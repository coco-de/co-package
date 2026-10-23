import 'package:meta/meta.dart';

/// Exact-pixel design comparison recorded by co_golden, separate from the
/// capture's Flutter diagnostics or a golden baseline verdict.
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
}

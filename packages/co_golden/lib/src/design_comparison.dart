import 'package:meta/meta.dart';

import 'design/report.dart';

/// Informational result of comparing a design export with a captured render.
enum GoldenDesignComparisonStatus {
  /// All decoded RGBA pixel channels match exactly.
  matched,

  /// The geometry matches, but at least one RGBA pixel differs.
  different,

  /// Different pixel geometry; no pixel ratio or diff is computed.
  sizeMismatch,
}

/// Design comparison metadata written as an optional run-manifest v1 field.
///
/// This does not change the variant's golden result. A passed capture means the
/// widget rendered successfully, and does not mean the design matches.
@immutable
final class GoldenDesignComparison {
  /// Creates comparison metadata. Artifact paths are output-relative POSIX paths.
  const GoldenDesignComparison({
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

  /// Captured, unmodified reference PNG path relative to the output directory.
  final String reference;

  /// Human-readable source label.
  final String label;

  /// Optional HTTP(S) source attribution.
  final String? sourceUrl;

  /// Pixel comparison outcome, independent from the golden test's pass/fail.
  final GoldenDesignComparisonStatus status;

  /// Original design width in pixels.
  final int referenceWidth;

  /// Original design height in pixels.
  final int referenceHeight;

  /// Captured render width in pixels.
  final int renderWidth;

  /// Captured render height in pixels.
  final int renderHeight;

  /// Visible diff PNG path, or `null` when dimensions differ.
  final String? diff;

  /// Number of differing RGBA pixels, or `null` when dimensions differ.
  final int? differentPixels;

  /// Number of compared pixels, or `null` when dimensions differ.
  final int? totalPixels;

  /// [differentPixels] / [totalPixels], or `null` when dimensions differ.
  final double? differenceRatio;

  /// Summary of the tolerant design analysis, when it ran. [status] stays the
  /// exact RGBA result; the analysis verdict applies tolerances and explains
  /// the differences in its report.
  final GoldenDesignAnalysisSummary? analysis;

  /// Copy with [summary] attached.
  GoldenDesignComparison withAnalysis(GoldenDesignAnalysisSummary summary) =>
      GoldenDesignComparison(
        reference: reference,
        label: label,
        status: status,
        referenceWidth: referenceWidth,
        referenceHeight: referenceHeight,
        renderWidth: renderWidth,
        renderHeight: renderHeight,
        sourceUrl: sourceUrl,
        diff: diff,
        differentPixels: differentPixels,
        totalPixels: totalPixels,
        differenceRatio: differenceRatio,
        analysis: summary,
      );

  /// JSON representation; no tolerance or design acceptance gate is implied.
  Map<String, Object?> toJson() => {
    'reference': reference,
    'label': label,
    'sourceUrl': sourceUrl,
    'status': status.name,
    'referenceWidth': referenceWidth,
    'referenceHeight': referenceHeight,
    'renderWidth': renderWidth,
    'renderHeight': renderHeight,
    'diff': diff,
    'differentPixels': differentPixels,
    'totalPixels': totalPixels,
    'differenceRatio': differenceRatio,
    if (analysis != null) 'analysis': analysis!.toJson(),
  };
}

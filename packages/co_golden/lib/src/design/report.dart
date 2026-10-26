import 'dart:convert';
import 'dart:io';

import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

import 'color.dart';
import 'finding.dart';
import 'geometry.dart';
import 'mask.dart';
import 'pixel_diff.dart';
import 'render_node.dart';
import 'spec.dart';
import 'tolerance.dart';

/// Schema name of design analysis reports.
const String goldenDesignReportSchema = 'co_golden.design_report';

/// Version of design analysis reports.
const int goldenDesignReportSchemaVersion = 1;

/// Most regions written to a report (largest first); the rest are counted in
/// `regionsTruncated`.
const int goldenReportRegionLimit = 100;

/// Overall result of a design analysis.
enum GoldenDesignVerdict {
  /// Pixels are within budget and no error finding remains.
  pass,

  /// Pixels exceed the budget or an error finding remains.
  fail,

  /// The pixels could not be compared — different frame sizes or scales, or
  /// too much of the frame masked. Structural findings are still listed.
  undetermined,
}

/// A differing pixel region, attributed to the design node and widget under
/// it.
@immutable
final class GoldenReportRegion {
  /// Creates a region entry.
  const GoldenReportRegion({
    required this.id,
    required this.region,
    this.design,
    this.widget,
    this.findings = const [],
    this.known,
  });

  /// `node:<design node id>` or `cell:<x>,<y>` — stable across runs.
  final String id;

  /// Pixel data.
  final GoldenPixelRegion region;

  /// Smallest design node containing the region's center.
  final GoldenDesignNode? design;

  /// Smallest rendered node containing the region's center.
  final GoldenRenderNode? widget;

  /// Ids of findings about the same element.
  final List<String> findings;

  /// Known difference that accepts the region, if any.
  final GoldenKnownDifference? known;

  /// JSON form.
  Map<String, Object?> toJson() => {
    'id': id,
    'rect': region.bounds.toJson(),
    'pixels': region.pixels,
    'logicalPixels': region.logicalPixels,
    'designColor': GoldenColorMath.hex(region.referenceColor),
    'renderColor': GoldenColorMath.hex(region.renderColor),
    'meanDeltaE': region.meanDeltaE,
    if (design != null) 'design': design!.toRef(),
    if (widget != null)
      'widget': {
        'id': widget!.id,
        'kind': widget!.kind,
        'type': widget!.widget,
        if (widget!.text != null) 'text': widget!.label,
        'rect': widget!.rect.toJson(),
        if (widget!.source != null) 'source': widget!.source!.label,
      },
    if (findings.isNotEmpty) 'findings': findings,
    if (known != null) 'known': known!.toJson(),
  };
}

/// Pixel part of a report.
@immutable
final class GoldenReportPixels {
  /// Creates the pixel part from a comparison.
  const GoldenReportPixels.compared(this.diff, {required this.diffPath})
    : reason = null,
      detail = null;

  /// Creates an undetermined pixel part.
  const GoldenReportPixels.undetermined(this.reason, this.detail)
    : diff = null,
      diffPath = null;

  /// The comparison, or `null` when undetermined.
  final GoldenPixelDiff? diff;

  /// Output-relative path of the tolerant difference map.
  final String? diffPath;

  /// Why the comparison is undetermined.
  final String? reason;

  /// Explanation of [reason].
  final String? detail;
}

/// Everything known about one variant's agreement with its design.
@immutable
final class GoldenDesignReport {
  /// Creates a report.
  const GoldenDesignReport({
    required this.suite,
    required this.scenario,
    required this.fileStem,
    required this.variant,
    required this.label,
    required this.reference,
    required this.render,
    required this.tolerance,
    required this.pixels,
    required this.snapshot,
    this.sourceUrl,
    this.referenceSha256,
    this.specPath,
    this.specSha256,
    this.spec,
    this.designSystem = const {},
    this.masks = const [],
    this.regions = const [],
    this.findings = const [],
    this.matchedDesign = 0,
    this.matchedRender = 0,
    this.comparedDesign = 0,
    this.warnings = const [],
  });

  /// Suite of the scenario.
  final String suite;

  /// Scenario name.
  final String scenario;

  /// Variant file stem.
  final String fileStem;

  /// Variant axes.
  final Map<String, Object?> variant;

  /// Design source label, usually `Figma`.
  final String label;

  /// Optional HTTP(S) link to the design.
  final String? sourceUrl;

  /// Output-relative path of the design snapshot.
  final String reference;

  /// SHA-256 of the design snapshot, to trace which export was compared.
  final String? referenceSha256;

  /// Path of the design specification as given.
  final String? specPath;

  /// SHA-256 of the design specification file.
  final String? specSha256;

  /// Parsed design specification.
  final GoldenDesignSpec? spec;

  /// Output-relative path of the captured render.
  final String render;

  /// Tolerances used.
  final GoldenDesignTolerance tolerance;

  /// Pixel comparison.
  final GoldenReportPixels pixels;

  /// What the inspector found.
  final GoldenRenderSnapshot snapshot;

  /// Design system name, catalog path, and counts.
  final Map<String, Object?> designSystem;

  /// Masks that were applied.
  final List<GoldenResolvedMask> masks;

  /// Pixel regions, largest first.
  final List<GoldenReportRegion> regions;

  /// Findings, most severe first.
  final List<GoldenDesignFinding> findings;

  /// Design nodes that were matched to rendered nodes.
  final int matchedDesign;

  /// Rendered nodes that were matched to design nodes.
  final int matchedRender;

  /// Design nodes that took part in the structural comparison.
  final int comparedDesign;

  /// Warnings about the comparison setup.
  final List<String> warnings;

  /// Findings that count, by severity.
  int count(GoldenFindingSeverity severity) =>
      findings.where((f) => f.counts && f.severity == severity).length;

  /// Findings accepted as known differences.
  int get knownCount => findings.where((f) => !f.counts).length;

  /// Differing pixels inside regions accepted as known differences.
  double get _acceptedPixels => regions
      .where((r) => r.known != null)
      .fold(0, (sum, r) => sum + r.region.pixels);

  /// Largest region in logical px² that is not accepted.
  double get largestRegion => regions
      .where((r) => r.known == null)
      .fold(
        0,
        (largest, r) =>
            r.region.logicalPixels > largest ? r.region.logicalPixels : largest,
      );

  /// Differing fraction of comparable pixels after regions accepted as known
  /// differences — the ratio the verdict uses — or `null` when undetermined.
  double? get effectiveRatio {
    final diff = pixels.diff;
    if (diff == null) return null;
    final comparable = diff.comparablePixels;
    if (comparable == 0) return 1;
    return (diff.differentPixels - _acceptedPixels) / comparable;
  }

  /// Pixel status after known differences: within budget when both the
  /// differing ratio and the largest region are, ignoring accepted regions.
  String get pixelStatus {
    final ratio = effectiveRatio;
    if (ratio == null) return 'undetermined';
    return ratio <= tolerance.budgetRatio &&
            largestRegion <= tolerance.budgetRegion
        ? 'pass'
        : 'fail';
  }

  /// Reasons behind [verdict], such as `pixels:budget` or `findings:error`.
  List<String> get verdictReasons {
    final reasons = <String>[];
    final status = pixelStatus;
    if (status == 'fail') reasons.add('pixels:budget');
    if (status == 'undetermined') {
      reasons.add('pixels:${pixels.reason ?? 'undetermined'}');
    }
    if (count(GoldenFindingSeverity.error) > 0) reasons.add('findings:error');
    return reasons;
  }

  /// Overall verdict: `fail` when pixels exceed the budget or an error
  /// finding counts, else `undetermined` when the pixels could not be
  /// compared (different sizes, too much masked), else `pass`.
  GoldenDesignVerdict get verdict {
    final status = pixelStatus;
    if (status == 'fail' || count(GoldenFindingSeverity.error) > 0) {
      return GoldenDesignVerdict.fail;
    }
    if (status == 'undetermined') return GoldenDesignVerdict.undetermined;
    return GoldenDesignVerdict.pass;
  }

  /// Findings that count, by category.
  Map<String, int> get byCategory {
    final counts = <String, int>{};
    for (final finding in findings) {
      if (!finding.counts) continue;
      counts[finding.category] = (counts[finding.category] ?? 0) + 1;
    }
    return {
      for (final category in GoldenFindingCategory.values)
        category: ?counts[category],
    };
  }

  /// JSON form written to `analysis/<suite>/<scenario>/<variant>.json`.
  Map<String, Object?> toJson() {
    final diff = pixels.diff;
    return {
      'schema': goldenDesignReportSchema,
      'schemaVersion': goldenDesignReportSchemaVersion,
      'suite': suite,
      'scenario': scenario,
      'fileStem': fileStem,
      'variant': variant,
      'verdict': verdict.name,
      'verdictReasons': verdictReasons,
      'summary': {
        'errors': count(GoldenFindingSeverity.error),
        'warnings': count(GoldenFindingSeverity.warning),
        'infos': count(GoldenFindingSeverity.info),
        'known': knownCount,
        'byCategory': byCategory,
        'designNodes': comparedDesign,
        'matchedDesignNodes': matchedDesign,
        'renderNodes': snapshot.nodes.length,
        'matchedRenderNodes': matchedRender,
      },
      'design': {
        'label': label,
        'sourceUrl': sourceUrl,
        'reference': reference,
        'referenceSha256': referenceSha256,
        'spec': specPath,
        'specSha256': specSha256,
        if (spec != null) ...{
          'source': spec!.source.toJson(),
          'frame': {
            'id': spec!.frame.id,
            'name': spec!.frame.name,
            'width': goldenRound(spec!.frame.rect.width),
            'height': goldenRound(spec!.frame.rect.height),
          },
          'hasStyles': spec!.hasStyles,
          if (spec!.warnings.isNotEmpty) 'warnings': spec!.warnings,
        },
      },
      'render': {
        'image': render,
        'width': goldenRound(snapshot.width),
        'height': goldenRound(snapshot.height),
        'sourceLocations': snapshot.sourceLocations,
      },
      if (designSystem.isNotEmpty) 'designSystem': designSystem,
      'tolerance': {
        ...tolerance.toJson(),
        if (tolerance.changed.isNotEmpty) 'changed': tolerance.changed,
      },
      'masks': [for (final mask in masks) mask.toJson()],
      'pixels': {
        'status': pixelStatus,
        if (pixels.reason != null) 'reason': pixels.reason,
        if (pixels.detail != null) 'detail': pixels.detail,
        if (diff != null) ...{
          'scale': goldenRound(diff.scale, 4),
          'width': diff.width,
          'height': diff.height,
          'differentPixels': diff.differentPixels,
          'antialiasedPixels': diff.antialiasedPixels,
          'comparablePixels': diff.comparablePixels,
          'maskedRatio': goldenRound(diff.maskedRatio, 4),
          'ratio': goldenRound(effectiveRatio!, 6),
          if (_acceptedPixels > 0) ...{
            'rawRatio': goldenRound(diff.ratio, 6),
            'knownPixels': _acceptedPixels.round(),
          },
          'largestRegion': largestRegion,
          'regionCount': diff.regions.length,
          'textBoxes': diff.textBoxCount,
          'transparentPixels': {
            'design': diff.transparentReferencePixels,
            'render': diff.transparentRenderPixels,
          },
          if (diff.notes.isNotEmpty) 'notes': diff.notes,
          'diff': pixels.diffPath,
        },
      },
      'regions': [
        for (final region in regions.take(goldenReportRegionLimit))
          region.toJson(),
      ],
      if (regions.length > goldenReportRegionLimit)
        'regionsTruncated': regions.length - goldenReportRegionLimit,
      'findings': [for (final finding in findings) finding.toJson()],
      if (warnings.isNotEmpty || snapshot.warnings.isNotEmpty)
        'warnings': [...warnings, ...snapshot.warnings],
      'inspection': snapshot.toJson(),
    };
  }

  /// Writes the report below [outputDirectory] at [relativePath].
  void write(String outputDirectory, String relativePath) {
    final file = File(p.join(outputDirectory, relativePath));
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(toJson()),
      flush: true,
    );
  }
}

/// Short form of a report kept in the run manifest, so galleries can list
/// verdicts without opening every report.
@immutable
final class GoldenDesignAnalysisSummary {
  /// Creates a summary.
  const GoldenDesignAnalysisSummary({
    required this.report,
    required this.verdict,
    required this.pixelStatus,
    required this.errors,
    required this.warnings,
    required this.infos,
    required this.known,
    this.byCategory = const {},
    this.ratio,
    this.largestRegion,
    this.regionCount,
    this.diff,
  });

  /// Summary of [source] written at [path].
  factory GoldenDesignAnalysisSummary.of(
    GoldenDesignReport source,
    String path,
  ) {
    final diff = source.pixels.diff;
    return GoldenDesignAnalysisSummary(
      report: path,
      verdict: source.verdict,
      pixelStatus: source.pixelStatus,
      errors: source.count(GoldenFindingSeverity.error),
      warnings: source.count(GoldenFindingSeverity.warning),
      infos: source.count(GoldenFindingSeverity.info),
      known: source.knownCount,
      byCategory: source.byCategory,
      ratio: source.effectiveRatio,
      largestRegion: diff == null ? null : source.largestRegion,
      regionCount: diff?.regions.length,
      diff: source.pixels.diffPath,
    );
  }

  /// Output-relative path of the full report.
  final String report;

  /// Overall verdict.
  final GoldenDesignVerdict verdict;

  /// `pass`, `fail`, or `undetermined`.
  final String pixelStatus;

  /// Error findings that count.
  final int errors;

  /// Warning findings that count.
  final int warnings;

  /// Info findings that count.
  final int infos;

  /// Findings accepted as known differences.
  final int known;

  /// Findings that count, by category.
  final Map<String, int> byCategory;

  /// Differing fraction of comparable pixels after known differences, when
  /// compared — the ratio the verdict uses.
  final double? ratio;

  /// Largest region in logical px², when compared.
  final double? largestRegion;

  /// Number of regions, when compared.
  final int? regionCount;

  /// Output-relative path of the tolerant difference map.
  final String? diff;

  /// JSON form.
  Map<String, Object?> toJson() => {
    'report': report,
    'verdict': verdict.name,
    'pixelStatus': pixelStatus,
    'findings': {
      'error': errors,
      'warning': warnings,
      'info': infos,
      'known': known,
    },
    if (byCategory.isNotEmpty) 'byCategory': byCategory,
    'ratio': ratio == null ? null : goldenRound(ratio!, 6),
    'largestRegion': largestRegion,
    'regionCount': regionCount,
    'diff': diff,
  };
}

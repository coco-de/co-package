import 'package:meta/meta.dart';

import 'design/mask.dart';
import 'design/tolerance.dart';

/// A local PNG exported from a design, associated with one exact variant,
/// optionally with the design's node data for a structural comparison.
///
/// The image is copied into capture output without resizing or modification.
/// [sourceUrl] is optional attribution only; the runner never fetches it.
@immutable
final class GoldenDesignReference {
  /// Describes a design export. Paths are relative to the test package unless
  /// absolute; a URL is not an image path.
  const GoldenDesignReference({
    required this.imagePath,
    this.label = 'Figma',
    this.sourceUrl,
    this.specPath,
    this.nodeId,
    this.masks = const [],
    this.knownDifferences = const [],
    this.tolerance,
  });

  /// Local path to the exported PNG.
  final String imagePath;

  /// Human-readable source label, such as `Figma`.
  final String label;

  /// Optional HTTP(S) link to the original design.
  final String? sourceUrl;

  /// Local path to the design's node data, which enables the structural
  /// comparison (fonts, colors, positions, components). Accepted formats:
  ///
  /// - `co_golden.design_spec` JSON, as written by the `design-spec` Figma
  ///   recipe of the coco-de skills (no API token needed);
  /// - a Figma REST API response of `GET /v1/files/:key/nodes?ids=:id`, or a
  ///   file or node document;
  /// - the output of the `compare-frames` Figma recipe (geometry only).
  final String? specPath;

  /// Frame node id inside [specPath] (`12:345` or `12-345`), required when the
  /// file holds more than one frame.
  final String? nodeId;

  /// Areas not to compare for this variant, each with a reason.
  final List<GoldenDesignMask> masks;

  /// Differences that are known and tracked, for this variant.
  final List<GoldenKnownDifference> knownDifferences;

  /// Tolerances for this variant instead of the matrix's.
  final GoldenDesignTolerance? tolerance;
}

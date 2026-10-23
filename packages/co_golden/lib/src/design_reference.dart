import 'package:meta/meta.dart';

/// A local PNG exported from a design, associated with one exact variant.
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
  });

  /// Local path to the exported PNG.
  final String imagePath;

  /// Human-readable source label, such as `Figma`.
  final String label;

  /// Optional HTTP(S) link to the original design.
  final String? sourceUrl;
}

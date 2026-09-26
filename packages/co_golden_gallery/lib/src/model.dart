import 'package:meta/meta.dart';

/// Outcome of one image, as far as the gallery knows it.
enum GalleryStatus {
  /// The run manifest reports the variant as passed.
  passed,

  /// The run manifest reports the variant as failed.
  failed,

  /// No manifest describes the image (for example a plain baseline PNG).
  unknown,
}

/// One image in the gallery.
@immutable
final class GalleryImage {
  /// Creates an image entry.
  const GalleryImage({
    required this.name,
    required this.path,
    this.device,
    this.theme,
    this.locale,
    this.textScale,
    this.platform,
    this.status = GalleryStatus.unknown,
    this.overflowCount = 0,
    this.errors = const [],
    this.width,
    this.height,
  });

  /// File name without extension, for example `phone__dark__en`.
  final String name;

  /// Path relative to the source root, with `/` separators.
  final String path;

  /// Device name from the manifest.
  final String? device;

  /// Theme name from the manifest.
  final String? theme;

  /// Locale tag from the manifest.
  final String? locale;

  /// Text scale from the manifest.
  final double? textScale;

  /// Target platform from the manifest.
  final String? platform;

  /// Outcome from the manifest.
  final GalleryStatus status;

  /// Number of layout overflow errors reported while rendering.
  final int overflowCount;

  /// Error descriptions from the manifest.
  final List<String> errors;

  /// Pixel width read from the PNG header, if known.
  final int? width;

  /// Pixel height read from the PNG header, if known.
  final int? height;

  /// Column key of the matrix grid: theme, locale, and text scale.
  String get columnKey => [
    theme ?? '',
    locale ?? '',
    if (textScale != null && textScale != 1) 'text ${_scale(textScale!)}x',
  ].where((part) => part.isNotEmpty).join(' · ');

  /// Human label of the variant, or the file name for plain images.
  String get label {
    final parts = [
      device,
      columnKey,
    ].whereType<String>().where((part) => part.isNotEmpty);
    return parts.isEmpty ? name : parts.join(' · ');
  }
}

/// Axis values a co_golden coverage declared, in declaration order.
///
/// Run manifests carry them under `plan.axes`. The gallery orders a
/// scenario's grid by them; without them it falls back to the order in which
/// each value first appears, which sampling and exclusion rules can scramble.
@immutable
final class GalleryAxes {
  /// Creates the axis lists.
  const GalleryAxes({
    this.devices = const [],
    this.themes = const [],
    this.locales = const [],
    this.textScales = const [],
  });

  /// Device names.
  final List<String> devices;

  /// Theme names.
  final List<String> themes;

  /// Locale tags.
  final List<String> locales;

  /// Text scale factors.
  final List<double> textScales;
}

/// A scenario and its images.
@immutable
final class GalleryScenario {
  /// Creates a scenario.
  const GalleryScenario({
    required this.suite,
    required this.name,
    required this.images,
    this.description,
    this.fromManifest = false,
    this.axes,
  });

  /// Suite of the scenario (usually the package).
  final String suite;

  /// Scenario name.
  final String name;

  /// Human description from the manifest.
  final String? description;

  /// Whether the images come from a co_golden run manifest. Such scenarios
  /// are shown as a device × variant grid.
  final bool fromManifest;

  /// Images in manifest (plan) order, or by name for plain images.
  final List<GalleryImage> images;

  /// Axis order declared by the coverage, when the manifest carries it.
  final GalleryAxes? axes;

  /// Number of images whose manifest status is failed.
  int get failedCount =>
      images.where((image) => image.status == GalleryStatus.failed).length;

  /// Stable anchor for links, for example `auth--login`.
  String get anchor => '${_slug(suite)}--${_slug(name)}';
}

/// Everything a gallery shows.
@immutable
final class GalleryCatalog {
  /// Creates a catalog. Scenarios are expected in display order.
  const GalleryCatalog(this.scenarios);

  /// Scenarios grouped by suite, in display order.
  final List<GalleryScenario> scenarios;

  /// Number of images.
  int get imageCount =>
      scenarios.fold(0, (sum, scenario) => sum + scenario.images.length);

  /// Number of failed images.
  int get failedCount =>
      scenarios.fold(0, (sum, scenario) => sum + scenario.failedCount);

  /// Suite names in display order.
  List<String> get suites {
    final seen = <String>{};
    return [
      for (final scenario in scenarios)
        if (seen.add(scenario.suite)) scenario.suite,
    ];
  }
}

String _slug(String value) =>
    value.toLowerCase().replaceAll(RegExp('[^a-z0-9]+'), '-');

String _scale(double value) =>
    value == value.roundToDouble() ? value.toInt().toString() : '$value';

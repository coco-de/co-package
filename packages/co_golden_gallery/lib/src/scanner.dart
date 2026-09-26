import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

import 'model.dart';

/// Schema name of co_golden run manifests.
const String goldenRunSchema = 'co_golden.run';

/// Highest run manifest schema version this gallery reads.
const int supportedGoldenRunSchemaVersion = 1;

const Set<String> _imageExtensions = {'.png', '.jpg', '.jpeg', '.webp'};

/// Thrown when a source tree cannot be turned into a gallery.
final class GallerySourceException implements Exception {
  /// Creates the exception.
  const GallerySourceException(this.message);

  /// What went wrong, including the offending path.
  final String message;

  @override
  String toString() => 'GallerySourceException: $message';
}

/// Result of scanning one or more source roots.
@immutable
final class GalleryScan {
  /// Creates a scan result.
  const GalleryScan({
    required this.catalog,
    required this.files,
    required this.missingImages,
  });

  /// Scenarios and images to show.
  final GalleryCatalog catalog;

  /// Absolute file of every image, keyed by its gallery path.
  final Map<String, String> files;

  /// Gallery paths that a manifest references but that do not exist.
  final List<String> missingImages;
}

/// Scans source roots and builds the gallery catalog.
///
/// A root may contain `runs/**/*.json` co_golden run manifests and an
/// `images/` tree. Images named by a manifest carry its variant metadata and
/// status. Any other image below `images/` is shown as a plain image, grouped
/// by its path: `images/<suite>/<scenario...>/<file>`.
///
/// Throws a [GallerySourceException] for a missing root, an unreadable or
/// foreign JSON file below `runs/`, a newer schema version, two roots that
/// provide the same gallery path, or when no image is found at all.
GalleryScan scanGallerySources(List<Directory> roots) {
  if (roots.isEmpty) {
    throw const GallerySourceException('No input directory was given.');
  }
  final scenarios = <String, _ScenarioBuilder>{};
  final files = <String, String>{};
  final missing = <String>[];

  for (final root in roots) {
    if (!root.existsSync()) {
      throw GallerySourceException('Input directory not found: ${root.path}');
    }
    final claimed = <String>{};
    for (final manifest in _jsonFiles(Directory(p.join(root.path, 'runs')))) {
      _readManifest(root, manifest, scenarios, files, missing, claimed);
    }
    for (final image in _imageFiles(Directory(p.join(root.path, 'images')))) {
      final relative = _posix(p.relative(image.path, from: root.path));
      if (claimed.contains(relative)) {
        continue;
      }
      _claim(files, relative, image.path);
      final segments = p.posix.split(relative).skip(1).toList();
      final suite = segments.length > 1 ? segments.first : 'root';
      final scenario = segments.length > 2
          ? segments.sublist(1, segments.length - 1).join('/')
          : 'images';
      final (width, height) = _pngSize(image);
      scenarios
          .putIfAbsent(
            '$suite\u0000$scenario',
            () => _ScenarioBuilder(suite: suite, name: scenario),
          )
          .images
          .add(
            GalleryImage(
              name: p.basenameWithoutExtension(relative),
              path: relative,
              width: width,
              height: height,
            ),
          );
    }
  }

  final built = [for (final builder in scenarios.values) builder.build()]
    ..sort((a, b) {
      final suite = a.suite.compareTo(b.suite);
      return suite != 0 ? suite : a.name.compareTo(b.name);
    });
  final catalog = GalleryCatalog(built);
  if (catalog.imageCount == 0) {
    throw GallerySourceException(
      'No images found below ${roots.map((root) => root.path).join(', ')}.',
    );
  }
  return GalleryScan(
    catalog: catalog,
    files: files,
    missingImages: List.unmodifiable(missing),
  );
}

void _readManifest(
  Directory root,
  File file,
  Map<String, _ScenarioBuilder> scenarios,
  Map<String, String> files,
  List<String> missing,
  Set<String> claimed,
) {
  final Object? decoded;
  try {
    decoded = jsonDecode(file.readAsStringSync());
  } on FormatException catch (error) {
    throw GallerySourceException('Invalid JSON in ${file.path}: $error');
  }
  if (decoded is! Map<String, Object?> ||
      decoded['schema'] != goldenRunSchema) {
    throw GallerySourceException(
      '${file.path} is not a $goldenRunSchema manifest.',
    );
  }
  final version = decoded['schemaVersion'];
  if (version is! int || version > supportedGoldenRunSchemaVersion) {
    throw GallerySourceException(
      '${file.path} uses schema version $version; this gallery reads up to '
      '$supportedGoldenRunSchemaVersion.',
    );
  }
  final suite = decoded['suite'];
  final scenario = decoded['scenario'];
  final results = decoded['results'];
  if (suite is! String || scenario is! String || results is! List<Object?>) {
    throw GallerySourceException(
      '${file.path} lacks suite, scenario, or results.',
    );
  }
  final description = decoded['description'];
  final builder = scenarios.putIfAbsent(
    '$suite\u0000$scenario',
    () => _ScenarioBuilder(suite: suite, name: scenario),
  );
  builder
    ..fromManifest = true
    ..description ??= description is String ? description : null;

  for (final raw in results) {
    if (raw is! Map<String, Object?>) {
      throw GallerySourceException('${file.path} has a malformed result.');
    }
    final variant = raw['variant'] is Map<String, Object?>
        ? raw['variant']! as Map<String, Object?>
        : const <String, Object?>{};
    final device = variant['device'];
    final image = raw['image'];
    var path = '';
    int? width;
    int? height;
    if (image is String && image.isNotEmpty) {
      path = _posix(image);
      final absolute = p.join(root.path, p.joinAll(p.posix.split(path)));
      claimed.add(path);
      if (File(absolute).existsSync()) {
        _claim(files, path, absolute);
        (width, height) = _pngSize(File(absolute));
      } else {
        missing.add(path);
      }
    }
    builder.images.add(
      GalleryImage(
        name: raw['fileStem'] is String
            ? raw['fileStem']! as String
            : p.basenameWithoutExtension(path),
        path: path,
        device: device is Map<String, Object?>
            ? device['name'] as String?
            : null,
        theme: variant['theme'] as String?,
        locale: variant['locale'] as String?,
        textScale: (variant['textScale'] as num?)?.toDouble(),
        platform: variant['platform'] as String?,
        status: switch (raw['status']) {
          'passed' => GalleryStatus.passed,
          'failed' => GalleryStatus.failed,
          _ => GalleryStatus.unknown,
        },
        overflowCount: (raw['overflowCount'] as num?)?.toInt() ?? 0,
        errors: [
          for (final error in raw['errors'] as List<Object?>? ?? const [])
            '$error',
        ],
        width: width,
        height: height,
      ),
    );
  }
}

void _claim(Map<String, String> files, String galleryPath, String absolute) {
  final existing = files[galleryPath];
  if (existing != null && existing != absolute) {
    throw GallerySourceException(
      'Two inputs provide $galleryPath ($existing and $absolute).',
    );
  }
  files[galleryPath] = absolute;
}

Iterable<File> _jsonFiles(Directory directory) => _files(
  directory,
  (file) => p.extension(file.path).toLowerCase() == '.json',
);

Iterable<File> _imageFiles(Directory directory) => _files(
  directory,
  (file) => _imageExtensions.contains(p.extension(file.path).toLowerCase()),
);

Iterable<File> _files(Directory directory, bool Function(File file) keep) {
  if (!directory.existsSync()) {
    return const [];
  }
  return directory
      .listSync(recursive: true, followLinks: false)
      .whereType<File>()
      .where(keep)
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
}

String _posix(String path) => p.posix.joinAll(p.split(path));

const List<int> _pngSignature = [137, 80, 78, 71, 13, 10, 26, 10];

/// Width and height from a PNG header, or nulls for other files.
(int?, int?) _pngSize(File file) {
  if (p.extension(file.path).toLowerCase() != '.png') {
    return (null, null);
  }
  final RandomAccessFile handle;
  try {
    handle = file.openSync();
  } on FileSystemException {
    return (null, null);
  }
  try {
    final header = handle.readSync(24);
    if (header.length < 24) {
      return (null, null);
    }
    for (var i = 0; i < _pngSignature.length; i++) {
      if (header[i] != _pngSignature[i]) {
        return (null, null);
      }
    }
    final data = ByteData.sublistView(header);
    return (data.getUint32(16), data.getUint32(20));
  } finally {
    handle.closeSync();
  }
}

final class _ScenarioBuilder {
  _ScenarioBuilder({required this.suite, required this.name});

  final String suite;
  final String name;
  final List<GalleryImage> images = [];
  String? description;
  bool fromManifest = false;

  GalleryScenario build() {
    final ordered = <GalleryImage>[...images];
    if (!fromManifest) {
      ordered.sort((a, b) => a.name.compareTo(b.name));
    }
    return GalleryScenario(
      suite: suite,
      name: name,
      description: description,
      fromManifest: fromManifest,
      images: List<GalleryImage>.unmodifiable(ordered),
    );
  }
}

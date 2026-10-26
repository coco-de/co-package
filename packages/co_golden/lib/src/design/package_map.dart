import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// A package from `.dart_tool/package_config.json`.
final class GoldenPackage {
  /// Creates a package entry.
  const GoldenPackage({
    required this.name,
    required this.root,
    required this.libDirectory,
    required this.project,
  });

  /// Package name.
  final String name;

  /// Absolute root directory.
  final String root;

  /// Absolute directory that `package:<name>/` resolves to.
  final String libDirectory;

  /// Whether the package is part of the project: a path dependency or
  /// workspace member (relative root in the package config), as opposed to a
  /// hosted, git, or SDK package.
  final bool project;
}

/// Resolves files to packages, so source locations read like
/// `lib/src/login_page.dart` for the tested package and
/// `package:coui_flutter/src/...` for dependencies.
final class GoldenPackageMap {
  GoldenPackageMap._(this.packages, this.workingDirectory);

  /// Reads the package configuration nearest to [from] (the working directory
  /// of `flutter test`, the tested package, by default). Returns an empty map
  /// when none is found.
  factory GoldenPackageMap.discover([String? from]) {
    final start = p.normalize(p.absolute(from ?? Directory.current.path));
    var directory = start;
    while (true) {
      final config = File(
        p.join(directory, '.dart_tool', 'package_config.json'),
      );
      if (config.existsSync()) {
        try {
          return GoldenPackageMap.parse(
            config.readAsStringSync(),
            configDirectory: config.parent.path,
            workingDirectory: start,
          );
        } on FormatException {
          break;
        }
      }
      final parent = p.dirname(directory);
      if (parent == directory) break;
      directory = parent;
    }
    return GoldenPackageMap._(const [], start);
  }

  /// Parses a package configuration whose file lives in [configDirectory].
  factory GoldenPackageMap.parse(
    String json, {
    required String configDirectory,
    required String workingDirectory,
  }) {
    final decoded = jsonDecode(json);
    if (decoded is! Map<String, Object?> || decoded['packages'] is! List) {
      throw const FormatException('Not a package_config.json.');
    }
    final base = Uri.directory(p.normalize(p.absolute(configDirectory)));
    final packages = <GoldenPackage>[];
    for (final raw in decoded['packages']! as List<Object?>) {
      if (raw is! Map<String, Object?>) continue;
      final name = raw['name'];
      final rootUri = raw['rootUri'];
      if (name is! String || rootUri is! String) continue;
      final parsed = Uri.parse(rootUri);
      final root = base.resolveUri(
        rootUri.endsWith('/') ? parsed : Uri.parse('$rootUri/'),
      );
      final lib = root.resolve((raw['packageUri'] as String?) ?? 'lib/');
      packages.add(
        GoldenPackage(
          name: name,
          root: p.normalize(root.toFilePath()),
          libDirectory: p.normalize(lib.toFilePath()),
          project: !parsed.hasScheme,
        ),
      );
    }
    // Longest roots first, so nested packages win over their parents.
    packages.sort((a, b) => b.root.length.compareTo(a.root.length));
    return GoldenPackageMap._(
      packages,
      p.normalize(p.absolute(workingDirectory)),
    );
  }

  /// Packages, longest root first.
  final List<GoldenPackage> packages;

  /// Directory that relative project paths are relative to.
  final String workingDirectory;

  /// Package named [name].
  GoldenPackage? byName(String name) {
    for (final package in packages) {
      if (package.name == name) return package;
    }
    return null;
  }

  /// Package that contains [path].
  GoldenPackage? packageOf(String path) {
    final file = p.normalize(path);
    for (final package in packages) {
      if (file == package.root || p.isWithin(package.root, file)) {
        return package;
      }
    }
    return null;
  }

  /// Display path of [path]: relative to [workingDirectory] for files inside
  /// it, `package:<name>/<path>` for library files of other packages, and the
  /// normalized path otherwise.
  String display(String path) {
    final file = p.normalize(path);
    if (p.isWithin(workingDirectory, file)) {
      return p.posix.joinAll(p.split(p.relative(file, from: workingDirectory)));
    }
    final package = packageOf(file);
    if (package != null && p.isWithin(package.libDirectory, file)) {
      final relative = p.relative(file, from: package.libDirectory);
      return 'package:${package.name}/${p.posix.joinAll(p.split(relative))}';
    }
    if (package != null && package.project) {
      return p.posix.joinAll(p.split(p.relative(file, from: workingDirectory)));
    }
    return p.posix.joinAll(p.split(file));
  }

  /// Converts a `file:` URI or path from a creation location into a path.
  static String toPath(String location) {
    final uri = Uri.tryParse(location);
    if (uri != null && uri.scheme == 'file') return uri.toFilePath();
    return location;
  }
}

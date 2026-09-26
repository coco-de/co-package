import 'dart:convert';

import 'package:flutter/services.dart';

final RegExp _packagePrefix = RegExp(r'^packages/[^/]+/');

bool _fontsLoaded = false;

/// Loads every font family declared in `FontManifest.json` into the test
/// engine, once per test process.
///
/// Families that come from a package are declared as
/// `packages/<package>/<Family>`. Design systems such as CoUI name the plain
/// family (`Pretendard`), which would never match and would render text with
/// the test fallback font. Such families are therefore also registered under
/// the plain name (see [goldenFontFamilies]).
///
/// Call it from `flutter_test_config.dart` after
/// `TestWidgetsFlutterBinding.ensureInitialized()`. Throws a [StateError]
/// when the manifest cannot be read, so a missing font setup fails loudly.
Future<void> loadGoldenFonts({AssetBundle? bundle}) async {
  if (_fontsLoaded) {
    return;
  }
  final assets = bundle ?? rootBundle;
  final String raw;
  try {
    raw = await assets.loadString('FontManifest.json');
  } on Object catch (error) {
    throw StateError(
      'FontManifest.json could not be read ($error). Initialize the test '
      'binding first and declare the fonts in pubspec.yaml.',
    );
  }
  final families = goldenFontFamilies(jsonDecode(raw));
  final bytes = <String, Future<ByteData>>{};
  for (final MapEntry(key: family, value: files) in families.entries) {
    final loader = FontLoader(family);
    for (final file in files) {
      loader.addFont(bytes.putIfAbsent(file, () => assets.load(file)));
    }
    await loader.load();
  }
  _fontsLoaded = true;
}

/// Font families to register for a decoded `FontManifest.json`, mapped to
/// their asset paths.
///
/// Every declared family is kept. A package family
/// (`packages/<package>/<Family>`) is additionally registered as the plain
/// `<Family>`, unless the manifest declares that plain family itself or
/// another package already claimed the alias. Families without assets are
/// dropped. Throws a [StateError] when [manifest] is not a list.
Map<String, List<String>> goldenFontFamilies(Object? manifest) {
  if (manifest is! List<Object?>) {
    throw StateError('FontManifest.json must contain a list of families.');
  }
  final declared = <String, List<String>>{};
  for (final entry in manifest) {
    if (entry is! Map<String, Object?>) {
      continue;
    }
    final family = entry['family'];
    final fonts = entry['fonts'];
    if (family is! String || fonts is! List<Object?>) {
      continue;
    }
    final files = [
      for (final font in fonts)
        if (font is Map<String, Object?> && font['asset'] is String)
          font['asset']! as String,
    ];
    if (files.isNotEmpty) {
      declared[family] = files;
    }
  }
  final aliases = <String, List<String>>{};
  for (final MapEntry(key: family, value: files) in declared.entries) {
    if (!_packagePrefix.hasMatch(family)) {
      continue;
    }
    final plain = family.replaceFirst(_packagePrefix, '');
    if (!declared.containsKey(plain)) {
      aliases.putIfAbsent(plain, () => files);
    }
  }
  return {...declared, ...aliases};
}

import 'co_l10n_bundle.dart';
import 'de/de_bundle.dart';
import 'en/en_bundle.dart';
import 'fr/fr_bundle.dart';
import 'it/it_bundle.dart';
import 'ja/ja_bundle.dart';
import 'ko/ko_bundle.dart';
import 'pt/pt_bundle.dart';
import 'ru/ru_bundle.dart';
import 'zh/zh_bundle.dart';

/// The domain-text bundles co_faker ships, by language code.
///
/// Korean and English carry the authored text of the domain packs and the
/// dedicated generators. Chinese, Japanese, German, French, Russian, Italian,
/// and Portuguese are registered with empty bundles: localizing a language
/// means filling its own bundle file, and the registry never changes. A
/// language whose bundle is empty has no domain text yet, and its generators
/// read English.
///
/// The bundles are checked against the English one when the registry is first
/// read: a key that English does not define, a list whose length differs from
/// English's, or an empty text makes the first read throw a [StateError] that
/// lists every problem, so a misaligned bundle cannot ship.
///
/// To add a language without changing co_faker, give a `CoFakerLocale` a
/// bundle (`CoFakerLocale.l10n`) instead.
abstract final class CoL10nRegistry {
  /// The bundles by language code, in registration order. The map is
  /// unmodifiable.
  static Map<String, CoL10nBundle> get bundles => _loaded;

  /// The English bundle: the reference whose keys and list lengths every other
  /// bundle follows, and the fallback of every key a language does not have.
  static CoL10nBundle get english => _loaded['en']!;

  /// The bundle of the language [code], such as `ja`, or `null` when none is
  /// registered. A registered but empty bundle is returned too; see
  /// [hasDomainData].
  static CoL10nBundle? bundleFor(String code) => _loaded[code];

  /// Whether the language [code] has authored domain text: it ships a bundle
  /// that is not empty.
  ///
  /// `CoFakerLanguage.domain` is this lookup, so a language turns its domain
  /// data on by filling its bundle.
  static bool hasDomainData(String code) => _loaded[code]?.isNotEmpty ?? false;

  /// Lists what is wrong with [bundle] when it is measured against the
  /// [english] bundle (the registered one by default); an empty list means it
  /// is sound.
  ///
  /// A bundle is sound when every key is one of English's, every key has as
  /// many texts as English's, and no text is empty. A language does not need
  /// every key. Use it to test a bundle that is not registered, such as the
  /// one a custom `CoFakerLocale` carries:
  ///
  /// ```dart
  /// expect(CoL10nRegistry.validate(spanishBundle), isEmpty);
  /// ```
  static List<String> validate(CoL10nBundle bundle, {CoL10nBundle? english}) {
    final reference = english ?? _registered['en']!;
    final language = bundle.language;
    final problems = <String>[];
    for (final entry in bundle.texts.entries) {
      final key = entry.key;
      final texts = entry.value;
      if (texts.isEmpty) {
        problems.add('$language: "$key" has no text');
      }
      for (var i = 0; i < texts.length; i++) {
        if (texts[i].trim().isEmpty) {
          problems.add('$language: "$key" has an empty text at index $i');
        }
      }
      if (identical(bundle, reference)) continue;
      final base = reference.texts[key];
      if (base == null) {
        problems.add('$language: "$key" is not a key of the English bundle');
      } else if (base.length != texts.length) {
        problems.add(
          '$language: "$key" has ${texts.length} texts, English has '
          '${base.length}',
        );
      }
    }
    return problems;
  }
}

/// Every language's bundle. Each language has its own entry, separated by a
/// blank line, and localizing a language edits only its bundle file, never
/// this list.
const Map<String, CoL10nBundle> _registered = <String, CoL10nBundle>{
  'ko': koBundle,

  'en': enBundle,

  'zh': zhBundle,

  'ja': jaBundle,

  'de': deBundle,

  'fr': frBundle,

  'ru': ruBundle,

  'it': itBundle,

  'pt': ptBundle,
};

/// The registered bundles after the load-time check; Dart initializes it on
/// first use.
final Map<String, CoL10nBundle> _loaded = _load();

Map<String, CoL10nBundle> _load() {
  final english = _registered['en'];
  if (english == null || english.isEmpty) {
    throw StateError(
      'The English bundle is the reference of every language: register it '
      'and give it text.',
    );
  }
  final problems = <String>[];
  for (final entry in _registered.entries) {
    if (entry.value.language != entry.key) {
      problems.add(
        '"${entry.key}" holds the bundle of "${entry.value.language}"',
      );
    }
    problems.addAll(CoL10nRegistry.validate(entry.value, english: english));
  }
  if (problems.isNotEmpty) {
    throw StateError(
      'Invalid domain text bundles:\n'
      '${problems.map((problem) => '  - $problem').join('\n')}',
    );
  }
  return Map<String, CoL10nBundle>.unmodifiable(_registered);
}

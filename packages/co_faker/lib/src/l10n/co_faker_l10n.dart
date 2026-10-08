import '../co_faker.dart';
import '../co_faker_languages.dart';
import 'co_l10n_bundle.dart';
import 'co_l10n_registry.dart';

/// Computes the value of a template placeholder, and is called only when the
/// template contains that placeholder.
///
/// A language chooses which placeholders its template uses, and a value that
/// draws from the random stream must not be drawn for a template that skips
/// it. See [CoFakerL10n.format].
typedef CoL10nLazyArg = Object? Function();

/// Authored domain text in the language of a [CoFaker]: `faker.l10n`.
///
/// The domain packs and the dedicated generators read their labels and
/// sentences through it by key (`dental.dentalProcedure`), so a language is a
/// bundle of data and the packs hold no `ko`/`en` pairs. A key is looked up in
/// this order, and the first bundle that has it answers:
///
/// 1. the bundle of the generator's locale, `CoFakerLocale.l10n`, which is how
///    a custom locale injects text;
/// 2. the shipped bundle of the generator's [language], from [CoL10nRegistry];
/// 3. the shipped English bundle.
///
/// A key that none of them has throws a [StateError], so a mistyped key shows
/// up instead of producing empty text. The lookup works key by key: a bundle
/// that translates only some keys serves those and leaves the rest to English.
///
/// ```dart
/// final faker = CoFaker(locale: 'ko', seed: 7);
/// faker.l10n.pick('dental.dentalProcedure'); // 스케일링
/// faker.l10n.format('workplace.sprintName', {'n': 3}); // 스프린트 3
/// ```
class CoFakerL10n {
  /// Reads the text of the language of [faker].
  CoFakerL10n(this.faker);

  /// Source of the locale, the custom locale bundle, and the random stream.
  final CoFaker faker;

  /// The language whose shipped bundle serves this generator before English.
  ///
  /// It is the language of the locale data that the constructor selected, as
  /// `CoFakerLanguages.resolve` reads it, when that language has domain text
  /// (`ko`, `en`, and each language whose bundle has been filled), and `en`
  /// otherwise. A code that the constructor does not know (`ko.UTF-8`)
  /// selects English data and reads English text, while a custom locale
  /// registered under that code reads its own language, as `faker.clinic` and
  /// `faker.saas` do. A language without a bundle, an unsupported or custom
  /// code, and Traditional Chinese (`zh_TW`, `zh_HK`, `zh_MO`, `zh-Hant`),
  /// whose readers are never handed Simplified text, read English. A regional
  /// locale (`ko_KR`) reads the bundle of its language.
  ///
  /// This is the language of the shipped bundle only: a custom locale's bundle
  /// answers first whatever [language] says.
  late final String language = _cachedLanguage();

  /// Every view that `derive` and `localized` make has the locale of its
  /// parent, so the language of a locale and its selected data is worked out
  /// once.
  static final Map<String, String> _languages = <String, String>{};
  static const int _languageCacheSize = 256;

  String _cachedLanguage() {
    final key = '${faker.locale}|${faker.localeData.code}';
    final known = _languages[key];
    if (known != null) return known;
    if (_languages.length >= _languageCacheSize) _languages.clear();
    return _languages[key] = _bundleLanguage();
  }

  String _bundleLanguage() {
    final byLocale = CoFakerLanguages.resolve(faker.locale);
    // Traditional Chinese, an unsupported language, and a custom code never
    // read the text of another language.
    if (!byLocale.supported) return 'en';
    // The locale data the constructor selected names its own language; a
    // custom code that is not a language leaves the locale's.
    final byData = CoFakerLanguages.resolve(faker.localeData.code);
    final code = byData.supported
        ? byData.language.code
        : byLocale.language.code;
    return CoL10nRegistry.hasDomainData(code) ? code : 'en';
  }

  /// The texts of [key]: the choices of a role, or a single text in a list of
  /// one.
  ///
  /// The list is not to be modified. Throws a [StateError] for a key that no
  /// bundle has, and for a custom locale's list whose length differs from
  /// English's.
  List<String> list(String key) {
    final custom = faker.localeData.l10n?.texts[key];
    if (custom != null) {
      _checkAligned(key, custom);
      return custom;
    }
    final shipped = language == 'en'
        ? null
        : CoL10nRegistry.bundleFor(language)?.texts[key];
    final found = shipped ?? CoL10nRegistry.english.texts[key];
    if (found == null) {
      throw StateError(
        'Unknown l10n key "$key": none of the bundles that serve locale '
        '"${faker.locale}" has it (the locale\'s own bundle, the shipped '
        '"$language" bundle, and the English bundle).',
      );
    }
    return found;
  }

  /// One of the texts of [key], picked from the random stream of [faker].
  ///
  /// It draws exactly what `faker.random.pick(list(key))` draws, so the same
  /// seed picks the same entry in every language.
  String pick(String key) => faker.random.pick(list(key));

  /// The text of [key] at [index], cycling when [index] passes the last text;
  /// it draws nothing from the random stream.
  ///
  /// Roles that follow the record index (a coherent row of a class, an
  /// equipment, and a room) use it, so the rows of two languages line up.
  String pickBalanced(String key, int index) =>
      faker.random.pickBalanced(list(key), index);

  /// The single text of [key], which has to be a list of one.
  ///
  /// Throws a [StateError] when [key] offers several texts: use [list],
  /// [pick], or [pickBalanced] for those.
  String text(String key) {
    final texts = list(key);
    if (texts.length != 1) {
      throw StateError(
        'l10n key "$key" has ${texts.length} texts; text reads a key with one '
        'text. Use list, pick, or pickBalanced.',
      );
    }
    return texts.single;
  }

  /// The text of [key] with each `{name}` placeholder replaced by `args[name]`.
  ///
  /// Placeholders are filled in a single pass, so a value that contains
  /// `{other}` stays as it is. A value that is a [CoL10nLazyArg] is called only
  /// when its placeholder occurs, in the order the placeholders occur:
  ///
  /// ```dart
  /// faker.l10n.format('common.maskedName', {
  ///   'lastName': () => faker.person.lastName(),
  ///   'initial': () => faker.person.firstName().substring(0, 1),
  /// });
  /// ```
  ///
  /// The Korean template (`{lastName}○○`) draws a family name and the English
  /// one (`{initial}***`) draws a given name, and neither draws the other.
  /// Throws a [StateError] for a placeholder that [args] does not have or
  /// whose value is `null`, and for any error [text] reports.
  String format(String key, Map<String, Object?> args) {
    return text(key).replaceAllMapped(CoL10nBundle.placeholderPattern, (match) {
      final name = match.group(1)!;
      if (!args.containsKey(name)) {
        throw StateError(
          'l10n text "$key" uses {$name}, but only '
          '${args.keys.map((arg) => '{$arg}').join(', ')} were given.',
        );
      }
      final value = args[name];
      final resolved = value is CoL10nLazyArg ? value() : value;
      if (resolved == null) {
        throw StateError('l10n text "$key": the value of {$name} is null.');
      }
      return '$resolved';
    });
  }

  void _checkAligned(String key, List<String> texts) {
    final reference = CoL10nRegistry.english.texts[key];
    if (reference != null && reference.length != texts.length) {
      throw StateError(
        'The l10n key "$key" of locale "${faker.locale}" has ${texts.length} '
        'texts, English has ${reference.length}: every language keeps the '
        'same number of texts, so that one seed picks the same entry in each.',
      );
    }
  }
}

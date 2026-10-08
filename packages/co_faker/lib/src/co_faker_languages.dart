/// A writing system, used to tell the text of one language in
/// [CoFakerLanguages] from another.
///
/// [han] and [kana] are separate entries because Japanese text is told apart
/// from Chinese text by its kana: both languages use han characters.
enum CoFakerScript {
  /// Latin letters: English, German, French, Italian, Portuguese, Spanish.
  latin,

  /// Han characters: Chinese.
  han,

  /// Hiragana and katakana, usually mixed with han (kanji): Japanese.
  kana,

  /// Cyrillic letters: Russian.
  cyrillic,

  /// Hangul syllables: Korean.
  hangul,
}

/// A language co_faker can generate data for.
///
/// The languages are listed in [CoFakerLanguages].
class CoFakerLanguage {
  /// Creates a language description.
  const CoFakerLanguage({
    required this.code,
    required this.locale,
    required this.script,
  });

  /// Lower-case ISO 639-1 code such as `ja`.
  final String code;

  /// Normalized code of the locale that `CoFaker.forLanguage` builds a
  /// generator with, such as `ja_jp`.
  ///
  /// It is the national locale of the language's main country, so the
  /// generator gets the same data as `CoFaker.forCountry`. A language without
  /// a national locale (`ko`, `es`) keeps its language-only locale.
  final String locale;

  /// The script the language's generated text is written in.
  ///
  /// Japanese is [CoFakerScript.kana]: its text mixes kana with han, and the
  /// kana is what Chinese text lacks.
  final CoFakerScript script;

  /// Whether the domain data is authored in this language: the domain packs,
  /// the dedicated generators, `faker.clinic` and `faker.saas`.
  ///
  /// When `false`, the basic modules (person, address, internet, text, and so
  /// on) still speak the language and the domain data is English.
  ///
  /// The answer comes from one lookup, not from a flag on each language, so
  /// a language that gains domain data turns it on without an edit to the
  /// registry in [CoFakerLanguages].
  bool get domain => _hasDomainData(code);

  @override
  String toString() => 'CoFakerLanguage($code)';
}

/// The outcome of [CoFakerLanguages.resolve]: the language co_faker uses for a
/// language setting, and whether it is the language the setting asked for.
class CoFakerLanguageResolution {
  /// Creates a resolution.
  const CoFakerLanguageResolution({
    required this.language,
    required this.supported,
    this.region,
  });

  /// The language co_faker generates data in: the language the setting names
  /// when it is [supported], otherwise English.
  final CoFakerLanguage language;

  /// Whether co_faker has data for the language the setting names.
  ///
  /// `false` for a language that is not in [CoFakerLanguages.all], for a tag
  /// without a language, and for Traditional Chinese (`zh-Hant`, `zh_TW`,
  /// `zh_HK`, `zh_MO`): its readers are never handed Simplified text. The
  /// resolution falls back to English instead.
  final bool supported;

  /// The region subtag of the setting in upper case, such as `CN` for
  /// `zh-Hans-CN` or `419` for `es-419`, or `null` when it has none.
  ///
  /// It is reported even when [supported] is `false`, but it does not choose
  /// the locale: [locale] follows the language alone, so `en-GB` still
  /// resolves to the United States locale. Use `CoFaker.forCountry` for a
  /// specific country.
  final String? region;

  /// Normalized code of the locale to build a generator with, the locale of
  /// [language].
  String get locale => language.locale;

  @override
  String toString() =>
      'CoFakerLanguageResolution(${language.code}, '
      '${supported ? 'supported' : 'unsupported'})';
}

/// The languages co_faker supports, and the rules that turn an app's language
/// setting into one of them.
///
/// A setting may be a BCP-47 tag (`zh-Hans`, `pt-BR`), a POSIX locale name
/// (`ja_JP.UTF-8`, `en_US@posix`), the output of Flutter's
/// `Locale.toLanguageTag()`, or the tag of a demo locale: [resolve] ignores
/// case, `-` versus `_`, the script subtag, the encoding, and the modifier.
///
/// ```dart
/// final resolved = CoFakerLanguages.resolve('zh-Hans-CN');
/// resolved.language.code; // zh
/// resolved.locale;        // zh_cn
/// resolved.region;        // CN
/// resolved.supported;     // true
///
/// CoFakerLanguages.resolve('zh_TW').supported; // false: English instead
/// ```
///
/// `CoFaker.forLanguage` builds a generator from a setting in one step.
abstract final class CoFakerLanguages {
  /// Korean (`ko`). It has no national locale: its data is the language-only
  /// locale.
  static const CoFakerLanguage korean = CoFakerLanguage(
    code: 'ko',
    locale: 'ko',
    script: CoFakerScript.hangul,
  );

  /// English (`en`), generated with the national locale of the United States.
  static const CoFakerLanguage english = CoFakerLanguage(
    code: 'en',
    locale: 'en_us',
    script: CoFakerScript.latin,
  );

  /// Simplified Chinese (`zh`), generated with the national locale of China.
  /// Traditional Chinese is not supported.
  static const CoFakerLanguage chinese = CoFakerLanguage(
    code: 'zh',
    locale: 'zh_cn',
    script: CoFakerScript.han,
  );

  /// Japanese (`ja`), generated with the national locale of Japan.
  static const CoFakerLanguage japanese = CoFakerLanguage(
    code: 'ja',
    locale: 'ja_jp',
    script: CoFakerScript.kana,
  );

  /// German (`de`), generated with the national locale of Germany.
  static const CoFakerLanguage german = CoFakerLanguage(
    code: 'de',
    locale: 'de_de',
    script: CoFakerScript.latin,
  );

  /// French (`fr`), generated with the national locale of France.
  static const CoFakerLanguage french = CoFakerLanguage(
    code: 'fr',
    locale: 'fr_fr',
    script: CoFakerScript.latin,
  );

  /// Russian (`ru`), generated with the national locale of Russia.
  static const CoFakerLanguage russian = CoFakerLanguage(
    code: 'ru',
    locale: 'ru_ru',
    script: CoFakerScript.cyrillic,
  );

  /// Italian (`it`), generated with the national locale of Italy.
  static const CoFakerLanguage italian = CoFakerLanguage(
    code: 'it',
    locale: 'it_it',
    script: CoFakerScript.latin,
  );

  /// Portuguese (`pt`), generated with the national locale of Brazil.
  static const CoFakerLanguage portuguese = CoFakerLanguage(
    code: 'pt',
    locale: 'pt_br',
    script: CoFakerScript.latin,
  );

  /// Spanish (`es`). It supports the basic modules only: its data is the
  /// language-only locale and its domain data is English.
  static const CoFakerLanguage spanish = CoFakerLanguage(
    code: 'es',
    locale: 'es',
    script: CoFakerScript.latin,
  );

  /// Every supported language: Korean, English, then the languages of the
  /// other large economies, and Spanish.
  static const List<CoFakerLanguage> all = <CoFakerLanguage>[
    korean,
    english,
    chinese,
    japanese,
    german,
    french,
    russian,
    italian,
    portuguese,
    spanish,
  ];

  /// Resolves a language setting [tag] to a supported language.
  ///
  /// Case, `-` versus `_`, the script subtag (`Hans`), the encoding
  /// (`.UTF-8`), and the modifier (`@posix`) are ignored; the language and
  /// the region are taken from what remains. `ko`, `ko_KR`, `ko-KR`,
  /// `zh-Hans`, `zh-Hans-CN`, `pt-BR`, `ja_JP.UTF-8`, `en_US@posix`, and
  /// `ZH_cn` are all read by the same rule.
  ///
  /// A language outside [all], a tag without a language, and Traditional
  /// Chinese resolve to English with [CoFakerLanguageResolution.supported]
  /// `false`. Chinese is Traditional for the script `Hant`, or for the
  /// regions `TW`, `HK`, and `MO` when the script is not `Hans`; the same
  /// rule as the demo locales of co_demo_prefs. `CoFaker(locale: 'zh_TW')`
  /// keeps the Chinese data it has always had; only this method and
  /// `CoFaker.forLanguage` refuse it.
  static CoFakerLanguageResolution resolve(String tag) {
    final subtags = _subtags(tag);
    final code = subtags.isEmpty ? '' : subtags.first;
    final rest = subtags.skip(1).toList();
    final region = _region(rest);
    final language = _byCode(code);
    if (language == null || (code == 'zh' && !_isSimplifiedChinese(rest))) {
      return CoFakerLanguageResolution(
        language: english,
        supported: false,
        region: region,
      );
    }
    return CoFakerLanguageResolution(
      language: language,
      supported: true,
      region: region,
    );
  }

  static CoFakerLanguage? _byCode(String code) {
    for (final language in all) {
      if (language.code == code) return language;
    }
    return null;
  }

  /// Splits [tag] into lower-case subtags. A POSIX name is
  /// `language[_territory][.codeset][@modifier]`; cutting at whichever of `.`
  /// and `@` comes first reads an out-of-order name the same way.
  static List<String> _subtags(String tag) {
    var value = tag.trim();
    final cut = value.indexOf(_codesetOrModifier);
    if (cut >= 0) value = value.substring(0, cut).trim();
    return <String>[
      for (final part in value.toLowerCase().split(_separator))
        if (part.isNotEmpty) part,
    ];
  }

  /// The first subtag of [subtags] (those after the language) that has the
  /// shape of a region: two letters or three digits.
  static String? _region(List<String> subtags) {
    for (final subtag in subtags) {
      // A single character opens an extension (`-u-`) or private use (`-x-`),
      // whose subtags are not regions.
      if (subtag.length == 1) return null;
      if (_regionShape.hasMatch(subtag)) return subtag.toUpperCase();
    }
    return null;
  }

  /// The rule of `DemoLocale.parse` in co_demo_prefs: the script `Hans` is
  /// Simplified whatever the region, otherwise `Hant` and the regions `TW`,
  /// `HK`, and `MO` are Traditional.
  static bool _isSimplifiedChinese(List<String> subtags) {
    if (subtags.contains('hans')) return true;
    return !subtags.any(_traditionalChinese.contains);
  }
}

/// Subtags that mark Traditional Chinese.
const Set<String> _traditionalChinese = <String>{'hant', 'tw', 'hk', 'mo'};

final RegExp _codesetOrModifier = RegExp('[.@]');
final RegExp _separator = RegExp('[-_]');
final RegExp _regionShape = RegExp(r'^(?:[a-z]{2}|[0-9]{3})$');

/// Whether the domain data of the language [code] is authored in that
/// language.
///
/// This is the one place that answers it: [CoFakerLanguage.domain] reads
/// nothing else, and no registry line carries a flag. Today the answer is
/// fixed, because the Korean and English text is the only authored domain
/// text. Story S2 (#59) replaces the body with a computation from the domain
/// bundle registry, where a language has domain data when it has a non-empty
/// bundle, so a language Story turns it on by adding its bundle and never
/// edits this file.
bool _hasDomainData(String code) => code == 'ko' || code == 'en';

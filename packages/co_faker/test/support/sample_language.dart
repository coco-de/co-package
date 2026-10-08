import 'package:co_faker/co_faker.dart';
import 'package:co_faker/src/language_coverage/co_language_texts.dart';

/// An in-memory sample of a localized language, built from the English data by
/// rewriting every text into the writing system of the language.
///
/// The tests of the language coverage gate need a language that is complete,
/// so that they can show the gate accepts it, and then break it one way at a
/// time to show the gate rejects each. The sample is not a translation and is
/// never registered: it is a letter-for-letter rewrite, so a text keeps its
/// length, its placeholders, and its digits, and has the writing system of the
/// language.
class SampleLanguage {
  /// Creates a sample of [code], one of `ja`, `zh`, `ru`, `de`, `fr`, `it`,
  /// and `pt`.
  const SampleLanguage(this.code);

  /// The language code.
  final String code;

  /// The national locale the sample is generated with.
  String get locale => switch (code) {
    'ja' => 'ja_jp',
    'zh' => 'zh_cn',
    'ru' => 'ru_ru',
    'de' => 'de_de',
    'fr' => 'fr_fr',
    'it' => 'it_it',
    'pt' => 'pt_br',
    _ => throw ArgumentError.value(code, 'code', 'no sample'),
  };

  String get _alphabet => switch (code) {
    'ja' => 'アイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホ',
    'zh' => '甲乙丙丁戊己庚辛壬癸子丑寅卯辰巳午未申酉戌亥天地玄黄',
    'ru' => 'абвгдежзиклмнопрстуфхцчшэюяъыь',
    _ => '',
  };

  /// The text of the sample for the English [text].
  ///
  /// The placeholders (`{name}`, `#{variable}`), the digits, and the
  /// punctuation stay as they are. A language that writes in Latin letters
  /// gets accented vowels and a marker that no English text has.
  String text(String english) {
    final out = StringBuffer();
    var hasLetters = false;
    final letter = RegExp(r'\p{L}', unicode: true);
    void rewrite(String piece) {
      for (final rune in piece.runes) {
        final char = String.fromCharCode(rune);
        if (!letter.hasMatch(char)) {
          out.write(char);
          continue;
        }
        hasLetters = true;
        if (_alphabet.isNotEmpty) {
          out.write(
            _alphabet[char.toLowerCase().runes.first % _alphabet.length],
          );
        } else if (rune < 128) {
          out.write(_accent(char));
        } else {
          out.write('x');
        }
      }
    }

    var last = 0;
    for (final match in RegExp(r'#\{[^{}]*\}|\{[^{}]*\}').allMatches(english)) {
      rewrite(english.substring(last, match.start));
      out.write(match.group(0));
      last = match.end;
    }
    rewrite(english.substring(last));
    if (_alphabet.isEmpty && hasLetters) out.write('·${_marker()}');
    return out.toString();
  }

  String _marker() => switch (code) {
    'de' => 'ä',
    'fr' => 'é',
    'it' => 'à',
    _ => 'ã',
  };

  String _accent(String char) {
    const accents = <String, Map<String, String>>{
      'de': {'a': 'ä', 'o': 'ö', 'u': 'ü'},
      'fr': {'a': 'à', 'e': 'é', 'o': 'ô'},
      'it': {'a': 'à', 'e': 'è', 'o': 'ò'},
      'pt': {'a': 'ã', 'e': 'ê', 'o': 'õ'},
    };
    return accents[code]?[char.toLowerCase()] ?? char;
  }

  /// The domain text bundle: every English key, every text rewritten.
  CoL10nBundle bundle({Map<String, List<String>>? allow}) => CoL10nBundle(
    language: code,
    texts: <String, List<String>>{
      for (final entry in CoL10nRegistry.english.texts.entries)
        entry.key: <String>[for (final text in entry.value) this.text(text)],
    },
    allowSameAsEnglish: allow ?? const <String, List<String>>{},
  );

  String _visit(CoTextPoint at, String english) =>
      at.kind == CoTextKind.text ? text(english) : english;

  /// The clinic data: every English text rewritten, with the values of a
  /// language that has no Korean-only value.
  ///
  /// A test breaks the sample with the named arguments: [cardIssuers],
  /// [diagnoses], and [packageNameFormat] replace those fields, [dropTexts]
  /// and [dropOps] leave the texts or the operations texts out, and [rewrite]
  /// changes a text after the sample has written it.
  CoFakerClinicData clinic({
    List<String>? cardIssuers,
    List<CoDiagnosisSpec>? diagnoses,
    String? packageNameFormat,
    bool dropTexts = false,
    bool dropOps = false,
    CoTextVisitor? rewrite,
  }) {
    final mapped = CoLanguageTexts.mapClinic(CoFakerClinicData.english, (
      at,
      english,
    ) {
      final written = _visit(at, english);
      return rewrite == null ? written : rewrite(at, written);
    }, resolveFallbacks: true);
    return CoFakerClinicData(
      specialties: mapped.specialties,
      clinicNamePrefixes: mapped.clinicNamePrefixes,
      staffRoles: mapped.staffRoles,
      visitPurposes: mapped.visitPurposes,
      procedures: mapped.procedures,
      diagnoses: diagnoses ?? mapped.diagnoses,
      drugStems: mapped.drugStems,
      drugForms: mapped.drugForms,
      drugUsages: mapped.drugUsages,
      complaints: mapped.complaints,
      findings: mapped.findings,
      plans: mapped.plans,
      memos: mapped.memos,
      questions: mapped.questions,
      cardIssuers: cardIssuers ?? mapped.cardIssuers,
      labels: mapped.labels,
      packageNameFormat: packageNameFormat ?? mapped.packageNameFormat,
      texts: dropTexts ? null : mapped.texts,
      ops: dropOps ? null : mapped.ops,
      clinicNameFormat: '{prefix}{suffix}',
      koreanValues: CoKoreanValues.none,
      maskedIdFormat: '########',
      addressLineFormat: '{line1}, {city}',
    );
  }

  /// The SaaS data: every English text rewritten, with the values of a
  /// language that has no Korean-only value. [dropOps] leaves the operations
  /// texts out, and [rewrite] changes a text after the sample has written it.
  CoFakerSaasData saas({bool dropOps = false, CoTextVisitor? rewrite}) {
    final mapped = CoLanguageTexts.mapSaas(CoFakerSaasData.english, (
      at,
      english,
    ) {
      final written = _visit(at, english);
      return rewrite == null ? written : rewrite(at, written);
    }, resolveFallbacks: true);
    return CoFakerSaasData(
      plans: mapped.plans,
      messageTemplates: mapped.messageTemplates,
      notices: mapped.notices,
      failureReasons: mapped.failureReasons,
      labels: mapped.labels,
      ops: dropOps ? null : mapped.ops,
      koreanValues: CoKoreanValues.none,
      businessNumberFormat: '##########',
    );
  }

  /// The data of the language, as the gate reads it.
  CoLanguageData data({
    CoL10nBundle? bundle,
    CoFakerClinicData? clinic,
    CoFakerSaasData? saas,
    bool withoutClinic = false,
    bool withoutSaas = false,
  }) => CoLanguageData(
    language: code,
    bundle: bundle ?? this.bundle(),
    clinic: withoutClinic ? null : clinic ?? this.clinic(),
    saas: withoutSaas ? null : saas ?? this.saas(),
  );

  /// A generator factory whose generators carry [data] on top of the national
  /// locale of the language, which is how data that is not registered is run.
  CoCoverageFakerFactory faker(CoLanguageData data) {
    final custom = CoFakerLocale(
      code: locale,
      l10n: data.bundle,
      clinic: data.clinic,
      saas: data.saas,
    ).merge(CoFakerLocales.resolve(locale));
    return (seed, domains) => CoFaker(
      locale: locale,
      seed: seed,
      now: DateTime.utc(2026, 1, 15),
      domains: domains,
      locales: <String, CoFakerLocale>{locale: custom},
    );
  }
}

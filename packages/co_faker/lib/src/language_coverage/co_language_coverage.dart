import '../clinic_data.dart';
import '../co_faker.dart';
import '../co_faker_languages.dart';
import '../co_faker_locales.dart';
import '../korean_values.dart';
import '../l10n/co_l10n_bundle.dart';
import '../l10n/co_l10n_clinic.dart';
import '../l10n/co_l10n_registry.dart';
import '../saas_data.dart';
import 'co_language_generation.dart';
import 'co_language_report.dart';
import 'co_language_text_scan.dart';
import 'co_language_texts.dart';

export 'co_language_generation.dart' show CoCoverageFakerFactory;
export 'co_language_report.dart';

/// The limits of the gate, measured on the Korean and English pair.
///
/// A language is compared with the English text, text by text. In the one
/// translation that already exists, Korean against English, 25 of the 757
/// translatable texts of the bundle (3.3%) read like the English ones: units,
/// acronyms, the name of a programming language, and the Korean plate pattern
/// that English keeps. They are the texts that no translation changes, and the
/// limits leave a margin over that.
class CoCoverageThresholds {
  /// Creates thresholds. The defaults are the ones the gate uses.
  const CoCoverageThresholds({
    this.maxSameAsEnglish = 0.05,
    this.maxSameAsEnglishLatin = 0.10,
    this.maxAllowedSameAsEnglish = 0.10,
    this.minScript = 0.95,
    this.minKana = 0.20,
    this.maxKana = 0.05,
    this.minGenerationScript = 0.90,
  });

  /// The largest share of translatable texts that may equal English in a
  /// language that does not write in Latin letters. An English text without a
  /// letter (`{month}/{day}`) has nothing to translate and does not count,
  /// and neither do the texts that `CoL10nBundle.allowSameAsEnglish` lists.
  ///
  /// Korean against English measures 3.3% before the allowed texts are taken
  /// out, and 0% after.
  final double maxSameAsEnglish;

  /// The same limit for German, French, Italian, and Portuguese, which write
  /// in the letters of English and share many words with it (`Bronze`,
  /// `Gold`, `Standard`, `Menu`, `Hotel`). The everyday vocabulary that
  /// co_faker ships for German, French, and Spanish has 9% to 12% of its
  /// words in the English lists, so a faithful translation may keep a few
  /// percent; the limit is twice the Korean measure.
  final double maxSameAsEnglishLatin;

  /// The largest share of translatable texts that `allowSameAsEnglish` may
  /// cover, in any language. The list is for the units, acronyms, and names
  /// that no translation changes, which are 3.3% of the Korean bundle; a list
  /// that covers a tenth of the texts is a way to leave them in English.
  final double maxAllowedSameAsEnglish;

  /// The smallest share of the texts of a language that must contain its
  /// writing system (kana or han, han, Cyrillic, Hangul). A text that equals
  /// English is left to (c) and not counted here. The Korean bundle, clinic
  /// data, and SaaS data measure 99.1%, before the units, acronyms, and
  /// names of its clinic and SaaS data are listed in `allowSameAsEnglish`,
  /// and 100% after.
  final double minScript;

  /// The smallest share of the texts of Japanese that must contain a kana.
  /// Han characters alone are Chinese: the particles and the endings of
  /// Japanese are kana, so most sentences have one, and what has none is the
  /// short names (`皮膚科`).
  final double minKana;

  /// The largest share of the texts of Chinese that may contain a kana,
  /// which only Japanese writes.
  final double maxKana;

  /// The smallest share of the texts that one generator writes that must
  /// contain the writing system of the language.
  final double minGenerationScript;
}

/// Everything the gate reads of one language.
class CoLanguageData {
  /// Creates the data of [language]. [registered] says whether the language
  /// has an entry in the registries, even an empty one.
  const CoLanguageData({
    required this.language,
    required this.bundle,
    this.clinic,
    this.saas,
    this.registered = true,
  });

  /// Reads the data that co_faker ships for [language]: its domain text
  /// bundle and the clinic and SaaS data of its registry entry.
  ///
  /// [language] is a language setting as `CoFaker.forLanguage` reads it
  /// (`ko`, `KO`, `ko-KR`, `en_US.UTF-8`); a tag of a supported language is
  /// the language itself, and any other code is looked up as it is.
  factory CoLanguageData.registered(String language) {
    final resolved = CoFakerLanguages.resolve(language);
    final code = resolved.supported ? resolved.language.code : language;
    final bundle = CoL10nRegistry.bundleFor(code);
    final entry = CoL10nClinic.entries[code];
    return CoLanguageData(
      language: code,
      bundle: bundle ?? CoL10nBundle(language: code),
      clinic: entry?.clinic,
      saas: entry?.saas,
      registered: bundle != null || entry != null,
    );
  }

  /// The language code.
  final String language;

  /// The domain text bundle.
  final CoL10nBundle bundle;

  /// The clinic data, or `null` while it is a stub.
  final CoFakerClinicData? clinic;

  /// The SaaS data, or `null` while it is a stub.
  final CoFakerSaasData? saas;

  /// Whether the language has an entry in the registries.
  final bool registered;

  /// How far the language is localized.
  CoLanguageLevel get level {
    final filled = <bool>[
      bundle.isNotEmpty,
      clinic != null,
      saas != null,
    ].where((filled) => filled).length;
    if (filled == 3) return CoLanguageLevel.localized;
    if (filled > 0) return CoLanguageLevel.partial;
    return registered ? CoLanguageLevel.planned : CoLanguageLevel.base;
  }
}

/// The language coverage gate: it decides whether a language is finished.
///
/// A language is finished when its texts are written in the language and line
/// up with English, so that one seed picks the same record in every language.
/// [check] reads the data of the language (the domain text bundle, the clinic
/// data, and the SaaS data), compares it with English, and then runs the
/// generators of the language and reads what they write:
///
/// - (a) A language other than Korean has no Hangul.
/// - (b) A language with a writing system of its own (Japanese, Chinese,
///   Russian) writes in it; Japanese has kana, and Chinese none.
/// - (c) No more than a few percent of the texts read like the English ones.
///   A text that is the same on purpose is listed in
///   `CoL10nBundle.allowSameAsEnglish`, a list that is kept short.
/// - (d) Every list has the length of the English list, in the same order,
///   and every map has the keys of the English map, in the same order.
/// - (e) The keys and the data sets that are still stubs are listed.
///
/// Besides, a translation keeps the `{name}` fields of its English text (each
/// as often as English has it, under the English name, in any order), a code
/// is the English one, no text is empty, the pairs of the exam questions hold,
/// and the clinic and SaaS data of a language other than Korean and English
/// set `koreanValues: CoKoreanValues.none`.
///
/// `dart run co_faker:coverage --language ja --strict` is [check] on the
/// shipped data, and a test of the package runs it for every language that
/// has data, so the check of a language pull request is this gate.
///
/// English is the reference and is not compared with itself. The Korean
/// bundle is compared with English, but not the Korean clinic and SaaS data,
/// a Korean-market data set with lists of its own sizes.
class CoLanguageCoverage {
  /// Creates the gate. [reference] is the English data (the shipped one by
  /// default); [seeds] and [records] say how much each generator runs.
  CoLanguageCoverage({
    CoLanguageData? reference,
    this.thresholds = const CoCoverageThresholds(),
    this.seeds = const <int>[7, 436, 20261005],
    this.records = 12,
  }) : reference = reference ?? CoLanguageData.registered('en');

  /// The English data every language is compared with.
  final CoLanguageData reference;

  /// The limits of the checks.
  final CoCoverageThresholds thresholds;

  /// The seeds the generators run with.
  final List<int> seeds;

  /// How many records each role generates for a seed.
  final int records;

  /// Checks the shipped data of [language].
  CoLanguageReport checkRegistered(String language) =>
      check(CoLanguageData.registered(language));

  /// Checks [data].
  ///
  /// The generators run only when the language is [CoLanguageLevel.localized],
  /// because a language that lacks a data set reads English for it. Pass
  /// [faker] to run them on a generator that carries data that is not
  /// registered, or [generate] `false` to read the data only.
  ///
  /// [strictProse] holds every generated text that has words to the writing
  /// system of the language, also when it reads the same in English and
  /// Korean. A language of real data fails it on its loanwords and acronyms,
  /// so it is meant for a sample language whose every text is rewritten, to
  /// find a generator that writes words of its own.
  CoLanguageReport check(
    CoLanguageData data, {
    CoCoverageFakerFactory? faker,
    bool generate = true,
    bool strictProse = false,
  }) {
    final language = data.language;
    final level = data.level;
    final isReference = language == reference.language;
    if (level == CoLanguageLevel.base || level == CoLanguageLevel.planned) {
      return CoLanguageReport(
        language: language,
        level: level,
        reference: isReference,
        issues: <CoLanguageIssue>[
          CoLanguageIssue(
            CoLanguageCheck.planned,
            language,
            level == CoLanguageLevel.base
                ? 'base — the language has no domain data registered; only '
                      'the basic modules speak it'
                : 'planned — no data is written yet: the domain text bundle, '
                      'the clinic data, and the SaaS data are stubs',
          ),
        ],
      );
    }
    final script = _scriptOf(language);
    final issues = <CoLanguageIssue>[];
    final notes = <String>[];
    final stats = <String, num>{};
    if (!isReference) {
      _DataLayer(
        language: language,
        script: script,
        thresholds: thresholds,
        allow: data.bundle.allowSameAsEnglish,
        // Korean is the language of Hangul. English keeps the Korean plate
        // pattern that it has always generated, and it is the reference.
        checkHangul: language != 'ko',
        // The Korean clinic and SaaS data is not a translation of the English
        // lists: it is a data set with lists of its own sizes.
        compareData: language != 'ko',
      ).run(reference, data, issues, notes, stats);
    }
    if (generate && level == CoLanguageLevel.localized) {
      // Without a generator of its own, the gate runs the generators that an
      // app gets, which read the registries: they have to be the data checked.
      if (faker == null) issues.addAll(_wiring(data));
      final result = runGenerationChecks(
        language: language,
        script: script,
        faker: faker ?? _registeredFaker(language),
        seeds: seeds,
        records: records,
        // English keeps the Korean plate pattern and the Korean holiday names
        // that it has always generated, byte for byte.
        checkHangul: language != 'ko' && language != 'en',
        minScript: thresholds.minGenerationScript,
        strictProse: strictProse,
      );
      issues.addAll(result.issues);
      stats['generatedTexts'] = result.texts;
      stats['generatorCalls'] = result.calls;
    }
    return CoLanguageReport(
      language: language,
      level: level,
      issues: issues,
      notes: notes,
      stats: stats,
      reference: isReference,
    );
  }

  /// What is wrong when the generators of an app (`CoFaker.forLanguage`) do not
  /// read [data]: the bundle of another language, or clinic or SaaS data other
  /// than the data that was checked. It happens when [data] is not what the
  /// registries hold, and tells that apart from a text that is not written.
  static List<CoLanguageIssue> _wiring(CoLanguageData data) {
    final language = data.language;
    final probe = CoFaker.forLanguage(
      language,
      seed: 1,
      now: generationClock,
      domains: generationDomains,
    );
    return <CoLanguageIssue>[
      if (probe.l10n.language != language)
        CoLanguageIssue(
          CoLanguageCheck.error,
          'CoFaker.forLanguage',
          'reads the text of "${probe.l10n.language}", not of "$language": '
              'the language is not registered with the data that was checked',
        ),
      if (data.clinic != null && !identical(probe.clinic.data, data.clinic))
        const CoLanguageIssue(
          CoLanguageCheck.error,
          'CoFaker.forLanguage',
          'does not read the clinic data that was checked: the registry of '
              'the language holds other data',
        ),
      if (data.saas != null && !identical(probe.saas.data, data.saas))
        const CoLanguageIssue(
          CoLanguageCheck.error,
          'CoFaker.forLanguage',
          'does not read the SaaS data that was checked: the registry of the '
              'language holds other data',
        ),
    ];
  }

  /// One row for each language of `CoFakerLanguages.all`, computed from the
  /// registries: nothing in it is written by hand.
  static List<CoLanguageSupport> support() => <CoLanguageSupport>[
    for (final language in CoFakerLanguages.all) _supportOf(language),
  ];

  static CoLanguageSupport _supportOf(CoFakerLanguage language) {
    final english = CoL10nRegistry.english;
    final data = CoLanguageData.registered(language.code);
    final locale =
        CoFakerLocales.all[language.locale] ??
        CoFakerLocales.resolve(language.code);
    final national = locale.national;
    final hasNames =
        (locale.firstNames.isNotEmpty || locale.femaleFirstNames.isNotEmpty) &&
        locale.lastNames.isNotEmpty;
    final hasAddresses =
        (national != null && national.localities.isNotEmpty) ||
        (locale.cities.isNotEmpty && locale.streetNames.isNotEmpty);
    return CoLanguageSupport(
      code: language.code,
      name: _names[language.code] ?? language.code,
      script: language.script.name,
      names: hasNames,
      addresses: hasAddresses,
      bundleKeys: <String>[
        for (final key in data.bundle.texts.keys)
          if (english.texts.containsKey(key)) key,
      ].length,
      bundleKeyTotal: english.texts.length,
      clinic: data.clinic != null,
      saas: data.saas != null,
      level: data.level,
    );
  }

  /// The table of [rows] as Markdown.
  static String supportMarkdown(List<CoLanguageSupport> rows) {
    final out = StringBuffer()
      ..writeln(
        '| Language | Script | Names | Addresses | Domain texts | Clinic '
        '| SaaS | Level |',
      )
      ..writeln('| --- | --- | --- | --- | --- | --- | --- | --- |');
    String mark(bool value) => value ? '✓' : '—';
    for (final row in rows) {
      out.writeln(
        '| `${row.code}` ${row.name} | ${row.script} | ${mark(row.names)} '
        '| ${mark(row.addresses)} | ${row.bundleKeys}/${row.bundleKeyTotal} '
        '| ${mark(row.clinic)} | ${mark(row.saas)} | ${row.level.name} |',
      );
    }
    return out.toString().trimRight();
  }

  static CoFakerScript _scriptOf(String language) {
    for (final known in CoFakerLanguages.all) {
      if (known.code == language) return known.script;
    }
    return CoFakerScript.latin;
  }

  static CoCoverageFakerFactory _registeredFaker(String language) {
    return (seed, domains) => CoFaker.forLanguage(
      language,
      seed: seed,
      now: generationClock,
      domains: domains,
    );
  }

  static const Map<String, String> _names = <String, String>{
    'ko': 'Korean',
    'en': 'English',
    'zh': 'Chinese (Simplified)',
    'ja': 'Japanese',
    'de': 'German',
    'fr': 'French',
    'ru': 'Russian',
    'it': 'Italian',
    'pt': 'Portuguese (Brazil)',
    'es': 'Spanish (Spain)',
    'ar': 'Arabic (Saudi Arabia)',
  };
}

/// One text found equal to its English text.
typedef _SameText = ({String slot, String where, String text});

/// The templates that choose among the names a generator offers, and the names
/// it offers: the template of `common.maskedName` says what is masked (English
/// keeps the initial, Korean the surname), and the two daycare templates
/// choose between the first and the second given name that the role draws
/// (English shows the second, Korean the first, and a new language writes
/// `{name1}`). A translation of these keeps the number of fields and takes
/// the names from this list.
const Map<String, Set<String>> _offeredFields = <String, Set<String>>{
  'common.maskedName': <String>{'lastName', 'firstName', 'initial'},
  'daycare.guardianLabel': <String>{'name1', 'name2'},
  'daycare.teacherName': <String>{'name1', 'name2'},
};

/// The patterns whose generator offers fields that the English pattern does
/// not use, and that a language may write besides the English ones: the
/// address line of a patient has the region of the place too (Japanese and
/// Chinese write `{region}{city}{line1}`), and a date may carry its weekday
/// (`{month}月{day}日({weekday})`). The English fields stay required.
const Map<String, Set<String>> _extraFields = <String, Set<String>>{
  'clinic.addressLineFormat': <String>{'region', 'regionCode'},
  'clinic.ops.dateFormat': <String>{'weekday'},
};

/// The data layer of the gate: it compares the texts of a language with the
/// English ones, slot by slot.
class _DataLayer {
  _DataLayer({
    required this.language,
    required this.script,
    required this.thresholds,
    required this.allow,
    required this.checkHangul,
    required this.compareData,
  });

  final String language;
  final CoFakerScript script;
  final CoCoverageThresholds thresholds;
  final Map<String, List<String>> allow;
  final bool checkHangul;
  final bool compareData;

  final List<CoLanguageIssue> _issues = <CoLanguageIssue>[];
  final List<String> _notes = <String>[];

  int _texts = 0;
  int _translatable = 0;
  final List<_SameText> _same = <_SameText>[];
  int _allowedSame = 0;
  int _scriptTotal = 0;
  int _scriptHit = 0;
  int _kana = 0;
  final List<_SameText> _scriptMissing = <_SameText>[];

  final Map<String, int> _slotTranslatable = <String, int>{};
  final Map<String, int> _slotSame = <String, int>{};
  final Map<String, Set<String>> _usedAllowances = <String, Set<String>>{};

  bool get _requiresScript => CoTextScan.requiresScript(script);

  void run(
    CoLanguageData reference,
    CoLanguageData data,
    List<CoLanguageIssue> issues,
    List<String> notes,
    Map<String, num> stats,
  ) {
    final englishBundle = CoLanguageTexts.ofBundle(reference.bundle);
    final englishClinic = CoLanguageTexts.ofClinic(
      reference.clinic ?? CoFakerClinicData.english,
      resolveFallbacks: true,
    );
    final englishSaas = CoLanguageTexts.ofSaas(
      reference.saas ?? CoFakerSaasData.english,
      resolveFallbacks: true,
    );

    _compare(englishBundle, CoLanguageTexts.ofBundle(data.bundle));
    _checkExamPrep(data.bundle.texts);
    stats['bundleKeys'] = <String>[
      for (final key in data.bundle.texts.keys)
        if (reference.bundle.texts.containsKey(key)) key,
    ].length;
    stats['bundleKeyTotal'] = reference.bundle.texts.length;

    final clinic = data.clinic;
    if (clinic == null) {
      _unregistered('clinic', 'the clinic data is a stub: English is used');
    } else if (compareData) {
      _checkKoreanValues('clinic', clinic.koreanValues);
      _compare(
        englishClinic,
        CoLanguageTexts.ofClinic(clinic),
        absent: <String, String>{
          if (clinic.texts == null)
            'clinic.texts.': 'clinic.texts: not written, English is used',
          if (clinic.ops == null)
            'clinic.ops.': 'clinic.ops: not written, English is used',
        },
      );
    } else {
      _scan(CoLanguageTexts.ofClinic(clinic, resolveFallbacks: true));
    }
    final saas = data.saas;
    if (saas == null) {
      _unregistered('saas', 'the SaaS data is a stub: English is used');
    } else if (compareData) {
      _checkKoreanValues('saas', saas.koreanValues);
      _compare(
        englishSaas,
        CoLanguageTexts.ofSaas(saas),
        absent: <String, String>{
          if (saas.ops == null)
            'saas.ops.': 'saas.ops: not written, English is used',
        },
      );
    } else {
      _scan(CoLanguageTexts.ofSaas(saas, resolveFallbacks: true));
    }
    _finish(<String>{
      ...englishBundle.slots.keys,
      ...englishClinic.slots.keys,
      ...englishSaas.slots.keys,
    });

    issues.addAll(_issues);
    notes.addAll(_notes);
    stats['textsChecked'] = _texts;
    stats['translatableTexts'] = _translatable;
    stats['sameAsEnglish'] = _same.length;
    stats['allowedSameAsEnglish'] = _allowedSame;
    if (_translatable > 0) {
      stats['sameAsEnglishRatio'] = _same.length / _translatable;
    }
    if (_scriptTotal > 0) {
      stats['scriptRatio'] = _scriptHit / _scriptTotal;
    }
  }

  void _issue(
    CoLanguageCheck check,
    String where,
    String message, {
    String? value,
  }) => _issues.add(CoLanguageIssue(check, where, message, value: value));

  /// A language other than Korean and English keeps no Korean-only value: its
  /// data says `koreanValues: CoKoreanValues.none`. The default of a data set
  /// that does not say is `legacy`, which keeps the Korean phone numbers,
  /// addresses, and registration numbers that English has always generated,
  /// and they hold no Hangul, so no other check would see them.
  void _checkKoreanValues(String where, CoKoreanValues values) {
    if (values == CoKoreanValues.none) return;
    _issue(
      CoLanguageCheck.invariant,
      '$where.koreanValues',
      'is ${values.name}: the data of a language other than Korean sets '
          'koreanValues: CoKoreanValues.none, or its generators keep writing '
          'Korean phone numbers, addresses, and registration numbers',
    );
  }

  /// The pairs of the exam questions: every explanation contains its correct
  /// choice (whatever its case, so that a choice that opens a sentence may be
  /// written in the case of the sentence), and the four choices of a question
  /// differ. The English and Korean bundles keep both, and the generator
  /// relies on them: it shuffles the choices and the answer key follows the
  /// correct one.
  void _checkExamPrep(Map<String, List<String>> texts) {
    final correct = texts['exam_prep.correctChoice'];
    final explanation = texts['exam_prep.explanation'];
    final wrong = <List<String>?>[
      for (var n = 1; n <= 3; n++) texts['exam_prep.wrongChoice$n'],
    ];
    if (correct == null || explanation == null || wrong.contains(null)) return;
    for (var i = 0; i < correct.length; i++) {
      if (i < explanation.length &&
          !explanation[i].toLowerCase().contains(correct[i].toLowerCase())) {
        _issue(
          CoLanguageCheck.invariant,
          'exam_prep.explanation[$i]',
          'does not contain its correct choice "${correct[i]}" '
              '(exam_prep.correctChoice[$i], case aside): an explanation '
              'names its answer',
          value: explanation[i],
        );
      }
      final choices = <String>[
        correct[i],
        for (final list in wrong)
          if (i < list!.length) list[i],
      ];
      if (choices.toSet().length != choices.length) {
        _issue(
          CoLanguageCheck.invariant,
          'exam_prep.questionStem[$i]',
          'two of the four choices are the same: ${choices.join(' / ')}',
        );
      }
    }
  }

  void _unregistered(String where, String message) =>
      _issue(CoLanguageCheck.unregistered, where, message);

  /// Compares every slot of [got] with the English slot of the same name.
  /// A group of slots that [absent] names (a prefix) is reported once.
  void _compare(
    CoTextTable english,
    CoTextTable got, {
    Map<String, String> absent = const <String, String>{},
  }) {
    for (final message in absent.entries) {
      _unregistered(
        message.key.substring(0, message.key.length - 1),
        message.value,
      );
    }
    for (final slot in english.slots.values) {
      if (slot.kind == CoTextKind.koreanOnly) continue;
      if (absent.keys.any(slot.name.startsWith)) continue;
      final found = got[slot.name];
      if (found == null || found.length == 0) {
        _unregistered(
          slot.name,
          slot.name.startsWith('clinic.') || slot.name.startsWith('saas.')
              ? 'is not written: English is used'
              : 'key is not registered: English is used',
        );
        continue;
      }
      _compareSlot(slot, found);
    }
    for (final slot in got.slots.values) {
      if (english[slot.name] == null) {
        _issue(
          CoLanguageCheck.unknownKey,
          slot.name,
          'is not a key of the English texts',
        );
      }
    }
  }

  void _compareSlot(CoTextSlot english, CoTextSlot got) {
    if (!english.keyed) {
      if (got.length != english.length) {
        _issue(
          CoLanguageCheck.length,
          english.name,
          'has ${got.length} texts, English has ${english.length}: keep the '
          'same number, in the same order',
        );
      }
      final count = got.length < english.length ? got.length : english.length;
      for (var i = 0; i < count; i++) {
        _compareRow(english, got, english.rows[i], got.rows[i]);
      }
      return;
    }
    final missing = <String>[
      for (final row in english.rows)
        if (got.cellsOf(row) == null) row,
    ];
    final unknown = <String>[
      for (final row in got.rows)
        if (english.cellsOf(row) == null) row,
    ];
    if (missing.isNotEmpty || unknown.isNotEmpty) {
      _issue(
        CoLanguageCheck.length,
        english.name,
        <String>[
          if (missing.isNotEmpty)
            'keys that English has are missing: ${missing.join(', ')}',
          if (unknown.isNotEmpty)
            'keys that English does not have: ${unknown.join(', ')}',
        ].join('; '),
      );
    } else if (!_sameOrder(english.rows, got.rows)) {
      // A generator that picks one of the entries takes it by position, so
      // the same seed picks another entry in a language that lists them in
      // another order.
      _issue(
        CoLanguageCheck.length,
        english.name,
        'lists its keys in another order than English (${got.rows.join(', ')}): '
        'a generator picks an entry by position, so keep the English order '
        '(${english.rows.join(', ')})',
      );
    }
    for (final row in english.rows) {
      if (got.cellsOf(row) != null) _compareRow(english, got, row, row);
    }
  }

  static bool _sameOrder(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _compareRow(
    CoTextSlot english,
    CoTextSlot got,
    String englishRow,
    String row,
  ) {
    final reference = english.cellsOf(englishRow)!;
    final cells = got.cellsOf(row)!;
    if (cells.length != reference.length) {
      _issue(
        CoLanguageCheck.length,
        '${english.name}[$row]',
        'has ${cells.length} texts, English has ${reference.length}',
      );
    }
    final count = cells.length < reference.length
        ? cells.length
        : reference.length;
    for (var c = 0; c < count; c++) {
      _compareCell(
        english,
        row,
        c,
        reference.length > 1,
        reference[c],
        cells[c],
      );
    }
  }

  String _where(CoTextSlot slot, String row, int cell, bool multi) =>
      '${slot.name}[$row]${multi ? '[$cell]' : ''}';

  void _compareCell(
    CoTextSlot slot,
    String row,
    int cell,
    bool multi,
    String english,
    String text,
  ) {
    final where = _where(slot, row, cell, multi);
    switch (slot.kind) {
      case CoTextKind.koreanOnly:
        return;
      case CoTextKind.code:
        if (text != english) {
          _issue(
            CoLanguageCheck.code,
            where,
            'is a code that stays "$english" in every language',
            value: text,
          );
        }
        return;
      case CoTextKind.format:
        if (checkHangul && CoTextScan.hasHangul(text)) {
          _issue(
            CoLanguageCheck.hangul,
            where,
            'has Hangul in a pattern: write it for the language',
            value: text,
          );
        }
        _checkPlaceholders(where, slot, english, text);
        return;
      case CoTextKind.text:
        break;
    }
    _texts++;
    if (text.trim().isEmpty) {
      _issue(CoLanguageCheck.empty, where, 'is empty');
      return;
    }
    if (checkHangul && CoTextScan.hasHangul(text)) {
      _issue(
        CoLanguageCheck.hangul,
        where,
        'has Hangul: translate it',
        value: text,
      );
    }
    _checkPlaceholders(where, slot, english, text);
    var allowed = false;
    // A text that differs from the English one by its case, its spaces, or the
    // shape of its quotes reads like it: it was not translated.
    final same = _fold(text) == _fold(english);
    if (CoTextScan.hasLetters(english)) {
      _translatable++;
      _slotTranslatable[slot.name] = (_slotTranslatable[slot.name] ?? 0) + 1;
      if (same) {
        if (_allows(slot.name, text)) {
          allowed = true;
          _allowedSame++;
        } else {
          _same.add((slot: slot.name, where: where, text: text));
          _slotSame[slot.name] = (_slotSame[slot.name] ?? 0) + 1;
        }
      }
    }
    // A text that equals English is reported by (c), once; it is not also a
    // text without the writing system.
    _checkScript(slot.name, where, text, allowed: allowed || same);
  }

  static final RegExp _blanks = RegExp(r'\s+');

  /// [text] as the comparison with English reads it: one space for any run of
  /// white space (a no-break space too), straight quotes, and no case.
  static String _fold(String text) => text
      .trim()
      .replaceAll(_blanks, ' ')
      .replaceAll('’', "'")
      .replaceAll('‘', "'")
      .replaceAll('“', '"')
      .replaceAll('”', '"')
      .toLowerCase();

  /// A translation keeps the `{name}` fields of its English text, each as often
  /// as English has it and under the English name, in any order: a generator
  /// fills the English names only, so a field that is renamed stays in the
  /// output as it is, and one that is dropped loses the value. A pattern
  /// (`{kind} #{number}`) reads a field after a number sign too; in a text, a
  /// `#{variable}` is the marker of a notification template, which a language
  /// may rename but keeps as many times as English has it.
  void _checkPlaceholders(
    String where,
    CoTextSlot slot,
    String english,
    String text,
  ) {
    final inPattern = slot.kind == CoTextKind.format;
    // A template that chooses among the names a generator offers counts the
    // offered names as one: English keeps the initial, Korean the surname.
    final choice = _offeredFields[slot.name];
    List<String> names(String source) => <String>[
      for (final name in CoTextScan.fieldNames(source, templates: inPattern))
        choice != null && choice.contains(name) ? choice.join('|') : name,
    ];
    final extra = _extraFields[slot.name];
    final wanted = names(english);
    final got = names(text);
    final lost = _without(wanted, got);
    final unknown = <String>[
      for (final name in _without(got, wanted))
        if (extra == null || !extra.contains(name)) name,
    ];
    if (lost.isNotEmpty || unknown.isNotEmpty) {
      String fields(List<String> names) =>
          names.map((name) => '{$name}').join(', ');
      _issue(
        CoLanguageCheck.placeholder,
        where,
        <String>[
          if (lost.isNotEmpty) 'lacks ${fields(lost)}, which English has',
          if (unknown.isNotEmpty)
            'has ${fields(unknown)}, which English does not have (a '
                'generator fills only the English names)',
        ].join('; '),
        value: text,
      );
    }
    if (inPattern) return;
    final markers = CoTextScan.templateVariables(english);
    final found = CoTextScan.templateVariables(text);
    if (found != markers) {
      _issue(
        CoLanguageCheck.placeholder,
        where,
        'has $found #{variable} markers, the English template has $markers',
        value: text,
      );
    }
  }

  /// The names of [names] that [other] does not have as often, in order.
  static List<String> _without(List<String> names, List<String> other) {
    final left = <String>[...other];
    final result = <String>[];
    for (final name in names) {
      if (!left.remove(name)) result.add(name);
    }
    return result;
  }

  void _checkScript(
    String slot,
    String where,
    String text, {
    required bool allowed,
  }) {
    if (!_requiresScript || allowed || !CoTextScan.hasLetters(text)) return;
    _scriptTotal++;
    if (CoTextScan.hasScript(text, script)) {
      _scriptHit++;
    } else {
      _scriptMissing.add((slot: slot, where: where, text: text));
    }
    if (CoTextScan.hasKana(text)) _kana++;
  }

  /// Whether `allowSameAsEnglish` lists [text] for [slot], and which entry
  /// allowed it, so that an entry that is never used can be reported.
  bool _allows(String slot, String text) {
    final values = allow[slot];
    if (values == null) return false;
    var allowed = false;
    if (values.contains(text)) {
      (_usedAllowances[slot] ??= <String>{}).add(text);
      allowed = true;
    }
    if (values.contains('*')) {
      (_usedAllowances[slot] ??= <String>{}).add('*');
      allowed = true;
    }
    return allowed;
  }

  /// Reads the texts of a data set that is not compared with English (the
  /// Korean clinic and SaaS data) for its writing system only.
  void _scan(CoTextTable table) {
    for (final slot in table.slots.values) {
      if (slot.kind != CoTextKind.text) continue;
      for (final row in slot.rows) {
        final cells = slot.cellsOf(row)!;
        for (var c = 0; c < cells.length; c++) {
          _texts++;
          final text = cells[c];
          // An allowance is spent by a text that the check would count against
          // the language, and by no other.
          final lacks =
              _requiresScript &&
              CoTextScan.hasLetters(text) &&
              !CoTextScan.hasScript(text, script);
          _checkScript(
            slot.name,
            _where(slot, row, c, cells.length > 1),
            text,
            allowed: lacks && _allows(slot.name, text),
          );
        }
      }
    }
  }

  /// The checks that need every text counted: the share of texts that read
  /// like English, the share that has the writing system, the slots that are
  /// English throughout, and the allowances.
  void _finish(Set<String> knownSlots) {
    final limit = script == CoFakerScript.latin
        ? thresholds.maxSameAsEnglishLatin
        : thresholds.maxSameAsEnglish;
    if (_translatable > 0 && _same.length / _translatable > limit) {
      _issue(
        CoLanguageCheck.sameAsEnglish,
        'all texts',
        '${_same.length} of $_translatable translatable texts '
            '(${_percent(_same.length / _translatable)}) equal the English ones; '
            'the limit is ${_percent(limit)}. Translate them, or list the ones '
            'that are the same on purpose in allowSameAsEnglish',
      );
      for (final same in _same) {
        _issue(
          CoLanguageCheck.sameAsEnglish,
          same.where,
          "equals English; to allow it: '${same.slot}': "
          "['${_quote(same.text)}']",
        );
      }
    } else if (_same.isNotEmpty) {
      _notes.add(
        '${_same.length} of $_translatable translatable texts equal English '
        '(${_percent(_same.length / _translatable)}, within the limit of '
        '${_percent(limit)}): ${_samples(_same)}',
      );
    }
    final allowedShare = _translatable == 0
        ? 0.0
        : _allowedSame / _translatable;
    if (allowedShare > thresholds.maxAllowedSameAsEnglish) {
      _issue(
        CoLanguageCheck.allowance,
        'allowSameAsEnglish',
        'covers $_allowedSame of $_translatable translatable texts '
            '(${_percent(allowedShare)}); at most '
            '${_percent(thresholds.maxAllowedSameAsEnglish)} may be: the list '
            'is for the units, acronyms, and names that no translation '
            'changes, and a longer one leaves texts in English',
      );
    }
    for (final entry in _slotSame.entries) {
      final translatable = _slotTranslatable[entry.key] ?? 0;
      if (translatable > 0 && entry.value == translatable) {
        _issue(
          CoLanguageCheck.sameAsEnglish,
          entry.key,
          'every text of the slot equals English: translate them, or allow '
          "the slot with '${entry.key}': ['*'] if all of them are units, "
          'acronyms, or names',
        );
      }
    }
    if (_scriptTotal > 0 && _scriptHit / _scriptTotal < thresholds.minScript) {
      _issue(
        CoLanguageCheck.script,
        'all texts',
        '${_scriptTotal - _scriptHit} of $_scriptTotal texts '
            '(${_percent(1 - _scriptHit / _scriptTotal)}) have no '
            '${_scriptName(script)}; at least ${_percent(thresholds.minScript)} '
            'must',
      );
      for (final missing in _scriptMissing) {
        _issue(
          CoLanguageCheck.script,
          missing.where,
          'has no ${_scriptName(script)}',
          value: missing.text,
        );
      }
    } else if (_scriptMissing.isNotEmpty) {
      _notes.add(
        '${_scriptMissing.length} of $_scriptTotal texts have no '
        '${_scriptName(script)} (within the limit): ${_samples(_scriptMissing)}',
      );
    }
    _checkKana();
    _checkAllowances(knownSlots);
  }

  /// Japanese and Chinese share the han characters, and only Japanese writes
  /// kana: han characters alone are not Japanese, and a kana is not Chinese.
  void _checkKana() {
    if (_scriptTotal == 0) return;
    final share = _kana / _scriptTotal;
    if (script == CoFakerScript.kana && share < thresholds.minKana) {
      _issue(
        CoLanguageCheck.script,
        'all texts',
        'only $_kana of $_scriptTotal texts (${_percent(share)}) have a kana: '
            'Japanese has one in most sentences (at least '
            '${_percent(thresholds.minKana)} of the texts do), and han '
            'characters alone are Chinese',
      );
    } else if (script == CoFakerScript.han && share > thresholds.maxKana) {
      _issue(
        CoLanguageCheck.script,
        'all texts',
        '$_kana of $_scriptTotal texts (${_percent(share)}) have a kana, '
            'which only Japanese writes (at most '
            '${_percent(thresholds.maxKana)} may)',
      );
    }
  }

  void _checkAllowances(Set<String> knownSlots) {
    for (final entry in allow.entries) {
      if (!knownSlots.contains(entry.key)) {
        _issue(
          CoLanguageCheck.allowance,
          entry.key,
          'is not a slot of the English texts: check the name',
        );
        continue;
      }
      final used = _usedAllowances[entry.key] ?? const <String>{};
      for (final value in entry.value) {
        if (value.isEmpty) {
          _issue(CoLanguageCheck.allowance, entry.key, 'lists an empty text');
        } else if (!used.contains(value)) {
          _issue(
            CoLanguageCheck.allowance,
            entry.key,
            value == '*'
                ? 'allows every text of the slot, but no text needs it: '
                      'remove it'
                : 'allows a text that no text of the slot needs any more: '
                      'remove it',
            value: value == '*' ? null : value,
          );
        }
      }
    }
  }

  static String _samples(List<_SameText> texts) =>
      '${texts.take(8).map((text) => '${text.where} “${CoTextScan.excerpt(text.text, length: 24)}”').join(', ')}'
      '${texts.length > 8 ? ', …' : ''}';

  static String _quote(String text) =>
      text.replaceAll(r'\', r'\\').replaceAll("'", r"\'");

  static String _percent(double ratio) =>
      '${(ratio * 100).toStringAsFixed(1)}%';

  static String _scriptName(CoFakerScript script) => switch (script) {
    CoFakerScript.han => 'han character',
    CoFakerScript.kana => 'kana or han character',
    CoFakerScript.cyrillic => 'Cyrillic letter',
    CoFakerScript.hangul => 'Hangul',
    CoFakerScript.latin => 'Latin letter',
    CoFakerScript.arabic => 'Arabic letter',
  };
}

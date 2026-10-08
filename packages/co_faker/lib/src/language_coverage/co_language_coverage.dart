import '../clinic_data.dart';
import '../co_faker.dart';
import '../co_faker_languages.dart';
import '../co_faker_locales.dart';
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
    this.minScript = 0.95,
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

  /// The smallest share of the texts of a language that must contain its
  /// writing system (kana or han, han, Cyrillic, Hangul). The Korean bundle,
  /// clinic data, and SaaS data measure 97.7% before the units and acronyms
  /// that equal English are taken out, and 100% after.
  final double minScript;

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
  factory CoLanguageData.registered(String language) {
    final bundle = CoL10nRegistry.bundleFor(language);
    final entry = CoL10nClinic.entries[language];
    return CoLanguageData(
      language: language,
      bundle: bundle ?? CoL10nBundle(language: language),
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
///   Russian) writes in it.
/// - (c) No more than a few percent of the texts read like the English ones.
///   A text that is the same on purpose is listed in
///   `CoL10nBundle.allowSameAsEnglish`.
/// - (d) Every list has the length of the English list, in the same order.
/// - (e) The keys and the data sets that are still stubs are listed.
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
    'es': 'Spanish',
  };
}

/// One text found equal to its English text.
typedef _SameText = ({String slot, String where, String text});

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
    stats['bundleKeys'] = <String>[
      for (final key in data.bundle.texts.keys)
        if (reference.bundle.texts.containsKey(key)) key,
    ].length;
    stats['bundleKeyTotal'] = reference.bundle.texts.length;

    final clinic = data.clinic;
    if (clinic == null) {
      _unregistered('clinic', 'the clinic data is a stub: English is used');
    } else if (compareData) {
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
    }
    for (final row in english.rows) {
      if (got.cellsOf(row) != null) _compareRow(english, got, row, row);
    }
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
    _checkPlaceholders(where, english, text);
    var allowed = false;
    if (CoTextScan.hasLetters(english)) {
      _translatable++;
      _slotTranslatable[slot.name] = (_slotTranslatable[slot.name] ?? 0) + 1;
      if (text == english) {
        if (_allows(slot.name, text)) {
          allowed = true;
          _allowedSame++;
        } else {
          _same.add((slot: slot.name, where: where, text: text));
          _slotSame[slot.name] = (_slotSame[slot.name] ?? 0) + 1;
        }
      }
    }
    _checkScript(slot.name, where, text, allowed: allowed);
  }

  void _checkPlaceholders(String where, String english, String text) {
    final expected = CoTextScan.placeholders(english);
    if (expected.isNotEmpty && CoTextScan.placeholders(text).isEmpty) {
      _issue(
        CoLanguageCheck.placeholder,
        where,
        'has no placeholder, English has '
        '${expected.map((name) => '{$name}').join(', ')}',
        value: text,
      );
    }
    if (CoTextScan.templateVariables(english) > 0 &&
        CoTextScan.templateVariables(text) == 0) {
      _issue(
        CoLanguageCheck.placeholder,
        where,
        'has no #{variable}, the English template has some',
        value: text,
      );
    }
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
          _checkScript(
            slot.name,
            _where(slot, row, c, cells.length > 1),
            cells[c],
            allowed: _allows(slot.name, cells[c]),
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
          'equals the English text; if it is a loanword, an acronym, or a '
          "name, allow it: '${same.slot}': ['${_quote(same.text)}']",
          value: same.text,
        );
      }
    } else if (_same.isNotEmpty) {
      _notes.add(
        '${_same.length} of $_translatable translatable texts equal English '
        '(${_percent(_same.length / _translatable)}, within the limit of '
        '${_percent(limit)}): ${_samples(_same)}',
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
    _checkAllowances(knownSlots);
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
  };
}

import '../co_faker.dart';
import '../co_faker_languages.dart';
import '../domain.dart';
import '../domains.dart';
import 'co_language_calls.dart';
import 'co_language_report.dart';
import 'co_language_text_scan.dart';

/// Builds the generator that the generation checks run, one for each seed,
/// with the domain packs that the check needs.
///
/// The default builds `CoFaker.forLanguage(language, seed: seed, domains:
/// domains)`, which is what an app that follows its language setting gets. A
/// test that checks data that is not registered passes a factory that builds a
/// generator carrying that data.
typedef CoCoverageFakerFactory =
    CoFaker Function(int seed, List<CoFakerDomain> domains);

/// The clock every generation check runs with, so a run is repeatable.
final DateTime generationClock = DateTime.utc(2026, 1, 15);

/// The domain packs that the generation checks run.
const List<CoFakerDomain> generationDomains = CoFakerDomains.all;

/// What the generation checks found and how much they ran.
typedef CoGenerationResult = ({
  List<CoLanguageIssue> issues,
  int texts,
  int calls,
});

/// The packs that no language but Korean can satisfy, with why: their roles
/// ask for Korean values by name (a Korean mobile number, a resident
/// registration number, a road-name address).
const Map<String, String> koreanOnlyPacks = <String, String>{
  'korea':
      'The roles of the korea pack ask for Korean values by name: Korean '
      'phone numbers, resident and business registration numbers, and '
      'road-name addresses.',
};

/// Runs the generators of a language and reads what they write.
///
/// Every role of every built-in domain pack, every registered entity, and
/// every call of [allLanguageCalls] (the dedicated generators, `faker.clinic`,
/// and `faker.saas`) runs with each of [seeds], and the roles with [records]
/// records each. Every text that comes out is read for:
///
/// - Hangul, when [checkHangul] is set (a call that is independent of the
///   locale by design, `CoLanguageCall.hangulReason`, is left out);
/// - a placeholder that no generator filled in (`{n}`);
/// - the writing system of [script], for the roles and the calls that return
///   plain text, when the language has one. A text that is the same in
///   English and Korean carries no language, and neither does a single token
///   such as an email address or a masked name, so only the texts that differ
///   between English and Korean and have words are held to [minScript]. With
///   [strictProse] every text that has words is held to it, which a sample
///   language whose every text is rewritten passes only when no generator
///   writes words of its own;
/// - an exception.
CoGenerationResult runGenerationChecks({
  required String language,
  required CoFakerScript script,
  required CoCoverageFakerFactory faker,
  required List<int> seeds,
  required int records,
  required bool checkHangul,
  required double minScript,
  bool strictProse = false,
}) {
  final run = _Generation(
    language: language,
    script: script,
    faker: faker,
    seeds: seeds,
    records: records,
    checkHangul: checkHangul,
    minScript: minScript,
    strictProse: strictProse,
  );
  run.roles();
  run.entities();
  run.calls();
  return run.result();
}

CoFaker _reference(String language, int seed) => CoFaker.forLanguage(
  language,
  seed: seed,
  now: generationClock,
  domains: generationDomains,
);

/// The packs a check runs entities with: without the packs that ask for
/// Korean values, whose roles a field name would otherwise infer.
List<CoFakerDomain> _entityDomains(String language) => <CoFakerDomain>[
  for (final pack in generationDomains)
    if (language == 'ko' || !koreanOnlyPacks.containsKey(pack.name)) pack,
];

/// One finding, counted every time it recurs.
class _Finding {
  _Finding(this.check, this.where, this.message, this.value);

  final CoLanguageCheck check;
  final String where;
  final String message;
  final String? value;
  int count = 1;
}

class _Generation {
  _Generation({
    required this.language,
    required this.script,
    required this.faker,
    required this.seeds,
    required this.records,
    required this.checkHangul,
    required this.minScript,
    required this.strictProse,
  });

  final String language;
  final CoFakerScript script;
  final CoCoverageFakerFactory faker;
  final List<int> seeds;
  final int records;
  final bool checkHangul;
  final double minScript;
  final bool strictProse;

  final Map<String, _Finding> _findings = <String, _Finding>{};
  final Map<String, ({int total, int hit, String? miss})> _scriptCounts =
      <String, ({int total, int hit, String? miss})>{};
  int _texts = 0;
  int _calls = 0;

  bool get _wantsScript =>
      CoTextScan.requiresScript(script) && language != 'en';

  CoGenerationResult result() => (
    issues: <CoLanguageIssue>[
      for (final finding in _findings.values)
        CoLanguageIssue(
          finding.check,
          finding.where,
          finding.count > 1
              ? '${finding.message} (${finding.count} times)'
              : finding.message,
          value: finding.value,
        ),
      ..._scriptIssues(),
    ],
    texts: _texts,
    calls: _calls,
  );

  void _report(
    CoLanguageCheck check,
    String where,
    String message, {
    String? value,
  }) {
    final key = '${check.name}|$where|$message';
    final known = _findings[key];
    if (known != null) {
      known.count++;
    } else {
      _findings[key] = _Finding(check, where, message, value);
    }
  }

  /// Reads one generated text for Hangul and for an unfilled placeholder.
  void _scan(
    String where,
    String text, {
    String? hangulReason,
    bool templates = false,
  }) {
    _texts++;
    if (checkHangul && hangulReason == null) {
      final hangul = _firstHangul(text);
      if (hangul != null) {
        _report(
          CoLanguageCheck.hangul,
          where,
          'the generated text has Hangul: a text is not translated, or a '
          'generator writes Korean whatever the language',
          value: hangul,
        );
      }
    }
    final unfilled = CoTextScan.unfilledPlaceholder(text, templates: templates);
    if (unfilled != null) {
      final at = text.indexOf(unfilled);
      _report(
        CoLanguageCheck.placeholder,
        where,
        'the generated text still has the placeholder $unfilled: the '
        'template uses a name that the generator does not fill',
        value: CoTextScan.around(text, at < 0 ? 0 : at),
      );
    }
  }

  static String? _firstHangul(String text) {
    final at = CoTextScan.firstHangul(text);
    return at < 0 ? null : CoTextScan.around(text, at);
  }

  /// The strings of [value]: every string, flattened.
  static String _describe(Object? value) {
    return switch (value) {
      null => '',
      final String text => text,
      num() || bool() || DateTime() => '',
      final Map<Object?, Object?> map => <String>[
        for (final entry in map.entries) ...<String>[
          _describe(entry.key),
          _describe(entry.value),
        ],
      ].join('\n'),
      final Iterable<Object?> list => list.map(_describe).join('\n'),
      _ => '$value',
    };
  }

  /// The texts of [value] when it is plain text: a string, or a list of
  /// them. Anything else (a record with codes and labels) is read leaf by
  /// leaf: see [_leaves].
  static List<String>? _plainTexts(Object? value) {
    if (value is String) return <String>[value];
    if (value is Iterable<Object?> && value.every((item) => item is String)) {
      return <String>[for (final item in value) item! as String];
    }
    return null;
  }

  static final RegExp _printedField = RegExp(r'(^|[(\[{]|, )[A-Za-z_]\w*: ');
  static final RegExp _printedList = RegExp(r'^\s*\[(.*)\][\s,)}]*$');
  static final RegExp _leafEdges = RegExp(r'^[\s(\[{]+|[\s,)\]}]+$');
  static final RegExp _space = RegExp(r'\s');
  static final RegExp _word = RegExp(r'\p{L}{2,}', unicode: true);

  /// The strings that [value] holds, one for each leaf, in order: the strings
  /// of lists and maps, and the fields of a record. A record cannot be taken
  /// apart in any other way than by how it prints (`(code: DUP, label: ...)`),
  /// so its fields are read from there.
  static List<String> _leaves(Object? value) {
    return switch (value) {
      null => const <String>[],
      final String text => <String>[text],
      num() || bool() || DateTime() || Enum() => const <String>[],
      final Map<Object?, Object?> map => <String>[
        for (final entry in map.entries) ...<String>[
          ..._leaves(entry.key),
          ..._leaves(entry.value),
        ],
      ],
      final Iterable<Object?> list => <String>[
        for (final item in list) ..._leaves(item),
      ],
      _ => <String>[
        for (final part in '$value'.replaceAll(_printedField, '\n').split('\n'))
          // A list prints as `[a, b]`: its items are leaves of their own.
          for (final leaf
              in _printedList.firstMatch(part)?.group(1)?.split(', ') ??
                  <String>[part])
            if (leaf.replaceAll(_leafEdges, '').isNotEmpty)
              leaf.replaceAll(_leafEdges, ''),
      ],
    };
  }

  /// A text whose writing system the gate reads: it has words, and it is not
  /// a single ASCII token such as an email address, a code, or a handle, nor a
  /// masked name (`K*** L.`), whose letters are random initials. An ASCII text
  /// of several words needs a word of two letters, so that a time stamp
  /// (`2026-01-15 09:00:00.000Z`) is not read as prose.
  static bool _isProse(String text) {
    if (!CoTextScan.hasLetters(text) || text.contains('***')) return false;
    final ascii = text.codeUnits.every((unit) => unit < 128);
    return !ascii || (_space.hasMatch(text) && _word.hasMatch(text));
  }

  /// Counts how many of the prose texts of [texts] have the writing system of
  /// the language. A text that has it is a hit. A text that lacks it is a
  /// miss, unless it reads the same in English and Korean, which makes it a
  /// code or a literal that carries no language: [independence] answers
  /// whether a text does, and is asked only when a text lacks the writing
  /// system (so that English and Korean are generated only when needed), and
  /// not at all with [strictProse]. It answers `null` when it cannot judge.
  /// The verdict comes once every seed has run: see [_scriptIssues].
  void _tally(
    String where,
    List<String> texts,
    bool Function(String text, int index)? Function() independence,
  ) {
    if (!_wantsScript) return;
    var total = 0;
    var hit = 0;
    final lacking = <int>[];
    for (var i = 0; i < texts.length; i++) {
      final text = texts[i];
      if (!_isProse(text)) continue;
      if (CoTextScan.hasScript(text, script)) {
        total++;
        hit++;
      } else {
        lacking.add(i);
      }
    }
    String? miss;
    if (lacking.isNotEmpty) {
      final independent = strictProse ? null : independence();
      if (!strictProse && independent == null) return;
      for (final i in lacking) {
        if (independent != null && independent(texts[i], i)) continue;
        total++;
        miss ??= texts[i];
      }
    }
    final known = _scriptCounts[where];
    _scriptCounts[where] = (
      total: (known?.total ?? 0) + total,
      hit: (known?.hit ?? 0) + hit,
      miss: known?.miss ?? miss,
    );
  }

  /// [_tally] for texts that stand in a list: one reads the same in English
  /// and Korean when the texts at its place there are equal.
  void _checkScript(
    String where,
    List<String> texts,
    List<String>? Function() english,
    List<String>? Function() korean,
  ) => _tally(where, texts, () {
    final en = english();
    // The Korean generator is the one that runs: nothing to generate twice.
    final ko = language == 'ko' ? texts : korean();
    if (en == null || ko == null) return null;
    return (text, index) =>
        index < en.length && index < ko.length && en[index] == ko[index];
  });

  /// [_tally] for the leaves of a record: they do not stand at the same place
  /// in every language when a field is empty in one, so a leaf reads the same
  /// in English and Korean when both outputs have it.
  void _checkLeaves(
    String where,
    List<String> leaves,
    List<String> Function() english,
    List<String> Function() korean,
  ) => _tally(where, leaves, () {
    final en = english().toSet();
    final ko = language == 'ko' ? leaves.toSet() : korean().toSet();
    return (text, index) => en.contains(text) && ko.contains(text);
  });

  /// One issue for each generator whose texts lack the writing system, over
  /// all the seeds together. With [strictProse] every text is rewritten, so a
  /// single text without it is a generator that writes words of its own.
  Iterable<CoLanguageIssue> _scriptIssues() sync* {
    final limit = strictProse ? 1.0 : minScript;
    for (final entry in _scriptCounts.entries) {
      final count = entry.value;
      if (count.total > 0 && count.hit / count.total < limit) {
        yield CoLanguageIssue(
          CoLanguageCheck.script,
          entry.key,
          '${count.total - count.hit} of ${count.total} generated texts have '
          'no writing system of the language (${script.name}): a text is not '
          'translated, or a generator writes English whatever the language',
          value: count.miss,
        );
      }
    }
  }

  /// Every role of every pack, for every seed.
  void roles() {
    for (final pack in generationDomains) {
      if (language != 'ko' && koreanOnlyPacks.containsKey(pack.name)) continue;
      for (final entry in pack.roles.entries) {
        final types = entry.value.supportedTypes;
        if (types != null && !types.contains('String')) continue;
        final qualified = '${pack.name}.${entry.key}';
        final where = 'role $qualified';
        _calls++;
        for (final seed in seeds) {
          List<String> outputs(CoFaker f) => <String>[
            for (var i = 0; i < records; i++)
              '${f.schema.record({'value': 'String'}, roles: {'value': qualified}, streamKey: qualified, index: i)['value']}',
          ];
          try {
            final texts = outputs(faker(seed, generationDomains));
            for (final text in texts) {
              _scan(where, text);
            }
            _checkScript(
              where,
              texts,
              () => outputs(_reference('en', seed)),
              () => outputs(_reference('ko', seed)),
            );
          } catch (error) {
            _report(CoLanguageCheck.error, where, _brief(error));
            break;
          }
        }
      }
    }
  }

  /// Every registered entity, for the first seed.
  ///
  /// An entity field that a name infers to a role of a Korean-only pack (the
  /// phone and the address of a clinic patient) would write Korean values in
  /// every language, so the entities run without those packs.
  void entities() {
    final domains = _entityDomains(language);
    for (final pack in domains) {
      for (final entity in pack.entities.entries) {
        final qualified = '${pack.name}.${entity.key}';
        final where = 'entity $qualified';
        final references = <String, int>{
          for (final field in entity.value.keys)
            if (field.endsWith('Id') && field != 'parentId') field: 3,
        };
        _calls++;
        try {
          final rows = faker(
            seeds.first,
            domains,
          ).schema.entities(qualified, 6, referenceCounts: references);
          for (final row in rows) {
            _scan(where, _describe(row));
          }
        } catch (error) {
          _report(CoLanguageCheck.error, where, _brief(error));
        }
      }
    }
  }

  /// Every call of the generators, for every seed.
  void calls() {
    for (final call in allLanguageCalls) {
      _calls++;
      for (final seed in seeds) {
        try {
          final output = call.run(faker(seed, generationDomains));
          _scan(
            call.name,
            _describe(output),
            hangulReason: call.hangulReason,
            templates: call.notificationTemplates,
          );
          if (call.hangulReason != null || call.englishReason != null) {
            // Written in the language of the person it is for, or made of
            // codes and names of its own: not read for a writing system.
            continue;
          }
          final plain = _plainTexts(output);
          if (plain != null) {
            _checkScript(
              call.name,
              plain,
              () => _plainTexts(call.run(_reference('en', seed))),
              () => _plainTexts(call.run(_reference('ko', seed))),
            );
          } else {
            _checkLeaves(
              call.name,
              _leaves(output),
              () => _leaves(call.run(_reference('en', seed))),
              () => _leaves(call.run(_reference('ko', seed))),
            );
          }
        } catch (error) {
          _report(CoLanguageCheck.error, call.name, _brief(error));
          break;
        }
      }
    }
  }

  static String _brief(Object error) {
    final text = '$error'.split('\n').first;
    return text.length <= 160 ? text : '${CoTextScan.cut(text, 160)}…';
  }
}

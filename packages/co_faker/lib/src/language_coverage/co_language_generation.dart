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
  void _scan(String where, String text, {String? hangulReason}) {
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
    final unfilled = CoTextScan.unfilledPlaceholder(text);
    if (unfilled != null) {
      _report(
        CoLanguageCheck.placeholder,
        where,
        'the generated text still has the placeholder $unfilled: the '
        'template uses a name that the generator does not fill',
        value: _around(text, text.indexOf(unfilled)),
      );
    }
  }

  static String? _firstHangul(String text) {
    for (var i = 0; i < text.length; i++) {
      if (CoTextScan.hasHangul(text[i])) return _around(text, i);
    }
    return null;
  }

  static String _around(String text, int index) {
    final start = index < 24 ? 0 : index - 24;
    final end = index + 24 > text.length ? text.length : index + 24;
    return text.substring(start, end).replaceAll('\n', ' ');
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
  /// them. Anything else (a record with codes and labels) is not read for its
  /// writing system, because its codes are English by design.
  static List<String>? _plainTexts(Object? value) {
    if (value is String) return <String>[value];
    if (value is Iterable<Object?> && value.every((item) => item is String)) {
      return <String>[for (final item in value) item! as String];
    }
    return null;
  }

  /// A text whose writing system the gate reads: it has words, and it is not
  /// a single ASCII token such as an email address, a code, or a handle, nor a
  /// masked name (`K*** L.`), whose letters are random initials.
  static bool _isProse(String text) {
    if (!CoTextScan.hasLetters(text) || text.contains('***')) return false;
    final ascii = text.codeUnits.every((unit) => unit < 128);
    return !(ascii && !RegExp(r'\s').hasMatch(text));
  }

  /// Holds [texts] to the writing system of the language, comparing each with
  /// the English and Korean text at the same place.
  void _checkScript(
    String where,
    List<String> texts,
    List<String>? english,
    List<String>? korean,
  ) {
    if (!_wantsScript || english == null || korean == null) return;
    var total = 0;
    var hit = 0;
    String? miss;
    for (var i = 0; i < texts.length; i++) {
      final text = texts[i];
      final languageIndependent =
          !strictProse &&
          i < english.length &&
          i < korean.length &&
          english[i] == korean[i];
      if (languageIndependent || !_isProse(text)) continue;
      total++;
      if (CoTextScan.hasScript(text, script)) {
        hit++;
      } else {
        miss ??= text;
      }
    }
    if (total > 0 && hit / total < minScript) {
      _report(
        CoLanguageCheck.script,
        where,
        '${total - hit} of $total generated texts have no writing system of '
        'the language (${script.name}): a text is not translated, or a '
        'generator writes English whatever the language',
        value: miss,
      );
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
            if (_wantsScript) {
              _checkScript(
                where,
                texts,
                outputs(_reference('en', seed)),
                outputs(_reference('ko', seed)),
              );
            }
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
          _scan(call.name, _describe(output), hangulReason: call.hangulReason);
          final plain = _plainTexts(output);
          if (_wantsScript && plain != null) {
            _checkScript(
              call.name,
              plain,
              _plainTexts(call.run(_reference('en', seed))),
              _plainTexts(call.run(_reference('ko', seed))),
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
    return text.length <= 160 ? text : '${text.substring(0, 160)}…';
  }
}

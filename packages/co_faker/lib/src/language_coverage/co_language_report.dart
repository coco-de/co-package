import 'co_language_text_scan.dart';

/// How far a language is localized, computed from the registries.
enum CoLanguageLevel {
  /// The language has no domain data registered: the basic modules (names,
  /// addresses, text) speak it and the domain packs read English.
  base,

  /// The language is registered with empty stubs: no domain text, clinic, or
  /// SaaS data is written yet.
  planned,

  /// Some of the three data sets (domain text bundle, clinic data, SaaS data)
  /// are written, not all.
  partial,

  /// All three data sets are written.
  localized,
}

/// What a [CoLanguageIssue] is about.
///
/// The entries with a letter are the checks of the gate; the others guard
/// what the checks rest on.
enum CoLanguageCheck {
  /// There is nothing to check: the language has no data yet.
  planned('planned'),

  /// (a) A text of a language other than Korean has Hangul in it.
  hangul('(a) Hangul'),

  /// (b) A text lacks the writing system of its language (kana or han for
  /// Japanese, han for Chinese, Cyrillic for Russian).
  script('(b) writing system'),

  /// (c) Too many texts read exactly like the English ones.
  sameAsEnglish('(c) same as English'),

  /// (d) A list does not have the length of the English list.
  length('(d) list length'),

  /// (e) A key or a data set is not registered: English is used instead.
  unregistered('(e) not registered'),

  /// A key that English does not have.
  unknownKey('unknown key'),

  /// A code that has to be the English one is not.
  code('code'),

  /// A placeholder is lost, or one is left unfilled in generated text.
  placeholder('placeholder'),

  /// A text is empty.
  empty('empty text'),

  /// An `allowSameAsEnglish` entry is wrong or no longer needed.
  allowance('allowSameAsEnglish'),

  /// A generator threw.
  error('generator error');

  const CoLanguageCheck(this.title);

  /// How reports name the check.
  final String title;
}

/// One thing that the coverage gate found wrong.
class CoLanguageIssue {
  /// Creates an issue of [check] at [where].
  const CoLanguageIssue(this.check, this.where, this.message, {this.value});

  /// The check that failed.
  final CoLanguageCheck check;

  /// Where: a slot and row (`clinic.cardIssuers[3]`), or the generator that
  /// produced the text (`role dental.dentalProcedure`, `clinic.payment`).
  final String where;

  /// What is wrong, and what to do about it.
  final String message;

  /// The text at fault, when there is one.
  final String? value;

  /// The issue as JSON-encodable data.
  Map<String, Object?> toJson() => <String, Object?>{
    'check': check.name,
    'where': where,
    'message': message,
    if (value != null) 'value': value,
  };

  @override
  String toString() {
    final text = value;
    return '${check.title}: $where — $message'
        '${text == null ? '' : ': “${CoTextScan.excerpt(text)}”'}';
  }
}

/// The result of checking one language.
class CoLanguageReport {
  /// Creates a report.
  const CoLanguageReport({
    required this.language,
    required this.level,
    required this.issues,
    this.notes = const <String>[],
    this.stats = const <String, num>{},
    this.reference = false,
  });

  /// The language code.
  final String language;

  /// How far the language is localized.
  final CoLanguageLevel level;

  /// Everything that is wrong. The language passes when there is none.
  final List<CoLanguageIssue> issues;

  /// Things worth a look that do not fail the check, such as the texts that
  /// equal English but stay within the limit.
  final List<String> notes;

  /// Counts that the checks computed: texts read, ratios, outputs generated.
  final Map<String, num> stats;

  /// Whether the language is the reference that the others are compared with.
  final bool reference;

  /// Whether the language passes every check.
  bool get passed => issues.isEmpty;

  /// The issues of [check].
  List<CoLanguageIssue> issuesOf(CoLanguageCheck check) => <CoLanguageIssue>[
    for (final issue in issues)
      if (issue.check == check) issue,
  ];

  /// The report as JSON-encodable data.
  Map<String, Object?> toJson() => <String, Object?>{
    'language': language,
    'level': level.name,
    'reference': reference,
    'passed': passed,
    'stats': stats,
    'issues': <Object?>[for (final issue in issues) issue.toJson()],
    'notes': notes,
  };

  /// A readable report: the verdict, the counts, and the issues by check.
  ///
  /// [limit] caps the issues that are listed per check; the rest are counted.
  String toMarkdown({int limit = 25}) {
    final out = StringBuffer()
      ..writeln('# Language coverage: $language')
      ..writeln()
      ..writeln('- Level: `${level.name}`');
    final count = issues.length;
    out.writeln(
      '- Result: **${passed ? 'PASS' : 'FAIL'}**'
      '${reference ? ' (reference language)' : ''}'
      '${passed ? '' : ' — $count issue${count == 1 ? '' : 's'}'}',
    );
    for (final entry in stats.entries) {
      out.writeln('- ${entry.key}: ${_number(entry.value)}');
    }
    for (final check in CoLanguageCheck.values) {
      final found = issuesOf(check);
      if (found.isEmpty) continue;
      out
        ..writeln()
        ..writeln('## ${check.title} (${found.length})')
        ..writeln();
      for (final issue in found.take(limit)) {
        final text = issue.value;
        out.writeln(
          '- `${issue.where}` — ${issue.message}'
          '${text == null ? '' : ': “${CoTextScan.excerpt(text)}”'}',
        );
      }
      if (found.length > limit) {
        out.writeln(
          '- … and ${found.length - limit} more '
          '(`--format json` lists them all)',
        );
      }
    }
    if (notes.isNotEmpty) {
      out
        ..writeln()
        ..writeln('## Notes')
        ..writeln();
      for (final note in notes.take(limit)) {
        out.writeln('- $note');
      }
      if (notes.length > limit) {
        out.writeln('- … and ${notes.length - limit} more');
      }
    }
    return out.toString().trimRight();
  }

  static String _number(num value) =>
      value is int || value == value.roundToDouble()
      ? '${value.toInt()}'
      : value.toStringAsFixed(4);
}

/// One row of the table of supported languages: what a language has, computed
/// from the registries.
class CoLanguageSupport {
  /// Creates a row.
  const CoLanguageSupport({
    required this.code,
    required this.name,
    required this.script,
    required this.names,
    required this.addresses,
    required this.bundleKeys,
    required this.bundleKeyTotal,
    required this.clinic,
    required this.saas,
    required this.level,
  });

  /// The language code, such as `ja`.
  final String code;

  /// The English name of the language.
  final String name;

  /// The writing system, such as `latin` or `kana`.
  final String script;

  /// Whether the basic modules have first and last names of the language.
  final bool names;

  /// Whether the basic modules have cities and street names of the language.
  final bool addresses;

  /// How many keys of the domain text bundle the language has written.
  final int bundleKeys;

  /// How many keys the English bundle has.
  final int bundleKeyTotal;

  /// Whether the clinic data is written.
  final bool clinic;

  /// Whether the SaaS data is written.
  final bool saas;

  /// How far the language is localized.
  final CoLanguageLevel level;

  /// The row as JSON-encodable data.
  Map<String, Object?> toJson() => <String, Object?>{
    'language': code,
    'name': name,
    'script': script,
    'names': names,
    'addresses': addresses,
    'bundleKeys': bundleKeys,
    'bundleKeyTotal': bundleKeyTotal,
    'clinic': clinic,
    'saas': saas,
    'level': level.name,
  };
}

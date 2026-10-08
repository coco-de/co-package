/// The header row of the glossary table of a language file.
const String glossaryHeader =
    '| Source term (English) | Translation | Forbidden forms | Rationale |';

/// One row of a glossary.
class GlossaryEntry {
  /// Creates an entry read from [line] of the file.
  const GlossaryEntry({
    required this.source,
    required this.translation,
    required this.forbidden,
    required this.rationale,
    required this.line,
  });

  /// The term in English.
  final String source;

  /// Its translation: the only one the texts of the language write.
  final String translation;

  /// The spellings that no text of the language may contain.
  final List<String> forbidden;

  /// Why.
  final String rationale;

  /// The line of the file, counted from 1.
  final int line;
}

/// What a language file says, and what is wrong with how it says it.
class LanguageDoc {
  /// Creates a reading of a language file.
  const LanguageDoc({
    required this.status,
    required this.glossary,
    required this.errors,
  });

  /// The value of the `status:` line, or `null` when there is not exactly one.
  final String? status;

  /// The rows of the glossary table.
  final List<GlossaryEntry> glossary;

  /// The faults of the format: a missing status line, a missing or malformed
  /// table, a row that is not four cells, an empty cell.
  final List<String> errors;
}

String _collapse(String text) => text.trim().replaceAll(RegExp(r'\s+'), ' ');

/// A cell without the pair of backticks that may surround it.
String _cell(String text) {
  final trimmed = text.trim();
  if (trimmed.length > 1 && trimmed.startsWith('`') && trimmed.endsWith('`')) {
    return trimmed.substring(1, trimmed.length - 1).trim();
  }
  return trimmed;
}

/// The cells of a table row, or `null` when it is not a row.
List<String>? _cells(String line) {
  final row = line.trim();
  if (!row.startsWith('|') || !row.endsWith('|') || row.length < 2) return null;
  const pipe = '\u0000';
  return row
      .substring(1, row.length - 1)
      .replaceAll(r'\|', pipe)
      .split('|')
      .map((cell) => cell.replaceAll(pipe, '|'))
      .toList();
}

/// Reads a language file: its status line and its glossary.
LanguageDoc parseLanguageDoc(String markdown) {
  final lines = markdown.split('\n');
  final errors = <String>[];
  String? status;
  final statusLines = <int>[
    for (var i = 0; i < lines.length; i++)
      if (lines[i].startsWith('status:')) i,
  ];
  if (statusLines.length != 1) {
    errors.add(
      'expected exactly one "status:" line, found ${statusLines.length}',
    );
  } else {
    status = lines[statusLines.single].substring('status:'.length).trim();
  }

  final glossary = <GlossaryEntry>[];
  final headers = <int>[
    for (var i = 0; i < lines.length; i++)
      if (_collapse(lines[i]) == _collapse(glossaryHeader)) i,
  ];
  if (headers.length != 1) {
    errors.add(
      'expected exactly one glossary table with the header '
      '"$glossaryHeader", found ${headers.length}',
    );
    return LanguageDoc(status: status, glossary: glossary, errors: errors);
  }
  final header = headers.single;
  if (header + 1 >= lines.length ||
      !RegExp(
        r'^\s*\|(\s*:?-{3,}:?\s*\|){4}\s*$',
      ).hasMatch(lines[header + 1])) {
    errors.add(
      'line ${header + 2}: the glossary header needs a delimiter row '
      '"| --- | --- | --- | --- |"',
    );
    return LanguageDoc(status: status, glossary: glossary, errors: errors);
  }
  for (var i = header + 2; i < lines.length; i++) {
    if (!lines[i].trimLeft().startsWith('|')) break;
    final number = i + 1;
    final cells = _cells(lines[i]);
    if (cells == null || cells.length != 4) {
      errors.add(
        'line $number: a glossary row has exactly four cells '
        '(${cells?.length ?? 0} found; write "\\|" for a pipe inside a cell)',
      );
      continue;
    }
    final source = _cell(cells[0]);
    final translation = _cell(cells[1]);
    final forbiddenCell = _cell(cells[2]);
    final rationale = _cell(cells[3]);
    for (final entry in <String, String>{
      'term': source,
      'translation': translation,
      'rationale': rationale,
    }.entries) {
      if (entry.value.isEmpty) {
        errors.add('line $number: the ${entry.key} is empty');
      }
    }
    glossary.add(
      GlossaryEntry(
        source: source,
        translation: translation,
        forbidden: forbiddenCell == '-' || forbiddenCell == '—'
            ? const <String>[]
            : <String>[
                for (final form in forbiddenCell.split(';'))
                  if (_cell(form).isNotEmpty) _cell(form),
              ],
        rationale: rationale,
        line: number,
      ),
    );
  }
  return LanguageDoc(status: status, glossary: glossary, errors: errors);
}

/// The faults of the glossary itself: a term that is written twice, and a
/// forbidden form that the texts could not avoid because a translation of the
/// glossary contains it.
List<String> glossaryProblems(LanguageDoc doc) {
  final problems = <String>[];
  final seen = <String, GlossaryEntry>{};
  for (final entry in doc.glossary) {
    final key = _collapse(entry.source).toLowerCase();
    final first = seen[key];
    if (first != null) {
      problems.add(
        'line ${entry.line}: the term "${entry.source}" is already the term '
        'of line ${first.line}: a term has one row, and one translation '
        '("${first.translation}" and "${entry.translation}")',
      );
    } else {
      seen[key] = entry;
    }
  }
  for (final entry in doc.glossary) {
    for (final form in entry.forbidden) {
      final lower = _collapse(form).toLowerCase();
      for (final other in doc.glossary) {
        if (_collapse(other.translation).toLowerCase().contains(lower)) {
          problems.add(
            other == entry
                ? 'line ${entry.line}: the forbidden form "$form" is inside '
                      'the translation "${entry.translation}" of its own row'
                : 'line ${entry.line}: the forbidden form "$form" is inside '
                      'the translation "${other.translation}" of the term '
                      '"${other.source}" (line ${other.line}), which the '
                      'texts have to write',
          );
        }
      }
    }
  }
  return problems;
}

/// Where the texts contain a forbidden form of the glossary: one message for
/// each place. Case is ignored.
List<String> forbiddenInTexts(
  LanguageDoc doc,
  Iterable<({String where, String text})> texts,
) {
  final found = <String>[];
  for (final entry in doc.glossary) {
    for (final form in entry.forbidden) {
      final lower = _collapse(form).toLowerCase();
      for (final text in texts) {
        if (_collapse(text.text).toLowerCase().contains(lower)) {
          found.add(
            'the forbidden form "$form" of the term "${entry.source}" '
            '(line ${entry.line}) is in ${text.where}: “${text.text}”',
          );
        }
      }
    }
  }
  return found;
}

/// Text helpers shared by the nav module. Not exported by the barrel.
library;

final RegExp _whitespaceRun = RegExp(r'\s+');

/// [input] with every whitespace run (line breaks, no-break and ideographic
/// spaces included) collapsed to one space, and trimmed.
String noteNavCollapse(String input) =>
    input.replaceAll(_whitespaceRun, ' ').trim();

/// A lower-cased copy of [input] with the **same length** in UTF-16 code units,
/// so a match offset found in the result is also valid in [input]. A character
/// whose lower case has another length is kept as it is.
///
/// No word boundaries are involved: Hangul and CJK text is compared as plain
/// code units (and is unchanged by lower-casing).
String noteNavFold(String input) {
  final lowered = input.toLowerCase();
  if (lowered.length == input.length) return lowered;
  final buffer = StringBuffer();
  for (final rune in input.runes) {
    final character = String.fromCharCode(rune);
    final lower = character.toLowerCase();
    buffer.write(lower.length == character.length ? lower : character);
  }

  return buffer.toString();
}

/// The comparison key of a name (tag or label): collapsed, then folded.
String noteNavKey(String input) => noteNavFold(noteNavCollapse(input));

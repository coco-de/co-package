import '../co_faker_languages.dart';

/// A range of code points, both ends included.
typedef _Range = (int, int);

/// What the language coverage gate reads in a string: which writing system its
/// letters belong to, and which placeholders it holds.
///
/// The writing systems are told apart by code point ranges that this class
/// lists, not by the Unicode tables of the platform, so a verdict is the same
/// everywhere.
abstract final class CoTextScan {
  /// Hangul: jamo, compatibility jamo, syllables, their extensions, the
  /// parenthesized and circled letters, and the half-width letters.
  static const List<_Range> _hangul = <_Range>[
    (0x1100, 0x11FF),
    (0x3130, 0x318F),
    (0x3200, 0x321E),
    (0x3260, 0x327E),
    (0xA960, 0xA97F),
    (0xAC00, 0xD7AF),
    (0xD7B0, 0xD7FF),
    (0xFFA0, 0xFFDC),
  ];

  /// Han characters (kanji, hanzi), the radicals, the iteration marks, and
  /// the extensions up to Extension H.
  static const List<_Range> _han = <_Range>[
    (0x2E80, 0x2FDF),
    (0x3005, 0x3005),
    (0x3007, 0x3007),
    (0x3400, 0x4DBF),
    (0x4E00, 0x9FFF),
    (0xF900, 0xFAFF),
    (0x20000, 0x2FA1F),
    (0x30000, 0x323AF),
  ];

  /// Hiragana and katakana, the phonetic extensions, half-width katakana, and
  /// the supplements.
  static const List<_Range> _kana = <_Range>[
    (0x3040, 0x309F),
    (0x30A0, 0x30FF),
    (0x31F0, 0x31FF),
    (0xFF66, 0xFF9F),
    (0x1B000, 0x1B16F),
  ];

  /// Cyrillic letters and their supplements.
  static const List<_Range> _cyrillic = <_Range>[
    (0x0400, 0x052F),
    (0x1C80, 0x1C8F),
    (0x2DE0, 0x2DFF),
    (0xA640, 0xA69F),
  ];

  static final RegExp _letter = RegExp(r'\p{L}', unicode: true);

  /// A `#{variable}` of a notification template: the braces open a variable
  /// whatever its name, and the name may be in any language.
  static final RegExp _templateVariable = RegExp(r'#\{[^{}]*\}');

  /// A `{name}` field that a generator fills in: one word between the braces,
  /// of letters, marks, digits, and underscores in any writing system, so
  /// that a field whose name was translated (`{回数}`) is still a field.
  static final RegExp _field = RegExp(
    r'\{([\p{L}\p{M}\p{N}_]+)\}',
    unicode: true,
  );

  /// A field written loosely: with spaces inside the braces (`{ n }`), or with
  /// the full-width braces that East Asian input produces. No generator fills
  /// one, so a text that comes out with one has a leak.
  static final RegExp _looseField = RegExp(
    r'[{｛]\s*[\p{L}\p{M}\p{N}_]+\s*[}｝]',
    unicode: true,
  );

  static bool _has(String text, List<_Range> ranges) {
    for (final rune in text.runes) {
      for (final range in ranges) {
        if (rune >= range.$1 && rune <= range.$2) return true;
      }
    }
    return false;
  }

  /// Whether [text] has a Hangul character.
  static bool hasHangul(String text) => _has(text, _hangul);

  /// Whether [text] has a hiragana or katakana character, which only
  /// Japanese writes.
  static bool hasKana(String text) => _has(text, _kana);

  /// Whether [text] has a letter of the writing system of [script]: for
  /// [CoFakerScript.kana] a kana or a han character, because Japanese writes
  /// both.
  ///
  /// Latin is never required of a language, so it answers `true`.
  static bool hasScript(String text, CoFakerScript script) {
    return switch (script) {
      CoFakerScript.latin => true,
      CoFakerScript.han => _has(text, _han),
      CoFakerScript.kana => _has(text, _kana) || _has(text, _han),
      CoFakerScript.cyrillic => _has(text, _cyrillic),
      CoFakerScript.hangul => _has(text, _hangul),
    };
  }

  /// Whether the gate can ask for the writing system of [script] in a text:
  /// every script but Latin.
  static bool requiresScript(CoFakerScript script) =>
      script != CoFakerScript.latin;

  /// [text] without its fields and `#{variables}`: what is left is the part
  /// that a translation has to write.
  static String withoutPlaceholders(String text) =>
      text.replaceAll(_templateVariable, '').replaceAll(_looseField, '');

  /// Whether [text] has a letter outside its placeholders. A text without one
  /// (`{month}/{day}`, `***-**-####`, `12:00`) has nothing to translate.
  static bool hasLetters(String text) =>
      _letter.hasMatch(withoutPlaceholders(text));

  /// The names of the `{name}` fields of [text], one for each occurrence, in
  /// the order they appear.
  ///
  /// A `#{variable}` is a marker of a notification template, which the
  /// generators leave in their output and whose name a language may translate,
  /// so it holds no field. A pattern that writes a number sign in front of a
  /// field (`{kind} #{number}`) reads the field with [templates] set.
  static List<String> fieldNames(String text, {bool templates = false}) {
    final source = templates ? text : text.replaceAll(_templateVariable, '');
    return <String>[
      for (final match in _field.allMatches(source)) match.group(1)!,
    ];
  }

  /// How many `#{variable}` markers [text] has.
  static int templateVariables(String text) =>
      _templateVariable.allMatches(text).length;

  /// The first field left in [text] that no generator filled, or `null`: a
  /// `{name}` in any writing system, with or without spaces inside the
  /// braces, in ASCII or full-width braces.
  ///
  /// A `#{variable}` counts too (`Laser #{numer}`: a field behind a number
  /// sign), except in a notification template ([templates]), which writes its
  /// variables on purpose.
  static String? unfilledPlaceholder(String text, {bool templates = false}) {
    final source = templates ? text.replaceAll(_templateVariable, '') : text;
    return _looseField.firstMatch(source)?.group(0);
  }

  /// The part of [text] around the UTF-16 position [index], on one line:
  /// [radius] code units on each side, never cutting a character in two.
  static String around(String text, int index, {int radius = 24}) {
    var start = index < radius ? 0 : index - radius;
    var end = index + radius > text.length ? text.length : index + radius;
    if (start > 0 && _isLowSurrogate(text.codeUnitAt(start))) start--;
    if (end < text.length && _isLowSurrogate(text.codeUnitAt(end))) end++;
    return text.substring(start, end).replaceAll('\n', ' ');
  }

  /// [text] cut to [length] code units, without cutting a character that
  /// takes two of them (an emoji, a rare han character) in half.
  static String cut(String text, int length) {
    if (text.length <= length) return text;
    final end = _isLowSurrogate(text.codeUnitAt(length)) ? length - 1 : length;
    return text.substring(0, end);
  }

  /// [text] on one line, cut to [length] characters with an ellipsis.
  static String excerpt(String text, {int length = 48}) {
    final line = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    return line.length <= length ? line : '${cut(line, length)}…';
  }

  static bool _isLowSurrogate(int unit) => unit >= 0xDC00 && unit <= 0xDFFF;
}

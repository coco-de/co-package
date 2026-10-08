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
  /// Hangul: jamo, compatibility jamo, syllables, and their extensions.
  static const List<_Range> _hangul = <_Range>[
    (0x1100, 0x11FF),
    (0x3130, 0x318F),
    (0xA960, 0xA97F),
    (0xAC00, 0xD7AF),
    (0xD7B0, 0xD7FF),
  ];

  /// Han characters (kanji, hanzi), the radicals, and the iteration marks.
  static const List<_Range> _han = <_Range>[
    (0x2E80, 0x2FDF),
    (0x3005, 0x3005),
    (0x3007, 0x3007),
    (0x3400, 0x4DBF),
    (0x4E00, 0x9FFF),
    (0xF900, 0xFAFF),
    (0x20000, 0x2FA1F),
  ];

  /// Hiragana and katakana, the phonetic extensions, and half-width katakana.
  static const List<_Range> _kana = <_Range>[
    (0x3040, 0x309F),
    (0x30A0, 0x30FF),
    (0x31F0, 0x31FF),
    (0xFF66, 0xFF9F),
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

  /// A `{name}` placeholder that a generator fills in.
  static final RegExp _placeholder = RegExp(r'\{([A-Za-z_]\w*)\}');

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

  /// [text] without its placeholders and `#{variables}`: what is left is the
  /// part that a translation has to write.
  static String withoutPlaceholders(String text) =>
      text.replaceAll(_templateVariable, '').replaceAll(_placeholder, '');

  /// Whether [text] has a letter outside its placeholders. A text without one
  /// (`{month}/{day}`, `***-**-####`, `12:00`) has nothing to translate.
  static bool hasLetters(String text) =>
      _letter.hasMatch(withoutPlaceholders(text));

  /// The names of the `{name}` placeholders of [text].
  static Set<String> placeholders(String text) => <String>{
    for (final match in _placeholder.allMatches(
      text.replaceAll(_templateVariable, ''),
    ))
      match.group(1)!,
  };

  /// How many `#{variable}` markers [text] has.
  static int templateVariables(String text) =>
      _templateVariable.allMatches(text).length;

  /// The first `{name}` placeholder left in [text] that no generator filled,
  /// or `null`. A `#{variable}` of a notification template is output on
  /// purpose and does not count.
  static String? unfilledPlaceholder(String text) {
    final cleaned = text.replaceAll(_templateVariable, '');
    return _placeholder.firstMatch(cleaned)?.group(0);
  }

  /// [text] on one line, cut to [length] characters with an ellipsis.
  static String excerpt(String text, {int length = 48}) {
    final line = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    return line.length <= length ? line : '${line.substring(0, length)}…';
  }
}

import 'package:open_note/src/note/study/utilities/note_calculator_exception.dart';

/// Token kinds of the calculator grammar.
enum NoteCalculatorTokenKind {
  /// A numeral such as `12` or `1.5e+20`.
  number,

  /// A function or constant name, or `π`.
  name,

  /// `+`
  plus,

  /// `-` or `−`.
  minus,

  /// `*` or `×`.
  times,

  /// `/` or `÷`.
  divide,

  /// `^`
  power,

  /// `%`
  percent,

  /// `(`
  leftParenthesis,

  /// `)`
  rightParenthesis,

  /// Marks the end of the input.
  end,
}

/// One token of a calculator expression. Not part of the public API.
class NoteCalculatorToken {
  /// A token of [kind] starting at [offset].
  const NoteCalculatorToken(
    this.kind,
    this.offset, {
    this.text = '',
    this.value = 0,
  });

  /// What the token is.
  final NoteCalculatorTokenKind kind;

  /// Index of the first character in the input.
  final int offset;

  /// The matched source text.
  final String text;

  /// The value of a [NoteCalculatorTokenKind.number].
  final double value;
}

/// Splits an expression into tokens. Not part of the public API.
abstract final class NoteCalculatorLexer {
  static final RegExp _number = RegExp(r'(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?');
  static final RegExp _name = RegExp(r'[A-Za-z]+');

  static const Map<String, NoteCalculatorTokenKind> _symbols = {
    '+': NoteCalculatorTokenKind.plus,
    '-': NoteCalculatorTokenKind.minus,
    '−': NoteCalculatorTokenKind.minus,
    '*': NoteCalculatorTokenKind.times,
    '×': NoteCalculatorTokenKind.times,
    '/': NoteCalculatorTokenKind.divide,
    '÷': NoteCalculatorTokenKind.divide,
    '^': NoteCalculatorTokenKind.power,
    '%': NoteCalculatorTokenKind.percent,
    '(': NoteCalculatorTokenKind.leftParenthesis,
    ')': NoteCalculatorTokenKind.rightParenthesis,
  };

  /// The tokens of [source], ending with a [NoteCalculatorTokenKind.end].
  static List<NoteCalculatorToken> tokenize(String source) {
    final tokens = <NoteCalculatorToken>[];
    var index = 0;
    while (index < source.length) {
      final character = source[index];
      if (character.trim().isEmpty) {
        index++;
        continue;
      }
      final token = _read(source, index);
      tokens.add(token);
      index += token.text.length;
    }

    return tokens
      ..add(NoteCalculatorToken(NoteCalculatorTokenKind.end, source.length));
  }

  static NoteCalculatorToken _read(String source, int index) {
    final character = source[index];
    final symbol = _symbols[character];
    if (symbol != null) {
      return NoteCalculatorToken(symbol, index, text: character);
    }
    if (character == 'π') {
      return NoteCalculatorToken(
        NoteCalculatorTokenKind.name,
        index,
        text: character,
      );
    }

    return _word(source, index);
  }

  static NoteCalculatorToken _word(String source, int index) {
    final number = _number.matchAsPrefix(source, index)?.group(0);
    if (number != null) {
      return NoteCalculatorToken(
        NoteCalculatorTokenKind.number,
        index,
        text: number,
        value: double.parse(number),
      );
    }
    final name = _name.matchAsPrefix(source, index)?.group(0);
    if (name != null) {
      return NoteCalculatorToken(
        NoteCalculatorTokenKind.name,
        index,
        text: name,
      );
    }

    throw NoteCalculatorException(
      NoteCalculatorError.syntax,
      'unexpected "${source[index]}"',
      offset: index,
    );
  }
}

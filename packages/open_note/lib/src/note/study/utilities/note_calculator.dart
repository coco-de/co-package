import 'package:open_note/src/note/study/utilities/internal/note_calculator_lexer.dart';
import 'package:open_note/src/note/study/utilities/internal/note_calculator_parser.dart';
import 'package:open_note/src/note/study/utilities/note_calculator_exception.dart';

/// A hand-written calculator (it never evaluates code).
///
/// **Grammar**
///
/// - Numbers: `12`, `1.5`, `.5`, `5.`, and scientific notation `1.5e+20`
///   (an `e` directly followed by digits or a signed number).
/// - Operators, loosest first: `+ -` (also `−`); `* /` (also `× ÷`) and `%`
///   as remainder; a leading `-`/`+` sign; `^`, **right-associative**
///   (`2^3^2` is 512) with an exponent that may carry a sign (`2^-1`). The
///   sign binds looser than `^`, so `-2^2` is -4.
/// - `%` is a remainder when an operand (number, name or `(`) follows it —
///   `7%3` is 1, with the Euclidean result (never negative) — and otherwise a
///   postfix percent, dividing the number before it by 100: `50%` is 0.5 and
///   `200*10%` is 20. So `10%-3` reads as `0.1 - 3`.
/// - Parentheses; functions `sqrt sin cos tan log ln abs` (radians, `log` is
///   base 10), always followed by `(`; constants `pi` (or `π`) and `e`. Names
///   ignore case. There is no implicit multiplication: `2pi` is an error.
///
/// Trigonometric results smaller than `1e-14` in magnitude are returned as 0.
abstract final class NoteCalculator {
  /// The longest accepted expression, in UTF-16 code units.
  static const int maxLength = 1000;

  /// The value of [expression].
  ///
  /// Throws [NoteCalculatorException] for malformed input (including input over
  /// [maxLength] or nested beyond 200 levels), division by zero, a function
  /// outside its domain, or a number or intermediate result too large for a
  /// double. The result is always finite, and never `-0.0`.
  static double evaluate(String expression) {
    if (expression.length > maxLength) {
      throw const NoteCalculatorException(
        NoteCalculatorError.syntax,
        'expression is too long',
      );
    }

    return NoteCalculatorParser(
      NoteCalculatorLexer.tokenize(expression),
    ).parse();
  }

  /// [value] as a calculator display shows it: whole numbers without a
  /// decimal point, other numbers rounded to 12 significant digits (so
  /// `0.1 + 0.2` reads `0.3`), and scientific notation (`1.5e+20`) from 1e15
  /// up or below 1e-6. [evaluate] reads every finite result back.
  static String format(double value) {
    if (!value.isFinite) return value.toString();
    if (value == 0) return '0';
    final magnitude = value.abs();
    if (magnitude >= 1e15 || magnitude < 1e-6) return _scientific(value);
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    final text = double.parse(value.toStringAsPrecision(12)).toString();

    return text.endsWith('.0') ? text.substring(0, text.length - 2) : text;
  }

  static String _scientific(double value) {
    final parts = value.toStringAsExponential(11).split('e');
    final mantissa = parts.first.replaceFirst(RegExp(r'\.?0+$'), '');

    return '${mantissa}e${parts.last}';
  }
}

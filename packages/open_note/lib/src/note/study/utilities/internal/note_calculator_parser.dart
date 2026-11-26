import 'dart:math' as math;

import 'package:open_note/src/note/study/utilities/internal/note_calculator_lexer.dart';
import 'package:open_note/src/note/study/utilities/note_calculator_exception.dart';

typedef _Apply = double Function(double left, double right, int offset);

class _Binary {
  const _Binary(this.precedence, this.apply, {this.rightAssociative = false});

  final int precedence;
  final _Apply apply;
  final bool rightAssociative;

  /// The lowest precedence the right operand may bind with.
  int get nextMinimum => rightAssociative ? precedence : precedence + 1;
}

/// Evaluates tokens by precedence climbing. Not part of the public API.
///
/// Precedence from loosest: `+ -`, then `* / %` (remainder), then a leading
/// sign, then `^` (right-associative; its exponent may carry a sign), then the
/// postfix percent, which applies to the number it follows.
class NoteCalculatorParser {
  /// Parses tokens that end with [NoteCalculatorTokenKind.end]; use once.
  NoteCalculatorParser(this._tokens);

  /// How deeply parentheses, signs and powers may nest.
  static const int maxDepth = 200;

  static const int _signPrecedence = 3;

  static const Map<NoteCalculatorTokenKind, _Binary> _operators = {
    NoteCalculatorTokenKind.plus: _Binary(1, _add),
    NoteCalculatorTokenKind.minus: _Binary(1, _subtract),
    NoteCalculatorTokenKind.times: _Binary(2, _multiply),
    NoteCalculatorTokenKind.divide: _Binary(2, _divide),
    NoteCalculatorTokenKind.percent: _Binary(2, _remainder),
    NoteCalculatorTokenKind.power: _Binary(4, _pow, rightAssociative: true),
  };

  static const Map<String, double> _constants = {
    'pi': math.pi,
    'π': math.pi,
    'e': math.e,
  };

  static const Map<String, double Function(double, int)> _functions = {
    'sqrt': _sqrt,
    'sin': _sin,
    'cos': _cos,
    'tan': _tan,
    'log': _log10,
    'ln': _ln,
    'abs': _absolute,
  };

  final List<NoteCalculatorToken> _tokens;
  int _index = 0;

  NoteCalculatorToken get _next => _tokens[_index];

  NoteCalculatorToken _take() => _tokens[_index++];

  /// The value of the whole expression.
  double parse() {
    final value = _expression(0, 0);
    if (_next.kind != NoteCalculatorTokenKind.end) throw _unexpected(_next);

    return value == 0 ? 0 : value;
  }

  double _expression(int minimum, int depth) {
    if (depth > maxDepth) {
      throw _failure(
        NoteCalculatorError.syntax,
        'nested too deeply',
        _next.offset,
      );
    }
    var left = _operand(depth);
    var operator = _operators[_next.kind];
    while (operator != null && operator.precedence >= minimum) {
      final offset = _take().offset;
      final right = _expression(operator.nextMinimum, depth + 1);
      left = _checked(operator.apply(left, right, offset), offset);
      operator = _operators[_next.kind];
    }

    return left;
  }

  /// A signed operand, or a primary with its postfix percents.
  double _operand(int depth) {
    switch (_next.kind) {
      case NoteCalculatorTokenKind.minus:
        _take();

        return -_expression(_signPrecedence, depth + 1);
      case NoteCalculatorTokenKind.plus:
        _take();

        return _expression(_signPrecedence, depth + 1);
      case _:
        return _percentages(_primary(depth));
    }
  }

  /// `%` not followed by an operand divides by 100; otherwise it is left for
  /// the binary loop, which reads it as a remainder.
  double _percentages(double value) {
    var result = value;
    while (_next.kind == NoteCalculatorTokenKind.percent &&
        !_startsOperand(_tokens[_index + 1].kind)) {
      _take();
      result /= 100;
    }

    return result;
  }

  static bool _startsOperand(NoteCalculatorTokenKind kind) =>
      kind == NoteCalculatorTokenKind.number ||
      kind == NoteCalculatorTokenKind.name ||
      kind == NoteCalculatorTokenKind.leftParenthesis;

  double _primary(int depth) {
    final token = _take();

    return switch (token.kind) {
      NoteCalculatorTokenKind.number => _checked(token.value, token.offset),
      NoteCalculatorTokenKind.leftParenthesis => _grouped(depth),
      NoteCalculatorTokenKind.name => _named(token, depth),
      _ => throw _unexpected(token),
    };
  }

  /// The inside of a parenthesis whose `(` has been consumed.
  double _grouped(int depth) {
    final value = _expression(0, depth + 1);
    _expect(NoteCalculatorTokenKind.rightParenthesis, 'missing ")"');

    return value;
  }

  double _named(NoteCalculatorToken token, int depth) {
    final name = token.text.toLowerCase();
    final constant = _constants[name];
    if (constant != null) return constant;
    final function = _functions[name];
    if (function == null) {
      throw _failure(
        NoteCalculatorError.syntax,
        'unknown name "${token.text}"',
        token.offset,
      );
    }
    _expect(NoteCalculatorTokenKind.leftParenthesis, '$name needs "("');

    return _checked(function(_grouped(depth), token.offset), token.offset);
  }

  void _expect(NoteCalculatorTokenKind kind, String message) {
    if (_next.kind != kind) {
      throw _failure(NoteCalculatorError.syntax, message, _next.offset);
    }
    _take();
  }

  static NoteCalculatorException _unexpected(NoteCalculatorToken token) {
    final what = token.kind == NoteCalculatorTokenKind.end
        ? 'unexpected end of expression'
        : 'unexpected "${token.text}"';

    return _failure(NoteCalculatorError.syntax, what, token.offset);
  }

  static NoteCalculatorException _failure(
    NoteCalculatorError error,
    String message,
    int offset,
  ) => NoteCalculatorException(error, message, offset: offset);

  /// [value], unless it left the real finite numbers.
  static double _checked(double value, int offset) {
    if (value.isNaN) {
      throw _failure(NoteCalculatorError.domain, 'not a number', offset);
    }
    if (value.isInfinite) {
      throw _failure(NoteCalculatorError.overflow, 'too large', offset);
    }

    return value;
  }

  static double _add(double a, double b, int offset) => a + b;

  static double _subtract(double a, double b, int offset) => a - b;

  static double _multiply(double a, double b, int offset) => a * b;

  static double _divide(double a, double b, int offset) {
    _nonZero(b, offset);

    return a / b;
  }

  static double _remainder(double a, double b, int offset) {
    _nonZero(b, offset);

    return a % b;
  }

  static double _pow(double a, double b, int offset) {
    if (a == 0 && b < 0) _nonZero(a, offset);

    return math.pow(a, b).toDouble();
  }

  static void _nonZero(double divisor, int offset) {
    if (divisor == 0) {
      throw _failure(
        NoteCalculatorError.divisionByZero,
        'division by zero',
        offset,
      );
    }
  }

  static void _require(bool defined, String name, int offset) {
    if (!defined) {
      throw _failure(NoteCalculatorError.domain, '$name undefined', offset);
    }
  }

  static double _sqrt(double x, int offset) {
    _require(x >= 0, 'sqrt', offset);

    return math.sqrt(x);
  }

  static double _sin(double x, int offset) => _snapped(math.sin(x));

  static double _cos(double x, int offset) => _snapped(math.cos(x));

  static double _tan(double x, int offset) => _snapped(math.tan(x));

  /// Removes the rounding noise of trigonometry, so `sin(pi)` is 0.
  static double _snapped(double value) => value.abs() < 1e-14 ? 0 : value;

  static double _log10(double x, int offset) {
    _require(x > 0, 'log', offset);
    final raw = math.log(x) / math.ln10;
    final whole = raw.roundToDouble();

    // Exact powers of ten give exact logarithms.
    return math.pow(10, whole) == x ? whole : raw;
  }

  static double _ln(double x, int offset) {
    _require(x > 0, 'ln', offset);

    return math.log(x);
  }

  static double _absolute(double x, int offset) => x.abs();
}

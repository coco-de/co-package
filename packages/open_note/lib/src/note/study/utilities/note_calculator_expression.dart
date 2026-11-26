import 'package:flutter/foundation.dart';
import 'package:open_note/src/note/study/utilities/note_calculator.dart';

/// Binary operators of the keypad ([percent] is also postfix, see
/// `NoteCalculator`).
enum NoteCalculatorOperator {
  /// `+`
  add('+'),

  /// `-`, also the sign of a negative number.
  subtract('-'),

  /// `×`
  multiply('×'),

  /// `÷`
  divide('÷'),

  /// `^`, right-associative.
  power('^'),

  /// `%`: remainder before an operand, percent otherwise.
  percent('%');

  const NoteCalculatorOperator(this.symbol);

  /// The text the key types.
  final String symbol;
}

/// Functions of one argument; the name is what `NoteCalculator` reads.
enum NoteCalculatorFunction {
  /// Square root; needs `x >= 0`.
  sqrt,

  /// Sine of radians.
  sin,

  /// Cosine of radians.
  cos,

  /// Tangent of radians.
  tan,

  /// Base-10 logarithm; needs `x > 0`.
  log,

  /// Natural logarithm; needs `x > 0`.
  ln,

  /// Absolute value.
  abs,
}

/// Named constants; the name is what `NoteCalculator` reads.
enum NoteCalculatorConstant {
  /// π.
  pi,

  /// Euler's number.
  e,
}

enum _Kind { digit, point, operator, percent, open, close, constant, value }

@immutable
class _Part {
  const _Part(this.kind, this.text, [String? source]) : source = source ?? text;

  final _Kind kind;

  /// What the user reads.
  final String text;

  /// What is evaluated (differs for computed values, which keep every digit).
  final String source;

  bool get isNumeral => kind == _Kind.digit || kind == _Kind.point;

  @override
  bool operator ==(Object other) =>
      other is _Part &&
      other.kind == kind &&
      other.text == text &&
      other.source == source;

  @override
  int get hashCode => Object.hash(kind, text, source);
}

/// The expression being typed on a calculator keypad, with the editing rules of
/// a keypad.
///
/// Immutable: every edit returns a new expression, or this one itself when the
/// key does not apply. Rules:
///
/// - a `×` is inserted when a constant, function, `(` or computed value follows
///   an operand, and when a digit follows `)`, a constant or a computed value
///   (a digit, constant or `(` after `%` instead means "remainder");
/// - a number cannot start with a redundant `0` or contain two points;
/// - typing an operator after another replaces it, except that `-` after `×`,
///   `÷` or `^` is a negative sign; an expression or `(` can only start with
///   `-`;
/// - `%` needs an operand before it and `)` needs an open `(`.
@immutable
class NoteCalculatorExpression {
  /// An empty expression.
  const NoteCalculatorExpression() : _parts = const [];

  const NoteCalculatorExpression._(this._parts);

  final List<_Part> _parts;

  static const _Part _times = _Part(_Kind.operator, '×');

  /// Whether nothing has been typed.
  bool get isEmpty => _parts.isEmpty;

  /// The expression as the user reads it.
  String get text => _parts.map((part) => part.text).join();

  /// The text `NoteCalculator.evaluate` reads: computed values at full
  /// precision and every open parenthesis closed.
  String get evaluationSource =>
      closed()._parts.map((part) => part.source).join();

  /// How many `(` (including those of functions) are still open.
  int get openParentheses => _parts.fold(0, (open, part) {
    if (part.kind == _Kind.open) return open + 1;

    return part.kind == _Kind.close ? open - 1 : open;
  });

  _Part? get _last => _parts.isEmpty ? null : _parts.last;

  /// Whether the text ends in something that is a complete operand.
  bool get _endsOperand => switch (_last?.kind) {
    _Kind.digit ||
    _Kind.point ||
    _Kind.close ||
    _Kind.constant ||
    _Kind.value ||
    _Kind.percent => true,
    _ => false,
  };

  /// Whether a new operand needs a `×` first (after `%` it would mean
  /// "remainder", so no `×` is added there).
  bool get _needsTimes => switch (_last?.kind) {
    _Kind.digit ||
    _Kind.point ||
    _Kind.close ||
    _Kind.constant ||
    _Kind.value => true,
    _ => false,
  };

  /// The trailing run of digits and point.
  List<_Part> get _numeral {
    var start = _parts.length;
    while (start > 0 && _parts[start - 1].isNumeral) {
      start--;
    }

    return _parts.sublist(start);
  }

  /// Whether the last part is a `-` used as a sign rather than as an operator.
  bool get _endsInSign {
    if (_last?.text != NoteCalculatorOperator.subtract.symbol) return false;
    if (_parts.length == 1) return true;
    final before = _parts[_parts.length - 2].kind;

    return before == _Kind.open || before == _Kind.operator;
  }

  /// This expression with every open parenthesis closed.
  NoteCalculatorExpression closed() {
    final missing = openParentheses;
    if (missing <= 0) return this;

    return NoteCalculatorExpression._([
      ..._parts,
      for (var i = 0; i < missing; i++) const _Part(_Kind.close, ')'),
    ]);
  }

  /// Types the digit [digit] (`0`–`9`; others are ignored).
  NoteCalculatorExpression appendDigit(int digit) {
    if (digit < 0 || digit > 9) return this;
    final numeral = _numeral;
    var parts = _parts;
    if (numeral.isEmpty && _needsTimes) {
      parts = [...parts, _times];
    } else if (numeral.length == 1 && numeral.single.text == '0') {
      if (digit == 0) return this;
      parts = parts.sublist(0, parts.length - 1);
    }

    return NoteCalculatorExpression._([...parts, _Part(_Kind.digit, '$digit')]);
  }

  /// Types the decimal point, starting with `0.` where no number is open.
  NoteCalculatorExpression appendDecimalPoint() {
    final numeral = _numeral;
    if (numeral.any((part) => part.kind == _Kind.point)) return this;
    if (numeral.isNotEmpty) return _plus(const _Part(_Kind.point, '.'));

    return NoteCalculatorExpression._([
      ..._parts,
      if (_needsTimes) _times,
      const _Part(_Kind.digit, '0'),
      const _Part(_Kind.point, '.'),
    ]);
  }

  /// Types [operator], following the rules in the class comment.
  NoteCalculatorExpression appendOperator(NoteCalculatorOperator operator) {
    if (operator == NoteCalculatorOperator.percent) {
      final applies = _endsOperand && _last?.kind != _Kind.percent;

      return applies ? _plus(_Part(_Kind.percent, operator.symbol)) : this;
    }
    final part = _Part(_Kind.operator, operator.symbol);
    final minus = operator == NoteCalculatorOperator.subtract;
    if (_last == null || _last?.kind == _Kind.open) {
      return minus ? _plus(part) : this;
    }
    if (_endsOperand) return _plus(part);

    return _afterOperator(part, minus: minus);
  }

  NoteCalculatorExpression _afterOperator(_Part part, {required bool minus}) {
    final sign = _endsInSign;
    if (minus) {
      if (sign) return this;
      final takesSign = const {'×', '÷', '^'}.contains(_last?.text);

      return takesSign ? _plus(part) : _replaceLast(part);
    }
    if (!sign) return _replaceLast(part);
    final signFollowsOperator =
        _parts.length > 1 && _parts[_parts.length - 2].kind == _Kind.operator;
    if (!signFollowsOperator) return this;

    return NoteCalculatorExpression._([
      ..._parts.sublist(0, _parts.length - 2),
      part,
    ]);
  }

  /// Types `(`.
  NoteCalculatorExpression appendOpenParenthesis() =>
      _appendOperand(const _Part(_Kind.open, '('));

  /// Types `)` when a parenthesis is open and an operand precedes it.
  NoteCalculatorExpression appendCloseParenthesis() =>
      openParentheses > 0 && _endsOperand
      ? _plus(const _Part(_Kind.close, ')'))
      : this;

  /// Types `name(`.
  NoteCalculatorExpression appendFunction(NoteCalculatorFunction function) =>
      _appendOperand(_Part(_Kind.open, '${function.name}('));

  /// Types a constant.
  NoteCalculatorExpression appendConstant(NoteCalculatorConstant constant) =>
      _appendOperand(_Part(_Kind.constant, constant.name));

  /// Inserts a computed [value] (memory recall, previous result) as one unit:
  /// it reads like `NoteCalculator.format` shows it but is evaluated at full
  /// precision. A negative value is parenthesised so that `^` applies to it as
  /// a whole. Non-finite values are ignored.
  NoteCalculatorExpression appendValue(double value) {
    if (!value.isFinite) return this;
    final shown = NoteCalculator.format(value);
    final exact = value == 0 ? '0' : value.toString();
    final negative = value < 0;

    return _appendOperand(
      _Part(
        _Kind.value,
        negative ? '($shown)' : shown,
        negative ? '($exact)' : exact,
      ),
    );
  }

  /// Removes the last key press; a whole function or computed value counts as
  /// one.
  NoteCalculatorExpression backspace() => _parts.isEmpty
      ? this
      : NoteCalculatorExpression._(_parts.sublist(0, _parts.length - 1));

  NoteCalculatorExpression _appendOperand(_Part operand) =>
      NoteCalculatorExpression._([..._parts, if (_needsTimes) _times, operand]);

  NoteCalculatorExpression _plus(_Part part) =>
      NoteCalculatorExpression._([..._parts, part]);

  NoteCalculatorExpression _replaceLast(_Part part) => _last == part
      ? this
      : NoteCalculatorExpression._([
          ..._parts.sublist(0, _parts.length - 1),
          part,
        ]);

  @override
  bool operator ==(Object other) =>
      other is NoteCalculatorExpression && listEquals(other._parts, _parts);

  @override
  int get hashCode => Object.hashAll(_parts);

  @override
  String toString() => 'NoteCalculatorExpression($text)';
}

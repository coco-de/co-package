import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:open_note/src/note/study/utilities/note_calculator.dart';
import 'package:open_note/src/note/study/utilities/note_calculator_entry.dart';
import 'package:open_note/src/note/study/utilities/note_calculator_exception.dart';
import 'package:open_note/src/note/study/utilities/note_calculator_expression.dart';
import 'package:open_note/src/note/study/utilities/note_calculator_key.dart';

/// The state machine behind a calculator keypad.
///
/// Keys edit an expression (see [NoteCalculatorExpression] for the editing
/// rules). [equals] evaluates it: on success the result is shown and recorded
/// in [history]; on failure [error] is set and the expression stays so it can
/// be corrected. While a result is shown, a digit, function, constant, point or
/// `(` starts a new expression, an operator continues from the result (at full
/// precision) and [backspace] clears it. Any edit dismisses an error.
///
/// The memory keys evaluate the current entry and show it as the result (which
/// is not added to the history). Every method does nothing after [dispose].
class NoteCalculatorController extends ChangeNotifier {
  /// [maxHistory] bounds [history]; the oldest entries are dropped.
  NoteCalculatorController({this.maxHistory = 50}) : assert(maxHistory >= 0);

  /// The most entries [history] keeps.
  final int maxHistory;

  final List<NoteCalculatorEntry> _history = [];
  NoteCalculatorExpression _input = const NoteCalculatorExpression();
  double? _result;
  NoteCalculatorError? _error;
  double? _memory;
  bool _disposed = false;

  /// The expression typed, or, while a result is shown, the one that produced
  /// it.
  String get expression => _input.text;

  /// The value shown after [equals] (or a memory key), else `null`.
  double? get result => _result;

  /// What the main line of the display reads: the formatted result, else the
  /// expression, else `0`.
  String get display {
    final value = _result;
    if (value != null) return NoteCalculator.format(value);

    return _input.isEmpty ? '0' : _input.text;
  }

  /// Why the last evaluation failed, until the next edit.
  NoteCalculatorError? get error => _error;

  /// Whether the memory holds a value (even `0`).
  bool get hasMemory => _memory != null;

  /// The memory value, `0` when empty.
  double get memory => _memory ?? 0;

  /// Finished calculations, oldest first.
  List<NoteCalculatorEntry> get history => UnmodifiableListView(_history);

  /// Applies a key press.
  void press(NoteCalculatorKey key) {
    final digit = key.digit;
    if (digit != null) return inputDigit(digit);
    final operator = key.arithmeticOperator;
    if (operator != null) return inputOperator(operator);
    final function = key.function;
    if (function != null) return inputFunction(function);
    final constant = key.constant;
    if (constant != null) return inputConstant(constant);

    return _command(key);
  }

  void _command(NoteCalculatorKey key) {
    switch (key) {
      case NoteCalculatorKey.decimalPoint:
        inputDecimalPoint();
      case NoteCalculatorKey.openParenthesis:
        inputOpenParenthesis();
      case NoteCalculatorKey.closeParenthesis:
        inputCloseParenthesis();
      case NoteCalculatorKey.clear:
        clear();
      case NoteCalculatorKey.backspace:
        backspace();
      case NoteCalculatorKey.equals:
        equals();
      case NoteCalculatorKey.memoryClear:
        memoryClear();
      case NoteCalculatorKey.memoryRecall:
        memoryRecall();
      case NoteCalculatorKey.memoryAdd:
        memoryAdd();
      case NoteCalculatorKey.memorySubtract:
        memorySubtract();
      case _:
        break;
    }
  }

  /// Types a digit `0`–`9`.
  void inputDigit(int digit) => _type((base) => base.appendDigit(digit));

  /// Types the decimal point.
  void inputDecimalPoint() => _type((base) => base.appendDecimalPoint());

  /// Types an operator. While a result is shown, continues from it.
  void inputOperator(NoteCalculatorOperator operator) {
    final value = _result;
    if (value == null) {
      _type((base) => base.appendOperator(operator));

      return;
    }
    if (_disposed) return;
    const empty = NoteCalculatorExpression();
    _show(empty.appendValue(value).appendOperator(operator));
  }

  /// Types `(`.
  void inputOpenParenthesis() => _type((base) => base.appendOpenParenthesis());

  /// Types `)` when one is open.
  void inputCloseParenthesis() =>
      _type((base) => base.appendCloseParenthesis());

  /// Types a function and its `(`.
  void inputFunction(NoteCalculatorFunction function) =>
      _type((base) => base.appendFunction(function));

  /// Types a constant.
  void inputConstant(NoteCalculatorConstant constant) =>
      _type((base) => base.appendConstant(constant));

  /// Clears the expression, result and error. Memory and history stay.
  void clear() {
    if (_disposed) return;
    _show(const NoteCalculatorExpression());
  }

  /// Removes the last key press, or clears a shown result.
  void backspace() {
    if (_disposed) return;
    _show(
      _result == null ? _input.backspace() : const NoteCalculatorExpression(),
    );
  }

  /// Evaluates the expression, closing open parentheses first. Does nothing
  /// when the expression is empty or a result is already shown.
  void equals() {
    if (_disposed || _result != null || _input.isEmpty) return;
    final value = _evaluate();
    if (value == null) return;
    final closed = _input.closed();
    _remember(
      NoteCalculatorEntry(
        expression: closed.text,
        result: NoteCalculator.format(value),
      ),
    );
    _show(closed, result: value);
  }

  /// Forgets every history entry.
  void clearHistory() {
    if (_disposed || _history.isEmpty) return;
    _history.clear();
    notifyListeners();
  }

  /// Adds the current value to the memory. Does nothing when there is no
  /// value; an invalid expression sets [error].
  void memoryAdd() => _accumulate(1);

  /// Subtracts the current value from the memory, like [memoryAdd].
  void memorySubtract() => _accumulate(-1);

  /// Types the memory value; does nothing while the memory is empty.
  void memoryRecall() {
    final value = _memory;
    if (value == null) return;
    _type((base) => base.appendValue(value));
  }

  /// Empties the memory.
  void memoryClear() {
    if (_disposed || _memory == null) return;
    _memory = null;
    notifyListeners();
  }

  void _accumulate(int sign) {
    if (_disposed) return;
    final value = _result ?? (_input.isEmpty ? null : _evaluate());
    if (value == null) return;
    final total = (_memory ?? 0) + sign * value;
    if (!total.isFinite) {
      _show(_input, result: _result, error: NoteCalculatorError.overflow);

      return;
    }
    final changed = total != _memory || _result == null;
    _memory = total;
    _input = _input.closed();
    _result = value;
    _error = null;
    if (changed) notifyListeners();
  }

  /// Applies a keypad edit: a shown result starts a fresh expression and any
  /// error is dismissed. A key that does not apply changes nothing.
  void _type(
    NoteCalculatorExpression Function(NoteCalculatorExpression base) edit,
  ) {
    if (_disposed) return;
    final base = _result == null ? _input : const NoteCalculatorExpression();
    final next = edit(base);
    if (identical(next, base)) return;
    _show(next);
  }

  double? _evaluate() {
    try {
      return NoteCalculator.evaluate(_input.evaluationSource);
    } on NoteCalculatorException catch (failure) {
      _show(_input, error: failure.error);

      return null;
    }
  }

  void _remember(NoteCalculatorEntry entry) {
    _history.add(entry);
    if (_history.length > maxHistory) {
      _history.removeRange(0, _history.length - maxHistory);
    }
  }

  void _show(
    NoteCalculatorExpression input, {
    double? result,
    NoteCalculatorError? error,
  }) {
    if (input == _input && result == _result && error == _error) return;
    _input = input;
    _result = result;
    _error = error;
    notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    super.dispose();
  }
}

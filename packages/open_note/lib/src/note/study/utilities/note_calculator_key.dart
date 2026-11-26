import 'package:open_note/src/note/study/utilities/note_calculator_expression.dart';

/// One key of the calculator keypad.
///
/// Operator, function and constant keys share their name with the value they
/// type ([arithmeticOperator], [function], [constant]).
enum NoteCalculatorKey {
  /// The `0` key.
  digit0,

  /// The `1` key.
  digit1,

  /// The `2` key.
  digit2,

  /// The `3` key.
  digit3,

  /// The `4` key.
  digit4,

  /// The `5` key.
  digit5,

  /// The `6` key.
  digit6,

  /// The `7` key.
  digit7,

  /// The `8` key.
  digit8,

  /// The `9` key.
  digit9,

  /// The decimal point.
  decimalPoint,

  /// `+`
  add,

  /// `−`
  subtract,

  /// `×`
  multiply,

  /// `÷`
  divide,

  /// `^`
  power,

  /// `%`
  percent,

  /// `(`
  openParenthesis,

  /// `)`
  closeParenthesis,

  /// Square root.
  sqrt,

  /// Sine.
  sin,

  /// Cosine.
  cos,

  /// Tangent.
  tan,

  /// Base-10 logarithm.
  log,

  /// Natural logarithm.
  ln,

  /// Absolute value.
  abs,

  /// The constant π.
  pi,

  /// Euler's number.
  e,

  /// Clears the entry (C).
  clear,

  /// Removes the last key press.
  backspace,

  /// Evaluates the expression.
  equals,

  /// Empties the memory (MC).
  memoryClear,

  /// Types the memory value (MR).
  memoryRecall,

  /// Adds to the memory (M+).
  memoryAdd,

  /// Subtracts from the memory (M−).
  memorySubtract;

  /// The digit a digit key types, else `null`.
  int? get digit => index <= digit9.index ? index - digit0.index : null;

  /// The operator an operator key types, else `null`.
  NoteCalculatorOperator? get arithmeticOperator =>
      NoteCalculatorOperator.values.asNameMap()[name];

  /// The function a function key types, else `null`.
  NoteCalculatorFunction? get function =>
      NoteCalculatorFunction.values.asNameMap()[name];

  /// The constant a constant key types, else `null`.
  NoteCalculatorConstant? get constant =>
      NoteCalculatorConstant.values.asNameMap()[name];
}

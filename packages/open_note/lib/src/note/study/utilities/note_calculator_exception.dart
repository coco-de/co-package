/// Why a calculation failed.
enum NoteCalculatorError {
  /// The text is not a well-formed expression.
  syntax,

  /// A division, remainder or `0 ^ -n` by zero.
  divisionByZero,

  /// A function is not defined there, such as `sqrt(-1)` or `ln(0)`.
  domain,

  /// A number or result is too large to represent.
  overflow,
}

/// Thrown by `NoteCalculator.evaluate` for input it cannot evaluate.
class NoteCalculatorException implements Exception {
  /// Creates a failure of kind [error].
  const NoteCalculatorException(this.error, this.message, {this.offset});

  /// The category, for choosing a user-facing message.
  final NoteCalculatorError error;

  /// An English diagnostic for developers; not meant to be shown to users.
  final String message;

  /// Index in the input where the problem was found, when known.
  final int? offset;

  @override
  String toString() {
    final at = offset == null ? '' : ' at $offset';

    return 'NoteCalculatorException(${error.name}$at): $message';
  }
}

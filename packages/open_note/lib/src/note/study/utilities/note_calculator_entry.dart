import 'package:flutter/foundation.dart';
import 'package:open_note/src/note/core/core.dart';

/// One finished calculation in the calculator history.
///
/// JSON: `{"expression": String, "result": String}`; missing or mistyped
/// values read as `''`.
@immutable
class NoteCalculatorEntry {
  /// Records that [expression] gave [result].
  const NoteCalculatorEntry({required this.expression, required this.result});

  /// Reads [value] leniently (see the class comment).
  factory NoteCalculatorEntry.fromJson(Object? value) {
    final json = NoteJson.asMap(value) ?? const <String, Object?>{};

    return NoteCalculatorEntry(
      expression: NoteJson.string(json, 'expression'),
      result: NoteJson.string(json, 'result'),
    );
  }

  /// The expression as it was shown, with all parentheses closed.
  final String expression;

  /// The result as it was shown.
  final String result;

  /// A copy with the given values replaced.
  NoteCalculatorEntry copyWith({String? expression, String? result}) =>
      NoteCalculatorEntry(
        expression: expression ?? this.expression,
        result: result ?? this.result,
      );

  /// The JSON form described in the class comment.
  JsonMap toJson() => {'expression': expression, 'result': result};

  @override
  bool operator ==(Object other) =>
      other is NoteCalculatorEntry &&
      other.expression == expression &&
      other.result == result;

  @override
  int get hashCode => Object.hash(expression, result);

  @override
  String toString() => 'NoteCalculatorEntry($expression = $result)';
}

import 'package:flutter/foundation.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/study/overlay/note_ai_pen_kind.dart';

/// The answer of the AI pen.
///
/// JSON: `{"kind": "solve"|"explain"|"translate", "text": string, "steps":
/// list of strings}` (`steps` left out when absent). [NoteAiPenResult.fromJson] never
/// throws: an unknown kind becomes `solve`, a missing text is empty and
/// non-string steps are skipped.
@immutable
class NoteAiPenResult {
  /// Creates a result; [steps] is copied.
  NoteAiPenResult({required this.kind, required this.text, List<String>? steps})
    : steps = steps == null ? null : List.unmodifiable(steps);

  /// Reads [toJson] output.
  factory NoteAiPenResult.fromJson(Object? value) {
    final json = NoteJson.asMap(value) ?? const <String, Object?>{};

    return NoteAiPenResult(
      kind: NoteJson.enumByName(
        NoteAiPenKind.values,
        json['kind'],
        NoteAiPenKind.solve,
      ),
      text: NoteJson.string(json, 'text'),
      steps: json['steps'] is List ? NoteJson.stringList(json, 'steps') : null,
    );
  }

  /// The kind this answers.
  final NoteAiPenKind kind;

  /// The answer.
  final String text;

  /// The worked steps, in order, when the service gives them (unmodifiable).
  final List<String>? steps;

  /// [text] followed by the numbered [steps], for copying.
  String get plainText => [
    if (text.isNotEmpty) text,
    if (steps case final List<String> steps when steps.isNotEmpty)
      [
        for (var i = 0; i < steps.length; i++) '${i + 1}. ${steps[i]}',
      ].join('\n'),
  ].join('\n\n');

  /// A copy with the given fields replaced.
  NoteAiPenResult copyWith({
    NoteAiPenKind? kind,
    String? text,
    List<String>? steps,
  }) => NoteAiPenResult(
    kind: kind ?? this.kind,
    text: text ?? this.text,
    steps: steps ?? this.steps,
  );

  /// The persisted form (see the class comment).
  JsonMap toJson() => {'kind': kind.name, 'text': text, 'steps': ?steps};

  @override
  bool operator ==(Object other) =>
      other is NoteAiPenResult &&
      other.kind == kind &&
      other.text == text &&
      listEquals(other.steps, steps);

  @override
  int get hashCode =>
      Object.hash(kind, text, steps == null ? null : Object.hashAll(steps!));

  @override
  String toString() => 'NoteAiPenResult(${kind.name}, $text)';
}

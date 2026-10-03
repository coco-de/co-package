/// One authored question with a coherent subject, choices, answer and explanation.
class CoFakeExamQuestion {
  /// Constructs a question; generators use one-based answer indices.
  const CoFakeExamQuestion({
    required this.subjectName,
    required this.unitName,
    required this.section,
    required this.stem,
    required this.choices,
    required this.answerKeys,
    required this.explanation,
    required this.difficulty,
  });

  /// Localized subject name.
  final String subjectName;

  /// Localized unit name.
  final String unitName;

  /// Stable section code.
  final String section;

  /// Authored general IT-knowledge question, not a past-exam excerpt.
  final String stem;

  /// Options in display order.
  final List<String> choices;

  /// One-based correct option indices.
  final List<int> answerKeys;

  /// Authored explanation matching the correct option.
  final String explanation;

  /// Difficulty code.
  final String difficulty;

  /// Primitive `①…|②…` adapter required by PRD #666.
  String get choiceSet => List.generate(
    choices.length,
    (i) => '${['①', '②', '③', '④', '⑤'][i]}${choices[i]}',
  ).join('|');

  /// Primitive one-based answer adapter (`"2"` or `"1,3"`).
  String get answerKey => answerKeys.join(',');

  /// Primitive fixture representation.
  Map<String, Object?> toJson() => {
    'subjectName': subjectName,
    'unitName': unitName,
    'section': section,
    'questionStem': stem,
    'choices': choices,
    'answerKeys': answerKeys,
    'explanation': explanation,
    'difficulty': difficulty,
  };
}

import '../co_faker.dart';
import 'co_fake_exam_question.dart';

/// General IT questions authored for the package, not copied from exams/books.
class CoFakerExamPrep {
  /// Uses only the supplied faker.
  const CoFakerExamPrep(this.faker);

  /// Locale and shuffle source.
  final CoFaker faker;

  /// Complete recipe section set.
  static const sections = [
    'db_model',
    'db_sql',
    'nw_transport',
    'nw_routing',
    'nw_app',
    'pg_basic',
    'pg_struct',
    'sec_crypto',
    'sec_access',
  ];

  /// The texts of question `i` are entry `i` of `exam_prep.subjectName`,
  /// `unitName`, `questionStem`, `explanation`, and of the four choices
  /// `correctChoice` and `wrongChoice1..3` in the language bundles, in the
  /// order of [sections].
  static const _choiceKeys = <String>[
    'exam_prep.correctChoice',
    'exam_prep.wrongChoice1',
    'exam_prep.wrongChoice2',
    'exam_prep.wrongChoice3',
  ];

  /// Returns a question with a seeded choice shuffle and matching answer keys.
  CoFakeExamQuestion question({int? index}) {
    if (index != null && index < 0) {
      throw ArgumentError.value(index, 'index');
    }
    final slot = index == null
        ? faker.random.int(max: sections.length - 1)
        : index % sections.length;
    final l10n = faker.l10n;
    final order = [0, 1, 2, 3];
    for (var i = order.length - 1; i > 0; i--) {
      final other = faker.random.int(max: i);
      final temp = order[i];
      order[i] = order[other];
      order[other] = temp;
    }
    // Choice 0 is the correct answer before the shuffle.
    final choices = [
      for (final key in _choiceKeys) l10n.pickBalanced(key, slot),
    ];
    return CoFakeExamQuestion(
      subjectName: l10n.pickBalanced('exam_prep.subjectName', slot),
      unitName: l10n.pickBalanced('exam_prep.unitName', slot),
      section: sections[slot],
      stem: l10n.pickBalanced('exam_prep.questionStem', slot),
      choices: List.unmodifiable(order.map((i) => choices[i])),
      answerKeys: List.unmodifiable([order.indexOf(0) + 1]),
      explanation: l10n.pickBalanced('exam_prep.explanation', slot),
      difficulty: ['easy', 'normal', 'hard'][slot % 3],
    );
  }
}

import '../co_faker.dart';
import 'authored_roles.dart';
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
    String text(String key) =>
        indexedText(faker, key, slot, rows: sections.length);
    final order = [0, 1, 2, 3];
    for (var i = order.length - 1; i > 0; i--) {
      final other = faker.random.int(max: i);
      final temp = order[i];
      order[i] = order[other];
      order[other] = temp;
    }
    // Choice 0 is the correct answer before the shuffle.
    final choices = [for (final key in _choiceKeys) text(key)];
    return CoFakeExamQuestion(
      subjectName: text('exam_prep.subjectName'),
      unitName: text('exam_prep.unitName'),
      section: sections[slot],
      stem: text('exam_prep.questionStem'),
      choices: List.unmodifiable(order.map((i) => choices[i])),
      answerKeys: List.unmodifiable([order.indexOf(0) + 1]),
      explanation: text('exam_prep.explanation'),
      difficulty: ['easy', 'normal', 'hard'][slot % 3],
    );
  }
}

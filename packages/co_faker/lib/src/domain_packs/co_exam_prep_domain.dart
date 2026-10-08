import '../co_faker.dart';
import '../domain.dart';
import 'authored_roles.dart';
import 'co_fake_exam_question.dart';
import 'co_faker_exam_prep.dart';

/// Exam preparation with coherent question/choices/answer/explanation adapters.
class CoExamPrepDomain extends CoFakerDomain {
  /// Creates this pack.
  const CoExamPrepDomain();
  @override
  String get name => 'exam_prep';

  /// The roots of the unit taxonomy: `unitParent` points at them and
  /// `exam_prep.taxonomyName` names them.
  static const _unitRoots = 4;
  static CoFakeExamQuestion _question(CoFaker f, CoDomainRoleContext c) =>
      CoFakerExamPrep(f.derive('exam/question')).question(index: c.index);
  @override
  Map<String, CoDomainRole> get roles => {
    'subjectName': authoredRole(
      (f, c) => _question(f, c).subjectName,
      coherent: true,
    ),
    'unitName': authoredRole(
      (f, c) => _question(f, c).unitName,
      coherent: true,
    ),
    'questionStem': authoredRole(
      (f, c) => _question(f, c).stem,
      coherent: true,
    ),
    'choiceSet': authoredRole(
      (f, c) => _question(f, c).choiceSet,
      coherent: true,
      description: 'Proper ①…|②… adapter of CoFakeExamQuestion.choices',
    ),
    'answerKey': authoredRole(
      (f, c) => _question(f, c).answerKey,
      coherent: true,
    ),
    'explanation': authoredRole(
      (f, c) => _question(f, c).explanation,
      coherent: true,
    ),
    'difficulty': authoredRole(
      (f, c) => _question(f, c).difficulty,
      coherent: true,
    ),
    'examPaperTitle': textRole('exam_prep.examPaperTitle'),
    'studyTaskTitle': textRole('exam_prep.studyTaskTitle'),
    'nickname': firstNameRole(),
    'section': authoredRole((f, c) => _question(f, c).section, coherent: true),
    'unitParent': parentRole(_unitRoots),
    'taxonomyName': taxonomyRole('exam_prep.taxonomyName', roots: _unitRoots),
  };
  @override
  Map<String, Map<String, String>> get entities => const {
    'question': {
      'id': 'int',
      'body': 'String',
      'choices': 'String',
      'answerKeys': 'String',
      'explanation': 'String',
      'section': 'String',
      'difficulty': 'String',
      'status': 'String',
    },
    'exam_unit': {'id': 'int', 'name': 'String', 'parentId': 'int'},
    'exam_paper': {'id': 'int', 'title': 'String', 'status': 'String'},
    'exam_attempt': {'id': 'int', 'paperId': 'int', 'status': 'String'},
  };
  @override
  Map<String, Map<String, String>> get entityRoles => const {
    'question': {
      'body': 'questionStem',
      'choices': 'choiceSet',
      'answerKeys': 'answerKey',
      'explanation': 'explanation',
      'section': 'section',
      'difficulty': 'difficulty',
    },
    'exam_unit': {'name': 'taxonomyName', 'parentId': 'unitParent'},
    'exam_paper': {'title': 'examPaperTitle'},
  };
  @override
  Map<String, Map<String, List<String>>> get enums => const {
    'question': {
      'status': ['draft', 'in_review', 'approved', 'needs_fix', 'retired'],
    },
    'exam_paper': {
      'status': ['draft', 'published', 'archived'],
    },
    'exam_attempt': {
      'status': ['in_progress', 'submitted', 'expired', 'graded', 'abandoned'],
    },
  };
}

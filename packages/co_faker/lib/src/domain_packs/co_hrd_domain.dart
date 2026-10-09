import '../domain.dart';
import 'authored_roles.dart';

/// Fictional corporate training titles, employees and certificate formats.
class CoHrdDomain extends CoFakerDomain {
  /// Creates this pack.
  const CoHrdDomain();
  @override
  String get name => 'hrd';
  @override
  Map<String, CoDomainRole> get roles => {
    'departmentName': textRole('hrd.departmentName'),
    'employeeName': firstNameRole(),
    'jobTitle': textRole('hrd.jobTitle'),
    'employeeNo': codeRole('SS', width: 5),
    'courseTitle': textRole('hrd.courseTitle'),
    'courseKind': textRole('hrd.courseKind'),
    'lessonTitle': textRole('hrd.lessonTitle'),
    'chapterTitle': textRole('hrd.chapterTitle'),
    'certificateNo': authoredRole(
      (f, c) =>
          'SSL-${f.now.toUtc().year}-${(c.index + 1).toString().padLeft(4, '0')}',
    ),
    'trainingHours': intRole(1, 8),
    'nudgeTitle': textRole('hrd.nudgeTitle'),
    'exemptionReason': textRole('hrd.exemptionReason'),
    'classroomPlace': textRole('hrd.classroomPlace'),
  };
  @override
  Map<String, Map<String, String>> get entities => const {
    'employee': {
      'id': 'int',
      'employeeNo': 'String',
      'name': 'String',
      'department': 'String',
      'jobTitle': 'String',
    },
    'training_course': {
      'id': 'int',
      'title': 'String',
      'category': 'String',
      'trainingHours': 'int',
    },
    'course_assignment': {
      'id': 'int',
      'employeeId': 'int',
      'courseId': 'int',
      'status': 'String',
    },
    'completion_certificate': {
      'id': 'int',
      'assignmentId': 'int',
      'certificateNo': 'String',
    },
  };
  @override
  Map<String, Map<String, String>> get entityRoles => const {
    'employee': {
      'employeeNo': 'employeeNo',
      'name': 'employeeName',
      'department': 'departmentName',
      'jobTitle': 'jobTitle',
    },
    'training_course': {
      'title': 'courseTitle',
      'category': 'courseKind',
      'trainingHours': 'trainingHours',
    },
    'completion_certificate': {'certificateNo': 'certificateNo'},
  };
  @override
  Map<String, Map<String, List<String>>> get enums => const {
    'course_assignment': {
      'status': ['assigned', 'in_progress', 'completed', 'overdue', 'exempted'],
    },
  };
}

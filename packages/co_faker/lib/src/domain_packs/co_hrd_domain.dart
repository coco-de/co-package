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
    'departmentName': textRole(
      ['영업', '생산', '연구개발', '고객지원', '경영지원', '물류'],
      [
        'Sales',
        'Production',
        'Research',
        'Support',
        'Administration',
        'Logistics',
      ],
    ),
    'employeeName': firstNameRole(),
    'jobTitle': textRole(
      ['사원', '매니저', '팀장'],
      ['Associate', 'Manager', 'Team lead'],
    ),
    'employeeNo': codeRole('SS', width: 5),
    'courseTitle': textRole(
      ['개인정보 바르게 다루기 2026(가상)', '함께 일하는 안전 수칙(가상)', '업무 기록 정리 기초(가상)'],
      [
        'Handling personal information 2026 (fictional)',
        'Working safely together (fictional)',
        'Organizing work records (fictional)',
      ],
    ),
    'courseKind': textRole(
      ['법정의무', '직무', '리더십'],
      ['Mandatory', 'Professional', 'Leadership'],
    ),
    'lessonTitle': textRole(
      ['기본 원칙 알아보기', '업무 사례 살펴보기', '기록 확인하기'],
      ['Understand basic principles', 'Review work examples', 'Check records'],
    ),
    'chapterTitle': textRole(
      ['시작 안내', '사례 확인', '요약 정리'],
      ['Introduction', 'Example review', 'Summary'],
    ),
    'certificateNo': authoredRole(
      (f, c) =>
          'SSL-${f.now.toUtc().year}-${(c.index + 1).toString().padLeft(4, '0')}',
    ),
    'trainingHours': intRole(1, 8),
    'nudgeTitle': textRole(
      ['기한이 가까운 교육 확인(예시)', '미완료 차시 안내(예시)'],
      [
        'Training deadline reminder (example)',
        'Incomplete lesson reminder (example)',
      ],
    ),
    'exemptionReason': textRole(
      ['외부 이수 증빙 제출(예시)', '휴직 기간 확인(예시)', '대체 교육 확인(예시)'],
      [
        'External completion evidence (example)',
        'Leave-period check (example)',
        'Alternative training check (example)',
      ],
    ),
    'classroomPlace': textRole(
      ['솔빛 교육실(가상)', '가람 세미나실(가상)'],
      ['Solbit classroom (fictional)', 'Garam seminar room (fictional)'],
    ),
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

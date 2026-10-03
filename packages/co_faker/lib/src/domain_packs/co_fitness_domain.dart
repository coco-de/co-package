import '../domain.dart';
import 'authored_roles.dart';

/// Fitness class, room and pass labels for booking recipes.
class CoFitnessDomain extends CoFakerDomain {
  /// Creates this pack.
  const CoFitnessDomain();
  @override
  String get name => 'fitness';
  @override
  Map<String, CoDomainRole> get roles => {
    'className': authoredRole(
      (f, c) => localized(
        f,
        '${['매트', '리포머', '체어', '요가'][c.index % 4]} ${['기초', '중급', '상급'][c.index % 3]}',
        '${['Mat', 'Reformer', 'Chair', 'Yoga'][c.index % 4]} ${['beginner', 'intermediate', 'advanced'][c.index % 3]}',
      ),
      coherent: true,
    ),
    'classCategory': enumRole(['mat', 'reformer', 'chair', 'yoga']),
    'classLevel': enumRole(['beginner', 'intermediate', 'advanced']),
    'equipment': authoredRole(
      (f, c) => localized(
        f,
        ['매트', '리포머', '체어', '요가 블록'][c.index % 4],
        ['Mat', 'Reformer', 'Chair', 'Yoga block'][c.index % 4],
      ),
      coherent: true,
    ),
    'studioRoom': authoredRole(
      (f, c) => localized(
        f,
        ['매트룸', '리포머룸', '체어룸', '요가룸'][c.index % 4],
        ['Mat room', 'Reformer room', 'Chair room', 'Yoga room'][c.index % 4],
      ),
      coherent: true,
    ),
    'instructorSpecialty': textRole(
      ['매트 수업', '리포머 수업', '요가 수업'],
      ['Mat instruction', 'Reformer instruction', 'Yoga instruction'],
    ),
    'passName': authoredRole(
      (f, c) => localized(
        f,
        ['매트 10회권(예시)', '리포머 20회권(예시)', '1개월 이용권(예시)'][c.index % 3],
        [
          '10 mat classes (example)',
          '20 reformer classes (example)',
          'Monthly pass (example)',
        ][c.index % 3],
      ),
      coherent: true,
    ),
    'passTerm': authoredRole(
      (f, c) => [60, 180, 30][c.index % 3],
      type: 'int',
      coherent: true,
      description: 'Pass validity in days, coherent with passName: 60, 180, 30',
    ),
    'cancelReason': textRole(
      ['일정 변경', '수업 시간 변경'],
      ['Schedule changed', 'Class time changed'],
    ),
    'noShowNote': textRole(
      ['출석 확인이 없는 예시 기록입니다.', '시작 시각 이후 미출석으로 표시한 예시입니다.'],
      [
        'Example record without attendance confirmation.',
        'Example marked absent after class start.',
      ],
    ),
  };
  @override
  Map<String, Map<String, String>> get entities => const {
    'class_session': {
      'id': 'int',
      'title': 'String',
      'category': 'String',
      'level': 'String',
      'room': 'String',
      'startsAt': 'DateTime',
    },
    'class_booking': {
      'id': 'int',
      'sessionId': 'int',
      'passName': 'String',
      'status': 'String',
    },
    'membership_pass': {
      'id': 'int',
      'passName': 'String',
      'validDays': 'int',
      'status': 'String',
    },
  };
  @override
  Map<String, Map<String, String>> get entityRoles => const {
    'class_session': {
      'title': 'className',
      'category': 'classCategory',
      'level': 'classLevel',
      'room': 'studioRoom',
      'startsAt': 'booking.startsAt',
    },
    'class_booking': {'passName': 'passName'},
    'membership_pass': {'passName': 'passName', 'validDays': 'passTerm'},
  };
  @override
  Map<String, Map<String, List<String>>> get enums => const {
    'class_booking': {
      'status': [
        'waitlisted',
        'booked',
        'cancelled',
        'expired',
        'late_cancelled',
        'attended',
        'absent',
      ],
    },
    'membership_pass': {
      'status': ['active', 'paused', 'expired', 'exhausted'],
    },
  };
}

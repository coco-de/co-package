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
      (f, c) => f.l10n.format('fitness.className', {
        'category': f.l10n.pickBalanced('fitness.classCategoryLabel', c.index),
        'level': f.l10n.pickBalanced('fitness.classLevelLabel', c.index),
      }),
      coherent: true,
    ),
    'classCategory': enumRole(['mat', 'reformer', 'chair', 'yoga']),
    'classLevel': enumRole(['beginner', 'intermediate', 'advanced']),
    'equipment': indexedTextRole('fitness.equipment'),
    'studioRoom': indexedTextRole('fitness.studioRoom'),
    'instructorSpecialty': textRole('fitness.instructorSpecialty'),
    'passName': indexedTextRole('fitness.passName'),
    'passTerm': authoredRole(
      (f, c) => [60, 180, 30][c.index % 3],
      type: 'int',
      coherent: true,
      description: 'Pass validity in days, coherent with passName: 60, 180, 30',
    ),
    'cancelReason': textRole('fitness.cancelReason'),
    'noShowNote': textRole('fitness.noShowNote'),
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

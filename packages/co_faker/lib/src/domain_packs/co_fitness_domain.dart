import '../domain.dart';
import 'authored_roles.dart';

/// Fitness class, room and pass labels for booking recipes.
class CoFitnessDomain extends CoFakerDomain {
  /// Creates this pack.
  const CoFitnessDomain();
  @override
  String get name => 'fitness';

  /// The class categories and levels, and the pass terms in days: the labels,
  /// equipment, rooms, and pass names are the texts of the same rows in the
  /// language bundles (`fitness.classCategoryLabel`, `classLevelLabel`,
  /// `equipment`, `studioRoom`, `passName`).
  static const _categories = <String>['mat', 'reformer', 'chair', 'yoga'];
  static const _levels = <String>['beginner', 'intermediate', 'advanced'];
  static const _passDays = <int>[60, 180, 30];
  @override
  Map<String, CoDomainRole> get roles => {
    'className': authoredRole(
      (f, c) => f.l10n.format('fitness.className', {
        'category': indexedText(
          f,
          'fitness.classCategoryLabel',
          c.index,
          rows: _categories.length,
        ),
        'level': indexedText(
          f,
          'fitness.classLevelLabel',
          c.index,
          rows: _levels.length,
        ),
      }),
      coherent: true,
    ),
    'classCategory': enumRole(_categories),
    'classLevel': enumRole(_levels),
    'equipment': indexedTextRole('fitness.equipment', rows: _categories.length),
    'studioRoom': indexedTextRole(
      'fitness.studioRoom',
      rows: _categories.length,
    ),
    'instructorSpecialty': textRole('fitness.instructorSpecialty'),
    'passName': indexedTextRole('fitness.passName', rows: _passDays.length),
    'passTerm': authoredRole(
      (f, c) => _passDays[c.index % _passDays.length],
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

import '../co_faker.dart';
import '../domain.dart';
import 'authored_roles.dart';

/// Daycare examples: given names only, no birth/identity numbers or drug brands.
class CoDaycareDomain extends CoFakerDomain {
  /// Creates this pack.
  const CoDaycareDomain();
  @override
  String get name => 'daycare';

  /// Draws two given names and fills the template of [key] with them: `{name1}`
  /// is the first and `{name2}` the second.
  ///
  /// Both names are drawn in every language, so the stream a record sees does
  /// not depend on the language. Korean has always shown the first draw and
  /// English the second, which the two shipped templates keep; a new language
  /// writes `{name1}`.
  static String _withTwoGivenNames(CoFaker f, String key) {
    final first = f.person.firstName();
    final second = f.person.firstName();
    return f.l10n.format(key, {'name1': first, 'name2': second});
  }

  @override
  Map<String, CoDomainRole> get roles => {
    'childName': textRole('daycare.childName'),
    'className': textRole('daycare.className'),
    'ageLabel': textRole('daycare.ageLabel'),
    'guardianLabel': authoredRole(
      (f, _) => _withTwoGivenNames(f, 'daycare.guardianLabel'),
    ),
    'teacherName': authoredRole(
      (f, _) => _withTwoGivenNames(f, 'daycare.teacherName'),
    ),
    'careLogKind': enumRole([
      'arrival',
      'meal',
      'snack',
      'nap',
      'toilet',
      'activity',
      'health',
      'departure',
    ]),
    'mealLevel': enumRole(['all', 'most', 'half', 'little', 'none']),
    'moodLabel': enumRole(['bright', 'calm', 'tired', 'fussy']),
    'napMinutes': intRole(0, 150, step: 10),
    'toiletNote': textRole('daycare.toiletNote'),
    'bodyTemperature': decimalRole(36.2, 37.4),
    'mealMenu': textRole('daycare.mealMenu'),
    'snackMenu': textRole('daycare.snackMenu'),
    'allergenLabel': textRole('daycare.allergenLabel'),
    'activityTitle': textRole('daycare.activityTitle'),
    'albumCaption': textRole('daycare.albumCaption'),
    'drugLabel': textRole('daycare.drugLabel'),
    'dosageLabel': textRole('daycare.dosageLabel'),
    'pickupRelation': enumRole(['parent', 'grandparent', 'relative', 'other']),
    'noticeTitle': textRole('daycare.noticeTitle'),
  };
  @override
  Map<String, Map<String, String>> get entities => const {
    'child': {
      'id': 'int',
      'name': 'String',
      'className': 'String',
      'ageLabel': 'String',
      'teacherName': 'String',
      'avatarUrl': 'String',
    },
    'daily_note': {
      'id': 'int',
      'childId': 'int',
      'mealLevel': 'String',
      'moodLabel': 'String',
      'napMinutes': 'int',
      'bodyTemperature': 'double',
      'status': 'String',
    },
    'medication_request': {
      'id': 'int',
      'childId': 'int',
      'drugLabel': 'String',
      'dosage': 'String',
      'status': 'String',
    },
  };
  @override
  Map<String, Map<String, String>> get entityRoles => const {
    'child': {
      'name': 'childName',
      'className': 'className',
      'ageLabel': 'ageLabel',
      'teacherName': 'teacherName',
    },
    'daily_note': {
      'mealLevel': 'mealLevel',
      'moodLabel': 'moodLabel',
      'napMinutes': 'napMinutes',
      'bodyTemperature': 'bodyTemperature',
    },
    'medication_request': {'drugLabel': 'drugLabel', 'dosage': 'dosageLabel'},
  };
  @override
  Map<String, Map<String, List<String>>> get enums => const {
    'daily_note': {
      'status': ['draft', 'sent', 'confirmed'],
    },
    'medication_request': {
      'status': [
        'draft',
        'requested',
        'acknowledged',
        'administered',
        'rejected',
        'canceled',
      ],
    },
  };
}

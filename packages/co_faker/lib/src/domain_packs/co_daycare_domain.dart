import '../domain.dart';
import 'authored_roles.dart';

/// Daycare examples: given names only, no birth/identity numbers or drug brands.
class CoDaycareDomain extends CoFakerDomain {
  /// Creates this pack.
  const CoDaycareDomain();
  @override
  String get name => 'daycare';
  @override
  Map<String, CoDomainRole> get roles => {
    'childName': textRole(
      ['지우', '하늘', '다온', '나래', '소담'],
      ['Jiu', 'Haneul', 'Daon', 'Narae', 'Sodam'],
    ),
    'className': textRole(
      ['해님반', '달님반', '별님반'],
      ['Sun class', 'Moon class', 'Star class'],
    ),
    'ageLabel': textRole(
      ['만 1세', '만 2세', '만 3세', '만 4세', '만 5세'],
      ['Age 1', 'Age 2', 'Age 3', 'Age 4', 'Age 5'],
    ),
    'guardianLabel': authoredRole(
      (f, _) => localized(
        f,
        '${f.person.firstName()} 보호자',
        '${f.person.firstName()} guardian',
      ),
    ),
    'teacherName': authoredRole(
      (f, _) => localized(
        f,
        '${f.person.firstName()} 선생님',
        'Teacher ${f.person.firstName()}',
      ),
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
    'toiletNote': textRole(
      ['배변 기록 1회(예시)', '배변 기록 2회(예시)', '기록 없음(예시)'],
      [
        'One toileting record (example)',
        'Two toileting records (example)',
        'No record (example)',
      ],
    ),
    'bodyTemperature': decimalRole(36.2, 37.4),
    'mealMenu': textRole(
      ['현미밥 · 채소 스튜', '두부 국 · 밥', '채소 볶음밥'],
      [
        'Brown rice and vegetable stew',
        'Tofu soup and rice',
        'Vegetable fried rice',
      ],
    ),
    'snackMenu': textRole(
      ['배 조각', '찐 고구마', '플레인 요거트'],
      ['Pear slices', 'Steamed sweet potato', 'Plain yogurt'],
    ),
    'allergenLabel': textRole(
      ['우유', '달걀', '대두', '밀', '해당 없음(예시)'],
      ['Milk', 'Egg', 'Soy', 'Wheat', 'None noted (example)'],
    ),
    'activityTitle': textRole(
      ['겨울 눈놀이', '종이 집 만들기', '색깔 블록 놀이'],
      ['Winter snow play', 'Making paper houses', 'Color block play'],
    ),
    'albumCaption': textRole(
      ['친구와 블록을 쌓는 가상 일러스트', '겨울 놀이를 그린 가상 일러스트'],
      [
        'Fictional illustration of building blocks together',
        'Fictional winter play illustration',
      ],
    ),
    'drugLabel': textRole(
      ['해열용 시럽(가상)', '기침용 시럽(가상)', '보습용 외용제(가상)'],
      [
        'Fever syrup (fictional)',
        'Cough syrup (fictional)',
        'Moisturizing topical (fictional)',
      ],
    ),
    'dosageLabel': textRole(
      ['보호자 작성 예시: 2mL', '보호자 작성 예시: 3mL', '보호자 작성 예시: 소량'],
      [
        'Guardian-authored example: 2mL',
        'Guardian-authored example: 3mL',
        'Guardian-authored example: small amount',
      ],
    ),
    'pickupRelation': enumRole(['parent', 'grandparent', 'relative', 'other']),
    'noticeTitle': textRole(
      ['겨울 놀이 안내(예시)', '식단 변경 안내(예시)', '안전 확인 안내(예시)'],
      [
        'Winter play notice (example)',
        'Meal change notice (example)',
        'Safety check notice (example)',
      ],
    ),
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

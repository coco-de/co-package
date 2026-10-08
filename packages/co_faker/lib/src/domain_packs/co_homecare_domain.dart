import 'dart:convert';
import '../co_faker.dart';
import '../domain.dart';
import 'authored_roles.dart';
import 'co_fake_vital_reading.dart';

/// Home-care roles with masked recipients and bounded vital examples.
class CoHomecareDomain extends CoFakerDomain {
  /// Creates this pack.
  const CoHomecareDomain();
  @override
  String get name => 'homecare';

  /// The kind of each care task; its label is `homecare.careTaskLabel` in the
  /// language bundles, in the same order.
  static const _careTaskKinds = <String>[
    'meal',
    'medication',
    'hygiene',
    'mobility',
    'toileting',
    'emotional',
  ];
  static CoFakeVitalReading _vital(CoFaker f) =>
      CoFakeVitalReading.generate(f.derive('homecare/vital'));
  @override
  Map<String, CoDomainRole> get roles => {
    'recipientName': maskedNameRole(),
    'careGrade': textRole('homecare.careGrade'),
    'careTaskLabel': indexedTextRole(
      'homecare.careTaskLabel',
      rows: _careTaskKinds.length,
    ),
    'careTaskKind': enumRole(_careTaskKinds),
    'vitalReading': authoredRole(
      (f, _) => jsonEncode(_vital(f).toJson()),
      coherent: true,
      description:
          'JSON pressure pair and bounded vitals; CoFakeVitalReading.generate for typed values',
    ),
    'remarkKind': enumRole([
      'fall_risk',
      'appetite',
      'skin',
      'mood',
      'sleep',
      'other',
    ]),
    'caregiverName': firstNameRole(),
    'visitKind': enumRole(['home_care', 'bathing', 'nursing_visit']),
    'guardianRelation': enumRole(['child', 'spouse', 'sibling', 'other']),
    'serviceMinutes': authoredRole(
      (f, _) => f.random.pick([60, 90, 120, 180]),
      type: 'int',
    ),
    'systolic': authoredRole(
      (f, _) => _vital(f).systolic,
      type: 'int',
      coherent: true,
    ),
    'diastolic': authoredRole(
      (f, _) => _vital(f).diastolic,
      type: 'int',
      coherent: true,
    ),
    'pulse': authoredRole(
      (f, _) => _vital(f).pulse,
      type: 'int',
      coherent: true,
    ),
    'bodyTemperature': authoredRole(
      (f, _) => _vital(f).bodyTemperature,
      type: 'double',
      coherent: true,
    ),
    'bloodGlucose': authoredRole(
      (f, _) => _vital(f).bloodGlucose,
      type: 'int',
      coherent: true,
    ),
  };
  @override
  Map<String, Map<String, String>> get entities => const {
    'care_recipient': {'id': 'int', 'name': 'String', 'careGrade': 'String'},
    'care_visit': {
      'id': 'int',
      'recipientId': 'int',
      'recipientName': 'String',
      'caregiverName': 'String',
      'visitKind': 'String',
      'durationMinutes': 'int',
      'status': 'String',
    },
    'vital_sign': {
      'id': 'int',
      'recipientId': 'int',
      'systolic': 'int',
      'diastolic': 'int',
      'pulse': 'int',
      'bodyTemperature': 'double',
      'bloodGlucose': 'int',
      'measuredAt': 'DateTime',
    },
  };
  @override
  Map<String, Map<String, String>> get entityRoles => const {
    'care_recipient': {'name': 'recipientName', 'careGrade': 'careGrade'},
    'care_visit': {
      'recipientName': 'recipientName',
      'caregiverName': 'caregiverName',
      'visitKind': 'visitKind',
      'durationMinutes': 'serviceMinutes',
    },
    'vital_sign': {
      'systolic': 'systolic',
      'diastolic': 'diastolic',
      'pulse': 'pulse',
      'bodyTemperature': 'bodyTemperature',
      'bloodGlucose': 'bloodGlucose',
    },
  };
  @override
  Map<String, Map<String, List<String>>> get enums => const {
    'care_visit': {
      'status': [
        'unassigned',
        'assigned',
        'in_visit',
        'completed',
        'confirmed',
        'missed',
        'canceled',
      ],
    },
  };
}

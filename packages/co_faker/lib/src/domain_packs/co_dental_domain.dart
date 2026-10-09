import '../domain.dart';
import 'authored_roles.dart';

/// Dental planning labels and valid FDI adult-tooth numbers.
class CoDentalDomain extends CoFakerDomain {
  /// Creates this pack.
  const CoDentalDomain();
  @override
  String get name => 'dental';
  @override
  Map<String, CoDomainRole> get roles => {
    'toothNumber': authoredRole(
      (f, _) =>
          '${f.number.int(min: 1, max: 4)}${f.number.int(min: 1, max: 8)}',
      type: 'String',
      description: 'FDI adult tooth: quadrant 1..4, position 1..8',
    ),
    'dentalProcedure': textRole('dental.dentalProcedure'),
    'dentalMaterial': textRole('dental.dentalMaterial'),
    'imageKind': enumRole([
      'panorama',
      'periapical',
      'intraoral_photo',
      'cephalometric',
    ]),
    'recallInterval': authoredRole(
      (f, _) => f.random.pick([3, 6, 12]),
      type: 'int',
      description: 'Recall interval in months: 3, 6, 12',
    ),
    'chairName': textRole('dental.chairName'),
    'hygieneNote': textRole('dental.hygieneNote'),
    'treatmentStage': enumRole(['planned', 'in_progress', 'done']),
  };
  @override
  Map<String, Map<String, String>> get entities => const {
    'plan_item': {
      'id': 'int',
      'planId': 'int',
      'procedureName': 'String',
      'toothNumber': 'String',
      'material': 'String',
    },
    'treatment_step': {
      'id': 'int',
      'planId': 'int',
      'toothNumber': 'String',
      'stage': 'String',
    },
    'dental_image': {
      'id': 'int',
      'planId': 'int',
      'imageKind': 'String',
      'imageUrl': 'String',
    },
    'treatment_plan': {'id': 'int', 'status': 'String'},
  };
  @override
  Map<String, Map<String, String>> get entityRoles => const {
    'plan_item': {
      'procedureName': 'dentalProcedure',
      'toothNumber': 'toothNumber',
      'material': 'dentalMaterial',
    },
    'treatment_step': {'toothNumber': 'toothNumber', 'stage': 'treatmentStage'},
    'dental_image': {'imageKind': 'imageKind'},
  };
  @override
  Map<String, Map<String, List<String>>> get enums => const {
    'treatment_plan': {
      'status': [
        'counseling',
        'awaiting_consent',
        'consented',
        'in_treatment',
        'completed',
        'on_hold',
      ],
    },
  };
}

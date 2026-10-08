import '../co_faker.dart';
import '../domain.dart';
import 'authored_roles.dart';
import 'co_fake_pet.dart';
import 'co_faker_vet.dart';

/// Veterinary labels with fictional unbranded medicine examples.
class CoVetDomain extends CoFakerDomain {
  /// Creates the pack.
  const CoVetDomain();
  @override
  String get name => 'vet';
  static CoFakePet _pet(CoFaker f, CoDomainRoleContext c) {
    // A coprime stride spreads the 60/35/5 schedule through small batches;
    // the first 40 pets must not all become dogs while a 100-row cycle remains
    // exactly weighted and still covers every species.
    final slot = (c.index * 37) % 100;
    final kind = slot < 60
        ? 'dog'
        : slot < 95
        ? 'cat'
        : CoFakerVet.animalKinds[2 + (slot - 95) % 3];
    return CoFakerVet(f.derive('vet/pet')).pet(animalKind: kind);
  }

  @override
  Map<String, CoDomainRole> get roles => {
    'petName': authoredRole((f, c) => _pet(f, c).name, coherent: true),
    'animalKind': authoredRole((f, c) => _pet(f, c).animalKind, coherent: true),
    'breed': authoredRole((f, c) => _pet(f, c).breed, coherent: true),
    'coatColor': authoredRole((f, c) => _pet(f, c).coatColor, coherent: true),
    'weightKg': authoredRole(
      (f, c) => _pet(f, c).weightKg,
      type: 'double',
      coherent: true,
    ),
    'vaccineName': textRole('vet.vaccineName'),
    'preventiveProduct': textRole('vet.preventiveProduct'),
    'vetDiagnosis': textRole('vet.vetDiagnosis'),
    'vetDrug': textRole('vet.vetDrug'),
    'clinicRoom': textRole('vet.clinicRoom'),
  };
  @override
  Map<String, Map<String, String>> get entities => const {
    'pet': {
      'id': 'int',
      'guardianId': 'int',
      'name': 'String',
      'animalKind': 'String',
      'breed': 'String',
      'coatColor': 'String',
      'weightKg': 'double',
      'sex': 'String',
      'photoUrl': 'String',
    },
    'vet_visit': {
      'id': 'int',
      'petId': 'int',
      'petName': 'String',
      'roomName': 'String',
      'visitReason': 'String',
      'status': 'String',
    },
    'vaccination': {
      'id': 'int',
      'petId': 'int',
      'vaccineName': 'String',
      'dueDate': 'DateTime',
      'done': 'bool',
    },
  };
  @override
  Map<String, Map<String, String>> get entityRoles => const {
    'pet': {
      'name': 'petName',
      'animalKind': 'animalKind',
      'breed': 'breed',
      'coatColor': 'coatColor',
      'weightKg': 'weightKg',
    },
    'vet_visit': {'petName': 'petName', 'roomName': 'clinicRoom'},
    'vaccination': {'vaccineName': 'vaccineName'},
  };
  @override
  Map<String, Map<String, List<String>>> get enums => const {
    'pet': {
      'animalKind': CoFakerVet.animalKinds,
      'sex': ['male', 'female'],
    },
    'vet_visit': {
      'visitReason': [
        'vaccination',
        'checkup',
        'skin',
        'digestive',
        'injury',
        'dental',
        'other',
      ],
      'status': [
        'booked',
        'arrived',
        'in_treatment',
        'awaiting_payment',
        'completed',
        'canceled',
        'no_show',
      ],
    },
  };
}

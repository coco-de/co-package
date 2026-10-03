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
    'vaccineName': textRole(
      ['종합백신(예시)', '광견병 예방접종(예시)', '고양이 종합백신(예시)'],
      [
        'Combination vaccine (example)',
        'Rabies vaccination (example)',
        'Feline combination vaccine (example)',
      ],
    ),
    'preventiveProduct': textRole(
      ['심장사상충 예방용 예시제(가상)', '외부 기생충 예방용 예시제(가상)'],
      [
        'Heartworm preventive example (fictional)',
        'External parasite preventive example (fictional)',
      ],
    ),
    'vetDiagnosis': textRole(
      ['피부 상태 관찰(예시)', '소화 상태 확인(예시)', '정기 건강 확인(예시)'],
      [
        'Skin observation (example)',
        'Digestive observation (example)',
        'Routine health observation (example)',
      ],
    ),
    'vetDrug': textRole(
      ['피부 관리 예시제(가상)', '소화 관리 예시제(가상)', '눈 관리 예시제(가상)'],
      [
        'Skin care example (fictional)',
        'Digestive care example (fictional)',
        'Eye care example (fictional)',
      ],
    ),
    'clinicRoom': textRole(
      ['동물 진료실 1', '동물 진료실 2', '예방접종실'],
      ['Vet room 1', 'Vet room 2', 'Vaccination room'],
    ),
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

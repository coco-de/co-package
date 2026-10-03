import '../co_faker.dart';
import 'authored_roles.dart';
import 'co_fake_pet.dart';

/// Offline species, breed and weight dictionaries.
class CoFakerVet {
  /// Uses only the supplied faker.
  const CoFakerVet(this.faker);

  /// Locale and random source.
  final CoFaker faker;

  /// Supported species codes.
  static const animalKinds = ['dog', 'cat', 'small_mammal', 'bird', 'reptile'];
  static const _breeds = <String, List<(String, String, double, double)>>{
    'dog': [
      ('말티즈', 'Maltese', 2.0, 5.0),
      ('푸들', 'Poodle', 2.0, 12.0),
      ('믹스견', 'Mixed dog', 3.0, 35.0),
    ],
    'cat': [
      ('코리안숏헤어', 'Domestic shorthair', 2.5, 6.5),
      ('믹스묘', 'Mixed cat', 2.0, 6.0),
    ],
    'small_mammal': [
      ('토끼', 'Rabbit', 0.6, 3.0),
      ('햄스터', 'Hamster', 0.03, 0.18),
    ],
    'bird': [('소형 앵무', 'Small parrot', 0.03, 0.15)],
    'reptile': [('육지거북', 'Tortoise', 0.2, 4.0)],
  };

  /// Valid breeds for a species, useful for recipe consistency checks.
  List<String> breeds(String animalKind) {
    final values = _breeds[animalKind];
    if (values == null) {
      throw ArgumentError.value(animalKind, 'animalKind');
    }
    return values
        .map((b) => localized(faker, b.$1, b.$2))
        .toList(growable: false);
  }

  /// Selects dog 60%, cat 35%, other 5% unless a species is supplied.
  CoFakePet pet({String? animalKind}) {
    final roll = faker.random.int(max: 99);
    final kind =
        animalKind ??
        (roll < 60
            ? 'dog'
            : roll < 95
            ? 'cat'
            : faker.random.pick<String>(animalKinds.sublist(2)));
    final breeds = _breeds[kind];
    if (breeds == null) {
      throw ArgumentError.value(kind, 'animalKind');
    }
    final breed = faker.random.pick(breeds);
    return CoFakePet(
      name: faker.random.pick(
        faker.locale.startsWith('ko')
            ? ['보리', '나비', '두부', '콩이', '구름']
            : ['Barley', 'Butterfly', 'Tofu', 'Bean', 'Cloud'],
      ),
      animalKind: kind,
      breed: localized(faker, breed.$1, breed.$2),
      coatColor: faker.random.pick(
        faker.locale.startsWith('ko')
            ? ['흰색', '갈색', '검정', '삼색', '회색']
            : ['White', 'Brown', 'Black', 'Tricolor', 'Gray'],
      ),
      weightKg: faker.number.decimal(min: breed.$3, max: breed.$4, decimals: 2),
    );
  }
}

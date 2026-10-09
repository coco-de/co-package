import 'package:co_demo_world/co_demo_world.dart';

/// The reference inputs shared by the tests.
final DemoWorldConfig sampleConfig = DemoWorldConfig(
  seed: 436,
  now: DateTime.utc(2026, 1, 15, 0, 30),
);

/// A pet record holding only business data (A).
class SamplePet {
  /// Creates a pet.
  const SamplePet({
    required this.id,
    required this.weightGrams,
    required this.status,
    required this.priceWon,
  });

  /// Stable id.
  final String id;

  /// Business number.
  final int weightGrams;

  /// Business status code.
  final String status;

  /// Business amount in KRW.
  final int priceWon;

  @override
  bool operator ==(Object other) =>
      other is SamplePet &&
      other.id == id &&
      other.weightGrams == weightGrams &&
      other.status == status &&
      other.priceWon == priceWon;

  @override
  int get hashCode => Object.hash(id, weightGrams, status, priceWon);

  @override
  String toString() => 'SamplePet($id, $weightGrams g, $status, ₩$priceWon)';
}

/// Builds the business data of a small world from the business stream only.
List<SamplePet> buildSamplePets(DemoWorldConfig config, {int count = 8}) {
  final faker = config.businessFaker(key: 'pets');
  return [
    for (var index = 1; index <= count; index++)
      SamplePet(
        id: 'pet-${index.toString().padLeft(4, '0')}',
        weightGrams: faker.random.int(min: 800, max: 40000),
        status: faker.random.pick(const ['booked', 'visited', 'vaccinated']),
        priceWon: faker.random.int(min: 10, max: 500) * 1000,
      ),
  ];
}

/// The display fields of the sample world.
DisplayFieldSet sampleFields({void Function(DisplayKey key)? onGenerate}) {
  String track(DisplayKey key, String value) {
    onGenerate?.call(key);
    return value;
  }

  return DisplayFieldSet({
    'pet.name': (faker, key) => track(key, faker.vet.pet().name),
    'guardian.name': (faker, key) => track(key, faker.person.fullName()),
    'guardian.city': (faker, key) => track(key, faker.address.city()),
    'note.text': (faker, key) => track(key, faker.text.sentence()),
  });
}

/// Every display key of [pets].
List<DisplayKey> sampleKeys(List<SamplePet> pets) => [
  for (final pet in pets) ...[
    DisplayKey('pet', pet.id, 'name'),
    DisplayKey('guardian', pet.id, 'name'),
    DisplayKey('guardian', pet.id, 'city'),
    DisplayKey('note', pet.id, 'text'),
  ],
];

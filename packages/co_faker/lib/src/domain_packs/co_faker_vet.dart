import '../co_faker.dart';
import 'co_fake_pet.dart';

/// Offline species, breed and weight dictionaries.
class CoFakerVet {
  /// Uses only the supplied faker.
  const CoFakerVet(this.faker);

  /// Locale and random source.
  final CoFaker faker;

  /// Supported species codes.
  static const animalKinds = ['dog', 'cat', 'small_mammal', 'bird', 'reptile'];

  /// Minimum and maximum weight in kg of each breed of a species; the breed
  /// names are `vet.breed.<species>` in the language bundles, in the same
  /// order.
  static const _breedWeights = <String, List<(double, double)>>{
    'dog': [(2.0, 5.0), (2.0, 12.0), (3.0, 35.0)],
    'cat': [(2.5, 6.5), (2.0, 6.0)],
    'small_mammal': [(0.6, 3.0), (0.03, 0.18)],
    'bird': [(0.03, 0.15)],
    'reptile': [(0.2, 4.0)],
  };

  /// Valid breeds for a species, useful for recipe consistency checks.
  List<String> breeds(String animalKind) {
    if (!_breedWeights.containsKey(animalKind)) {
      throw ArgumentError.value(animalKind, 'animalKind');
    }
    return faker.l10n.list('vet.breed.$animalKind').toList(growable: false);
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
    final weights = _breedWeights[kind];
    if (weights == null) {
      throw ArgumentError.value(kind, 'animalKind');
    }
    // The same draw as `faker.random.pick` over the breeds of the species.
    final breed = faker.random.int(max: weights.length - 1);
    return CoFakePet(
      name: faker.l10n.pick('vet.petName'),
      animalKind: kind,
      breed: faker.l10n.list('vet.breed.$kind')[breed],
      coatColor: faker.l10n.pick('vet.coatColor'),
      weightKg: faker.number.decimal(
        min: weights[breed].$1,
        max: weights[breed].$2,
        decimals: 2,
      ),
    );
  }
}

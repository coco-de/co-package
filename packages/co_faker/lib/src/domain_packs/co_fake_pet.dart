/// A coherent fictional pet profile, rather than independent species/breed picks.
class CoFakePet {
  /// Creates a generated pet profile.
  const CoFakePet({
    required this.name,
    required this.animalKind,
    required this.breed,
    required this.coatColor,
    required this.weightKg,
  });

  /// Fictional pet name.
  final String name;

  /// Species code (dog/cat/small_mammal/bird/reptile).
  final String animalKind;

  /// Breed belonging to [animalKind].
  final String breed;

  /// Localized coat description.
  final String coatColor;

  /// Illustrative weight within the breed's range, not a clinical judgement.
  final double weightKg;

  /// Primitive fixture adapter.
  Map<String, Object?> toJson() => {
    'name': name,
    'animalKind': animalKind,
    'breed': breed,
    'coatColor': coatColor,
    'weightKg': weightKg,
  };
}

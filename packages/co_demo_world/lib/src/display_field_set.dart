import 'package:co_faker/co_faker.dart';

import 'display_key.dart';

/// Generates one display value.
///
/// [faker] is already derived for [key] (an independent stream per
/// entity/id/field) and set to the display language, so the generator only
/// picks values. [key] lets a generator read the entity's business data
/// (for example its sex, to pick a matching given name) from the demo world.
typedef DisplayGenerator = String Function(CoFaker faker, DisplayKey key);

/// The display fields a demo generates, each with the one generator that owns
/// it, keyed `entity.field` (for example `pet.name`).
///
/// Registering generators up front keeps one field = one generator (two call
/// sites cannot produce different values for the same key), and gives
/// [DemoLocaleSupport] the exact list of fields the demo consumes.
class DisplayFieldSet {
  /// Creates a field set from `entity.field` → generator.
  DisplayFieldSet(Map<String, DisplayGenerator> generators)
    : generators = Map<String, DisplayGenerator>.unmodifiable(generators) {
    for (final key in generators.keys) {
      final parts = key.split('.');
      if (parts.length != 2 || parts.any((part) => part.isEmpty)) {
        throw ArgumentError.value(key, 'generators', 'keys are entity.field');
      }
    }
  }

  /// `entity.field` → generator.
  final Map<String, DisplayGenerator> generators;

  /// The generator for [fieldKey] (`entity.field`).
  ///
  /// Throws a [StateError] for an unregistered field, so a typo fails loudly
  /// instead of silently showing an empty value.
  DisplayGenerator generatorFor(String fieldKey) {
    final generator = generators[fieldKey];
    if (generator == null) {
      throw StateError(
        'No display generator for "$fieldKey". Registered: '
        '${generators.keys.join(', ')}',
      );
    }
    return generator;
  }
}

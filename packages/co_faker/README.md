# co_faker

Pure Dart fake data for tests, fixtures, prototypes, local development, and
database seed scripts. It does not start a server, make network requests, or
depend on Flutter.

## Why co_faker

- Deterministic output with `seed`, so snapshots and tests stay reproducible.
- Fluent modules such as `faker.person`, `faker.address`, and `faker.internet`.
- Batch and schema helpers for creating typed or map-based fixture data.
- Built-in English, Korean, Japanese, Chinese, Spanish, French, and German
  data with language fallback.
- Partial custom locales can override only the data a project needs.
- No runtime dependencies.

## Install

```yaml
dependencies:
  co_faker: ^0.1.0
```

## Quick start

```dart
import 'package:co_faker/co_faker.dart';

void main() {
  final faker = CoFaker(locale: 'ko', seed: 42);

  print(faker.person.fullName());
  print(faker.internet.email());
  print(faker.address.fullAddress());
  print(faker.text.sentence());
  print(faker.commerce.productName());
}
```

`CoFaker` uses one random stream. Reusing the same seed creates the same
sequence, which is useful for tests and local fixtures.

## Fixtures Without A Server

Use `generate` for typed records and `object` for JSON-like maps:

```dart
final faker = CoFaker(seed: 7);

final users = faker.generate(20, (faker, index) {
  return UserFixture(
    id: faker.id.uuid(),
    name: faker.person.fullName(),
    email: faker.internet.email(),
    index: index,
  );
});

final product = faker.object({
  'id': (_) => faker.id.uuid(),
  'name': (_) => faker.commerce.productName(),
  'price': (_) => faker.commerce.price(),
});
```

The package only creates values in memory. A fixture can be passed directly to
a repository, a widget, a test subject, or a seed script.

## Locales

```dart
final korean = CoFaker(locale: 'ko');
final regional = CoFaker(locale: 'ko_KR'); // falls back to `ko`
final french = CoFaker(locale: 'fr');

print(korean.person.fullName());
print(french.address.city());
```

Regional locale resolution is exact code, language code, then English. Add a
partial locale without implementing every category:

```dart
final custom = CoFaker(
  locale: 'acme',
  locales: {
    'acme': const CoFakerLocale(
      code: 'acme',
      firstNames: ['Ada', 'Linus'],
      lastNames: ['Example'],
      nameFormat: '{first} {last}',
    ),
  },
);
```

Missing lists use English data. The locale data is immutable by convention and
can be shared between generators.

## Template Sugar

```dart
final message = faker.fake(
  'Hello {{person.firstName}}, contact {{internet.email}} in {{address.city}}.',
);
```

Unknown placeholders are kept as-is. Project-specific placeholders can be
added without subclassing:

```dart
final value = faker.fake(
  '{{orderNumber}}',
  custom: {
    'orderNumber': (faker) => 'ORD-${faker.number.int(min: 1000, max: 9999)}',
  },
);
```

## Development

From the repository root:

```bash
dart pub get
dart pub global activate melos
melos run verify
```

## License

BSD-3-Clause (Cocode Inc.)

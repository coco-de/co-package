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
  co_faker: ^0.2.0
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
sequence, which is useful for tests and local fixtures. Pass `now` as well
when dates must be repeatable: the `date` module measures from that clock.

## Records From A Schema

`faker.schema` turns a field schema (the shape used by entity manifests and
code generators) into records. Roles such as name, email, price, image, or
date are inferred from the field names and can be forced per field:

```dart
final faker = CoFaker(locale: 'ko', seed: 7, now: DateTime.utc(2026));

final course = faker.schema(
  {
    'title': 'String',
    'instructor': 'String',
    'price': 'int',
    'startsAt': 'DateTime?',
    'thumbnailUrl': 'String',
    'status': 'String',
  },
  index: 0,
  enums: {'status': ['draft', 'open', 'closed']},
  roles: {'title': 'productName'},
  entity: 'course',
);

final courses = faker.schema.records(20, fields, streamKey: 'course');
```

- Every field draws from its own derived stream, so adding or removing a
  field never changes the other values.
- Enum fields cycle through their values by index, so every value appears.
- Dates are generated in UTC and serialized with a `Z` suffix on `String`
  fields.
- `referenceCounts: {'courseId': 20}` bounds foreign keys; `entity` decides
  whether a bare `name` field is a person's name or a title.
- `faker.schema.infer('dueAt', type: 'DateTime')` exposes the inferred
  `CoFieldRole` for tooling.

## Derived Streams And Balanced Picks

```dart
final base = CoFaker(seed: 42);
final titles = base.derive('course/title'); // independent of `base`
final prices = base.derive('course/price');

final status = base.random.pickBalanced(['draft', 'open', 'closed'], index);
```

`derive` never consumes the parent stream, and the same seed and key always
produce the same derived stream. `pickBalanced` cycles by index and does not
consume the stream either.

## Offline Images And UTC Dates

```dart
faker.image.placeholderDataUri(width: 640, height: 480, label: 'Cover');
faker.image.avatarDataUri(size: 96); // initials from a localized first name
faker.date.past(days: 30, utc: true).toIso8601String(); // ends with `Z`
```

`placeholderDataUri` and `avatarDataUri` embed an SVG in the value, so widget
tests, golden files, and static demos render without any request.
`avatarUrl` and `placeholderUrl` still point at public placeholder services.

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

## Pinning Before A pub.dev Release

Until the package is published, depend on it by git reference and pin the
same commit everywhere values must match (a generator, the generated code,
and its golden files):

```yaml
dependencies:
  co_faker:
    git:
      url: https://github.com/coco-de/co-package.git
      path: packages/co_faker
      ref: <commit>
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

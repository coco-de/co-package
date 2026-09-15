## 0.2.0

- Add `faker.schema(...)` / `CoFakerSchema`: generate records from a field
  schema (`{'title': 'String', 'price': 'int', 'startsAt': 'DateTime?'}`)
  with role inference from field names, forced roles, enum cycling,
  reference bounds, per-field derived streams, and type coercion.
- Add `CoFaker.derive(key)` and `CoRandom.derive(key)`: independent random
  streams derived from the base seed so adding a field never changes other
  values. Expose `CoFaker.seed` and `CoRandom.deriveSeed`.
- Add `CoRandom.pickBalanced(items, index)`: cycle through items by index
  without consuming the stream, so every enum value appears in a fixture.
- Add a `utc` option to `date.between`, `date.past`, `date.future`, and
  `date.dateOfBirth` so serialized dates carry a `Z` suffix.
- Add `image.placeholderDataUri(...)` and `image.avatarDataUri(...)`: offline
  SVG data URIs that render in widget tests, golden files, and static demos
  without a network request.
- Expand the Korean locale (50 given names, 30 family names, 20 cities, 100
  words, 30 product nouns, 18 categories, more companies and job titles).
- Export the module, random source, and schema types from the package barrel.
- Add `commerce.category` and `image.placeholderDataUri` template
  placeholders.

## 0.1.0

- Add deterministic fake data generation with seeded random streams.
- Add English, Korean, Japanese, Chinese, Spanish, French, and German locales.
- Add locale fallback, partial custom locales, fixture batches, schema objects,
  and template interpolation.

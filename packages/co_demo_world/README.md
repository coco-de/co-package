# co_demo_world

Deterministic demo worlds whose **generated display text follows the UI
language**. When a visitor switches a running demo from Korean to Japanese,
the screens *and* the co_faker sample data (people, places, products,
messages) change to Japanese — without restarting the app, without touching
business data, and without losing what the visitor typed.

Pure Dart (no Flutter dependency): demo apps, consoles, Widgetbook catalogs,
golden tests, BDD steps and server seeds use the same contract. It builds on
[co_faker](../co_faker) and [co_demo_prefs](../co_demo_prefs).

Requirement source: coco-de/cocode#1065 (Project coco-de/cocode#637).

## Three kinds of data

| Kind | Examples | On a language switch |
|---|---|---|
| **A — business** | ids, relations, record counts, default order, status codes, permissions, revisions, amounts, currency, stock, booking times, results of user actions | **unchanged** — codes stay, only labels and formatting follow the language |
| **B — display** | fictional people and organization names, product and course names, address lines, generated messages and notes, domain labels | **re-projected** into the new language |
| **C — user input** | values being typed, notes the visitor wrote, names they edited | **unchanged** — and shown instead of B |

The UI language never changes the business country, jurisdiction, currency or
time zone. Fixed-language documents (for example a statutory receipt) are
per-field exceptions the demo records itself.

## Usage

```dart
import 'package:co_demo_world/co_demo_world.dart';

final config = DemoWorldConfig(
  seed: 436,
  now: DateTime.utc(2026, 1, 15),          // the demo's "today"
  businessLocale: 'ko', currencyCode: 'KRW', timeZone: 'Asia/Seoul',
);

// A — business data, once, on the business stream (never the UI language).
final faker = config.businessFaker(key: 'pets');
final pets = [
  for (var i = 1; i <= 20; i++)
    Pet(id: 'pet-$i', weightGrams: faker.random.int(min: 800, max: 40000)),
];

// B — one generator per display field, keyed entity.field.
final projector = DisplayProjector(
  config: config,
  fields: DisplayFieldSet({
    'pet.name': (f, key) => f.vet.pet().name,
    'guardian.name': (f, key) => f.person.fullName(),
  }),
);
projector.text(DisplayKey('pet', 'pet-1', 'name'));   // 나비 · Butterfly · …

// C — user edits win and survive language switches.
projector.overlay.set(DisplayKey('pet', 'pet-1', 'name'), '보리둥이');
```

### Live language switch (Flutter)

```dart
final switcher = DemoLocaleSwitcher(
  initial: DemoFakerLocales.resolve(DemoPrefs.fromUri(Uri.base).locale?.tag).locale,
  // Optional: warm what is on screen, or load deferred data.
  prepare: (locale) => projector.warm(visibleKeys(), locale),
  // UI language and display data change in the same step.
  onCommit: (_, next) {
    projector.locale = next;
    appLocale.value = next;       // your locale signal → MaterialApp.locale
  },
);
DemoEmbedSync(allowLocalhost: kDebugMode).start((prefs) {
  final locale = prefs.locale;
  if (locale != null) switcher.request(locale);   // only the latest wins
});
```

- Rebuild text from `projector.text(key)` in `build` — reads are pure and
  memoized; they never write, reseed or notify.
- Keep routes, selections, carts, form state, search, filters and paging in
  their own state; a language switch does not touch them.
- Search and sort by display text with `projector.searchText(keys)`, which
  follows the current language.
- Format A values with `DemoFormat.money` / `decimal` / `date` (call
  `DemoFormat.ensureInitialized()` once): same amount and currency, the
  language's separators, ASCII digits everywhere.
- `DemoLocaleSwitcher.isSwitching` is `true` while a request is preparing —
  show a loading state instead of mixing the new UI language with old data.

## Determinism

- A display value is a pure function of
  (seed, clock, language, entity, id, field). Each value draws from its own
  stream, `derive('entity/id/field')` on the display seed, so the order of
  reads never matters and switching back to a language shows the same text.
- The business and display streams are derived from the seed with different
  keys: projecting in any language never consumes business draws.
- Keys use the entity **id**, never its list position.
- The language is not part of the derivation key: where co_faker's word lists
  are aligned across languages, the same record comes out translated
  (나비 ↔ Butterfly ↔ ちょうちょ).
- VM, dart2js and dart2wasm produce the same values (`platform_parity_test`).
  This relies on co_faker's platform-independent `deriveSeed` (co-package#69).

## Languages

`DemoFakerLocales.table` maps the eleven UI languages of co_demo_prefs to
co_faker locales: `ko`→`ko`, `en`→`en_US`, `zh-Hans`→`zh_CN`, `ja`→`ja_JP`,
`de`→`de_DE`, `fr`→`fr_FR`, `es`→`es_ES`, `pt`→`pt_BR`, `it`→`it_IT`,
`ru`→`ru_RU`, `ar`→`ar_SA`. `DemoFakerLocales.resolve(tag)` never throws: a
missing, unsupported or Traditional Chinese tag resolves to the fallback and
says why.

Requesting a locale proves nothing — co_faker silently falls back to English
for data it does not have. `DemoLocaleSupport.evaluate` measures the fields a
demo actually consumes in all eleven languages and `markdownTable` renders the
support table each demo keeps in its repository. Measured with co_faker after
co-package#57 (the domain data of zh · ja · de · fr · ru · it · pt) and the
Spanish and Arabic national locales of co-package#71:

| field | ko | en | zh-Hans | ja | de | fr | es | pt | it | ru | ar |
|---|---|---|---|---|---|---|---|---|---|---|---|
| `person.fullName` | native | native | native | native | native | native | native | native | native | native | native |
| `address.city` | native | native | native | native | native | native | native | native | native | native | native |
| `text.sentence` | native | native | native | native | native | native | native | native | native | native | native |
| domain packs (`vet.pet().name`, `catalog.item().name`, …) | native | native | native | native | partial | partial | native | native | partial | native | en-fallback |

Domain-pack languages came with co-package#57 (zh · de · ja · fr · ru · it · pt)
and come with co-package#71 (es · ar): the basic modules of es and ar and the
domain data of es are native, and the domain data of ar follows. Arabic text is right to left and
keeps the digits 0–9. The domain-packs row is the `pet.name`
of the sample world. `partial` means that some of the sampled values are the
same word as in English: a third of the sampled pet names are `Tofu`, a loanword
that de, fr and it keep. Bumping the co_faker ref improves demos without code
changes; their support tables show it.

## Installing

Pin the release commit; co_faker and co_demo_prefs come from the same commit
through relative paths, so every package of the workspace resolves to one ref.

```yaml
dependencies:
  co_demo_world:
    git:
      url: https://github.com/coco-de/co-package.git
      path: packages/co_demo_world
      ref: <co_demo_world-vX.Y.Z commit SHA>
```

If the app also depends on co_faker or co_demo_prefs directly, use the **same
ref** (cocode S-9).

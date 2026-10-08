# Reusable demo domain packs

The package supplies original fictional dictionaries and generators for
[the 36 source PRDs](prd_domain_inventory.json). Registration is explicit:

```dart
final f = CoFaker(
  locale: 'ko', seed: 436, now: DateTime.utc(2026, 1, 15),
  domains: [CoFakerDomains.fx, CoFakerDomains.remit, CoFakerDomains.korea],
);
final row = f.schema.record(
  {'recipient': 'String', 'bank': 'String', 'principal': 'int'},
  roles: {
    'recipient': 'remit.romanizedNameMasked',
    'bank': 'remit.bankNameFictional',
    'principal': 'remit.sendAmount',
  },
  streamKey: 'exchange_remittance/transfers', index: 0,
);
```

The initial `clinic`, `saas`, `korea` precedence in `CoFakerDomains.all` is
unchanged. New packs infer no global suffix patterns. Use qualified roles or
`schema.entity('pack.entity')`, not an ambiguous bare role shared by packs.
Unknown packs/roles/entities fail rather than borrowing a similarly named role.

## Public helper contracts

All types below are exported by `package:co_faker/co_faker.dart`, have primitive
`toJson()` adapters, and use only the supplied faker and its derived streams.

| API | Result / coherence contract |
|---|---|
| `f.fx.currency(code:)` | `CoFakeFxCurrency`: ISO code, localized name, quote unit, fictional KRW base rate, allowed denominations |
| `f.fx.rateSeries(currencyCode:, days:, endAt:, endRate:)` | `List<CoFakeFxRatePoint>`: chronological midnight-UTC dates, positive rates within ±15% of endpoint; 1–3660 days; last point equals endpoint; extending history preserves overlap |
| `f.fx.denomination(currencyCode:)` | `int` selected only from that currency's note units |
| `f.fx.maskedAccount()` | `****-**-####`, never a complete account |
| `f.remit.recipient(index:, countryCode:, payoutMethod:)` | `CoFakeRemitRecipient`: masked initials/account; country→currency relationship; fixture-local positive id |
| `f.remit.transfer(index:, recipient:, sendAmount:, status:)` | `CoFakeRemittance`: linked recipient, principal/fee, consistent payout arithmetic, UTC dates, integer quote/payout adapters |
| `f.remit.milestones(transfer)` | Chronological primitive records on a permitted path ending at the supplied status, referencing the same transfer |
| `f.vet.pet(animalKind:)` | `CoFakePet`: species-consistent breed and weight; helper's default sampling is dog 60%, cat 35%, other 5% |
| `f.vet.breeds(kind)` | Species-specific localized breed list; unknown species fails |
| `f.catalog.item(grocery:, index:)` | `CoFakeCatalogItem`: unique ordinal code for indexed fixtures, matching generic name/category/unit/storage and price ≤ listPrice |
| `f.booking.slot(...)`, `f.booking.slots(...)` | `CoFakeBookingSlot`: UTC start/end, bounded remaining ≤ capacity, time label; closed Sundays optionally have capacity 0; default 7×16 = 112 blocks |
| `f.examPrep.question(index:)` | `CoFakeExamQuestion`: authored general IT stem/subject/unit, four seeded-shuffled choices, one-based matching answer/explanation and section/difficulty codes |
| `CoFakeVitalReading.generate(f)` | Consistent pressure pair, pulse, Celsius temperature and mg/dL glucose within illustrative ranges, without classification |
| `CoFakerHelpdesk(f).drafts()` | Eight human-authored primitive simulated-AI records covering account/billing/data_export/integration/bug; no AI service calls |

For one-field scalar generation, use `schema.record` and a qualified role. For
linked values, generate one typed helper result or use a registered coherent
schema. Calling independently seeded scalar roles and then combining them does
not establish an association. To force a pet species, use `pet(animalKind:)`;
overriding only the species enum of a schema is not a complete profile override.

## Numeric / serialized units

Unless listed here or in the inventory's `types` table, requested roles return
`String`. New numeric roles accept their numeric type (`int` may widen to
`double`/`num`) and a numeric `String` adapter; incompatible booleans/dates fail.

| Role | Type / unit |
|---|---|
| `vet.weightKg` | `double`, kilograms, constrained by breed |
| `dental.toothNumber` | `String`, FDI quadrant 1–4 and position 1–8; values like 19/20/49 are impossible |
| `dental.recallInterval` | `int`, 3/6/12 months |
| `homecare.serviceMinutes` | `int`, 60/90/120/180 minutes |
| `fx.krwAmount` | `int`, 10,000–5,000,000 KRW |
| `fx.denomination` | `int`, foreign banknote units for the matching currency |
| `commerce.price`, `salePrice`, `listPrice` | `int`, illustrative KRW prices from a coherent catalog |
| `b2b_trade.packUnit` | `int`, pieces/units per package from the matching item specification |
| `fitness.passTerm` | `int`, days (60/180/30), matching the indexed pass name |
| `daycare.napMinutes`, `bodyTemperature` | `int` minutes 0–150; `double` Celsius 36.2–37.4 |
| `hrd.trainingHours` | `int`, 1–8 hours |
| `meetup.duesAmount` | `int`, illustrative KRW 1,000–20,000 |
| `brokerage.quoteAmount`, `responseTime` | `int` illustrative KRW 50,000–60,000,000; `int` minutes 5–360 |
| `logistics.tonnage`, `palletCount`, `expiryDate` | `double` tonnes (1/2.5/5/11); `int` pallets 1–24; `DateTime` UTC |
| `fx.rateSeries` | `String` containing a JSON array of 365 actual rate points; use typed helper for other durations |
| `exam_prep.choiceSet`, `answerKey` | Numbered `①…|②…` primitive adapter; one-based comma-separated answer index string |
| `homecare.vitalReading` | `String` JSON pressure pair and associated vital signs with units |

The native schema remains primitive (`String`, `int`, `double`, `num`, `bool`,
`DateTime`, nullable forms). Lists/custom DTO schemas are not silently converted
to scalar numbers; use the typed helpers or the documented serialization.

## FX / remittance direction and minor units

FX quotes are **KRW per `unitAmount` foreign units**. USD's example base is
1452.30 per 1 USD; JPY is 935.20 per 100 JPY; VND is 5.62 per 100 VND.
The shared six currencies are USD/JPY/EUR/CNY/THB/VND; PHP/NPR helper quotes are
also supported. They are offline examples, not observed or live exchange rates.

Remittance rates instead mean **foreign units per 1 KRW**. Supported corridors
are VN→VND, PH→PHP, NP→NPR, US→USD, CN→CNY (the latter two are included by the
PRD's complete receive-currency enum). Principal is whole KRW. A VN example has
`appliedRate = 17.85`, `rateNumerator = 1785`, `rateDenominator = 100`,
`sendAmount = 1000000`, `receiveAmount = 17850000.0`. `receiveMinorDigits` is 0
for VND and 2 for PHP/NPR/USD/CNY; `receiveMinorUnits` is an integer payout adapter.
The fictional remit quote is not derived by inverting the FX retail quote.

## Recipe enums, clocks and relationships

Explicit `enums:` overrides win over any role/default enum. This allows the
existing SaaS messaging API to retain its old alimtalk/sms/lms defaults while a
campaign or newsletter recipe asks for its own codes. Empty/unknown enums are
reported as gaps; unknown explicit role names remain errors even with enums.

Use seed 436 and `DateTime.utc(2026, 1, 15)` for the standard preview. Workplace
PRDs use 1015/2026/314 and brokerage PRDs use 406/777/1119. The inventory records
each source's seed. All new date-producing helpers use UTC; display-time-zone
conversion (including Korean business-hour conversion) belongs to the recipe.

Use independent derived streams (`f.derive('recipe/entity/id')`) for helpers.
Schema fields are derived from `streamKey/index/field`. Opt-in coherent roles
use a fresh `streamKey/index` view and named substreams, so related fields agree
while adding an unrelated field does not change them. Existing/custom roles
retain their legacy field-derived behavior; `CoDomainRole.generateRecord` and
`supportedTypes` are optional extensions.

Registered taxonomy examples have roots first (`parentId = 0`) followed by
children referencing earlier root ids, with names tied to the root vocabulary.
Other integer references use `referenceCounts:` (default bound 10), not a SQL
foreign-key engine. Complete cross-record code references and fixed-tour graphs
are recipe assembly. Typed remittance transfers explicitly take a recipient
object to retain that association.

## Language bundles

The authored text of the packs and of the dedicated generators (`fx`, `remit`,
`vet`, `catalog`, `examPrep`, and the helpdesk drafts) lives in language
bundles, not in the packs. A role reads its text by key through `faker.l10n`:
`<pack>.<role>` (`dental.dentalProcedure`), or `<generator>.<name>`
(`fx.currencyName.USD`) for the generators. Korean and English are built in
(`lib/src/l10n/ko` and `en`). Chinese, Japanese, German, French, Russian,
Italian, and Portuguese are registered with empty bundles and read English
until their bundle is filled in; Spanish supports the basic modules only and
has no bundle.

- A key has the same number of texts in every language, in the same order, so
  one seed picks the same entry whatever the language. Roles that follow the
  record index (the class, equipment, and room of one row) rely on that order.
- A pack never branches on the locale. It reads the bundle with
  `textRole(key)`, `indexedTextRole(key, rows: n)`, `taxonomyRole(key)`,
  `maskedNameRole()`, or `faker.l10n.format(key, args)`, and fills the
  placeholders (`{n}`) itself. A role that cycles a table of `n` rows (the
  codes and numbers that stay in the pack) states `n`, and an assertion fails
  when the bundle has another number of texts for it.
- What is not text stays in the pack: codes (`enumRole`), numbers, prices,
  dates, and identifiers do not depend on the language.
- A new role adds its key to the English bundle and the Korean one;
  `test/l10n_domain_test.dart` fails for a key that no pack reads and for a key
  a pack reads that no bundle has.
- A custom locale adds a language with `CoFakerLocale.l10n`; see the README.
- A language is finished when `dart run co_faker:coverage --language <code>
  --strict` passes: its texts are written in the language, line up with
  English, and leave no key a stub. `docs/languages/README.md` describes the
  gate and the files a language fills.

## Authored-data restrictions

New organization/place/works labels are explicitly fictional or generic.
Daycare names are two-character given names in Korean; recipients/guests are
masked. Medicine labels are unbranded fictional examples, not recommendations.
Consultation text is limited to general example information and gives no
individual judgement, result promise or actionable legal/tax advice. Fandom
creator names are exactly two approved fictional names: `모래시계 정원` and
`하늘결` in Korean and English (and in a language without domain text, which
reads English), and two fictional names of its own in a language that is
localized (the key `fandom.creatorName`).

Regression denylists cover a curated set of known medicine brands, works,
organizations and result/advice claims **only in the newly authored data paths**.
They are not a claim that every name or trademark worldwide was screened. Each
language declares its own conventions in `test/language_safety/<language>.dart`
(how a fictional name is marked, how general-information text begins, the
phrases that promise a result, and the spellings of the denied brands in its
writing system), and the scan reads every language that has domain text.
Imagery uses the existing offline data-URI generator; app-specific webp/media
bundles are mapped by the recipe, with no external image request.

See [coverage and explicit remaining boundaries](prd-domain-coverage.md).

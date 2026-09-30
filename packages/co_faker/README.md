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
  co_faker: ^0.8.0
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

## Korean Identity, Clinic (EMR), And SaaS Back Office

Three domain modules cover Korean medical-clinic software: `faker.korea`,
`faker.clinic`, and `faker.saas`. Pass `now` so every date is repeatable.

```dart
final faker = CoFaker(locale: 'ko', seed: 7, now: DateTime.utc(2026, 9, 30));

final patient = faker.clinic.patient(); // name, sex, birthDate, rrnMasked,
                                        // phone, address, insurance ...
final staff = faker.clinic.staff(role: 'counselor'); // 상담실장
final line = faker.clinic.procedure(category: '레이저'); // price in its band
final owned = faker.clinic.packageBalance(); // 회차권 remaining sessions
final soap = faker.clinic.soap();
final slots = faker.clinic.businessSlots(DateTime.utc(2026, 10, 1));
final payments = faker.clinic.splitPayment(amount: 350000); // sums up

final tenant = faker.saas.tenant(); // clinic, business number, plan
final invoice = faker.saas.invoice(monthsAgo: 1); // supply + 10% VAT
final log = faker.saas.messageLog(); // alimtalk / sms / lms delivery row
final kpi = faker.saas.timeSeries(days: 30, base: 40, trend: 0.5);
```

Front desk, chart, and billing widgets:

```dart
final rooms = faker.clinic.rooms();
faker.clinic.queueBoard(rooms: rooms, count: 4); // per-room queue snapshot
faker.clinic.visitPurposeTree(); // ids + parent ids (시술 › 레이저)
faker.clinic.vitals(age: 42);
faker.clinic.consentHistory(); faker.clinic.visitHeatmap();
faker.clinic.canvasMarks(regions: ['forehead', 'chin']); // 0..1 pen chart
faker.id.uuidV7(at: DateTime.utc(2026, 1, 1)); // time-ordered id
CoFakerClinic.maskName('김하늘'); // 김*늘
CoFakerKorea.holidays(year: 2026); // 2024-2030, with substitute holidays
faker.clinic.closureNotice(date: DateTime.utc(2026, 9, 25)); // 추석 휴진 안내
faker.clinic.teamNote(authors: myStaff, mentions: myStaff);
faker.clinic.vitalsNote(vitals: faker.clinic.vitals());
```

Operations console (vendor back office):

```dart
faker.saas.prepaidLedger(); // won top-ups with tier bonuses
faker.saas.operator(); // role, status, 2FA, allowed IPs
faker.saas.operatorEvent(action: 'tenant.approve');
faker.saas.invoices(6, numberFormat: CoInvoiceNumberFormat.monthly,
    statusWeights: {'paid': 80, 'failed': 15, 'overdue': 5});
faker.saas.masterChanges(kind: 'fee'); faker.saas.masterChecks();
faker.saas.integrationSnapshot(); faker.saas.incidents();
faker.saas.timeSeries(granularity: CoTimeGranularity.hour);
faker.saas.announcement(kind: 'regulation');
```

Longer clinic texts and signatures:

```dart
faker.clinic.inquiry(language: 'ja'); // LINE thread, question + reply turns
faker.clinic.consentForm(kind: 'privacy'); // clauses + "not legal" disclaimer
faker.clinic.feedback(); // sentiment, score, comment
faker.clinic.counselSession(topic: 'lifting'); // timed transcript + quote
faker.clinic.integrationResult(service: 'eligibility');
faker.clinic.device(kind: 'picoLaser'); // invented vendor and model
faker.clinic.teamNote(); // "@name role, ..." handoff note
faker.clinic.guardian(patientAge: 12); // parent, phone

final ink = faker.signature.strokes(name: patient.name); // stable per name
CoFakerSignature.svgDataUri(ink); // offline image
CoFakerSignature.toOpenBoardPoints(ink); // open_board Point maps
```

Consent clauses, integration messages, insurers, devices, and drug names
are examples only: consent forms carry a disclaimer that they are not
legally reviewed, and vendor, insurer, and drug names are invented.

Codes (`nhis`, `waiting`, `noShow`, `prepaid`, `pastDue`, `revealRrn`, ...)
are locale independent and match typical enum names; `faker.clinic.label` and
`faker.saas.label` localize them. Korean and English data are built in and
other locales fall back to English; a custom locale can supply its own
`CoFakerClinicData` / `CoFakerSaasData`.

### Fake by construction

Identity values look real but can never belong to a real person or company:

| Value | Rule |
| --- | --- |
| Mobile phone | `010-0###-####` — subscriber blocks never start with `0` |
| Landline | `{area}-0##-####` — exchanges never start with the trunk `0` |
| Resident number (주민등록번호) | Masked `YYMMDD-G******` by default. Unmasked values fail the checksum, which every number issued before 2020-10 satisfies, so unmasked output requires a birth date before 2020-10 |
| Business number (사업자등록번호) | Always fails the checksum |
| English phone | `555-01##`, the fictional NANP block |
| Audit IPs | RFC 5737 documentation ranges only |
| Drug names | Invented stems, not marketed products |
| Diagnoses | A small illustrative subset of public ICD-10 / KCD codes — not a claim-grade master |

`CoFakerKorea.isRrnChecksumValid` and `isBusinessNumberChecksumValid` let tests
assert the rule. Road names and postal code ranges are real public geography,
so a generated address may coincidentally exist; do not send mail to it.

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

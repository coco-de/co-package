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
- National locales for the ten largest economies by GDP, plus Brazil: names,
  coherent addresses, fictional phone numbers, and currencies per country.
- Partial custom locales can override only the data a project needs.
- No runtime dependencies.

## Install

```yaml
dependencies:
  co_faker: ^0.9.0
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

## 도메인 팩 만들기

기존 `faker.clinic`·`faker.saas` 생성기는 그대로 사용할 수 있습니다. 스키마에서
도메인 필드 역할을 추론하거나 팩의 엔티티를 생성하려면 필요한 팩을 등록합니다.

```dart
final faker = CoFaker(
  locale: 'ko',
  seed: 7,
  now: DateTime.utc(2026, 10, 1),
  domains: CoFakerDomains.all, // clinic, saas, korea 우선순위 + 신규 팩
);

final patient = faker.schema.entity('clinic.patient', index: 0);
final patients = faker.schema.entities('clinic.patient', 20);
final invoice = faker.schema.record(
  {'number': 'String', 'status': 'String'},
  entity: 'saas.invoice',
  streamKey: 'saas.invoice',
  roles: {'number': 'saas.invoiceNumber'},
);
```

`seed`와 `now`, 엔티티명, 인덱스, 필드가 같으면 결과가 같습니다. 각 필드는
`streamKey/index/field`에서 독립된 난수 흐름을 파생하므로 다른 필드를 추가해도
기존 값은 바뀌지 않습니다. `entity`와 `entities`는 팩의 스키마, 역할, enum을
읽고 `pack.entity`를 스트림 키로 사용합니다. 같은 이름의 엔티티가 여러 팩에
있으면 `pack.entity`로 지정하세요. `roles`·`enums` 인자로 일부 필드를
덮어쓸 수 있습니다.

새 팩은 `CoFakerDomain`을 구현합니다. 생성기는 전달된 `CoFaker`의 난수와
시계만 사용해야 같은 입력에서 같은 값을 얻습니다.

```dart
class LibraryDomain extends CoFakerDomain {
  const LibraryDomain();

  @override
  String get name => 'library';

  @override
  Map<String, CoDomainRole> get roles => {
    'isbn': CoDomainRole(
      (faker, _) => faker.random.digits('979-11-#####-##-#'),
      description: 'Example ISBN-shaped value',
      fieldPatterns: const ['isbn'],
    ),
  };

  @override
  Map<String, Map<String, String>> get entities => const {
    'book': {'id': 'int', 'title': 'String', 'isbn': 'String'},
  };
}

final library = CoFaker(
  seed: 7,
  now: DateTime.utc(2026),
  domains: [...CoFakerDomains.all, const LibraryDomain()],
);
final book = library.schema.entity('library.book');
```

역할 이름은 `library.isbn`처럼 팩 이름을 붙여 명시할 수 있습니다. 필드명
패턴은 대소문자를 무시하며, `=isbn`은 정확히 일치할 때만, `book.isbn`은
해당 엔티티에만 적용됩니다. 팩의 `entityRoles`는 이름만으로 알아낼 수 없는
필드에 역할을 지정하고, `enums`는 status 필드의 허용 값을 제공합니다.

착수 전 엔티티·필드 계획의 커버리지를 점검할 수 있습니다.

```dart
final report = CoFakerCoverage(faker).check([
  const CoCoverageEntity('clinic.patient'),
  const CoCoverageEntity(
    'appointment',
    fields: {'patientId': 'int', 'status': 'String'},
    roles: {'status': 'status'},
  ),
]);
print(report.toMarkdown());
print(report.toJson()); // cob plan 등에서 사용
```

CLI는 JSON 계획을 표 또는 JSON으로 출력합니다. `entities`에는 등록된
엔티티명을 문자열로 넣거나 `name`, `fields`, `roles`, `enums`를 가진 객체를
넣습니다. `domains`를 생략하면 `CoFakerDomains.all`의 등록된 팩을 사용합니다.

```json
{
  "domains": ["clinic", "saas", "korea"],
  "entities": [
    "clinic.patient",
    {
      "name": "appointment",
      "fields": {"patientId": "int", "status": "String"},
      "enums": {"status": ["booked", "cancelled"]}
    }
  ]
}
```

```sh
dart run co_faker:coverage --input plan.json
dart run co_faker:coverage --input plan.json --format json --strict
```

### PRD 데모용 도메인 팩

36개 PRD(#653–#688)의 신규 역할은 `vet`, `dental`, `homecare`, `fx`,
`remit`, `travel_wallet`, `commerce`, `grocery`, `b2b_trade`, `group_deal`,
`booking`, `fitness`, `space_rental`, `dining`, `daycare`, `exam_prep`, `hrd`,
`neighborhood`, `meetup`, `fandom`, `content`, `helpdesk`, `campaign`,
`workplace`, `brokerage`, `logistics`, `hospitality` 팩에서 제공합니다.
`CoFakerDomains.byName('travel_wallet')`로 조회하거나 필요한 팩만 등록합니다.

신규 팩은 일반 `name`·`status`·`comment` 필드에 전역 패턴을 추가하지 않습니다.
`roles: {'name': 'grocery.produceName'}`처럼 **팩을 명시**하거나 등록된 엔티티를
사용하세요. 숫자 역할의 단위와 지원 타입이 명시되며, 잘못된 타입에는 임의
숫자를 대신 만들지 않고 오류를 냅니다. `enums:`에 직접 넣은 레시피 값은
기존 SaaS 채널/상태 역할을 포함해 우선 적용됩니다.

```dart
final demo = CoFaker(
  locale: 'ko', seed: 436, now: DateTime.utc(2026, 1, 15),
  domains: CoFakerDomains.all,
);
final pet = demo.derive('guardian/1/pet/1').vet.pet(animalKind: 'dog');
final product = demo.derive('catalog').catalog.item(grocery: true, index: 7);
final rates = demo.fx.rateSeries(currencyCode: 'JPY', days: 30);
final question = demo.derive('questions/1').examPrep.question(index: 1);
final slots = demo.booking.slots(days: 7, sundayClosed: true);
final recipient = demo.derive('recipient/1').remit.recipient(countryCode: 'VN');
final transfer = demo.derive('transfer/1').remit.transfer(
  recipient: recipient, sendAmount: 1000000, status: 'approved',
);
// Primitive JSON: pet.toJson(), product.toJson(), rates.map((p) => p.toJson()),
// question.toJson(), slots.map((s) => s.toJson()), transfer.toJson().
```

`rateSeries` 역할은 실제 일별 시계열 JSON 문자열이고,
`choiceSet`은 `①…|②…` 문자열, `vitalReading`은 단위가 포함된 바이탈 JSON입니다.
typed API는 각각 `CoFakeFxRatePoint`, `CoFakeExamQuestion`,
`CoFakeVitalReading.generate(faker)`입니다. 환율은 가상값이며 FX의
`baseRate`(KRW / `unitAmount` 외화)와 송금의 `appliedRate`(외화 / 1 KRW)는
방향이 다릅니다. 송금은 `rateNumerator`·`rateDenominator`·`receiveMinorUnits`도
제공합니다(VN 예시: 1785/100, 1,000,000 KRW → 17,850,000 VND).

[팩 계약과 단위](docs/domain-packs.md),
[36개 원문별 정확한 역할 목록](docs/prd_domain_inventory.json),
[검증 범위와 남은 경계](docs/prd-domain-coverage.md)를 확인하세요.
전체 앱 시드 건수·투어 고정 레코드·연결 관계·집계·상태 전이는 레시피가
조립하며, 등록된 스키마는 재사용 가능한 예시 스키마입니다.

`--input` 없이 실행하면 표준 입력을 읽습니다. `--strict`는 미지원 필드나
enum 누락이 있으면 종료 코드 1을 반환합니다. 잘못된 입력은 종료 코드 2입니다.
표의 `supported`는 팩 역할, `generic`은 범용 생성, `needsEnum`은 허용 값
누락, `unsupported`는 미지 엔티티·역할·타입 또는 의미를 알 수 없는 필드입니다.

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
faker.clinic.canvasMarks(template: 'faceFront'); // 3:4 chart face layout
faker.clinic.canvasMarks(regionRects: myTemplateRects); // your own layout
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

### Language data: amounts and Korean-only values

What differs by language is a field of the data, not a branch in the
generators, so a language is added with data alone:

- `currency` (`CoCurrencyFormat`) writes amounts: `$1,234` for English, `1,234`
  for Korean, and with a pattern, separators, and fraction digits `¥1,234`,
  `1.234,00 €`, `R$ 1.234,00`, or `1 234,00 ₽`. `faker.clinic.money(1234)` and
  `faker.saas.money(1234)` write an amount the way the generated texts do.
  Its code, symbol, and fraction digits should agree with the country data
  (`CoFakerCountry.currencyCode`, `currencySymbol`, `currencyMinorUnits`).
- `priceScale` (`CoClinicPriceScale`, `CoSaasPriceScale`) holds the rounding
  units, the installment and split thresholds, the point unit, the VAT rate,
  and the prepaid wallet amounts, in the currency of the data.
- `clinicNameFormat` orders a clinic name; the texts that the generators
  assemble (`회` or `x` of a package, the `님` of a mention, holiday names, date
  labels, health messages, audit targets) are fields of `CoFakerClinicTexts`,
  `CoFakerClinicOps`, and `CoFakerSaasOps`. A field that is missing falls back
  to English.
- `koreanValues` (`CoKoreanValues`) says which Korean-only values are
  generated.

Some concepts exist only in Korea: the resident registration number
(주민등록번호, shown masked on a patient), the business registration number,
card approval and cash receipt numbers, the public holiday calendar behind
`closureNotice` (`CoFakerKorea.holidays`), and the national health insurance
(`nhis`, `medicalAid1`, `medicalAid2`) and its insurers.

| `koreanValues` | Used by | Generates |
| --- | --- | --- |
| `korean` | the Korean data | Korean phones, road-name addresses, and every Korean-only value |
| `legacy` | the English data, and custom data that does not choose | the locale's phones and addresses, plus the Korean-only values English has always generated, so English output stays byte for byte stable |
| `none` | the data of every other language | the locale's phones and, in a national locale, its postal addresses; a neutral masked ID (`maskedIdFormat`), business number (`businessNumberFormat`), and 6-digit authorization code; no cash receipt number and no public holidays |

A language without data of its own gets the English data, and a code that is
not a supported language (a custom code, or Traditional Chinese such as
`zh_TW`) never receives another language's data. Maintainers add a language by
filling `lib/src/l10n/<language>/<language>_clinic.dart` and
`<language>_saas.dart`, which `lib/src/l10n/co_l10n_clinic.dart` already reads.

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

### Countries: GDP top 10

National locales cover the ten largest economies by nominal GDP (World Bank,
2025) plus Brazil, which other sources rank in the top ten:

| Country | Locale | Country | Locale |
|---|---|---|---|
| United States | `en_US` | France | `fr_FR` |
| China | `zh_CN` | Russia | `ru_RU` |
| Germany | `de_DE` | Italy | `it_IT` |
| Japan | `ja_JP` | Canada | `en_CA` |
| United Kingdom | `en_GB` | Brazil | `pt_BR` |
| India | `en_IN` | | |

```dart
final japan = CoFaker.forCountry('JP', seed: 7, now: DateTime.utc(2026));
japan.person.fullName();        // 林 蓮
japan.internet.email();         // kaito.shimizu@example.com
japan.internet.phoneNumber();   // 070-0103-4483 (fictional)
japan.address.fullAddress();    // 〒600-8497 京都府京都市下京区宮前3丁目12-3

for (final country in CoFakerCountries.gdpTop10) {
  final faker = CoFaker(locale: country.locale, seed: 7);
  print('${country.name}: ${faker.person.fullName()}');
}
// United States: Elijah Moore, China: 马浩然, Germany: Finn Neumann, ...
```

- `CoFaker(locale: 'ja-JP')` and `CoFaker.forCountry('JPN')` select the same
  locale; `faker.country` tells which country a generator describes.
- Phone numbers are fictional by construction: a regulator's range reserved
  for fiction where one exists (NANP 555-01xx, Ofcom, Bundesnetzagentur,
  ARCEP), otherwise a prefix that no number type uses.
  `phoneNumber(international: true)` adds the calling code.
- In `faker.schema` records, the city, postal code, region, and address fields
  of one record describe the same place. Force a region field with
  `roles: {'state': 'region'}`.
- Emails, URLs, and usernames are romanized (`Müller` → `mueller`,
  `佐藤` → `sato`, `Иванова` → `ivanova`) on reserved example domains.
- The earlier language codes (`en`, `ko`, `ja`, `zh`, `es`, `fr`, `de`) keep
  their output. `it`, `pt`, and `ru` previously fell back to English and now
  resolve to Italy, Brazil, and Russia.

Sources, the phone rationale per country, and the compatibility notes are in
[docs/countries.md](docs/countries.md).

## Language settings

Hand an app's language setting to `CoFaker.forLanguage` and it picks the
language and its locale. It reads a BCP-47 tag (`zh-Hans`, `pt-BR`), a POSIX
locale name (`ja_JP.UTF-8`, `en_US@posix`), or what Flutter's
`Locale.toLanguageTag()` returns, and ignores case, `-` versus `_`, the
script subtag, the encoding, and the modifier. co_faker depends on neither
Flutter nor co_demo_prefs; both only supply the string:

```dart
// A Flutter app: the locale of the running app, e.g. zh-Hans-CN.
final locale = Localizations.localeOf(context);
final faker = CoFaker.forLanguage(
  locale.toLanguageTag(),
  seed: 7,
  now: DateTime.utc(2026),
);
faker.locale;            // zh_cn
faker.language;          // zh
faker.person.fullName(); // 马浩然

// A demo built on co_demo_prefs: DemoLocale.tag is ko, en, zh-Hans, ja, ...
final demo = CoFaker.forLanguage(demoLocale.tag, seed: 7);
```

Each language is generated with the national locale of its main country:

| Setting | Locale | Country |
|---|---|---|
| `ko` | `ko` | none |
| `en` | `en_us` | United States |
| `zh`, `zh-Hans`, `zh-CN` | `zh_cn` | China |
| `ja` | `ja_jp` | Japan |
| `de` | `de_de` | Germany |
| `fr` | `fr_fr` | France |
| `ru` | `ru_ru` | Russia |
| `it` | `it_it` | Italy |
| `pt`, `pt-BR` | `pt_br` | Brazil |
| `es` | `es` | none, basic modules only |

- **Unsupported languages and Traditional Chinese get English.** `ar`, `und`,
  `zh-Hant`, `zh_TW`, `zh_HK`, and `zh_MO` resolve to `en_us`; Traditional
  readers are never handed Simplified text. `CoFakerLanguages.resolve(tag)`
  reports it with `supported == false` and also returns the `language`, the
  `locale`, and the `region` it read:

  ```dart
  final resolved = CoFakerLanguages.resolve('zh_TW');
  resolved.supported; // false
  resolved.locale;    // en_us
  resolved.region;    // TW
  ```

- **The region is read, not used.** `en-GB` is English with the `en_us` data
  and `pt-PT` is `pt_br`. Use `CoFaker.forCountry` to pick a country.
- **`ko` and `es` have no national locale.** `faker.country` is `null`, and
  `address.postalAddress()`, `locality()`, `region()`, `regionCode()`, and
  `postalCodeFor()` throw a `StateError`, as they do for
  `CoFaker(locale: 'ko')`. Check `faker.country` before calling them.
- **Custom locales** passed to `forLanguage` are looked up by the resolved
  locale (`ja_jp`), not by the language code, so register an override under
  `CoFakerLanguage.locale`. `CoFaker(locale: 'ja', locales: {'ja': ...})`
  still works as before.
- **Domain data follows `CoFakerLanguage.domain`.** The domain packs,
  `faker.clinic`, and `faker.saas` are English in a language whose `domain` is
  `false`, while the basic modules (names, addresses, phone numbers, and so
  on) already speak the language.

`CoFaker(locale: 'ja')` is not `CoFaker.forLanguage('ja')`. A bare language
code selects the language-only data the language has always had, a few names,
cities, and companies, and `faker.locale` stays `ja`. `forLanguage('ja')`
selects the national locale `ja_jp`, with the same coherent addresses,
fictional phone numbers, and currency-aware prices as
`CoFaker.forCountry('JP')`. The constructor keeps its output, so existing
fixtures keep their values; use `forLanguage` when the language comes from a
setting. `faker.language` names the language of either generator (`ja` for
`ja` and for `ja_jp`).

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

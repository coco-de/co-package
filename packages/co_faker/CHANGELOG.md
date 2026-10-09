## Unreleased

- Cover the 34 fields of the demo W1 recipes (co-package#78): new roles and
  `entityRoles` in the fitness, daycare, meetup, content, helpdesk, workplace,
  brokerage, logistics, and hospitality packs, so `CoFakerCoverage` reports
  them as supported. Business identifiers (`ticketNo`, `trackingNo`,
  `contactLast4`, `shelfSlot`, `extension`, `arrivalEta`, `stayMonth`,
  signatures) are the same in every language; display texts come from ten new
  bundle keys written in all eleven languages (AI draft, native review
  pending). See `docs/domain-packs.md`.
- Localize the domain mock data in Arabic (`ar`, co-package#71): the domain
  text bundle (242 keys), the clinic data, and the SaaS data, in Modern
  Standard Arabic as written in Saudi Arabia, right to left with the digits
  0–9, SAR (`1,234.00 ر.س`) and 15 % VAT. The same seed picks the translation
  of the same record. `dart run co_faker:coverage --language ar --strict`
  passes. The translation is an AI draft for native review
  (`docs/languages/ar.md`).
- Behavior change: the clinic, SaaS, and domain pack output of `ar`, `ar_SA`,
  and `forLanguage('ar')` changes from English to Arabic.
- Localize the domain mock data in Spanish (`es`, co-package#71): the domain
  text bundle (242 keys), the clinic data, and the SaaS data, in Peninsular
  Spanish with EUR (`1.234,00 €`) and 21 % IVA. The same seed picks the
  translation of the same record. `dart run co_faker:coverage --language es
  --strict` passes. The translation is an AI draft for native review
  (`docs/languages/es.md`).
- Behavior change: the clinic, SaaS, and domain pack output of `es`, `es_ES`,
  and `forLanguage('es')` changes from English to Spanish.
- Add the national locales of Spain (`es_ES`) and Saudi Arabia (`ar_SA`) for
  the demo languages Spanish and Arabic (co-package#71): gendered names,
  coherent city, region and postal codes, national address order, fictional
  phone numbers (prefixes that libphonenumber rejects), romanized Arabic
  usernames, and EUR / SAR. Arabic is right to left and keeps the digits 0–9.
- `CoFakerLanguages` supports Arabic (`ar`, `CoFakerScript.arabic`), and
  Spanish is generated with `es_ES`. `es` and `ar` are registered with empty
  domain stubs (`planned`) until their domain data lands.
- Behavior change: `CoFaker.forLanguage('es')` builds `es_ES` instead of the
  bare `es`, and `CoFaker(locale: 'ar')` and `forLanguage('ar')` give Arabic
  data instead of English. `CoFaker(locale: 'es')` keeps its output.
- Add national locales for the ten largest economies by GDP (World Bank 2025)
  plus Brazil: `en_US`, `zh_CN`, `de_DE`, `ja_JP`, `en_GB`, `en_IN`,
  `fr_FR`, `ru_RU`, `it_IT`, `en_CA`, `pt_BR`. They carry gendered names
  (Russian family names agree with the sex), coherent city, region and postal
  codes, national address order, romanized usernames, reserved email domains,
  and currency-aware prices. See `docs/countries.md`.
- Add `CoFakerCountries` (`all`, `gdpTop10`, `byCode`), `CoFaker.forCountry`,
  `CoFaker.country`, `CoFakerLocales.resolve`, `address.postalAddress()`,
  `region()`, `regionCode()`, `locality()`, `postalCodeFor()`, the `region`
  schema role and `internet.phoneNumber(international: true)`.
- National phone numbers are fictional by construction: regulator ranges
  reserved for fiction (NANP, Ofcom, Bundesnetzagentur, ARCEP) or prefixes
  that libphonenumber rejects for every number type.
- Schema records of a national locale share one place, so their city, postal
  code, region and address fields agree.
- Fix locale lookup to use the normalized code: custom locales registered with
  a regional code such as `ko-KR` were never selected.
- Behavior change: regional codes with a national locale (such as `ja_JP`)
  and the languages `it`, `pt` (Brazil) and `ru`, which used to fall back,
  now resolve to the national locales. The earlier language codes keep their
  0.10.0 output, guarded by a snapshot regression test.
- Add 27 Korean/English domain packs for the 36 demo PRDs, preserving the
  original `clinic`, `saas`, `korea` lookup precedence and seeded defaults.
- Add coherent typed FX histories, masked remittance recipients/transfers,
  veterinary profiles, brand-free catalogs, UTC booking slots, authored exam
  questions, vital readings and eight human-authored simulated support drafts.
- Add strict primitive role-type metadata and opt-in record-derived adapters;
  explicit recipe enums override domain roles without altering default outputs.
- Add an independent source/role inventory and coverage CLI, plus regression
  checks for numeric/enum bounds, relationships, UTC dates, field stability,
  English fallback and scoped authored-data restrictions.
- Add language settings: `CoFakerLanguages` (`all`, `resolve`),
  `CoFakerLanguage`, `CoFakerLanguageResolution`, `CoFaker.forLanguage` and
  `faker.language`. A BCP-47 tag, a POSIX locale name, or Flutter's
  `Locale.toLanguageTag()` resolves to one of the supported languages (`ko`,
  `en`, `zh`, `ja`, `de`, `fr`, `ru`, `it`, `pt`, `es`) and the national locale
  of its main country. Traditional Chinese and unsupported languages resolve
  to English with `supported == false`.
- Add domain text bundles: `CoL10nBundle`, `CoL10nRegistry`, `faker.l10n`
  (`CoFakerL10n`) and `CoFakerLocale.l10n`. The 27 domain packs and the
  dedicated generators (`fx`, `remit`, `vet`, `booking`, `catalog`, `examPrep`,
  the helpdesk drafts) read their labels, names and sentences by key from the
  bundle of the language of the generator, so a language is data, not code. A
  bundle has the keys of the English one (242) with as many texts as English
  has, so the same seed picks the same record in every language.
  `CoFakerLanguage.domain` is computed from the registry. Korean and English
  output is byte for byte what it was.
- Add language data for `faker.clinic` and `faker.saas`: `CoFakerClinicData`
  gains `currency` (`CoCurrencyFormat`), `priceScale` (`CoClinicPriceScale`),
  `clinicNameFormat`, `maskedIdFormat`, `addressLineFormat` and `koreanValues`
  (`CoKoreanValues`); `CoFakerSaasData` gains `currency`, `priceScale`
  (`CoSaasPriceScale`), `businessNumberFormat` and `koreanValues`. The texts
  that the generators used to assemble inline (honorifics, holiday names, date
  labels, health messages) are fields of the data too. Add `clinic.money` and
  `saas.money`. A registry holds the data of each language; the Korean and
  English output is unchanged.
- Add the language coverage gate: `CoLanguageCoverage` decides whether a
  language is finished. It compares the bundle, the clinic data and the SaaS
  data with English text by text (no Hangul in a language other than Korean,
  the writing system of Japanese, Chinese and Russian, few texts that read like
  English, lists and maps of the English length and order, the `{name}` fields
  of every text kept under their English names, `koreanValues: none`, no key
  left unregistered) and runs the generators of the language for Hangul,
  unfilled placeholders and exceptions.
  `dart run co_faker:coverage --languages [--format markdown|json]` prints the
  table of supported languages, computed from the registries, and
  `dart run co_faker:coverage --language <code> --strict` runs the gate and
  exits with 1 when it fails. `CoL10nBundle.allowSameAsEnglish` lists the texts
  that equal English on purpose (units, acronyms, names). `docs/languages/`
  holds one file for each language, with a glossary, and a test checks that no
  term has two translations and that no forbidden form is written.
- Add the bundle key `fandom.creatorName`: the two approved creator names of
  the `fandom` pack were a constant that no language could change. Korean and
  English keep their names, and another language writes names of its own.
  `CoFandomDomain.creatorNames` stays.
- Add domain data for Chinese (Simplified, `zh`), Japanese (`ja`), German
  (`de`), French (`fr`), Russian (`ru`), Italian (`it`), and Portuguese
  (Brazil, `pt`): the domain text bundle (242 keys), the clinic data, and the
  SaaS data of each language. `CoFaker.forLanguage('<code>')`,
  `CoFaker(locale: '<code>')`, and the national locale (`zh_CN`, `ja_JP`,
  `de_DE`, `fr_FR`, `ru_RU`, `it_IT`, `pt_BR`) now generate the domain packs,
  the dedicated generators, `faker.clinic`, and `faker.saas` in that language,
  with the currency (CNY, JPY, EUR, RUB, BRL), the number and date formats, and
  the register of the language, fictional names, and no Korean-only values. The
  same seed picks the same record as in English and Korean. Every language
  passes `dart run co_faker:coverage --language <code> --strict`, and
  `docs/languages/<code>.md` holds its glossary and a native-speaker review
  checklist. These translations are AI drafts that no native speaker has
  reviewed yet.
- Behavior change: when a language gets domain data (its bundle, clinic data
  and SaaS data), its `clinic`, `saas` and domain pack output reads the language
  instead of English. The basic modules (names, addresses, internet, text) do
  not change: they keep their 0.10.0 output for every locale code, guarded by
  the snapshot regression test. That test pins the domain keys of the snapshot
  (`clinic.*`, `schema.patient`, `schema.invoice`) only for the codes whose
  language has no domain data yet, as the registries say, because those keys
  change on purpose when a language is localized; the same goes for the
  clinic and SaaS fallback test. `zh_TW`, `es`, and unsupported codes keep
  every key.
- Behavior change: a locale code that only starts with `ko` and is not Korean
  (`kok`, `kor`, `korean`, `ko1`, `ko.UTF-8`, `ko@euro`) reads English
  everywhere now: the domain packs, the dedicated generators (`fx`, `remit`,
  `vet`, `catalog`, `examPrep`, the helpdesk drafts), `faker.clinic` and
  `faker.saas` give the English output. On 0.11.0 the packs and the generators
  read Korean text for these codes, and `faker.clinic` and `faker.saas` read
  English text with Korean-style values (a clinic name written without a space,
  won-sized prices, Korean mobile numbers, road-name addresses, resident and
  business registration numbers), because they tested the code with
  `startsWith('ko')`. `ko`, `ko_KR`, `ko-KR` and `KO_kr` are Korean as before.
- Behavior change: `faker.clinic` and `faker.saas` follow the data fields, not
  the locale code. A custom `ko*` data set that leaves the new fields empty gets
  the English scale and formats (the `legacy` values), and a custom `ko` locale
  that gives no clinic or SaaS data gets the built-in Korean data.
- Behavior change: Traditional Chinese (`zh_TW`, `zh_HK`, `zh_MO`, `zh-Hant`)
  and every code that is not a supported language read English domain data. They
  are never handed Simplified Chinese.

## [0.12.0](https://github.com/coco-de/co-package/compare/co_faker-v0.11.1...co_faker-v0.12.0) (2026-10-09)


### 기능

* **co_faker:** ✨ 도메인 목데이터 스페인어 현지화 — 번들 · clinic · saas ([#71](https://github.com/coco-de/co-package/issues/71)) ([#92](https://github.com/coco-de/co-package/issues/92)) ([74d7268](https://github.com/coco-de/co-package/commit/74d72685fed2e5a7d850beb84da820ad569b06d3))
* **co_faker:** ✨ 도메인 목데이터 아랍어 현지화 — 번들 · clinic · saas ([#71](https://github.com/coco-de/co-package/issues/71)) ([#93](https://github.com/coco-de/co-package/issues/93)) ([f42b193](https://github.com/coco-de/co-package/commit/f42b193a68147a24be6f0ee1707f369ba9da0382))
* **co_faker:** ✨ 스페인 · 사우디아라비아 국가 로케일과 es · ar 언어 등록 ([#71](https://github.com/coco-de/co-package/issues/71)) ([#91](https://github.com/coco-de/co-package/issues/91)) ([bf9cf89](https://github.com/coco-de/co-package/commit/bf9cf89764df0312ddd95e1eea9c1566e6207719))
* **co_faker:** ✨ 언어 설정에 따른 도메인 목데이터 현지화 — GDP 상위 10개국 언어 7종 (zh · ja · de · fr · ru · it · pt) ([#89](https://github.com/coco-de/co-package/issues/89)) ([bd4e400](https://github.com/coco-de/co-package/commit/bd4e400dba9f28442f864e6e17367b0f87fd8046)), closes [#57](https://github.com/coco-de/co-package/issues/57)

## [0.11.1](https://github.com/coco-de/co-package/compare/co_faker-v0.11.0...co_faker-v0.11.1) (2026-10-08)


### 버그 수정

* **co_faker:** 🐛 deriveSeed 가 웹(dart2js · dart2wasm)에서도 VM 과 같은 값을 낸다 ([#69](https://github.com/coco-de/co-package/issues/69)) ([#73](https://github.com/coco-de/co-package/issues/73)) ([24736be](https://github.com/coco-de/co-package/commit/24736bea717cc6edbd5102c22d0e522e5ede87ec))

## [0.11.0](https://github.com/coco-de/co-package/compare/co_faker-v0.10.0...co_faker-v0.11.0) (2026-10-04)


### 기능

* **co_faker:** ✨ GDP 상위 국가 국가별 목데이터 — 국가 로케일 11종 · 레지스트리 · 가상 전화번호 ([#55](https://github.com/coco-de/co-package/issues/55)) ([214919b](https://github.com/coco-de/co-package/commit/214919b9ede0be55afe6842bda496cd83e6d8245))


### 버그 수정

* **co_faker:** 🐛 로케일 조회를 정규화된 코드로 한다 ([#55](https://github.com/coco-de/co-package/issues/55)) ([5482260](https://github.com/coco-de/co-package/commit/548226086f0d0da266d5fbf8a6580bd949a007df))

## [0.10.0](https://github.com/coco-de/co-package/compare/co_faker-v0.9.0...co_faker-v0.10.0) (2026-10-03)


### 기능

* **co_faker:** ✨ 데모 도메인 팩 27종과 출처 회귀 ([#48](https://github.com/coco-de/co-package/issues/48)) ([a815c50](https://github.com/coco-de/co-package/commit/a815c500fea0bbd6e9ef2d1aab70855b8859db8e))

## 0.8.1

- `clinic.canvasMarks` gains `regionRects:` (`Map<String, CoRegionRect>` in
  normalized `0..1` coordinates): each pen mark is an ellipse inside the
  caller's rectangle, so marks line up with any chart template.
- Add the `faceFront` template (`CoFakerClinic.faceFrontRegions`): region
  rectangles of a frontal face on a 3:4 portrait canvas, matching the
  clinic-emr chart `faceFront` outline.
- Document the default `face` template (`CoFakerClinic.faceRegions`): region
  centers on a square canvas in standard frontal proportions. Its output is
  unchanged for the same seed.

## [0.9.0](https://github.com/coco-de/co-package/compare/co_faker-v0.8.1...co_faker-v0.9.0) (2026-09-30)


### 기능

* **co_faker:** ✨ 등록형 도메인 팩과 스키마 커버리지 점검 추가 ([#39](https://github.com/coco-de/co-package/issues/39)) ([2158468](https://github.com/coco-de/co-package/commit/2158468fb669f1869ec8d9df9732114d63fe208b)), closes [#38](https://github.com/coco-de/co-package/issues/38)

## 0.8.0

- Add `CoFakerKorea.holidays(year:)` / `holidaysOn(date)`: Korean public
  holidays for 2024-2030 (`CoFakerKorea.holidayYears`) — fixed solar
  holidays, a per-year lunar table (Seollal, Chuseok, Buddha's Birthday),
  and substitute holidays under the current rules. Election days and
  temporary holidays are not included.
- Add `clinic.closureNotice(date:, clinicName:)`: closure notices that span
  the whole holiday stretch (for example Chuseok plus Sunday) with the
  reopening day, or a non-holiday reason, with correct Korean particles.
- `clinic.teamNote` gains `authors:` and `mentions:` to pick the author and
  the mentioned staff from the caller's own staff names.
- Add `clinic.staffNotice(kind: training|policy|schedule)` and
  `clinic.vitalsNote(vitals:)` (mention-free observation notes that flag
  high blood pressure, fever, low SpO2, or high glucose).
- `CoFakerClinicOps` gains optional `staffNotices`, `vitalsNotes`,
  `closure`, and `closureReasons` (empty falls back to English).

## 0.7.0

Widgetbook and golden-test generators. Existing APIs only gain optional
parameters and record fields; base patient values for a seed are unchanged.

- `clinic.patient` gains `chartNo` (`chartNumber:`, `CoChartNumberFormat`
  plain/padded/yearly), `visitCount`, `lastVisitAt`, `channel`/
  `channelLabel`, and `specialNote`, drawn from a stream derived from the
  patient so the existing fields keep their values. Add `clinic.chartNumber`.
- Add `clinic.patientTag(s)`, `clinic.acquisitionChannel`,
  `clinic.specialNote`, `CoFakerClinic.maskName` (`김*늘`) and
  `clinic.maskedName`.
- Add `clinic.termsVersion`, `clinic.consentHistory` (agree/withdraw events
  by kind and channel; the required privacy consent is never withdrawn), and
  `clinic.consentDispatch`.
- Add `clinic.rooms()` (room layout with staff and colors),
  `clinic.queueBoard(rooms:, count:)` (per-room queue snapshots),
  `clinic.visitPurposeTree()` (ids and parent ids; `visitPurpose` gains
  `purposeId`/`detailId`), `clinic.receptionSource`, `clinic.kioskPurpose`,
  `CoFakerClinic.palette` and `clinic.color`.
- Add `clinic.vitals(age:, sex:)` with age-realistic ranges.
- Add `clinic.adjustment`, `clinic.cardDecline` (ISO 8583-style response
  codes, same reasons as `saas.autopayFailure`), `clinic.paymentMessage`,
  `clinic.pointTransaction`, and `clinic.compoundPackageName`.
- Add `clinic.visitHeatmap` (weekday × hour).
- Add `clinic.task`, `clinic.counselEvidence`, `clinic.counselFailure`,
  `clinic.claimIssue`, and `clinic.crmSendFailure`.
- `clinic.inquiry` turns gain `language` and a Korean `translation`
  (`CoFakeTurn`); the inquiry lists are index-aligned across languages.
- Add `clinic.canvasMarks(template: 'face')`: normalized pen-chart circles
  and a highlighter swipe; `CoFakerSignature.toOpenBoardPoints` gains
  `width`/`height` scaling.
- Add `id.uuidV7(at:)`: deterministic, time-ordered UUID v7.
- Add `CoFakerClinicOps` (Korean and English) linked by the optional
  `CoFakerClinicData.ops`.

## 0.6.0

Operations console (vendor back office) generators. Existing APIs only gain
optional parameters and record fields.

- Add `saas.prepaidLedger()` (won wallet: top-ups with tier bonuses from
  `CoFakerSaas.prepaidBonusTiers` — 100,000 won +10% up to 15,000,000 won
  +60% — payment methods, usage, refunds) and `CoFakerSaas.prepaidBonus`.
- Add notification templates `QUESTIONNAIRE`, `SURVEY`, and the advertising
  `AD_EVENT`; `saas.messageTemplate(code:)`; templates gain `advertising`
  and `rejectReason` (advertising templates are always rejected).
- Add `saas.operator()` (vendor operator roster: role, status, 2FA, allowed
  RFC 5737 CIDRs) and `saas.operatorEvent(action:)` (console action keys such
  as `tenant.approve` with target and summary).
- `saas.invoice` gains `status`, `statusWeights`, `numberFormat`
  (`CoInvoiceNumberFormat.monthly` → `INV-YYYY-MM-NNNN`), and `sequence`;
  a `failed` invoice carries `failureCode`/`failureReason`. Add
  `saas.invoices(count)` and `saas.autopayFailure()` (limit exceeded, card
  expired, insufficient funds, lost, suspended, issuer timeout).
- Add `saas.masterChanges(kind:)` (sample `EX-` coded rows with old/new
  prices) and `saas.masterChecks()` (upload validation checks).
- `saas.timeSeries` gains `granularity` (`CoTimeGranularity.hour` shaped by
  clinic hours, `day`, `month` with a winter peak) and `count`.
- Add `saas.integrationSnapshot()` (status fixed per service by the seed,
  success rate, 24h calls, latency) and `saas.incidents()`.
- Add `saas.opsAlert()`, `saas.announcement(kind: release|regulation)` with
  audience, channels, and read rate, and `saas.tenantActivity()`.
- Add `CoFakerSaasOps` (Korean and English) linked by the optional
  `CoFakerSaasData.ops`; `saas.label` falls back to English.

## 0.5.0

- Add `faker.signature` (`CoFakerSignature`): deterministic handwritten-looking
  signature strokes (`CoInkPoint` x/y/pressure/timestamp), stable per `name`,
  with `svgPath`, `svgDataUri`/`dataUri` for offline rendering, and
  `toOpenBoardPoints` shaped like `open_board`'s `Point` (`x`, `y`, `p`,
  `timestamp`).
- Add clinic text generators backed by the new `CoFakerClinicTexts` (Korean
  and English; `CoFakerClinicData.texts`, other locales fall back to
  English):
  - `clinic.inquiry(language:)`: foreign-patient messenger threads in
    `ko`/`en`/`ja`/`zh`/`vi` on each language's usual channel (KakaoTalk,
    WhatsApp, LINE, WeChat, Zalo), plus `clinic.messengerHandle`.
  - `clinic.consentForm(kind:)`: procedure, privacy, photo, marketing, and
    anesthesia consent clauses, always with a disclaimer that the text is an
    example and not a legally reviewed form.
  - `clinic.feedback(sentiment:)`: satisfaction comments (positive 70%,
    neutral 20%, negative 10%) with matching 1-5 scores.
  - `clinic.counselSession(topic:)`: counseling transcripts with timed
    counselor/patient turns, a quote from the procedure catalog, a package
    price, a booking decision, and a summary.
  - `clinic.insurerName()` (fictional insurers) and
    `clinic.integrationResult(service:)`: example eligibility, DUR, claim
    review, e-prescription, and identity QR responses with `ok` flags.
  - `clinic.device(kind:)`: clinic devices with invented vendors and model
    names (no trademarks), serials, and `N호기` display names.
  - `clinic.teamNote()`: chart collaboration notes with `@` mentions and
    handoffs.
  - `clinic.familyRelation()` / `clinic.guardian(patientAge:)`: relation
    codes and age-plausible guardians.
- `clinic.label` now also resolves relation, device kind, and sentiment codes
  and falls back to English labels.
- Add `clinic.insurerName` and `clinic.feedback` template placeholders.

## 0.4.0

- Add `faker.korea` (`CoFakerKorea`): Korean identity values that are
  **deliberately invalid** — mobile numbers in the unassignable
  `010-0###-####` block, landlines whose exchange starts with `0`, resident
  registration numbers masked by default (`YYMMDD-G******`) and, unmasked,
  forced to fail the checksum (birth dates before 2020-10 only), business
  registration numbers forced to fail the checksum, road-name addresses with
  per-province postal codes, birth dates, and card approval numbers. Static
  `isRrnChecksumValid`, `isBusinessNumberChecksumValid`, `maskPhone`, and
  `areaCodeOf` helpers.
- Add `faker.clinic` (`CoFakerClinic`): clinic names, specialties, staff and
  roles, patients (sex ratio, dermatology age distribution, masked RRN,
  insurance type), visit purposes, a procedure catalog with price bands,
  session packages and remaining balances, prepaid balances, an illustrative
  ICD-10/KCD subset, fictional drug names and prescriptions, chart memos and
  SOAP notes, intake questionnaires, business-hour slots (`CoClinicHours`:
  lunch break, short Saturdays, closed Sundays), appointment slots, visit
  flow and stages, time-aware reservation statuses, and payments (card,
  cash, transfer, prepaid, split payments that always add up).
- Add `faker.saas` (`CoFakerSaas`): clinic tenants, plans, subscriptions,
  monthly invoices with 10% VAT, message credit ledgers, sender numbers,
  notification templates, delivery logs, claim master versions, integration
  health checks, audit events on RFC 5737 documentation IPs, notices, and
  daily KPI time series with trend, weekly seasonality, and noise.
- Add `CoFakerLocale.clinic` / `CoFakerLocale.saas` data packs
  (`CoFakerClinicData`, `CoFakerSaasData`) with Korean and English data;
  other locales fall back to English. Codes are locale independent and
  `label(code)` localizes them.
- Add `CoSex`, `person.sex(femaleRatio:)`, and gendered
  `person.firstName(sex:)` / `fullName(sex:)` backed by the new
  `CoFakerLocale.femaleFirstNames` / `maleFirstNames` (Korean and English).
- Add `CoFakerPerson.romanize` (Revised Romanization): Korean usernames and
  emails are now readable (`seoyeon.kim@example.kr`) instead of `user1234`.
- Add schema roles `rrn` and `businessNumber`, inferred from `rrn*`,
  `residentNumber`, `businessNumber`, `bizNo`, and `brn` fields.
- Add `korea.*` and `clinic.*` template placeholders.
- **Changed output:** Korean phone numbers now use `010-0###-####` and
  English ones the fictional `555-01##` block; Korean usernames and emails
  are romanized. Fixtures that snapshot these values for a seed change once.

## 0.3.0

- Add schema roles `currencyPair` (`USD/KRW`, two distinct ISO 4217 codes),
  `place` (meeting places and venues from the new locale `places` list) and
  `rate` (positive decimal with four digits). Inferred from field names such
  as `pair`, `placeName`/`venue`/`meetingPoint`, and `*Rate`/`exchangeRate`,
  so P2P exchange fixtures no longer render lorem words or person names for
  currency pairs, rates and meeting places.
- Add `CoFakerLocale.places` (Korean and English data; other locales fall
  back to English).

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

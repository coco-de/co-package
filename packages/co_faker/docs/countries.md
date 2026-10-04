# National locales: the ten largest economies

co_faker 0.11 adds one national locale per country of the ten largest economies by
nominal GDP, plus Brazil. A national locale is a `CoFakerLocale` with
`CoFakerNationalData`. On top of the language data it adds:

- cities with their region and postal code templates;
- fictional phone formats;
- the national address and street-line order;
- romanization for usernames;
- currency minor units.

```dart
final faker = CoFaker.forCountry('BR', seed: 7, now: DateTime.utc(2026));
final address = faker.address.postalAddress();
// address.city, address.region, address.postalCode always agree.
final rows = faker.schema.records(20, {
  'name': 'String', 'email': 'String', 'phone': 'String',
  'city': 'String', 'state': 'String', 'zip': 'String', 'address': 'String',
}, roles: {'state': 'region'}, entity: 'customer');
```

## Which countries

`CoFakerCountries.gdpTop10` follows the World Bank World Development
Indicators, indicator `NY.GDP.MKTP.CD` (GDP, current US$). These are 2025
values, last updated on 2026-07-13, from
`https://api.worldbank.org/v2/country/all/indicator/NY.GDP.MKTP.CD?date=2025`.

| Rank | Country | Locale | Currency | GDP 2025 (US$ bn) |
|---:|---|---|---|---:|
| 1 | United States | `en_US` | USD | 30,770 |
| 2 | China | `zh_CN` | CNY | 19,498 |
| 3 | Germany | `de_DE` | EUR | 5,051 |
| 4 | Japan | `ja_JP` | JPY (no minor unit) | 4,435 |
| 5 | United Kingdom | `en_GB` | GBP | 4,003 |
| 6 | India | `en_IN` | INR | 3,956 |
| 7 | France | `fr_FR` | EUR | 3,366 |
| 8 | Russia | `ru_RU` | RUB | 2,561 |
| 9 | Italy | `it_IT` | EUR | 2,552 |
| 10 | Canada | `en_CA` | CAD | 2,320 |
| 11 | Brazil | `pt_BR` | BRL | 2,280 |

Ranks 9 to 11 are within a few percent of each other and differ between
sources and editions. The IMF's 2026 projections put Brazil in the top ten
and Canada or Russia outside it. `CoFakerCountries.all` therefore includes
Brazil, so "the GDP top ten" is covered whichever source a reader has in mind.
The ranking is a snapshot in the source code. A later edition is a source
change, not something fetched at runtime.

## Phone numbers are fictional by construction

Every generated number either sits in a range a regulator reserves for
fiction, or uses a prefix that no number type uses. Google libphonenumber
9.0.40 rejects every number from the second group for every number type, in
both notations.

| Country | Formats | Why it cannot reach a person |
|---|---|---|
| US, CA | `(212) 555-01##` and other real area codes | NANP reserves 555-0100 to 555-0199 for fiction in every area code |
| GB | `07700 900###`, `020 7946 0###`, `01x1 496 0###`, `0191 498 0###`, `029 2018 0###` | Ofcom: telephone numbers for use in TV and radio drama |
| DE | `030 23125###`, `069 90009###`, `040 66969###`, `0221 4710###`, `089 99998###`, `0171 39200##`, `0176 040690##` | Bundesnetzagentur, Mitteilung 148/2021 ("Drama Numbers") |
| FR | `06 39 98 ## ##`, `01 99 00 ## ##`, `02 61 91`, `03 53 01`, `04 65 71`, `05 36 49` | ARCEP, décision 2018-0881: blocks for audiovisual productions |
| JP | `090-0###-####`, `070-0###-####`, `03-0###-####`, `011-0##-####` | No reserved range. Subscriber numbers never start with 0 after these prefixes. (`080-0` is toll-free and `06-0` personal, so they are excluded.) |
| CN | `154 #### ####`, `164 …`, `194 …`, `021-0###-####` | No reserved range. These mobile prefixes are unallocated, and Shanghai numbers never start with 0. |
| IN | `011 0### ####` and five other metro codes | No reserved range, and every mobile series validates. Local numbers never start with 0, the trunk prefix. |
| IT | `30# ### ####` | No reserved range. Mobile numbers start with 3, but no number type uses `30`. |
| RU | `8 (5##) ###-##-##` | No reserved range. Zone 5 is unused in the Russian numbering plan. |
| BR | `(20) 9####-####` and `(30)` to `(80)` | No reserved range. These area codes (DDD) are not assigned to any region. |

`test/national_locales_test.dart` checks every generated number against these
rules. The rules are written there from the sources, separately from the
locale data, so an edited format cannot silently become a real number.

To re-check the unassigned prefixes after a libphonenumber update, run:

```sh
pip install phonenumbers
dart run tool/national_phone_formats.dart | python3 tool/verify_phone_formats.py
```

`internet.phoneNumber()` returns the national notation. Pass
`international: true` to get the same digits with the calling code, for example
`+81 90-0123-4567`. Each country mixes mobiles and landlines by
`CoFakerNationalData.mobileShare`.

## Addresses, names, and text

- **Coherent places.** `address.postalAddress()` picks one locality, and its
  city, region, region code and postal code belong together. Postal codes use
  the city's real prefix, for example `787##` for Austin or `M@? #?#` for
  Toronto. The full code is plausible but may not exist. In
  `faker.schema`, the `city`, `postalCode`, `address` and `region` fields of
  one record share a place drawn from the record's own stream, so adding
  fields never moves it.
- **National order.** Each country writes its addresses in its own order:
  - United States: `1234 Oak Street, Austin, TX 78701`
  - Germany: `Hauptstraße 12, 10115 Berlin`
  - Japan: `〒100-0011 東京都千代田区本町2丁目3-15`
  - Russia: `630099, г. Новосибирск, ул. Ленина, д. 12`
  - Brazil: `Rua das Flores, 123 - Recife - PE, 50123-456`
- **Names.**
  - Given names come in gendered lists of 20 or more per sex.
  - Russian family names agree with the sex: `Иванова` for a woman. `fullName()`
    keeps the given and family names consistent.
  - Chinese and Japanese names are written family name first.
- **Romanized handles.** Usernames and emails are ASCII:
  - Chinese and Japanese names use an authored romanization: `佐藤` → `sato`,
    `浩然` → `haoran`.
  - Cyrillic is transliterated letter by letter: `Фёдоров` → `fyodorov`.
  - Latin diacritics are folded, and German umlauts become `ae`, `oe` and `ue`.
- **Text.**
  - Chinese and Japanese join words without spaces and end sentences with `。`.
  - Product names follow the language's word order. French, Italian and
    Portuguese put the adjective after the noun.
  - Adjectives agree with the nouns they are paired with.
- **Prices** use the currency's minor units, so yen prices are whole numbers.
- **Safe identifiers.**
  - Emails and URLs use reserved domains only: `example.com`, `example.net`,
    `example.org` and `<country>.example`.
  - Company names are invented. A regression test rejects a curated list of
    well-known brands.

## Compatibility

- The earlier language codes keep their output byte for byte:
  - `en`, `ko`, `ja`, `zh`, `es`, `fr`, `de`;
  - regional codes that still fall back to them, such as `ko_KR`, `es_MX`,
    `fr_CA` and `en_AU`;
  - unknown codes.

  `test/legacy_locale_stability_test.dart` compares their whole public
  generator surface with a snapshot recorded by 0.10.0.
- Regional codes that now have a national locale resolve to it instead of
  their language: `en_US`, `zh_CN`, `de_DE`, `ja_JP`, `en_GB`, `en_IN`,
  `fr_FR`, `ru_RU`, `it_IT`, `en_CA`, `pt_BR`. Language codes that had no data
  and fell back to English now resolve to a national locale: `it` and `ru` to
  their country, `pt` to Brazil.
- Locale lookup now uses the normalized code, as documented. Before this
  change a custom locale registered as `ko-KR` was never found.
- The national-only APIs throw a `StateError` on a language-only locale:
  `address.locality()`, `region()`, `regionCode()`, `postalCodeFor()`,
  `postalAddress()` and the `region` schema role.
- `CoFakerLocales.resolve(code)` returns the built-in locale `CoFaker` would
  pick for a code. Use it as the base when extending a locale with
  `CoFakerLocale.merge`.

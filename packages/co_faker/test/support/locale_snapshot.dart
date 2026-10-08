import 'dart:convert';

import 'package:co_faker/co_faker.dart';

/// Locale codes whose output must stay byte-identical across releases.
///
/// The language codes shipped before 0.11.0 and regional codes that still
/// fall back to them. `xx_yy` covers the English fallback for unknown codes.
const List<String> stableLocaleCodes = <String>[
  'en',
  'ko',
  'ja',
  'zh',
  'es',
  'fr',
  'de',
  'es_MX',
  'ko_KR',
  'fr_CA',
  'de_AT',
  'zh_TW',
  'en_AU',
  'xx_YY',
];

/// Whether [key] of the snapshot is a domain key: a value that the domain
/// data of the language decides (the clinic and the SaaS data, and the
/// entities that the clinic and SaaS packs generate), as opposed to the base
/// modules (person, address, internet, text, ...) that the locale data decides.
///
/// The base keys keep their 0.10.0 bytes for every code, always. The domain
/// keys keep them while the language has no domain data of its own: once a
/// language is localized its clinic, SaaS, and domain pack output reads the
/// language instead of English, which is the point of localizing it. See
/// `domainLocalized` in `language_state.dart`.
bool isDomainSnapshotKey(String key) =>
    key.startsWith('clinic.') ||
    key == 'schema.patient' ||
    key == 'schema.invoice';

/// Exercises the generic public API of a seeded [CoFaker] for [locale] and
/// returns every value as a string, keyed by call site.
///
/// The snapshot only reads public generators, so it can be produced by one
/// release and compared against another.
Map<String, String> localeSnapshot(String locale) {
  CoFaker faker() => CoFaker(
    locale: locale,
    seed: 20261005,
    now: DateTime.utc(2026, 10, 5, 9),
    domains: CoFakerDomains.all,
  );

  final values = <String, String>{};
  void put(String key, Object? value) {
    values[key] = value is String ? value : jsonEncode(_jsonSafe(value));
  }

  final f = faker();
  for (var i = 0; i < 3; i++) {
    put('person.firstName.$i', f.person.firstName());
    put('person.lastName.$i', f.person.lastName());
    put('person.fullName.$i', f.person.fullName());
  }
  put('person.firstName.female', f.person.firstName(sex: CoSex.female));
  put('person.firstName.male', f.person.firstName(sex: CoSex.male));
  put('person.fullName.female', f.person.fullName(sex: CoSex.female));
  put('person.fullName.male', f.person.fullName(sex: CoSex.male));
  put('person.name', f.person.name());
  put('person.username.0', f.person.username());
  put('person.username.1', f.person.username());
  put('person.jobTitle', f.person.jobTitle());
  put('person.gender', f.person.gender());
  put('person.sex', f.person.sex().name);

  for (var i = 0; i < 2; i++) {
    put('address.city.$i', f.address.city());
    put('address.country.$i', f.address.country());
    put('address.countryCode.$i', f.address.countryCode());
    put('address.streetName.$i', f.address.streetName());
    put('address.streetAddress.$i', f.address.streetAddress());
    put('address.postalCode.$i', f.address.postalCode());
    put('address.fullAddress.$i', f.address.fullAddress());
  }
  put('address.latitude', f.address.latitude());
  put('address.longitude', f.address.longitude());

  for (var i = 0; i < 3; i++) {
    put('internet.email.$i', f.internet.email());
    put('internet.phoneNumber.$i', f.internet.phoneNumber());
  }
  put('internet.domain', f.internet.domain());
  put('internet.url', f.internet.url());
  put('internet.ipv4', f.internet.ipv4());
  put('internet.ipv6', f.internet.ipv6());

  put('text.word', f.text.word());
  put('text.words', f.text.words(4));
  put('text.sentence', f.text.sentence());
  put('text.sentences', f.text.sentences(2));
  put('text.paragraph', f.text.paragraph());
  put('text.slug', f.text.slug());

  put('number.int', f.number.int());
  put('number.decimal', f.number.decimal());
  put('number.bool', f.number.bool());

  put('date.past', f.date.past(utc: true));
  put('date.future', f.date.future(utc: true));
  put('date.dateOfBirth', f.date.dateOfBirth(utc: true));

  for (var i = 0; i < 2; i++) {
    put('commerce.productName.$i', f.commerce.productName());
    put('commerce.companyName.$i', f.commerce.companyName());
    put('commerce.price.$i', f.commerce.price());
  }
  put('commerce.category', f.commerce.category());
  final currency = f.commerce.currency();
  put('commerce.currency', '${currency.code} ${currency.symbol}');

  put('id.uuid', f.id.uuid());
  put('id.uuidV7', f.id.uuidV7());
  put('image.avatarDataUri', f.image.avatarDataUri());
  put('image.placeholderDataUri', f.image.placeholderDataUri());

  put(
    'fake',
    f.fake(
      '{{person.fullName}} <{{internet.email}}> {{address.city}} '
      '{{address.postalCode}} {{internet.phoneNumber}} {{commerce.companyName}}',
    ),
  );
  put('derive.fullName', f.derive('customer/1').person.fullName());
  put('localized.fullName', faker().localized('en').person.fullName());

  final schemaFaker = faker();
  put(
    'schema.records',
    schemaFaker.schema.records(3, const {
      'id': 'int',
      'name': 'String',
      'email': 'String',
      'phone': 'String',
      'city': 'String',
      'country': 'String',
      'postalCode': 'String',
      'address': 'String',
      'company': 'String',
      'price': 'double',
      'currency': 'String',
      'title': 'String',
      'description': 'String',
      'slug': 'String',
      'createdAt': 'DateTime',
    }, entity: 'customer'),
  );
  put('schema.patient', schemaFaker.schema.entities('clinic.patient', 2));
  put('schema.invoice', schemaFaker.schema.entities('saas.invoice', 2));

  final korea = faker().korea;
  put('korea.mobilePhone', korea.mobilePhone());
  put('korea.landlinePhone', korea.landlinePhone());
  put('korea.rrn', korea.rrn());
  put('korea.businessNumber', korea.businessNumber());
  put('korea.roadAddress', korea.roadAddress().line1);

  final clinic = faker().clinic;
  put('clinic.clinicName', clinic.clinicName());
  put('clinic.drugName', clinic.drugName());
  put('clinic.chartMemo', clinic.chartMemo());

  return values;
}

Object? _jsonSafe(Object? value) {
  return switch (value) {
    final DateTime date => date.toIso8601String(),
    final Map<Object?, Object?> map => <String, Object?>{
      for (final entry in map.entries) '${entry.key}': _jsonSafe(entry.value),
    },
    final Iterable<Object?> list => list.map(_jsonSafe).toList(),
    _ => value,
  };
}

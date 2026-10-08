import 'clinic.dart';
import 'co_faker_languages.dart';
import 'co_faker_locale.dart';
import 'countries/co_faker_countries.dart';
import 'countries/co_faker_country.dart';
import 'domain.dart';
import 'domain_packs/co_faker_fx.dart';
import 'domain_packs/co_faker_remit.dart';
import 'domain_packs/co_faker_vet.dart';
import 'domain_packs/co_faker_booking.dart';
import 'domain_packs/co_faker_catalog.dart';
import 'domain_packs/co_faker_exam_prep.dart';
import 'co_faker_locales.dart';
import 'korea.dart';
import 'modules.dart';
import 'random_source.dart';
import 'saas.dart';
import 'signature.dart';
import 'schema.dart';

/// A callback used by [CoFaker.generate].
typedef CoFakerBuilder<T> = T Function(CoFaker faker, int index);

/// A pure Dart fake data generator for tests, fixtures, prototypes, and seed
/// scripts.
///
/// A single [CoFaker] owns the random stream, locale, and module instances.
/// Pass [seed] whenever a test or fixture needs repeatable data, and pass
/// [now] as well when dates must be repeatable too.
///
/// ```dart
/// final faker = CoFaker(locale: 'ko', seed: 42, now: DateTime.utc(2026));
/// final user = faker.object({
///   'id': (_) => faker.id.uuid(),
///   'name': (_) => faker.person.fullName(),
///   'email': (_) => faker.internet.email(),
/// });
/// final users = faker.generate(20, (faker, index) => {
///   'index': index,
///   'name': faker.person.fullName(),
/// });
/// final course = faker.schema({'title': 'String', 'price': 'int'});
/// ```
class CoFaker {
  /// Creates a fake data generator.
  ///
  /// [locale] accepts language codes such as `en`, `ko`, `ja`, `zh`, `es`,
  /// `fr`, and `de`, and national codes such as `en_US` or `ja-JP` for the
  /// countries in [CoFakerCountries]. A code first tries an exact custom or
  /// built-in locale, then falls back to the language, then English.
  ///
  /// The language codes that predate national locales (`en`, `ko`, `ja`,
  /// `zh`, `es`, `fr`, `de`) keep their language-only data, which is thinner
  /// than the data of a national locale such as `ja_JP`. To follow an app's
  /// language setting, use [CoFaker.forLanguage] instead: it also reads tags
  /// such as `zh-Hans` and `ja_JP.UTF-8`, and gives each language the data
  /// of its national locale.
  CoFaker({
    String locale = 'en',
    int? seed,
    DateTime? now,
    Map<String, CoFakerLocale> locales = const <String, CoFakerLocale>{},
    CoRandom? random,
    this.domains = const <CoFakerDomain>[],
  }) : locale = _normalizeLocale(locale),
       now = now ?? DateTime.now(),
       random = random ?? CoRandom(seed),
       _customLocales = _normalizeLocales(locales) {
    final available = <String, CoFakerLocale>{
      ...CoFakerLocales.all,
      ..._customLocales,
    };
    // `this.locale` is the normalized code: the raw parameter would miss
    // regional keys such as `ja_jp` and custom locales such as `ko-KR`.
    final selected =
        available[this.locale] ??
        available[_languageCode(this.locale)] ??
        available['en']!;
    localeData = selected.merge(available['en']!);
  }

  /// Creates a generator for the national locale of [code], an ISO 3166-1
  /// alpha-2 or alpha-3 country code such as `JP` or `BRA`.
  ///
  /// Throws an [ArgumentError] for countries without a national locale; see
  /// [CoFakerCountries.all].
  factory CoFaker.forCountry(
    String code, {
    int? seed,
    DateTime? now,
    Map<String, CoFakerLocale> locales = const <String, CoFakerLocale>{},
    CoRandom? random,
    List<CoFakerDomain> domains = const <CoFakerDomain>[],
  }) {
    final country = CoFakerCountries.byCode(code);
    if (country == null) {
      throw ArgumentError.value(
        code,
        'code',
        'no national locale; supported: '
            '${CoFakerCountries.all.map((country) => country.code).join(', ')}',
      );
    }
    return CoFaker(
      locale: country.locale,
      seed: seed,
      now: now,
      locales: locales,
      random: random,
      domains: domains,
    );
  }

  /// Creates a generator for an app's language setting [tag], such as the
  /// BCP-47 tag `zh-Hans` or `pt-BR`, the POSIX locale `ja_JP.UTF-8`, or the
  /// output of Flutter's `Locale.toLanguageTag()`.
  ///
  /// [CoFakerLanguages.resolve] reads the tag: case, `-` versus `_`, the
  /// script subtag, the encoding, and the modifier are ignored. The language
  /// is then generated with the national locale of its country: `en` with
  /// `en_US`, `zh` with `zh_CN`, `ja` with `ja_JP`, `de` with `de_DE`, `fr`
  /// with `fr_FR`, `ru` with `ru_RU`, `it` with `it_IT`, and `pt` with
  /// `pt_BR`. That is the data of [CoFaker.forCountry], whereas
  /// `CoFaker(locale: 'ja')` selects the thinner language-only data.
  ///
  /// `ko` and `es` have no national locale and keep their language-only
  /// locales. Their [country] is `null`, and the address methods that need a
  /// national locale (`postalAddress`, `locality`, `region`, `regionCode`,
  /// `postalCodeFor`) throw a [StateError], as they do for
  /// `CoFaker(locale: 'ko')`.
  ///
  /// A language that is not supported, and Traditional Chinese (`zh-Hant`,
  /// `zh_TW`, `zh_HK`, `zh_MO`), get English (`en_US`): its readers are never
  /// handed Simplified text. `CoFakerLanguages.resolve(tag).supported` tells
  /// whether a setting was honored.
  ///
  /// [seed], [now], [locales], [random], and [domains] are passed to the
  /// [CoFaker] constructor unchanged. [locales] are looked up by the code of
  /// the resolved locale (`ja_jp`), not by the tag or the language code: a
  /// custom locale registered as `ja` is shadowed by the built-in `ja_jp`, so
  /// register an override under `CoFakerLanguage.locale`. The constructor
  /// keeps its own rule, and `CoFaker(locale: 'ja', locales: {'ja': custom})`
  /// still selects `custom`.
  ///
  /// ```dart
  /// final faker = CoFaker.forLanguage('zh-Hans-CN', seed: 7);
  /// faker.locale;   // zh_cn
  /// faker.language; // zh
  /// ```
  factory CoFaker.forLanguage(
    String tag, {
    int? seed,
    DateTime? now,
    Map<String, CoFakerLocale> locales = const <String, CoFakerLocale>{},
    CoRandom? random,
    List<CoFakerDomain> domains = const <CoFakerDomain>[],
  }) {
    return CoFaker(
      locale: CoFakerLanguages.resolve(tag).locale,
      seed: seed,
      now: now,
      locales: locales,
      random: random,
      domains: domains,
    );
  }

  /// The normalized locale code selected for this generator.
  final String locale;

  /// The language of [locale]: the code before its first `_`, such as `ja`
  /// for `ja_jp` and `zh` for `zh_hans`.
  ///
  /// It follows [locale] and nothing else, so `zh_tw`, which has always been
  /// served the Chinese data, reports `zh`. [CoFakerLanguages.resolve] is the
  /// strict reader: it refuses Traditional Chinese, so
  /// `CoFakerLanguages.resolve(locale).supported` tells whether the locale
  /// is a supported language.
  String get language => _languageCode(locale);

  /// The clock used by date generation.
  final DateTime now;

  /// Registered domain packs, used by [schema] to resolve and infer domain
  /// roles and to generate domain entities. See [CoFakerDomain].
  final List<CoFakerDomain> domains;

  /// The random source shared by all modules.
  final CoRandom random;

  /// The seed of [random], or `null` when the stream is not seeded.
  int? get seed => random.seed;

  /// The effective locale data after English fallback is applied.
  late final CoFakerLocale localeData;

  /// The country of a national locale, or `null` for a language-only locale
  /// such as `en` or `ko`.
  CoFakerCountry? get country => localeData.national?.country;

  final Map<String, CoFakerLocale> _customLocales;

  /// Person and identity values.
  late final CoFakerPerson person = CoFakerPerson(this);

  /// Address and location values.
  late final CoFakerAddress address = CoFakerAddress(this);

  /// Email, URL, IP, and phone values.
  late final CoFakerInternet internet = CoFakerInternet(this);

  /// Placeholder text values.
  late final CoFakerText text = CoFakerText(this);

  /// Alias for [text], matching the naming used by common faker libraries.
  CoFakerText get lorem => text;

  /// Numeric and boolean values.
  late final CoFakerNumber number = CoFakerNumber(this);

  /// Date and time values.
  late final CoFakerDate date = CoFakerDate(this);

  /// Commerce and product values.
  late final CoFakerCommerce commerce = CoFakerCommerce(this);

  /// Identifier values.
  late final CoFakerId id = CoFakerId(this);

  /// Image URLs and offline image data URIs.
  late final CoFakerImage image = CoFakerImage(this);

  /// Korean identity values that are deliberately invalid: unassignable
  /// phone numbers, checksum-failing resident and business registration
  /// numbers, and road-name addresses.
  late final CoFakerKorea korea = CoFakerKorea(this);

  /// Clinic and EMR domain values: clinics, staff, patients, procedures,
  /// diagnoses, prescriptions, chart notes, slots, visit flow, payments.
  late final CoFakerClinic clinic = CoFakerClinic(this);

  /// SaaS back-office values: tenants, plans, subscriptions, invoices,
  /// messaging, claim masters, integration health, audit logs, KPIs.
  late final CoFakerSaas saas = CoFakerSaas(this);

  /// Offline fictional currency quotes and daily UTC rate series.
  late final CoFakerFx fx = CoFakerFx(this);

  /// Masked remittance recipients and coherent illustrative transfers.
  late final CoFakerRemit remit = CoFakerRemit(this);

  /// Coherent fictional pet species, breed and weight profiles.
  late final CoFakerVet vet = CoFakerVet(this);

  /// Coherent UTC booking blocks, including optional closed Sundays.
  late final CoFakerBooking booking = CoFakerBooking(this);

  /// Brand-free commerce/grocery catalog entries.
  late final CoFakerCatalog catalog = CoFakerCatalog(this);

  /// Authored IT questions with shuffled choices and matching answers.
  late final CoFakerExamPrep examPrep = CoFakerExamPrep(this);

  /// Handwritten-looking signature strokes, SVG, and open_board points.
  late final CoFakerSignature signature = CoFakerSignature(this);

  /// Records generated from a field schema, callable as
  /// `faker.schema(fields)`.
  late final CoFakerSchema schema = CoFakerSchema(this);

  /// Creates another view with the same random stream and a different locale.
  ///
  /// Sharing the stream is useful when a fixture switches locale for one
  /// field. Create a new [CoFaker] with the same [seed] for an independent
  /// stream instead.
  CoFaker localized(String locale) {
    return CoFaker(
      locale: locale,
      now: now,
      random: random,
      locales: _customLocales,
      domains: domains,
    );
  }

  /// Creates a generator with an independent random stream derived from this
  /// generator's seed and [key], keeping the locale, clock, and custom
  /// locales.
  ///
  /// Use one derived generator per entity, record, or field so that adding a
  /// field to a fixture does not change the values of the other fields. The
  /// same seed and [key] always produce the same derived stream.
  CoFaker derive(String key) {
    return CoFaker(
      locale: locale,
      now: now,
      random: random.derive(key),
      locales: _customLocales,
      domains: domains,
    );
  }

  /// Generates [count] values using [builder].
  List<T> generate<T>(int count, CoFakerBuilder<T> builder) {
    if (count < 0) {
      throw ArgumentError.value(count, 'count', 'must not be negative');
    }
    return List<T>.generate(
      count,
      (index) => builder(this, index),
      growable: false,
    );
  }

  /// Generates a map from field factories, useful for untyped API fixtures.
  Map<String, Object?> object(
    Map<String, Object? Function(CoFaker faker)> fields,
  ) {
    return <String, Object?>{
      for (final entry in fields.entries) entry.key: entry.value(this),
    };
  }

  /// Replaces faker placeholders such as `{{person.fullName}}` in [template].
  ///
  /// Unknown placeholders are preserved. [custom] can add project-specific
  /// providers without subclassing or modifying the generator.
  String fake(
    String template, {
    Map<String, String Function(CoFaker faker)> custom =
        const <String, String Function(CoFaker faker)>{},
  }) {
    final providers = <String, String Function(CoFaker faker)>{
      'person.firstName': (_) => person.firstName(),
      'person.lastName': (_) => person.lastName(),
      'person.fullName': (_) => person.fullName(),
      'person.name': (_) => person.name(),
      'person.username': (_) => person.username(),
      'person.jobTitle': (_) => person.jobTitle(),
      'address.city': (_) => address.city(),
      'address.country': (_) => address.country(),
      'address.streetAddress': (_) => address.streetAddress(),
      'address.postalCode': (_) => address.postalCode(),
      'internet.email': (_) => internet.email(),
      'internet.domain': (_) => internet.domain(),
      'internet.url': (_) => internet.url(),
      'internet.ipv4': (_) => internet.ipv4(),
      'internet.phoneNumber': (_) => internet.phoneNumber(),
      'text.word': (_) => text.word(),
      'text.sentence': (_) => text.sentence(),
      'lorem.word': (_) => text.word(),
      'lorem.sentence': (_) => text.sentence(),
      'commerce.productName': (_) => commerce.productName(),
      'commerce.companyName': (_) => commerce.companyName(),
      'commerce.category': (_) => commerce.category(),
      'id.uuid': (_) => id.uuid(),
      'image.avatarUrl': (_) => image.avatarUrl(),
      'image.placeholderDataUri': (_) => image.placeholderDataUri(),
      'korea.mobilePhone': (_) => korea.mobilePhone(),
      'korea.landlinePhone': (_) => korea.landlinePhone(),
      'korea.rrn': (_) => korea.rrn(),
      'korea.businessNumber': (_) => korea.businessNumber(),
      'clinic.clinicName': (_) => clinic.clinicName(),
      'clinic.chartMemo': (_) => clinic.chartMemo(),
      'clinic.drugName': (_) => clinic.drugName(),
      'clinic.insurerName': (_) => clinic.insurerName(),
      'clinic.feedback': (_) => clinic.feedback().comment,
      ...custom,
    };

    return template.replaceAllMapped(RegExp(r'\{\{\s*([\w.]+)\s*\}\}'), (
      match,
    ) {
      final key = match.group(1)!;
      final provider = providers[key];
      return provider == null ? match.group(0)! : provider(this);
    });
  }

  static Map<String, CoFakerLocale> _normalizeLocales(
    Map<String, CoFakerLocale> locales,
  ) {
    return <String, CoFakerLocale>{
      for (final entry in locales.entries)
        _normalizeLocale(entry.key): entry.value,
    };
  }

  static String _normalizeLocale(String value) {
    return value.trim().replaceAll('-', '_').toLowerCase();
  }

  static String _languageCode(String value) {
    return _normalizeLocale(value).split('_').first;
  }
}

import 'co_faker_locale.dart';
import 'co_faker_locales.dart';
import 'modules.dart';
import 'random_source.dart';
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
  /// `fr`, and `de`. Regional values such as `ko_KR` first try an exact
  /// custom locale, then fall back to the language, then English.
  CoFaker({
    String locale = 'en',
    int? seed,
    DateTime? now,
    Map<String, CoFakerLocale> locales = const <String, CoFakerLocale>{},
    CoRandom? random,
  }) : locale = _normalizeLocale(locale),
       now = now ?? DateTime.now(),
       random = random ?? CoRandom(seed),
       _customLocales = _normalizeLocales(locales) {
    final available = <String, CoFakerLocale>{
      ...CoFakerLocales.all,
      ..._customLocales,
    };
    final selected =
        available[locale] ??
        available[_languageCode(locale)] ??
        available['en']!;
    localeData = selected.merge(available['en']!);
  }

  /// The normalized locale code selected for this generator.
  final String locale;

  /// The clock used by date generation.
  final DateTime now;

  /// The random source shared by all modules.
  final CoRandom random;

  /// The seed of [random], or `null` when the stream is not seeded.
  int? get seed => random.seed;

  /// The effective locale data after English fallback is applied.
  late final CoFakerLocale localeData;

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

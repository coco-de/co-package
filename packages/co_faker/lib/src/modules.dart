import 'dart:core';
import 'dart:core' as core;

import 'co_faker.dart';

/// Generates person and identity values.
class CoFakerPerson {
  /// Creates a person generator backed by [faker].
  CoFakerPerson(this.faker);

  /// The faker instance used by this module.
  final CoFaker faker;

  /// Generates a localized first name.
  String firstName() => faker.random.pick(faker.localeData.firstNames);

  /// Generates a localized last name.
  String lastName() => faker.random.pick(faker.localeData.lastNames);

  /// Generates a localized gender label.
  String gender() => faker.random.pick(faker.localeData.genders);

  /// Generates a name from the current locale's name format.
  String fullName({String? firstName, String? lastName}) {
    final first = firstName ?? this.firstName();
    final last = lastName ?? this.lastName();
    return faker.localeData.nameFormat
        .replaceAll('{first}', first)
        .replaceAll('{last}', last);
  }

  /// Alias for [fullName], useful when mirroring common faker APIs.
  String name({String? firstName, String? lastName}) {
    return fullName(firstName: firstName, lastName: lastName);
  }

  /// Generates a localized job title.
  String jobTitle() => faker.random.pick(faker.localeData.jobTitles);

  /// Generates a URL-safe username.
  String username({String? firstName, String? lastName}) {
    final first = _slugPart(firstName ?? this.firstName());
    final last = _slugPart(lastName ?? this.lastName());
    final base = [first, last].where((part) => part.isNotEmpty).join('.');
    return base.isEmpty ? 'user${faker.number.int(min: 1, max: 9999)}' : base;
  }

  static String _slugPart(String value) {
    return value.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');
  }
}

/// Generates addresses and geographic values.
class CoFakerAddress {
  /// Creates an address generator backed by [faker].
  CoFakerAddress(this.faker);

  /// The faker instance used by this module.
  final CoFaker faker;

  /// Generates a city name.
  String city() => faker.random.pick(faker.localeData.cities);

  /// Generates a country name.
  String country() => faker.random.pick(faker.localeData.countries);

  /// Generates an ISO-like country code.
  String countryCode() => faker.random.pick(faker.localeData.countryCodes);

  /// Generates a street name.
  String streetName() => faker.random.pick(faker.localeData.streetNames);

  /// Generates a street address.
  String streetAddress() {
    return faker.localeData.addressFormat
        .replaceAll('{number}', faker.random.int(min: 1, max: 9999).toString())
        .replaceAll('{street}', streetName())
        .replaceAll('{city}', city());
  }

  /// Generates a postal code from the locale's `#` template.
  String postalCode() => faker.random.digits(faker.localeData.postalCodeFormat);

  /// Generates a complete address string.
  String fullAddress() {
    return '${streetAddress()}, ${postalCode()}, ${country()}';
  }

  /// Generates a latitude in the valid geographic range.
  double latitude() => faker.number.double(min: -90, max: 90);

  /// Generates a longitude in the valid geographic range.
  double longitude() => faker.number.double(min: -180, max: 180);
}

/// Generates email addresses, domains, URLs, and network values.
class CoFakerInternet {
  /// Creates an internet generator backed by [faker].
  CoFakerInternet(this.faker);

  /// The faker instance used by this module.
  final CoFaker faker;

  /// Generates an email address from a name and a safe example domain.
  String email({String? firstName, String? lastName, String? domain}) {
    final user = faker.person.username(
      firstName: firstName,
      lastName: lastName,
    );
    final selectedDomain =
        domain ?? faker.random.pick(faker.localeData.emailDomains);
    return '$user@$selectedDomain';
  }

  /// Generates a domain name.
  String domain() => faker.random.pick(faker.localeData.domains);

  /// Generates an HTTPS URL.
  String url({String? path}) {
    final suffix = path ?? faker.person.username();
    return 'https://${domain()}/${_urlPart(suffix)}';
  }

  /// Generates an IPv4 address.
  String ipv4() {
    return List<String>.generate(
      4,
      (_) => faker.number.int(min: 0, max: 255).toString(),
      growable: false,
    ).join('.');
  }

  /// Generates an IPv6 address.
  String ipv6() {
    return List<String>.generate(
      8,
      (_) => faker.random.string(4, alphabet: '0123456789abcdef'),
      growable: false,
    ).join(':');
  }

  /// Generates a phone number from the locale's phone template.
  String phoneNumber() =>
      faker.random.digits(faker.random.pick(faker.localeData.phoneFormats));

  static String _urlPart(String value) {
    final part = value.toLowerCase().replaceAll(RegExp('[^a-z0-9/-]'), '-');
    return part.replaceAll(RegExp('-+'), '-').replaceAll(RegExp(r'^-|-$'), '');
  }
}

/// Generates localized placeholder text.
class CoFakerText {
  /// Creates a text generator backed by [faker].
  CoFakerText(this.faker);

  /// The faker instance used by this module.
  final CoFaker faker;

  /// Generates one localized word.
  String word() => faker.random.pick(faker.localeData.words);

  /// Generates [count] localized words.
  String words(int count) {
    _checkCount(count);
    return List<String>.generate(count, (_) => word()).join(' ');
  }

  /// Generates a sentence containing [wordCount] words.
  String sentence({int wordCount = 6}) {
    final value = words(wordCount);
    if (value.isEmpty) return value;
    return '${value[0].toUpperCase()}${value.substring(1)}.';
  }

  /// Generates [count] sentences.
  String sentences(int count, {int wordCount = 6}) {
    _checkCount(count);
    return List<String>.generate(
      count,
      (_) => sentence(wordCount: wordCount),
    ).join(' ');
  }

  /// Generates [count] sentences separated by newlines.
  String paragraph({int sentenceCount = 3, int wordCount = 6}) {
    return sentences(sentenceCount, wordCount: wordCount);
  }

  /// Generates [count] paragraphs separated by blank lines.
  String paragraphs(int count, {int sentenceCount = 3, int wordCount = 6}) {
    _checkCount(count);
    return List<String>.generate(
      count,
      (_) => paragraph(sentenceCount: sentenceCount, wordCount: wordCount),
    ).join('\n\n');
  }

  /// Generates a lowercase slug.
  String slug({int wordCount = 3}) {
    return words(wordCount)
        .toLowerCase()
        .replaceAll(RegExp('[^a-z0-9 ]'), '')
        .trim()
        .replaceAll(RegExp(' +'), '-');
  }

  static void _checkCount(int count) {
    if (count < 0) {
      throw ArgumentError.value(count, 'count', 'must not be negative');
    }
  }
}

/// Generates numbers and booleans.
class CoFakerNumber {
  /// Creates a number generator backed by [faker].
  CoFakerNumber(this.faker);

  /// The faker instance used by this module.
  final CoFaker faker;

  /// Generates an integer in the inclusive range [min]..[max].
  core.int int({core.int min = 0, core.int max = 999}) {
    return faker.random.int(min: min, max: max);
  }

  /// Alias for [int] when a more explicit name reads better in a schema.
  core.int integer({core.int min = 0, core.int max = 999}) {
    return int(min: min, max: max);
  }

  /// Generates a double in the inclusive range [min]..[max].
  core.double double({core.double min = 0, core.double max = 1}) {
    return faker.random.double(min: min, max: max);
  }

  /// Generates a decimal number rounded to [decimals] places.
  core.double decimal({
    core.double min = 0,
    core.double max = 100,
    core.int decimals = 2,
  }) {
    if (decimals < 0) {
      throw ArgumentError.value(decimals, 'decimals', 'must not be negative');
    }
    return core.double.parse(
      double(min: min, max: max).toStringAsFixed(decimals),
    );
  }

  /// Generates a random boolean.
  core.bool bool() => faker.random.bool();
}

/// Generates dates relative to the clock captured by [CoFaker].
class CoFakerDate {
  /// Creates a date generator backed by [faker].
  CoFakerDate(this.faker);

  /// The faker instance used by this module.
  final CoFaker faker;

  /// Generates a date between [from] and [to], inclusive.
  DateTime between(DateTime from, DateTime to) {
    if (from.isAfter(to)) {
      throw ArgumentError.value(from, 'from', 'must not be after to');
    }
    final range = to.millisecondsSinceEpoch - from.millisecondsSinceEpoch;
    if (range == 0) return from;
    return DateTime.fromMillisecondsSinceEpoch(
      from.millisecondsSinceEpoch + faker.random.int(max: range),
    );
  }

  /// Generates a date within the previous [days] days.
  DateTime past({int days = 365}) {
    _checkDays(days);
    return between(faker.now.subtract(Duration(days: days)), faker.now);
  }

  /// Generates a date within the next [days] days.
  DateTime future({int days = 365}) {
    _checkDays(days);
    return between(faker.now, faker.now.add(Duration(days: days)));
  }

  /// Generates a date of birth for an age in the inclusive range.
  DateTime dateOfBirth({int minAge = 18, int maxAge = 70}) {
    if (minAge < 0 || maxAge < minAge) {
      throw ArgumentError('minAge and maxAge must describe a valid age range');
    }
    final age = faker.number.int(min: minAge, max: maxAge);
    final end = DateTime(faker.now.year - age, faker.now.month, faker.now.day);
    final start = DateTime(
      faker.now.year - age - 1,
      faker.now.month,
      faker.now.day + 1,
    );
    return between(start, end);
  }

  static void _checkDays(int days) {
    if (days < 0) {
      throw ArgumentError.value(days, 'days', 'must not be negative');
    }
  }
}

/// Generates commerce and product values.
class CoFakerCommerce {
  /// Creates a commerce generator backed by [faker].
  CoFakerCommerce(this.faker);

  /// The faker instance used by this module.
  final CoFaker faker;

  /// Generates a product name from a localized adjective and noun.
  String productName() {
    final adjective = faker.random.pick(faker.localeData.productAdjectives);
    final noun = faker.random.pick(faker.localeData.productNouns);
    return '$adjective $noun';
  }

  /// Generates a product category.
  String category() => faker.random.pick(faker.localeData.categories);

  /// Generates a localized company name.
  String companyName() => faker.random.pick(faker.localeData.companyNames);

  /// Generates a price with two decimal places.
  double price({double min = 5, double max = 500}) {
    return faker.number.decimal(min: min, max: max);
  }

  /// Returns the current locale's currency code and symbol.
  ({String code, String symbol}) currency() {
    return (
      code: faker.localeData.currencyCode,
      symbol: faker.localeData.currencySymbol,
    );
  }
}

/// Generates identifiers and safe local image URLs.
class CoFakerId {
  /// Creates an identifier generator backed by [faker].
  CoFakerId(this.faker);

  /// The faker instance used by this module.
  final CoFaker faker;

  /// Generates a deterministic UUID v4-shaped identifier.
  String uuid() {
    final part1 = hex(8);
    final part2 = hex(4);
    final part3 = '4${hex(3)}';
    final variant = faker.random.pick(<String>['8', '9', 'a', 'b']);
    final part4 = '$variant${hex(3)}';
    final part5 = hex(12);
    return '$part1-$part2-$part3-$part4-$part5';
  }

  /// Generates a hexadecimal string of [length].
  String hex(int length) {
    if (length < 0) {
      throw ArgumentError.value(length, 'length', 'must not be negative');
    }
    return faker.random.string(length, alphabet: '0123456789abcdef');
  }
}

/// Generates image URLs without downloading or contacting a server.
class CoFakerImage {
  /// Creates an image generator backed by [faker].
  CoFakerImage(this.faker);

  /// The faker instance used by this module.
  final CoFaker faker;

  /// Generates a stable avatar URL pointing at a public placeholder service.
  String avatarUrl({int size = 128}) {
    _checkSize(size);
    final image = faker.number.int(min: 1, max: 70);
    return 'https://i.pravatar.cc/$size?img=$image';
  }

  /// Generates a placeholder image URL.
  String placeholderUrl({int width = 640, int height = 480}) {
    _checkSize(width);
    _checkSize(height);
    return 'https://placehold.co/${width}x$height';
  }

  static void _checkSize(int size) {
    if (size <= 0) {
      throw ArgumentError.value(size, 'size', 'must be greater than zero');
    }
  }
}

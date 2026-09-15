import 'dart:convert';
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
  ///
  /// With [utc] the result is a UTC value, so `toIso8601String()` carries a
  /// `Z` suffix and fixtures compare equal across machines in different time
  /// zones. Without it the result is in the local time zone.
  DateTime between(DateTime from, DateTime to, {bool utc = false}) {
    if (from.isAfter(to)) {
      throw ArgumentError.value(from, 'from', 'must not be after to');
    }
    final range = to.millisecondsSinceEpoch - from.millisecondsSinceEpoch;
    final offset = range == 0 ? 0 : faker.random.int(max: range);
    return DateTime.fromMillisecondsSinceEpoch(
      from.millisecondsSinceEpoch + offset,
      isUtc: utc,
    );
  }

  /// Generates a date within the previous [days] days.
  DateTime past({int days = 365, bool utc = false}) {
    _checkDays(days);
    return between(
      faker.now.subtract(Duration(days: days)),
      faker.now,
      utc: utc,
    );
  }

  /// Generates a date within the next [days] days.
  DateTime future({int days = 365, bool utc = false}) {
    _checkDays(days);
    return between(faker.now, faker.now.add(Duration(days: days)), utc: utc);
  }

  /// Generates a date of birth for an age in the inclusive range.
  DateTime dateOfBirth({int minAge = 18, int maxAge = 70, bool utc = false}) {
    if (minAge < 0 || maxAge < minAge) {
      throw ArgumentError('minAge and maxAge must describe a valid age range');
    }
    final age = faker.number.int(min: minAge, max: maxAge);
    final now = utc ? faker.now.toUtc() : faker.now;
    final end = utc
        ? DateTime.utc(now.year - age, now.month, now.day)
        : DateTime(now.year - age, now.month, now.day);
    final start = utc
        ? DateTime.utc(now.year - age - 1, now.month, now.day + 1)
        : DateTime(now.year - age - 1, now.month, now.day + 1);
    return between(start, end, utc: utc);
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

/// Generates image URLs and offline image data URIs without downloading or
/// contacting a server.
///
/// [avatarUrl] and [placeholderUrl] point at public placeholder services and
/// need network access when rendered. [placeholderDataUri] and
/// [avatarDataUri] embed a small SVG in the value itself, so widget tests,
/// golden files, and offline demos render them without any request.
class CoFakerImage {
  /// Creates an image generator backed by [faker].
  CoFakerImage(this.faker);

  /// The faker instance used by this module.
  final CoFaker faker;

  /// Background colors used by the data URI generators.
  static const List<String> palette = <String>[
    '#4F6D8F',
    '#5B8C5A',
    '#B2452D',
    '#1E6E76',
    '#A66B0A',
    '#6B4E9B',
    '#8A5A44',
    '#3C7A89',
  ];

  /// Generates an SVG placeholder image as a `data:image/svg+xml;base64,` URI.
  ///
  /// The background is picked from [palette] unless [background] is given,
  /// and [label] (default `width×height`) is centered in [foreground]. The
  /// value renders offline in `Image.network`, `<img>`, and golden tests.
  String placeholderDataUri({
    int width = 640,
    int height = 480,
    String? label,
    String? background,
    String? foreground,
  }) {
    _checkSize(width);
    _checkSize(height);
    final fill = background ?? faker.random.pick<String>(palette);
    final text = _escapeXml(label ?? '$width\u00d7$height');
    final fontSize = (width < height ? width : height) ~/ 8;
    return _svgDataUri(
      width: width,
      height: height,
      fill: fill,
      textFill: foreground ?? '#FFFFFF',
      text: text,
      fontSize: fontSize < 12 ? 12 : fontSize,
    );
  }

  /// Generates a square avatar with [initials] as a
  /// `data:image/svg+xml;base64,` URI.
  ///
  /// When [initials] is omitted the first character of a localized first
  /// name is used, so the avatar matches the locale of the fixture.
  String avatarDataUri({
    int size = 128,
    String? initials,
    String? background,
    String? foreground,
  }) {
    _checkSize(size);
    final fill = background ?? faker.random.pick<String>(palette);
    final label = initials ?? faker.person.firstName().substring(0, 1);
    return _svgDataUri(
      width: size,
      height: size,
      fill: fill,
      textFill: foreground ?? '#FFFFFF',
      text: _escapeXml(label),
      fontSize: size ~/ 2,
      rounded: true,
    );
  }

  static String _svgDataUri({
    required int width,
    required int height,
    required String fill,
    required String textFill,
    required String text,
    required int fontSize,
    bool rounded = false,
  }) {
    final radius = rounded ? ' rx="${width ~/ 2}"' : '';
    final svg =
        '<svg xmlns="http://www.w3.org/2000/svg" width="$width" '
        'height="$height" viewBox="0 0 $width $height">'
        '<rect width="$width" height="$height"$radius fill="$fill"/>'
        '<text x="50%" y="50%" dominant-baseline="central" '
        'text-anchor="middle" font-family="sans-serif" '
        'font-size="$fontSize" fill="$textFill">$text</text>'
        '</svg>';
    return 'data:image/svg+xml;base64,${base64Encode(utf8.encode(svg))}';
  }

  static String _escapeXml(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

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

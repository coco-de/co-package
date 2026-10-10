import 'co_faker.dart';
import 'countries/co_faker_locality.dart';
import 'domain.dart';

/// The kind of value a schema field should receive.
///
/// A role is inferred from the field name and type by [CoFakerSchema.infer]
/// and can be forced per field through the `roles` argument of
/// [CoFakerSchema.record]. Role names are matched case-insensitively by
/// [CoFieldRole.parse], which also accepts a few aliases such as `badge`
/// for [category] and `enum` for [status].
enum CoFieldRole {
  /// A primary key: `index + 1` for numbers, a UUID for strings.
  id,

  /// A foreign key such as `courseId`, bounded by the referenced record count.
  reference,

  /// An ordering value such as `sortOrder`, equal to `index + 1`.
  ordinal,

  /// A localized full name.
  name,

  /// A localized given name.
  firstName,

  /// A localized family name.
  lastName,

  /// A URL-safe username or nickname.
  username,

  /// An email address on an example domain.
  email,

  /// A phone number in the locale's format.
  phone,

  /// An HTTPS URL.
  url,

  /// An offline SVG placeholder image data URI.
  image,

  /// An offline SVG avatar data URI.
  avatar,

  /// A full street address.
  address,

  /// A city name.
  city,

  /// A country name.
  country,

  /// A postal code.
  postalCode,

  /// A company or organization name.
  company,

  /// A job title.
  jobTitle,

  /// A short title made of a few localized words.
  title,

  /// A slightly longer line of localized words.
  subtitle,

  /// A product category, also used for badges and tags.
  category,

  /// A product name made of an adjective and a noun.
  productName,

  /// One or two sentences of body text.
  description,

  /// A price or amount, rounded for integers.
  price,

  /// A small non-negative count such as stock or capacity.
  quantity,

  /// A rating between 1 and 5.
  rating,

  /// A percentage between 0 and 100.
  progress,

  /// An adult age.
  age,

  /// A recent past date, generated in UTC.
  date,

  /// An upcoming date such as a deadline, generated in UTC.
  dateFuture,

  /// A date of birth, generated in UTC.
  dateOfBirth,

  /// One of the allowed values, cycled so that every value appears.
  status,

  /// A boolean flag.
  boolean,

  /// A hex color such as `#1e6e76`.
  color,

  /// A lowercase slug.
  slug,

  /// An uppercase alphanumeric code such as a SKU or coupon.
  code,

  /// A latitude.
  latitude,

  /// A longitude.
  longitude,

  /// A localized gender label.
  gender,

  /// The locale's ISO 4217 currency code.
  currency,

  /// A plain number chosen by the field type.
  number,

  /// A couple of localized words.
  text,

  /// A currency pair such as `USD/KRW` (two distinct ISO 4217 codes).
  currencyPair,

  /// A meeting place or venue name from the locale's `places` list.
  place,

  /// An exchange or conversion rate: a positive decimal with four digits.
  rate,

  /// A masked, fake Korean resident registration number (`YYMMDD-G******`).
  rrn,

  /// A fake Korean business registration number with an invalid checksum.
  businessNumber,

  /// A state, province, prefecture or region name of a national locale such
  /// as `en_US`. Never inferred from a field name; force it with
  /// `roles: {'state': 'region'}`. Fails for a language-only locale.
  region;

  /// Parses a role name such as `title`, `Date` or `badge`.
  ///
  /// Returns `null` for unknown names so callers can decide whether to fall
  /// back to inference or to fail.
  static CoFieldRole? parse(String value) {
    final key = value.trim().toLowerCase().replaceAll('_', '');
    for (final role in CoFieldRole.values) {
      if (role.name.toLowerCase() == key) return role;
    }
    return switch (key) {
      'badge' || 'tag' || 'genre' => category,
      'enum' || 'state' || 'stage' => status,
      'ref' || 'foreignkey' || 'fk' => reference,
      'index' || 'order' || 'position' || 'sortorder' => ordinal,
      'datetime' || 'timestamp' || 'past' => date,
      'future' || 'deadline' || 'due' => dateFuture,
      'birthday' || 'dob' => dateOfBirth,
      'money' || 'amount' || 'cost' => price,
      'count' || 'stock' => quantity,
      'percent' || 'ratio' => progress,
      'bool' || 'flag' => boolean,
      'fullname' || 'person' => name,
      'thumbnail' || 'photo' || 'picture' => image,
      'body' || 'content' => description,
      'link' || 'website' => url,
      'fulladdress' || 'street' || 'location' => address,
      'zip' || 'zipcode' => postalCode,
      'organization' || 'brand' => company,
      'int' || 'double' || 'num' => number,
      'string' || 'word' => text,
      'residentnumber' || 'ssn' => rrn,
      'bizno' || 'brn' || 'businessregistrationnumber' => businessNumber,
      'province' || 'prefecture' => region,
      _ => null,
    };
  }
}

/// Generates fixture records from a field schema.
///
/// A schema is a map of field name to Dart type name, the shape used by
/// entity manifests and code generators:
///
/// ```dart
/// final faker = CoFaker(locale: 'ko', seed: 7, now: DateTime.utc(2026));
/// final course = faker.schema(
///   {'title': 'String', 'instructor': 'String', 'price': 'int',
///    'startsAt': 'DateTime?', 'status': 'String'},
///   index: 0,
///   enums: {'status': ['draft', 'open', 'closed']},
/// );
/// ```
///
/// Each field draws from its own derived random stream, so adding or removing
/// a field never changes the values of the other fields, and the same seed,
/// clock, schema, and index always produce the same record. Dates are
/// generated in UTC so serialized fixtures compare equal across machines.
class CoFakerSchema {
  /// Creates a schema generator backed by [faker].
  CoFakerSchema(this.faker);

  /// The faker instance used by this module.
  final CoFaker faker;

  /// Shorthand for [record], so `faker.schema(fields)` reads naturally.
  Map<String, Object?> call(
    Map<String, String> fields, {
    int index = 0,
    Map<String, String> roles = const <String, String>{},
    Map<String, List<String>> enums = const <String, List<String>>{},
    Map<String, int> referenceCounts = const <String, int>{},
    String streamKey = 'schema',
    String? entity,
  }) {
    return record(
      fields,
      index: index,
      roles: roles,
      enums: enums,
      referenceCounts: referenceCounts,
      streamKey: streamKey,
      entity: entity,
    );
  }

  /// Generates one record for [index].
  ///
  /// [fields] maps field names to Dart type names (`String`, `int`, `double`,
  /// `bool`, `DateTime`, optionally suffixed with `?`). [roles] forces a
  /// [CoFieldRole] or registered domain role by name for specific fields,
  /// [enums] lists the allowed
  /// values of [CoFieldRole.status] fields, and [referenceCounts] bounds the
  /// values of [CoFieldRole.reference] fields (default 10). [streamKey]
  /// namespaces the derived random streams so two entities with identical
  /// schemas still receive different values. [entity] is the entity name and
  /// only affects inference: a bare `name` field becomes a person's name for
  /// person-like entities (`user`, `customer`, `instructor`, ...) and a
  /// short title otherwise.
  Map<String, Object?> record(
    Map<String, String> fields, {
    int index = 0,
    Map<String, String> roles = const <String, String>{},
    Map<String, List<String>> enums = const <String, List<String>>{},
    Map<String, int> referenceCounts = const <String, int>{},
    String streamKey = 'schema',
    String? entity,
  }) {
    if (index < 0) {
      throw ArgumentError.value(index, 'index', 'must not be negative');
    }
    final result = <String, Object?>{};
    for (final entry in fields.entries) {
      final roleName =
          roles[entry.key] ?? faker.domains.entityRole(entity, entry.key);
      final role = roleName == null ? null : CoFieldRole.parse(roleName);
      final domainRole = roleName == null || role != null
          ? null
          : faker.domains.findRole(roleName);
      if (roleName != null && role == null && domainRole == null) {
        throw ArgumentError.value(roleName, 'roles', 'unknown role');
      }
      result[entry.key] = value(
        entry.key,
        entry.value,
        index: index,
        role: enums.containsKey(entry.key) ? CoFieldRole.status : role,
        domainRole: enums.containsKey(entry.key) ? null : domainRole,
        values: enums[entry.key] ?? faker.domains.enumValues(entity, entry.key),
        referenceCount: referenceCounts[entry.key],
        source: faker.derive('$streamKey/$index/${entry.key}'),
        recordSource: faker.derive('$streamKey/$index'),
        entity: entity,
      );
    }
    return result;
  }

  /// Generates one record from a registered pack's entity schema.
  ///
  /// Use `pack.entity` when more than one pack defines the same entity name.
  /// The qualified name and field each namespace an independent stream.
  Map<String, Object?> entity(
    String name, {
    int index = 0,
    Map<String, String> roles = const <String, String>{},
    Map<String, List<String>> enums = const <String, List<String>>{},
    Map<String, int> referenceCounts = const <String, int>{},
  }) {
    final found = faker.domains.findEntity(name);
    if (found == null) {
      throw ArgumentError.value(name, 'name', 'unknown domain entity');
    }
    final qualified = '${found.domain.name}.${found.name}';
    return record(
      found.fields,
      index: index,
      roles: roles,
      enums: enums,
      referenceCounts: referenceCounts,
      streamKey: qualified,
      entity: qualified,
    );
  }

  /// Generates [count] records from a registered entity schema.
  List<Map<String, Object?>> entities(
    String name,
    int count, {
    Map<String, String> roles = const <String, String>{},
    Map<String, List<String>> enums = const <String, List<String>>{},
    Map<String, int> referenceCounts = const <String, int>{},
  }) => faker.generate(
    count,
    (_, index) => entity(
      name,
      index: index,
      roles: roles,
      enums: enums,
      referenceCounts: referenceCounts,
    ),
  );

  /// Generates [count] records with indexes `0..count-1`.
  List<Map<String, Object?>> records(
    int count,
    Map<String, String> fields, {
    Map<String, String> roles = const <String, String>{},
    Map<String, List<String>> enums = const <String, List<String>>{},
    Map<String, int> referenceCounts = const <String, int>{},
    String streamKey = 'schema',
    String? entity,
  }) {
    return faker.generate(
      count,
      (_, index) => record(
        fields,
        index: index,
        roles: roles,
        enums: enums,
        referenceCounts: referenceCounts,
        streamKey: streamKey,
        entity: entity,
      ),
    );
  }

  /// Infers the role of a field from its [name] and [type].
  ///
  /// [hasEnum] marks fields whose allowed values are known, which always
  /// resolves to [CoFieldRole.status]. [entity] decides whether a bare
  /// `name` field is a person's name or a title.
  ///
  /// A name word matches only at the start of a camelCase or snake_case word
  /// (`capacity` is not a `city`), and the first matching role that fits
  /// [type] wins: a `bool` field is always [CoFieldRole.boolean], and a
  /// numeric field never takes a text role.
  CoFieldRole infer(
    String name, {
    String type = 'String',
    bool hasEnum = false,
    String? entity,
  }) {
    if (hasEnum) return CoFieldRole.status;
    final baseType = _baseType(type);
    return _candidates(
      _FieldName(name),
      baseType,
      entity,
    ).firstWhere((role) => _fits(role, baseType));
  }

  /// The roles [n] suggests, most specific first; [infer] takes the first
  /// that fits the field type, and the last ones always fit.
  Iterable<CoFieldRole> _candidates(
    _FieldName n,
    String baseType,
    String? entity,
  ) sync* {
    final key = n.key;
    if (key == 'name') {
      yield _isPersonEntity(entity) ? CoFieldRole.name : CoFieldRole.title;
    }

    if (key == 'id' || key == 'uid' || key == 'pk') yield CoFieldRole.id;
    if (key.endsWith('id') && key.length > 2) yield CoFieldRole.reference;
    if (key == 'index' ||
        key.endsWith('index') ||
        n.has('sortorder') ||
        key == 'order' ||
        key == 'position' ||
        key == 'rank' ||
        key == 'seq' ||
        key == 'sequence') {
      yield CoFieldRole.ordinal;
    }
    if (n.has('rrn') || n.has('residentnumber')) {
      yield CoFieldRole.rrn;
    }
    if (n.hasAny(const [
      'businessnumber',
      'businessregistration',
      'bizno',
      'brn',
    ])) {
      yield CoFieldRole.businessNumber;
    }
    if (key == 'pair' || key.endsWith('pair')) yield CoFieldRole.currencyPair;
    if (key == 'place' ||
        n.hasAny(const [
          'placename',
          'venue',
          'meetingpoint',
          'meetingplace',
          'spot',
        ])) {
      yield CoFieldRole.place;
    }
    if (key.endsWith('rate')) yield CoFieldRole.rate;
    if (n.has('email')) yield CoFieldRole.email;
    if (n.has('account')) yield CoFieldRole.username;
    if (n.has('phone') || n.has('mobile') || key == 'tel') {
      yield CoFieldRole.phone;
    }
    if (n.has('avatar') || n.has('profileimage')) {
      yield CoFieldRole.avatar;
    }
    if (n.hasAny(const [
      'image',
      'thumbnail',
      'photo',
      'picture',
      'cover',
      'banner',
      'logo',
      'icon',
    ])) {
      yield CoFieldRole.image;
    }
    if (n.hasAny(const ['url', 'link', 'website', 'homepage'])) {
      yield CoFieldRole.url;
    }
    if (n.has('firstname') || key == 'givenname') {
      yield CoFieldRole.firstName;
    }
    if (n.has('lastname') || n.has('familyname') || key == 'surname') {
      yield CoFieldRole.lastName;
    }
    if (n.has('username') || n.has('nickname') || key == 'handle') {
      yield CoFieldRole.username;
    }
    if (n.has('jobtitle') || key == 'job' || n.has('occupation')) {
      yield CoFieldRole.jobTitle;
    }
    if (n.hasAny(const [
      'company',
      'publisher',
      'brand',
      'vendor',
      'organization',
      'shopname',
      'storename',
    ])) {
      yield CoFieldRole.company;
    }
    if (n.has('product')) yield CoFieldRole.productName;
    if (n.hasAny(const [
      'name',
      'author',
      'writer',
      'owner',
      'instructor',
      'teacher',
      'student',
      'customer',
      'seller',
      'buyer',
      'member',
      'host',
      'guest',
      'person',
    ])) {
      yield CoFieldRole.name;
    }
    if (n.hasAny(const [
      'address',
      'street',
      'location',
      'region',
      'district',
    ])) {
      yield CoFieldRole.address;
    }
    if (n.has('city')) yield CoFieldRole.city;
    if (n.has('country')) yield CoFieldRole.country;
    if (n.has('postal') || n.has('zip')) {
      yield CoFieldRole.postalCode;
    }
    if (n.has('subtitle')) yield CoFieldRole.subtitle;
    if (n.hasAny(const ['title', 'subject', 'headline', 'caption'])) {
      yield CoFieldRole.title;
    }
    if (n.hasAny(const ['status', 'state', 'stage', 'phase'])) {
      yield CoFieldRole.status;
    }
    if (n.hasAny(const [
          'category',
          'genre',
          'tag',
          'hashtag',
          'label',
          'skill',
          'keyword',
        ]) ||
        key == 'kind' ||
        key == 'type') {
      yield CoFieldRole.category;
    }
    if (n.hasAny(const [
      'description',
      'content',
      'body',
      'summary',
      'memo',
      'note',
      'comment',
      'message',
      'bio',
      'review',
      'intro',
      'text',
      'reason',
    ])) {
      yield CoFieldRole.description;
    }
    if (n.hasAny(const [
      'price',
      'amount',
      'cost',
      'salary',
      'balance',
      'subtotal',
      'budget',
      'revenue',
    ])) {
      yield CoFieldRole.price;
    }
    // `total` is money only as the head noun (`orderTotal`) or before a money
    // unit (`totalMinor`); `totalSessions` counts sessions.
    if (n.words.last == 'total' ||
        (n.words.first == 'total' && _moneyUnits.contains(n.words.last))) {
      yield CoFieldRole.price;
    }
    if (n.has('rating') || n.has('stars')) {
      yield CoFieldRole.rating;
    }
    if (n.hasAny(const [
      'count',
      'quantity',
      'qty',
      'stock',
      'capacity',
      'remaining',
      'views',
      'likes',
      'seats',
      'minutes',
      'duration',
      'pages',
      'level',
      'headcount',
      'guests',
    ])) {
      yield CoFieldRole.quantity;
    }
    if (n.words.first == 'total') yield CoFieldRole.quantity;
    if (n.hasAny(const ['progress', 'percent', 'score'])) {
      yield CoFieldRole.progress;
    }
    if (key == 'age') yield CoFieldRole.age;
    if (n.has('birth') || key == 'dob') yield CoFieldRole.dateOfBirth;
    if (n.hasAny(const ['due', 'expire', 'deadline', 'scheduled', 'until']) ||
        key.startsWith('start') ||
        key.startsWith('end')) {
      yield CoFieldRole.dateFuture;
    }
    if (key.endsWith('edat') ||
        key.endsWith('sat') ||
        key.endsWith('dueat') ||
        n.has('date') ||
        n.has('time')) {
      yield CoFieldRole.date;
    }
    if (n.has('gender') || key == 'sex') yield CoFieldRole.gender;
    if (n.has('currency')) yield CoFieldRole.currency;
    if (n.has('color') || n.has('colour')) {
      yield CoFieldRole.color;
    }
    if (n.has('slug')) yield CoFieldRole.slug;
    if (n.hasAny(const [
      'code',
      'sku',
      'token',
      'apikey',
      'accesskey',
      'isbn',
      'serial',
      'uuid',
    ])) {
      yield CoFieldRole.code;
    }
    if (key == 'lat' || n.has('latitude')) yield CoFieldRole.latitude;
    if (key == 'lng' || key == 'lon' || n.has('longitude')) {
      yield CoFieldRole.longitude;
    }
    if (baseType == 'bool' ||
        key.startsWith('is') ||
        key.startsWith('has') ||
        key.startsWith('can') ||
        n.hasAny(const [
          'enabled',
          'active',
          'completed',
          'done',
          'visible',
          'public',
          'deleted',
          'verified',
          'flag',
        ])) {
      yield CoFieldRole.boolean;
    }
    if (baseType == 'DateTime') yield CoFieldRole.date;
    if (baseType == 'int' || baseType == 'double' || baseType == 'num') {
      yield CoFieldRole.number;
    }
    yield CoFieldRole.text;
  }

  /// Generates a single field value.
  ///
  /// [role] overrides inference; [values] supplies the allowed values for
  /// status fields; [referenceCount] bounds reference fields; [source] is the
  /// generator to draw from (defaults to [faker]).
  Object? value(
    String name,
    String type, {
    int index = 0,
    CoFieldRole? role,
    CoDomainRoleRef? domainRole,
    List<String>? values,
    int? referenceCount,
    CoFaker? source,
    CoFaker? recordSource,
    String? entity,
  }) {
    final f = source ?? faker;
    final baseType = _baseType(type);
    final selectedDomainRole =
        domainRole ??
        (role == null && values == null
            ? faker.domains.inferRole(name, entity: entity)
            : null);
    if (selectedDomainRole != null) {
      final adapter = selectedDomainRole.role;
      if (adapter.supportedTypes != null &&
          !adapter.supportedTypes!.contains(baseType)) {
        throw ArgumentError.value(
          type,
          'type',
          '${selectedDomainRole.domain.name}.${selectedDomainRole.name} '
              'supports ${adapter.supportedTypes!.join(', ')}',
        );
      }
      final generator = recordSource != null && adapter.generateRecord != null
          ? adapter.generateRecord!
          : adapter.generate;
      final raw = generator(
        recordSource != null && adapter.generateRecord != null
            ? recordSource
            : f,
        (field: name, type: type, index: index, entity: entity),
      );
      return _coerce(f, raw, baseType, index);
    }
    final resolved =
        role ??
        infer(name, type: baseType, hasEnum: values != null, entity: entity);
    final raw = _generate(
      f,
      resolved,
      baseType,
      index,
      values,
      referenceCount,
      recordSource,
    );
    return _coerce(f, raw, baseType, index);
  }

  /// The city and postal code one record of a national locale shares, so
  /// its city, postal code, region and address fields agree. `null` for a
  /// language-only locale, which keeps independent fields.
  ({CoFakerLocality locality, String postalCode})? _place(
    CoFaker f,
    CoFaker? recordSource,
  ) {
    final national = f.localeData.national;
    if (national == null) return null;
    final shared = (recordSource ?? f).derive('~place');
    final locality = shared.random.pick(national.localities);
    return (
      locality: locality,
      postalCode: shared.address.postalCodeFor(locality),
    );
  }

  Object? _generate(
    CoFaker f,
    CoFieldRole role,
    String baseType,
    int index,
    List<String>? values,
    int? referenceCount,
    CoFaker? recordSource,
  ) {
    switch (role) {
      case CoFieldRole.id:
        return baseType == 'String' ? f.id.uuid() : index + 1;
      case CoFieldRole.reference:
        if (baseType == 'String') return f.id.uuid();
        return f.number.int(min: 1, max: referenceCount ?? 10);
      case CoFieldRole.ordinal:
        return index + 1;
      case CoFieldRole.name:
        return f.person.fullName();
      case CoFieldRole.firstName:
        return f.person.firstName();
      case CoFieldRole.lastName:
        return f.person.lastName();
      case CoFieldRole.username:
        return f.person.username();
      case CoFieldRole.email:
        return f.internet.email();
      case CoFieldRole.phone:
        return f.internet.phoneNumber();
      case CoFieldRole.url:
        return f.internet.url();
      case CoFieldRole.image:
        return f.image.placeholderDataUri(label: '${index + 1}');
      case CoFieldRole.avatar:
        return f.image.avatarDataUri();
      case CoFieldRole.address:
        final place = _place(f, recordSource);
        if (place == null) return f.address.fullAddress();
        return f.address
            .postalAddress(
              locality: place.locality,
              postalCode: place.postalCode,
            )
            .formatted;
      case CoFieldRole.city:
        return _place(f, recordSource)?.locality.city ?? f.address.city();
      case CoFieldRole.country:
        return f.address.country();
      case CoFieldRole.postalCode:
        return _place(f, recordSource)?.postalCode ?? f.address.postalCode();
      case CoFieldRole.region:
        return _place(f, recordSource)?.locality.region ?? f.address.region();
      case CoFieldRole.company:
        return f.commerce.companyName();
      case CoFieldRole.jobTitle:
        return f.person.jobTitle();
      case CoFieldRole.title:
        return _capitalize(f.text.words(3));
      case CoFieldRole.subtitle:
        return _capitalize(f.text.words(5));
      case CoFieldRole.category:
        return f.commerce.category();
      case CoFieldRole.productName:
        return f.commerce.productName();
      case CoFieldRole.description:
        return f.text.sentences(2);
      case CoFieldRole.price:
        if (baseType == 'double' || baseType == 'num') {
          return f.commerce.price();
        }
        return f.number.int(min: 10, max: 2000) * 100;
      case CoFieldRole.quantity:
        return f.number.int(min: 0, max: 100);
      case CoFieldRole.rating:
        if (baseType == 'double' || baseType == 'num') {
          return f.number.decimal(min: 1, max: 5, decimals: 1);
        }
        return f.number.int(min: 1, max: 5);
      case CoFieldRole.progress:
        return f.number.int(min: 0, max: 100);
      case CoFieldRole.age:
        return f.number.int(min: 18, max: 70);
      case CoFieldRole.date:
        return f.date.past(utc: true);
      case CoFieldRole.dateFuture:
        return f.date.future(days: 90, utc: true);
      case CoFieldRole.dateOfBirth:
        return f.date.dateOfBirth(utc: true);
      case CoFieldRole.status:
        return f.random.pickBalanced(values ?? _defaultStatuses, index);
      case CoFieldRole.boolean:
        return f.number.bool();
      case CoFieldRole.color:
        return '#${f.id.hex(6)}';
      case CoFieldRole.slug:
        return f.text.slug();
      case CoFieldRole.code:
        return f.random.string(8, alphabet: _codeAlphabet);
      case CoFieldRole.latitude:
        return f.address.latitude();
      case CoFieldRole.longitude:
        return f.address.longitude();
      case CoFieldRole.gender:
        return f.person.gender();
      case CoFieldRole.currency:
        return f.commerce.currency().code;
      case CoFieldRole.number:
        if (baseType == 'double' || baseType == 'num') {
          return f.number.decimal(min: 0, max: 1000);
        }
        return f.number.int();
      case CoFieldRole.text:
        return f.text.words(2);
      case CoFieldRole.currencyPair:
        final base = f.random.pick(_currencyCodes);
        final quotes = _currencyCodes.where((c) => c != base).toList();
        return '$base/${f.random.pick(quotes)}';
      case CoFieldRole.place:
        return f.random.pick(f.localeData.places);
      case CoFieldRole.rate:
        return f.number.decimal(min: 0.01, max: 2000, decimals: 4);
      case CoFieldRole.rrn:
        return f.korea.rrn();
      case CoFieldRole.businessNumber:
        return f.korea.businessNumber();
    }
  }

  /// Converts [raw] to the declared [baseType], falling back to a plain
  /// value of that type when the role produced something incompatible (for
  /// example a name role on an `int` field).
  Object? _coerce(CoFaker f, Object? raw, String baseType, int index) {
    switch (baseType) {
      case 'int':
        if (raw is int) return raw;
        if (raw is double) return raw.round();
        if (raw is bool) return raw ? 1 : 0;
        return f.number.int();
      case 'double':
      case 'num':
        if (raw is double) return raw;
        if (raw is int) return raw.toDouble();
        return f.number.decimal(min: 0, max: 1000);
      case 'bool':
        if (raw is bool) return raw;
        if (raw is int) return raw.isEven;
        return f.number.bool();
      case 'DateTime':
        if (raw is DateTime) return raw;
        return f.date.past(utc: true);
      default:
        if (raw is DateTime) return raw.toIso8601String();
        if (raw is String) return raw;
        return raw?.toString() ?? '';
    }
  }

  /// Major ISO 4217 codes used by [CoFieldRole.currencyPair].
  static const List<String> _currencyCodes = <String>[
    'USD',
    'EUR',
    'JPY',
    'KRW',
    'CNY',
    'GBP',
    'AUD',
    'CAD',
    'CHF',
    'HKD',
    'SGD',
    'TWD',
    'THB',
    'VND',
  ];

  static const List<String> _defaultStatuses = <String>[
    'pending',
    'active',
    'done',
  ];

  static const String _codeAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  static String _baseType(String type) {
    var value = type.trim();
    if (value.endsWith('?')) value = value.substring(0, value.length - 1);
    return value;
  }

  /// Whether [role] makes a value of [baseType]: a `bool` field takes only
  /// [CoFieldRole.boolean], and a numeric field only a numeric role or a
  /// 0/1 [CoFieldRole.boolean].
  static bool _fits(CoFieldRole role, String baseType) {
    switch (baseType) {
      case 'bool':
        return role == CoFieldRole.boolean;
      case 'int':
      case 'double':
      case 'num':
        return _numericRoles.contains(role);
      default:
        return true;
    }
  }

  /// Last words that make a `total<word>` field an amount of money.
  static const Set<String> _moneyUnits = <String>{
    'minor',
    'cents',
    'won',
    'krw',
    'usd',
  };

  static const Set<CoFieldRole> _numericRoles = <CoFieldRole>{
    CoFieldRole.id,
    CoFieldRole.reference,
    CoFieldRole.ordinal,
    CoFieldRole.price,
    CoFieldRole.quantity,
    CoFieldRole.rating,
    CoFieldRole.progress,
    CoFieldRole.age,
    CoFieldRole.boolean,
    CoFieldRole.latitude,
    CoFieldRole.longitude,
    CoFieldRole.rate,
    CoFieldRole.number,
  };

  static bool _isPersonEntity(String? entity) {
    if (entity == null) return true;
    final key = _normalize(entity);
    return _containsAny(key, const [
      'user',
      'account',
      'member',
      'customer',
      'student',
      'instructor',
      'teacher',
      'author',
      'person',
      'profile',
      'employee',
      'staff',
      'seller',
      'buyer',
      'host',
      'guest',
      'contact',
      'patient',
      'client',
    ]);
  }

  static String _normalize(String name) {
    return name.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');
  }

  static bool _containsAny(String key, List<String> needles) {
    for (final needle in needles) {
      if (key.contains(needle)) return true;
    }
    return false;
  }

  static String _capitalize(String value) {
    if (value.isEmpty) return value;
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }
}

/// A field name normalized like `_normalize`, with the offsets where its
/// camelCase, snake_case, or digit words start.
class _FieldName {
  factory _FieldName(String name) {
    final key = CoFakerSchema._normalize(name);
    final words = [
      for (final match in RegExp(
        '[A-Z]+(?![a-z])|[A-Z]?[a-z]+|[0-9]+',
      ).allMatches(name))
        match[0]!.toLowerCase(),
    ];
    if (words.isEmpty || words.join() != key) {
      // Letters outside a-z: no reliable words, so any offset may start one.
      return _FieldName._(key, [key], {for (var i = 0; i < key.length; i++) i});
    }
    final starts = <int>{};
    var offset = 0;
    for (final word in words) {
      starts.add(offset);
      offset += word.length;
    }
    return _FieldName._(key, words, starts);
  }

  const _FieldName._(this.key, this.words, this.starts);

  /// Lowercased letters and digits of the name.
  final String key;

  /// The words of the name, lowercased.
  final List<String> words;

  /// Offsets in [key] where a word starts.
  final Set<int> starts;

  /// Whether [needle] occurs in [key] starting at a word start; it may run
  /// over several words (`sortorder` in `sortOrder`).
  bool has(String needle) {
    for (var i = key.indexOf(needle); i >= 0; i = key.indexOf(needle, i + 1)) {
      if (starts.contains(i)) return true;
    }
    return false;
  }

  /// Whether any of [needles] [has] a match.
  bool hasAny(List<String> needles) => needles.any(has);
}

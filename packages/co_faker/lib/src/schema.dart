import 'co_faker.dart';

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
  text;

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
  /// [CoFieldRole] by name for specific fields, [enums] lists the allowed
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
      final roleName = roles[entry.key];
      final role = roleName == null ? null : CoFieldRole.parse(roleName);
      if (roleName != null && role == null) {
        throw ArgumentError.value(roleName, 'roles', 'unknown role');
      }
      result[entry.key] = value(
        entry.key,
        entry.value,
        index: index,
        role: role,
        values: enums[entry.key],
        referenceCount: referenceCounts[entry.key],
        source: faker.derive('$streamKey/$index/${entry.key}'),
        entity: entity,
      );
    }
    return result;
  }

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
  CoFieldRole infer(
    String name, {
    String type = 'String',
    bool hasEnum = false,
    String? entity,
  }) {
    if (hasEnum) return CoFieldRole.status;
    final key = _normalize(name);
    final baseType = _baseType(type);
    if (key == 'name') {
      return _isPersonEntity(entity) ? CoFieldRole.name : CoFieldRole.title;
    }

    if (key == 'id' || key == 'uid' || key == 'pk') return CoFieldRole.id;
    if (key.endsWith('id') && key.length > 2) return CoFieldRole.reference;
    if (key == 'index' ||
        key.endsWith('index') ||
        key.contains('sortorder') ||
        key == 'order' ||
        key == 'position' ||
        key == 'rank' ||
        key == 'seq' ||
        key == 'sequence') {
      return CoFieldRole.ordinal;
    }
    if (key.contains('email')) return CoFieldRole.email;
    if (key.contains('account')) return CoFieldRole.username;
    if (key.contains('phone') || key.contains('mobile') || key == 'tel') {
      return CoFieldRole.phone;
    }
    if (key.contains('avatar') || key.contains('profileimage')) {
      return CoFieldRole.avatar;
    }
    if (_containsAny(key, const [
      'image',
      'thumbnail',
      'photo',
      'picture',
      'cover',
      'banner',
      'logo',
      'icon',
    ])) {
      return CoFieldRole.image;
    }
    if (_containsAny(key, const ['url', 'link', 'website', 'homepage'])) {
      return CoFieldRole.url;
    }
    if (key.contains('firstname') || key == 'givenname') {
      return CoFieldRole.firstName;
    }
    if (key.contains('lastname') ||
        key.contains('familyname') ||
        key == 'surname') {
      return CoFieldRole.lastName;
    }
    if (key.contains('username') ||
        key.contains('nickname') ||
        key == 'handle') {
      return CoFieldRole.username;
    }
    if (key.contains('jobtitle') ||
        key == 'job' ||
        key.contains('occupation')) {
      return CoFieldRole.jobTitle;
    }
    if (_containsAny(key, const [
      'company',
      'publisher',
      'brand',
      'vendor',
      'organization',
      'shopname',
      'storename',
    ])) {
      return CoFieldRole.company;
    }
    if (key.contains('product')) return CoFieldRole.productName;
    if (_containsAny(key, const [
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
      return CoFieldRole.name;
    }
    if (_containsAny(key, const [
      'address',
      'street',
      'location',
      'region',
      'district',
    ])) {
      return CoFieldRole.address;
    }
    if (key.contains('city')) return CoFieldRole.city;
    if (key.contains('country')) return CoFieldRole.country;
    if (key.contains('postal') || key.contains('zip')) {
      return CoFieldRole.postalCode;
    }
    if (key.contains('subtitle')) return CoFieldRole.subtitle;
    if (_containsAny(key, const ['title', 'subject', 'headline', 'caption'])) {
      return CoFieldRole.title;
    }
    if (_containsAny(key, const ['status', 'state', 'stage', 'phase'])) {
      return CoFieldRole.status;
    }
    if (_containsAny(key, const ['category', 'genre', 'tag', 'label']) ||
        key == 'kind' ||
        key == 'type') {
      return CoFieldRole.category;
    }
    if (_containsAny(key, const [
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
      return CoFieldRole.description;
    }
    if (_containsAny(key, const [
      'price',
      'amount',
      'cost',
      'salary',
      'balance',
      'total',
      'budget',
      'revenue',
    ])) {
      return CoFieldRole.price;
    }
    if (key.contains('rating') || key.contains('stars')) {
      return CoFieldRole.rating;
    }
    if (_containsAny(key, const [
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
    ])) {
      return CoFieldRole.quantity;
    }
    if (_containsAny(key, const ['progress', 'percent', 'score'])) {
      return CoFieldRole.progress;
    }
    if (key == 'age') return CoFieldRole.age;
    if (key.contains('birth') || key == 'dob') return CoFieldRole.dateOfBirth;
    if (_containsAny(key, const [
          'due',
          'expire',
          'deadline',
          'scheduled',
          'until',
        ]) ||
        key.startsWith('start') ||
        key.startsWith('end')) {
      return CoFieldRole.dateFuture;
    }
    if (key.endsWith('edat') ||
        key.endsWith('sat') ||
        key.endsWith('dueat') ||
        key.contains('date') ||
        key.contains('time')) {
      return CoFieldRole.date;
    }
    if (key.contains('gender') || key == 'sex') return CoFieldRole.gender;
    if (key.contains('currency')) return CoFieldRole.currency;
    if (key.contains('color') || key.contains('colour')) {
      return CoFieldRole.color;
    }
    if (key.contains('slug')) return CoFieldRole.slug;
    if (_containsAny(key, const [
      'code',
      'sku',
      'token',
      'apikey',
      'accesskey',
      'isbn',
      'serial',
      'uuid',
    ])) {
      return CoFieldRole.code;
    }
    if (key == 'lat' || key.contains('latitude')) return CoFieldRole.latitude;
    if (key == 'lng' || key == 'lon' || key.contains('longitude')) {
      return CoFieldRole.longitude;
    }
    if (baseType == 'bool' ||
        key.startsWith('is') ||
        key.startsWith('has') ||
        key.startsWith('can') ||
        _containsAny(key, const [
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
      return CoFieldRole.boolean;
    }
    if (baseType == 'DateTime') return CoFieldRole.date;
    if (baseType == 'int' || baseType == 'double' || baseType == 'num') {
      return CoFieldRole.number;
    }
    return CoFieldRole.text;
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
    List<String>? values,
    int? referenceCount,
    CoFaker? source,
    String? entity,
  }) {
    final f = source ?? faker;
    final baseType = _baseType(type);
    final resolved =
        role ??
        infer(name, type: baseType, hasEnum: values != null, entity: entity);
    final raw = _generate(f, resolved, baseType, index, values, referenceCount);
    return _coerce(f, raw, baseType, index);
  }

  Object? _generate(
    CoFaker f,
    CoFieldRole role,
    String baseType,
    int index,
    List<String>? values,
    int? referenceCount,
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
        return f.address.fullAddress();
      case CoFieldRole.city:
        return f.address.city();
      case CoFieldRole.country:
        return f.address.country();
      case CoFieldRole.postalCode:
        return f.address.postalCode();
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

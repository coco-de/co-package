import 'co_faker.dart';

/// What a domain role generator knows about the field it fills.
typedef CoDomainRoleContext = ({
  String field,
  String type,
  int index,
  String? entity,
});

/// Generates one field value for a domain role.
typedef CoDomainRoleGenerator =
    Object? Function(CoFaker faker, CoDomainRoleContext context);

/// A field role contributed by a [CoFakerDomain].
///
/// [fieldPatterns] let `faker.schema` infer the role from field names. A
/// pattern is compared with the field name lowercased and stripped of
/// everything but letters and digits: it matches when the name equals the
/// pattern or ends with it (`chartno` matches `chartNo` and
/// `patientChartNo`). A pattern starting with `=` only matches the exact name
/// (`=address` matches `address` but not `emailAddress`). A pattern of the
/// form `entity.field` only matches that field of that entity (`clinic.name`
/// matches `name` on a `clinic` entity).
class CoDomainRole {
  /// Creates a domain role.
  const CoDomainRole(
    this.generate, {
    this.description = '',
    this.fieldPatterns = const <String>[],
    this.generateRecord,
    this.supportedTypes,
  });

  /// Produces the value; it must draw only from the given faker.
  final CoDomainRoleGenerator generate;

  /// Optional coherent record adapter. Receives a fresh, record-derived stream
  /// shared by key (not by mutable state) across fields of the same record.
  /// Existing roles keep their original independent field streams.
  final CoDomainRoleGenerator? generateRecord;

  /// Declared primitive output types, when this role uses a strict adapter.
  /// `null` retains the legacy coercion behavior for existing/custom packs.
  final List<String>? supportedTypes;

  /// One line for coverage reports and documentation.
  final String description;

  /// Normalized field names that infer this role.
  final List<String> fieldPatterns;

  /// Whether this role is inferred for [field] of [entity].
  bool matches(String field, {String? entity}) {
    final key = normalize(field);
    final owner = entity == null
        ? null
        : normalize(entity.contains('.') ? entity.split('.').last : entity);
    for (final pattern in fieldPatterns) {
      final dot = pattern.indexOf('.');
      if (dot >= 0) {
        if (owner == pattern.substring(0, dot) &&
            key == pattern.substring(dot + 1)) {
          return true;
        }
      } else if (pattern.startsWith('=')) {
        if (key == pattern.substring(1)) return true;
      } else if (key == pattern || key.endsWith(pattern)) {
        return true;
      }
    }
    return false;
  }

  /// Lowercases [name] and keeps only letters and digits.
  static String normalize(String name) =>
      name.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');
}

/// A pluggable domain pack: named field roles, the entity schemas of the
/// domain, and enum values of their status fields.
///
/// Register packs with `CoFaker(domains: [...])`. Then `faker.schema`
/// resolves roles such as `chartNo` or `clinic.procedureName` (explicitly
/// through `roles:` or inferred from field names), `faker.schema.entity`
/// generates records for the pack's entities, and [CoFakerCoverage] reports
/// which fields of a planned entity list the registered packs cover.
///
/// Built-in packs: `CoFakerDomains.korea`, `CoFakerDomains.clinic`,
/// `CoFakerDomains.saas`. A project pack is a small subclass:
///
/// ```dart
/// class LibraryDomain extends CoFakerDomain {
///   const LibraryDomain();
///   @override
///   String get name => 'library';
///   @override
///   Map<String, CoDomainRole> get roles => {
///     'isbn': CoDomainRole(
///       (f, _) => f.random.digits('979-11-#####-##-#'),
///       fieldPatterns: const ['isbn'],
///     ),
///   };
///   @override
///   Map<String, Map<String, String>> get entities => const {
///     'book': {'id': 'int', 'title': 'String', 'isbn': 'String'},
///   };
/// }
/// ```
abstract class CoFakerDomain {
  /// Const constructor for subclasses.
  const CoFakerDomain();

  /// Unique pack name, also the prefix of qualified role names
  /// (`clinic.chartNo`).
  String get name;

  /// Roles keyed by role name.
  Map<String, CoDomainRole> get roles;

  /// Entity field schemas (`field → Dart type`) keyed by entity name.
  Map<String, Map<String, String>> get entities =>
      const <String, Map<String, String>>{};

  /// Enum values of status-like fields: entity → field → values.
  Map<String, Map<String, List<String>>> get enums =>
      const <String, Map<String, List<String>>>{};

  /// Explicit roles of entity fields whose names alone would not infer
  /// them: entity → field → role name.
  Map<String, Map<String, String>> get entityRoles =>
      const <String, Map<String, String>>{};
}

/// A resolved domain role: the pack and its role name.
typedef CoDomainRoleRef = ({
  CoFakerDomain domain,
  String name,
  CoDomainRole role,
});

/// Lookups over a list of registered domain packs.
extension CoFakerDomainLookup on List<CoFakerDomain> {
  /// Finds a role by `name` or qualified `domain.name`; the first pack that
  /// defines a bare name wins.
  CoDomainRoleRef? findRole(String roleName) {
    final dot = roleName.indexOf('.');
    for (final domain in this) {
      if (dot >= 0) {
        if (domain.name != roleName.substring(0, dot)) continue;
        final name = roleName.substring(dot + 1);
        final role = domain.roles[name];
        if (role != null) return (domain: domain, name: name, role: role);
      } else {
        final role = domain.roles[roleName];
        if (role != null) return (domain: domain, name: roleName, role: role);
      }
    }
    return null;
  }

  /// Infers a domain role from [field] (and [entity]), in pack order.
  CoDomainRoleRef? inferRole(String field, {String? entity}) {
    for (final domain in this) {
      for (final entry in domain.roles.entries) {
        if (entry.value.matches(field, entity: entity)) {
          return (domain: domain, name: entry.key, role: entry.value);
        }
      }
    }
    return null;
  }

  /// Finds an entity schema by `name` or `domain.name`.
  ({CoFakerDomain domain, String name, Map<String, String> fields})? findEntity(
    String entityName,
  ) {
    final dot = entityName.indexOf('.');
    for (final domain in this) {
      final name = dot >= 0 ? entityName.substring(dot + 1) : entityName;
      if (dot >= 0 && domain.name != entityName.substring(0, dot)) continue;
      final fields = domain.entities[name];
      if (fields != null) return (domain: domain, name: name, fields: fields);
    }
    return null;
  }

  /// Enum values the packs define for [field] of [entity], if any.
  List<String>? enumValues(String? entity, String field) {
    if (entity == null) return null;
    final dot = entity.indexOf('.');
    final key = dot < 0 ? entity : entity.substring(dot + 1);
    for (final domain in this) {
      if (dot >= 0 && domain.name != entity.substring(0, dot)) {
        continue;
      }
      final values = domain.enums[key]?[field];
      if (values != null) return values;
    }
    return null;
  }

  /// Role name the packs assign to [field] of [entity], if any.
  ///
  /// An explicit [CoFakerDomain.entityRoles] entry wins. Otherwise a pack
  /// that owns [entity] (lists it in its entities or entity roles) lends its
  /// role of the same name as [field] (`providerName` on a `brokerage`
  /// entity is `brokerage.providerName`), ahead of the general roles.
  String? entityRole(String? entity, String field) {
    if (entity == null) return null;
    final dot = entity.indexOf('.');
    final key = dot < 0 ? entity : entity.substring(dot + 1);
    final owners = <CoFakerDomain>[];
    for (final domain in this) {
      if (dot >= 0 && domain.name != entity.substring(0, dot)) {
        continue;
      }
      final role = domain.entityRoles[key]?[field];
      if (role != null) {
        return role.contains('.') ? role : '${domain.name}.$role';
      }
      if (domain.entities.containsKey(key) ||
          domain.entityRoles.containsKey(key)) {
        owners.add(domain);
      }
    }
    final normalized = CoDomainRole.normalize(field);
    for (final domain in owners) {
      for (final role in domain.roles.keys) {
        if (CoDomainRole.normalize(role) == normalized) {
          return '${domain.name}.$role';
        }
      }
    }
    return null;
  }
}

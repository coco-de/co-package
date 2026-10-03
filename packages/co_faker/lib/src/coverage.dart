import 'co_faker.dart';
import 'domain.dart';
import 'schema.dart';

/// One planned entity. Omit [fields] to inspect a registered entity schema.
/// [roles] may also name fields absent from [fields]; their type is `String`.
class CoCoverageEntity {
  /// Creates a coverage request for [name].
  const CoCoverageEntity(
    this.name, {
    this.fields = const <String, String>{},
    this.roles = const <String, String>{},
    this.enums = const <String, List<String>>{},
  });

  /// Entity name, optionally qualified as `pack.entity`.
  final String name;

  /// Field name to Dart type (`String`, `int`, `double`, `num`, `bool`, `DateTime`).
  final Map<String, String> fields;

  /// Explicit field name to built-in or domain role.
  final Map<String, String> roles;

  /// Allowed values of status fields.
  final Map<String, List<String>> enums;
}

/// The level of fixture support for a planned field.
enum CoCoverageStatus {
  /// A registered domain role can generate this field.
  supported,

  /// The general schema generator can fill this field.
  generic,

  /// A status field needs its allowed values supplied.
  needsEnum,

  /// An entity, role, field type, or field meaning is not known.
  unsupported,
}

/// The result of checking one planned field.
class CoCoverageRow {
  /// Creates a coverage row.
  const CoCoverageRow({
    required this.entity,
    required this.field,
    required this.type,
    required this.role,
    required this.status,
    this.detail = '',
  });

  /// Planned entity name.
  final String entity;

  /// Planned field name, or an empty string for an unknown entity.
  final String field;

  /// Declared Dart type.
  final String type;

  /// Resolved role, if any.
  final String role;

  /// Coverage level.
  final CoCoverageStatus status;

  /// Reason or next action when support is incomplete.
  final String detail;

  /// Machine-readable row for `cob plan` and other callers.
  Map<String, String> toJson() => <String, String>{
    'entity': entity,
    'field': field,
    'type': type,
    'role': role,
    'status': status.name,
    'detail': detail,
  };
}

/// Coverage results, in request and field order.
class CoCoverageReport {
  /// Creates a report.
  const CoCoverageReport(this.rows);

  /// One row per field.
  final List<CoCoverageRow> rows;

  /// Whether all fields can be generated without missing enum values.
  bool get complete => rows.every(
    (row) =>
        row.status == CoCoverageStatus.supported ||
        row.status == CoCoverageStatus.generic,
  );

  /// Machine-readable rows.
  List<Map<String, String>> toJson() =>
      rows.map((row) => row.toJson()).toList();

  /// Markdown table for plans and pull requests.
  String toMarkdown() {
    final lines = <String>[
      '| Entity | Field | Type | Role | Coverage | Detail |',
      '| --- | --- | --- | --- | --- | --- |',
    ];
    for (final row in rows) {
      final cells = <String>[
        row.entity,
        row.field,
        row.type,
        row.role,
        row.status.name,
        row.detail,
      ].map((cell) => cell.replaceAll('|', r'\|').replaceAll('\n', ' '));
      lines.add('| ${cells.join(' | ')} |');
    }
    return lines.join('\n');
  }
}

/// Checks a plan against the roles and entities registered on [faker].
class CoFakerCoverage {
  /// Creates a checker for [faker].
  const CoFakerCoverage(this.faker);

  /// Faker whose domain packs and general schema roles are available.
  final CoFaker faker;

  /// Checks planned [entities] without generating values or consuming random
  /// state. An unknown entity with supplied fields is checked field by field.
  CoCoverageReport check(List<CoCoverageEntity> entities) {
    final rows = <CoCoverageRow>[];
    for (final request in entities) {
      final found = faker.domains.findEntity(request.name);
      final fields = request.fields.isEmpty
          ? found?.fields ?? const <String, String>{}
          : request.fields;
      if (fields.isEmpty && request.roles.isEmpty) {
        rows.add(
          CoCoverageRow(
            entity: request.name,
            field: '',
            type: '',
            role: '',
            status: CoCoverageStatus.unsupported,
            detail: 'Unknown entity or no fields',
          ),
        );
        continue;
      }
      for (final field in <String>{...fields.keys, ...request.roles.keys}) {
        final type = fields[field] ?? 'String';
        final roleName =
            request.roles[field] ??
            faker.domains.entityRole(request.name, field);
        final enumValues =
            request.enums[field] ??
            faker.domains.enumValues(request.name, field);
        rows.add(
          _checkField(
            request.name,
            field,
            type,
            roleName,
            enumValues,
            overrideDomain: request.enums.containsKey(field),
          ),
        );
      }
    }
    return CoCoverageReport(rows);
  }

  CoCoverageRow _checkField(
    String entity,
    String field,
    String type,
    String? roleName,
    List<String>? enumValues, {
    bool overrideDomain = false,
  }) {
    final baseType = type.endsWith('?')
        ? type.substring(0, type.length - 1)
        : type;
    if (!const <String>{
      'String',
      'int',
      'double',
      'num',
      'bool',
      'DateTime',
    }.contains(baseType)) {
      return CoCoverageRow(
        entity: entity,
        field: field,
        type: type,
        role: roleName ?? '',
        status: CoCoverageStatus.unsupported,
        detail: 'Unsupported Dart type',
      );
    }
    final genericRole = roleName == null ? null : CoFieldRole.parse(roleName);
    final domainRole = roleName != null && genericRole == null
        ? faker.domains.findRole(roleName)
        : null;
    if (roleName != null && genericRole == null && domainRole == null) {
      return CoCoverageRow(
        entity: entity,
        field: field,
        type: type,
        role: roleName,
        status: CoCoverageStatus.unsupported,
        detail: 'Unknown role',
      );
    }
    final inferredDomain = roleName == null && enumValues == null
        ? faker.domains.inferRole(field, entity: entity)
        : null;
    final selectedDomain = overrideDomain ? null : domainRole ?? inferredDomain;
    if (selectedDomain != null) {
      final supported = selectedDomain.role.supportedTypes;
      return CoCoverageRow(
        entity: entity,
        field: field,
        type: type,
        role: '${selectedDomain.domain.name}.${selectedDomain.name}',
        status: supported == null || supported.contains(baseType)
            ? CoCoverageStatus.supported
            : CoCoverageStatus.unsupported,
        detail: supported == null || supported.contains(baseType)
            ? ''
            : 'Role supports ${supported.join(', ')}',
      );
    }
    final resolved = overrideDomain
        ? CoFieldRole.status
        : genericRole ??
              faker.schema.infer(
                field,
                type: type,
                hasEnum: enumValues != null,
                entity: entity,
              );
    final needsEnum =
        resolved == CoFieldRole.status &&
        (enumValues == null || enumValues.isEmpty);
    final unknown =
        roleName == null && enumValues == null && resolved == CoFieldRole.text;
    return CoCoverageRow(
      entity: entity,
      field: field,
      type: type,
      role: resolved.name,
      status: needsEnum
          ? CoCoverageStatus.needsEnum
          : unknown
          ? CoCoverageStatus.unsupported
          : CoCoverageStatus.generic,
      detail: needsEnum
          ? 'Supply enum values'
          : unknown
          ? 'Add a domain role or an explicit schema role'
          : '',
    );
  }
}

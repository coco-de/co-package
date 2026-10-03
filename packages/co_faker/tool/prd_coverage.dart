import 'dart:convert';
import 'dart:io';

import 'package:co_faker/co_faker.dart';

/// Reports actual role lookup/type support for the independent PRD inventory.
void main(List<String> args) {
  final inventory =
      jsonDecode(File('docs/prd_domain_inventory.json').readAsStringSync())
          as Map<String, dynamic>;
  final types = (inventory['types'] as Map).cast<String, String>();
  final faker = CoFaker(
    seed: 436,
    now: DateTime.parse(inventory['clock'] as String),
    domains: CoFakerDomains.all,
  );
  final requests = <CoCoverageEntity>[];
  for (final source in inventory['sources'] as List) {
    final fields = <String, String>{};
    final roles = <String, String>{};
    for (final entry in (source['roles'] as Map).entries) {
      for (final role in entry.value as List) {
        final qualified = '${entry.key}.$role';
        fields[qualified] = types[qualified] ?? 'String';
        roles[qualified] = qualified;
      }
    }
    requests.add(
      CoCoverageEntity('PRD-${source['issue']}', fields: fields, roles: roles),
    );
  }
  final report = CoFakerCoverage(faker).check(requests);
  if (args.contains('--summary')) {
    final unique = report.rows.map((row) => row.role).toSet();
    final counts = <String, int>{};
    for (final name in unique) {
      final pack = name.split('.').first;
      counts[pack] = (counts[pack] ?? 0) + 1;
    }
    stdout.writeln(
      const JsonEncoder.withIndent('  ').convert({
        'sourceCount': requests.length,
        'newPackCount': (inventory['newPacks'] as List).length,
        'roleRequests': report.rows.length,
        'uniqueRoles': unique.length,
        'supportedRows': report.rows
            .where((row) => row.status == CoCoverageStatus.supported)
            .length,
        'unsupportedRows': report.rows
            .where((row) => row.status == CoCoverageStatus.unsupported)
            .length,
        'packUniqueRoleCounts': counts,
        'registeredNewRoles': CoFakerDomains.all
            .skip(3)
            .fold<int>(0, (n, pack) => n + pack.roles.length),
        'registeredNewEntities': CoFakerDomains.all
            .skip(3)
            .fold<int>(0, (n, pack) => n + pack.entities.length),
        'sources': [
          for (final request in requests)
            {
              'source':
                  '${inventory['sourceBase']}${request.name.substring(4)}',
              'roleRequests': request.roles.length,
              'supported': report.rows
                  .where(
                    (row) =>
                        row.entity == request.name &&
                        row.status == CoCoverageStatus.supported,
                  )
                  .length,
            },
        ],
      }),
    );
    if (!report.complete) exitCode = 1;
    return;
  }
  stdout.writeln(
    args.contains('--markdown')
        ? report.toMarkdown()
        : const JsonEncoder.withIndent('  ').convert(report.toJson()),
  );
  if (!report.complete) exitCode = 1;
}

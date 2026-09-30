import 'dart:convert';
import 'dart:io';

import 'package:co_faker/co_faker.dart';
import 'package:test/test.dart';

void main() {
  test('reports pack support, generic fill, enum gaps and unknown roles', () {
    final faker = CoFaker(domains: CoFakerDomains.all, seed: 7);
    final report = CoFakerCoverage(faker).check(const [
      CoCoverageEntity('clinic.patient'),
      CoCoverageEntity(
        'appointment',
        fields: {
          'patientId': 'int',
          'status': 'String',
          'mystery': 'String',
          'custom': 'String',
        },
        roles: {'custom': 'notRegistered'},
      ),
      CoCoverageEntity('missing'),
    ]);
    CoCoverageRow row(String entity, String field) => report.rows.firstWhere(
      (row) => row.entity == entity && row.field == field,
    );
    expect(row('clinic.patient', 'chartNo').status, CoCoverageStatus.supported);
    expect(row('clinic.patient', 'id').status, CoCoverageStatus.generic);
    expect(row('appointment', 'patientId').status, CoCoverageStatus.generic);
    expect(row('appointment', 'status').status, CoCoverageStatus.needsEnum);
    expect(row('appointment', 'mystery').status, CoCoverageStatus.unsupported);
    expect(row('appointment', 'custom').detail, 'Unknown role');
    expect(row('missing', '').status, CoCoverageStatus.unsupported);
    expect(report.complete, isFalse);
    expect(report.toMarkdown(), contains('| clinic.patient | chartNo |'));
    expect(report.toJson().first['status'], isNotEmpty);
  });

  test(
    'explicit enums complete a generic status field without random draws',
    () {
      final faker = CoFaker(domains: CoFakerDomains.all, seed: 7);
      final control = CoFaker(seed: 7);
      faker.random.int();
      control.random.int();
      final report = CoFakerCoverage(faker).check(const [
        CoCoverageEntity(
          'appointment',
          fields: {'status': 'String'},
          enums: {
            'status': ['booked', 'cancelled'],
          },
        ),
      ]);
      expect(report.complete, isTrue);
      expect(report.rows.single.status, CoCoverageStatus.generic);
      expect(faker.random.int(), control.random.int());
    },
  );

  test('CLI emits JSON for cob plan and strict reports gaps', () async {
    final input = jsonEncode({
      'entities': [
        'clinic.patient',
        {
          'name': 'appointment',
          'fields': {'status': 'String'},
        },
      ],
    });
    final temporary = await Directory.systemTemp.createTemp(
      'co_faker_coverage_',
    );
    final plan = File('${temporary.path}/plan.json');
    try {
      await plan.writeAsString(input);
      final result = await Process.run(Platform.resolvedExecutable, [
        'run',
        'co_faker:coverage',
        '--input',
        plan.path,
        '--format',
        'json',
        '--strict',
      ], workingDirectory: Directory.current.path);
      expect(result.exitCode, 1, reason: '${result.stderr}');
      final json = jsonDecode(result.stdout as String) as Map<String, dynamic>;
      expect(json['complete'], isFalse);
      expect(json['rows'], isA<List<dynamic>>());
    } finally {
      await temporary.delete(recursive: true);
    }
  });
}

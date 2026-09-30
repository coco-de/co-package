import 'package:co_faker/co_faker.dart';
import 'package:test/test.dart';

class _LibraryDomain extends CoFakerDomain {
  const _LibraryDomain();

  @override
  String get name => 'library';

  @override
  Map<String, CoDomainRole> get roles => {
    'isbn': CoDomainRole(
      (faker, _) => faker.random.digits('979-11-#####-##-#'),
      fieldPatterns: const ['isbn'],
    ),
  };

  @override
  Map<String, Map<String, String>> get entities => const {
    'book': {'id': 'int', 'title': 'String', 'isbn': 'String'},
  };
}

void main() {
  CoFaker faker() => CoFaker(
    locale: 'ko',
    seed: 42,
    now: DateTime.utc(2026, 10, 1),
    domains: [...CoFakerDomains.all, const _LibraryDomain()],
  );

  test('registered roles generate stable values with independent fields', () {
    final first = faker().schema.entity('library.book', index: 2);
    final secondFaker = faker();
    secondFaker.random.int();
    final second = secondFaker.schema.entity('library.book', index: 2);
    expect(second, first);
    expect(first['isbn'], matches(RegExp(r'^979-11-\d{5}-\d{2}-\d$')));

    final extended = faker().schema.record(
      {'id': 'int', 'title': 'String', 'isbn': 'String', 'note': 'String'},
      index: 2,
      streamKey: 'library.book',
      entity: 'library.book',
    );
    for (final field in first.keys) {
      expect(extended[field], first[field], reason: field);
    }
    expect(faker().schema.entities('library.book', 3)[2], first);
  });

  test('clinic and SaaS examples resolve entity roles and enum values', () {
    final patient = faker().schema.entity('clinic.patient');
    expect(patient['chartNo'], matches(RegExp(r'^\d')));
    expect(patient['rrnMasked'], contains('*'));
    expect(patient['phone'], startsWith('010-0'));

    final invoice = faker().schema.entity('saas.invoice', index: 3);
    expect(invoice['number'], startsWith('INV-2026-09-0004'));
    final operators = faker().schema.entities('saas.operator', 3);
    expect(operators.map((row) => row['status']).toList(), [
      'active',
      'invited',
      'suspended',
    ]);
  });

  test('qualified lookup does not borrow an enum from another pack', () {
    final invoice = faker().schema.entity('saas.invoice');
    expect(invoice['status'], isA<String>());
    expect(() => faker().schema.entity('missing.book'), throwsArgumentError);
  });
}

import 'package:co_faker/co_faker.dart';

void main() {
  // A fixed seed and clock make every value below repeatable.
  final faker = CoFaker(locale: 'ko', seed: 42, now: DateTime.utc(2026, 1, 1));

  final users = faker.generate(3, (faker, index) {
    return faker.object({
      'id': (_) => faker.id.uuid(),
      'index': (_) => index,
      'name': (_) => faker.person.fullName(),
      'email': (_) => faker.internet.email(),
      'joinedAt': (_) => faker.date.past(days: 90, utc: true).toIso8601String(),
    });
  });

  // Records from a field schema: roles are inferred from the field names.
  final courses = faker.schema.records(
    3,
    {
      'title': 'String',
      'instructor': 'String',
      'price': 'int',
      'startsAt': 'DateTime?',
      'thumbnailUrl': 'String',
      'status': 'String',
    },
    enums: {
      'status': ['draft', 'open', 'closed'],
    },
    streamKey: 'course',
  );

  // Clinic (EMR) and SaaS back-office fixtures. Identity values are fake by
  // construction: unassignable phone blocks and checksum-failing numbers.
  final patients = faker.generate(3, (faker, _) => faker.clinic.patient());
  final tenant = faker.saas.tenant();
  final slots = faker.clinic.businessSlots(DateTime.utc(2026, 1, 2));

  for (final patient in patients) {
    // ignore: avoid_print
    print(patient);
  }
  // ignore: avoid_print
  print(tenant);
  // ignore: avoid_print
  print('${slots.length} slots, first ${slots.first}');

  for (final user in users) {
    // ignore: avoid_print
    print(user);
  }
  for (final course in courses) {
    // ignore: avoid_print
    print(course);
  }
}

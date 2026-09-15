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

  for (final user in users) {
    // ignore: avoid_print
    print(user);
  }
  for (final course in courses) {
    // ignore: avoid_print
    print(course);
  }
}

import 'package:co_faker/co_faker.dart';

void main() {
  final faker = CoFaker(locale: 'en', seed: 42);

  final users = faker.generate(3, (faker, index) {
    return faker.object({
      'id': (_) => faker.id.uuid(),
      'index': (_) => index,
      'name': (_) => faker.person.fullName(),
      'email': (_) => faker.internet.email(),
      'joinedAt': (_) => faker.date.past(days: 90).toIso8601String(),
    });
  });

  for (final user in users) {
    // ignore: avoid_print
    print(user);
  }
}

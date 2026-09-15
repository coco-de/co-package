import 'dart:convert';

import 'package:co_faker/co_faker.dart';
import 'package:test/test.dart';

void main() {
  group('derive', () {
    test('creates independent streams that do not affect each other', () {
      final base = CoFaker(seed: 5);
      final a = base.derive('a');
      final b = base.derive('b');

      final aFirst = a.number.int();
      // Drawing from the sibling stream must not move stream `a`.
      b.number.int();
      b.number.int();
      final aSecond = a.number.int();

      final control = CoFaker(seed: 5).derive('a');
      expect(control.number.int(), aFirst);
      expect(control.number.int(), aSecond);
    });

    test('is deterministic for the same seed and key', () {
      final first = CoFaker(seed: 9, locale: 'ko').derive('course/0/title');
      final second = CoFaker(seed: 9, locale: 'ko').derive('course/0/title');

      expect(first.text.words(3), second.text.words(3));
      expect(first.locale, 'ko');
    });

    test('differs across keys and preserves the clock', () {
      final now = DateTime.utc(2026, 1, 1);
      final base = CoFaker(seed: 9, now: now);

      expect(base.derive('x').id.uuid(), isNot(base.derive('y').id.uuid()));
      expect(base.derive('x').now, now);
    });

    test('exposes the seed and derives stable seeds', () {
      expect(CoFaker(seed: 3).seed, 3);
      expect(CoFaker().seed, isNull);
      expect(CoRandom.deriveSeed(3, 'k'), CoRandom.deriveSeed(3, 'k'));
      expect(CoRandom.deriveSeed(3, 'k'), isNot(CoRandom.deriveSeed(4, 'k')));
      expect(CoRandom.deriveSeed(3, 'k'), greaterThanOrEqualTo(0));
    });
  });

  group('pickBalanced', () {
    test('cycles through items by index without consuming the stream', () {
      final random = CoRandom(1);
      const items = ['a', 'b', 'c'];

      final before = CoRandom(1).int();
      expect(random.pickBalanced(items, 0), 'a');
      expect(random.pickBalanced(items, 4), 'b');
      expect(random.int(), before);
    });

    test('validates input', () {
      final random = CoRandom(1);

      expect(() => random.pickBalanced(<int>[], 0), throwsArgumentError);
      expect(() => random.pickBalanced([1], -1), throwsArgumentError);
    });
  });

  group('date utc', () {
    test('returns UTC values with a Z suffix when requested', () {
      final faker = CoFaker(seed: 1, now: DateTime.utc(2026, 1, 1, 9));

      final past = faker.date.past(utc: true);
      final future = faker.date.future(days: 10, utc: true);
      final birth = faker.date.dateOfBirth(utc: true);

      expect(past.isUtc, isTrue);
      expect(past.toIso8601String(), endsWith('Z'));
      expect(future.isUtc, isTrue);
      expect(future.isAfter(faker.now) || future == faker.now, isTrue);
      expect(birth.isUtc, isTrue);
      expect(faker.date.past().isUtc, isFalse);
    });

    test('keeps the inclusive range when from equals to', () {
      final faker = CoFaker(seed: 1);
      final at = DateTime.utc(2026, 5, 5);

      expect(faker.date.between(at, at, utc: true), at);
    });
  });

  group('image data URIs', () {
    test('embeds a valid SVG without any network host', () {
      final faker = CoFaker(seed: 2);

      final uri = faker.image.placeholderDataUri(
        width: 320,
        height: 200,
        label: 'A & B <c>',
      );

      expect(uri, startsWith('data:image/svg+xml;base64,'));
      final svg = utf8.decode(base64Decode(uri.split(',').last));
      expect(svg, contains('width="320"'));
      expect(svg, contains('A &amp; B &lt;c&gt;'));
      expect(svg, isNot(contains('https://')));
    });

    test('avatar uses initials from the locale and is deterministic', () {
      final first = CoFaker(seed: 2, locale: 'ko').image.avatarDataUri();
      final second = CoFaker(seed: 2, locale: 'ko').image.avatarDataUri();
      final svg = utf8.decode(base64Decode(first.split(',').last));

      expect(first, second);
      expect(svg, contains('rx="64"'));
      expect(svg, matches(RegExp('>[가-힣]</text>')));
    });

    test('validates sizes', () {
      final faker = CoFaker(seed: 2);

      expect(
        () => faker.image.placeholderDataUri(width: 0),
        throwsArgumentError,
      );
      expect(() => faker.image.avatarDataUri(size: -1), throwsArgumentError);
    });
  });

  group('Korean locale', () {
    test('has enough vocabulary to avoid immediate repetition', () {
      final locale = CoFakerLocales.korean;

      expect(locale.firstNames.length, greaterThanOrEqualTo(50));
      expect(locale.lastNames.length, greaterThanOrEqualTo(30));
      expect(locale.words.length, greaterThanOrEqualTo(100));
      expect(locale.productNouns.length, greaterThanOrEqualTo(30));
      expect(locale.categories.length, greaterThanOrEqualTo(15));
      expect(locale.firstNames.toSet().length, locale.firstNames.length);
      expect(locale.words.toSet().length, locale.words.length);
    });

    test('generates distinct names across a small fixture', () {
      final faker = CoFaker(locale: 'ko', seed: 11);
      final names = faker.generate(10, (f, _) => f.person.fullName()).toSet();

      expect(names.length, greaterThanOrEqualTo(8));
    });
  });
}

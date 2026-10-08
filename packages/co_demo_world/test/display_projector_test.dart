import 'package:co_demo_world/co_demo_world.dart';
import 'package:test/test.dart';

import 'support/sample_world.dart';

void main() {
  late List<SamplePet> pets;
  late List<DisplayKey> keys;

  setUp(() {
    pets = buildSamplePets(sampleConfig);
    keys = sampleKeys(pets);
  });

  group('determinism', () {
    test('the same inputs give the same values in every language', () {
      final first = DisplayProjector(
        config: sampleConfig,
        fields: sampleFields(),
      );
      final second = DisplayProjector(
        config: sampleConfig,
        fields: sampleFields(),
      );
      for (final locale in DemoLocale.values) {
        for (final key in keys) {
          expect(
            first.generated(key, locale: locale),
            second.generated(key, locale: locale),
            reason: '${locale.tag} ${key.path}',
          );
        }
      }
    });

    test('values do not depend on the order of reads', () {
      final forward = DisplayProjector(
        config: sampleConfig,
        fields: sampleFields(),
      );
      final backward = DisplayProjector(
        config: sampleConfig,
        fields: sampleFields(),
      );
      final forwardValues = {
        for (final key in keys)
          key: forward.generated(key, locale: DemoLocale.ja),
      };
      for (final key in keys.reversed) {
        expect(
          backward.generated(key, locale: DemoLocale.ja),
          forwardValues[key],
        );
      }
    });

    test('a different seed gives different display values', () {
      final other = DisplayProjector(
        config: DemoWorldConfig(seed: 437, now: sampleConfig.now),
        fields: sampleFields(),
      );
      final base = DisplayProjector(
        config: sampleConfig,
        fields: sampleFields(),
      );
      final differing = keys
          .where((key) => other.generated(key) != base.generated(key))
          .length;
      expect(differing, greaterThan(keys.length ~/ 2));
    });
  });

  group('language switch', () {
    test('changes display text and returns to the same text', () {
      final projector = DisplayProjector(
        config: sampleConfig,
        fields: sampleFields(),
      );
      final guardian = DisplayKey('guardian', pets.first.id, 'name');
      final korean = projector.text(guardian);
      projector.locale = DemoLocale.en;
      final english = projector.text(guardian);
      projector.locale = DemoLocale.ja;
      final japanese = projector.text(guardian);
      projector.locale = DemoLocale.ko;

      expect(RegExp('[가-힣]').hasMatch(korean), isTrue, reason: korean);
      expect(RegExp('[A-Za-z]').hasMatch(english), isTrue, reason: english);
      expect(RegExp('[぀-ヿ一-鿿]').hasMatch(japanese), isTrue);
      expect(projector.text(guardian), korean);
    });

    test('never changes the business data (A)', () {
      final before = List<SamplePet>.of(pets);
      final projector = DisplayProjector(
        config: sampleConfig,
        fields: sampleFields(),
      );
      for (final locale in [
        DemoLocale.ko,
        DemoLocale.en,
        DemoLocale.ja,
        DemoLocale.ar,
        DemoLocale.ko,
      ]) {
        projector.locale = locale;
        keys.forEach(projector.text);
      }
      expect(pets, before);
      // Rebuilding the world after projecting in every language gives the
      // same records: the display stream does not consume business draws.
      expect(buildSamplePets(sampleConfig), before);
    });

    test('the business stream ignores the UI language entirely', () {
      final worlds = [
        for (final locale in DemoLocale.values)
          buildSamplePets(
            DemoWorldConfig(
              seed: sampleConfig.seed,
              now: sampleConfig.now,
              baseLocale: locale,
            ),
          ),
      ];
      for (final world in worlds) {
        expect(world, worlds.first);
      }
    });
  });

  group('reads', () {
    test('generate each value once per language and never again', () {
      final generated = <String>[];
      final projector = DisplayProjector(
        config: sampleConfig,
        fields: sampleFields(onGenerate: (key) => generated.add(key.path)),
      );
      for (var round = 0; round < 5; round++) {
        keys.forEach(projector.text);
      }
      expect(generated, hasLength(keys.length));
      expect(projector.memoizedCount(DemoLocale.ko), keys.length);

      projector.locale = DemoLocale.en;
      keys.forEach(projector.text);
      projector.locale = DemoLocale.ko;
      keys.forEach(projector.text);
      expect(generated, hasLength(keys.length * 2));
    });

    test('warm projects ahead of a switch without changing the language', () {
      final projector = DisplayProjector(
        config: sampleConfig,
        fields: sampleFields(),
      );
      projector.warm(keys.take(4), DemoLocale.ar);
      expect(projector.locale, DemoLocale.ko);
      expect(projector.memoizedCount(DemoLocale.ar), 4);
    });

    test('an unregistered field fails loudly', () {
      final projector = DisplayProjector(
        config: sampleConfig,
        fields: sampleFields(),
      );
      expect(
        () => projector.text(DisplayKey('pet', 'pet-0001', 'nickname')),
        throwsStateError,
      );
    });
  });

  group('user edits (C)', () {
    test('win over the projection and survive a language switch', () {
      final projector = DisplayProjector(
        config: sampleConfig,
        fields: sampleFields(),
      );
      final key = DisplayKey('pet', pets.first.id, 'name');
      final generatedKo = projector.text(key);
      projector.overlay.set(key, '보리둥이');
      for (final locale in DemoLocale.values) {
        projector.locale = locale;
        expect(projector.text(key), '보리둥이', reason: locale.tag);
      }
      projector.locale = DemoLocale.ko;
      expect(projector.generated(key), generatedKo);
      expect(projector.overlay.remove(key), isTrue);
      expect(projector.text(key), generatedKo);
    });
  });

  group('search text', () {
    test('follows the current language', () {
      final projector = DisplayProjector(
        config: sampleConfig,
        fields: sampleFields(),
      );
      final record = [
        DisplayKey('guardian', pets.first.id, 'name'),
        DisplayKey('guardian', pets.first.id, 'city'),
      ];
      final korean = projector.searchText(record);
      projector.locale = DemoLocale.en;
      final english = projector.searchText(record);
      expect(
        korean,
        contains(
          projector
              .generated(record.first, locale: DemoLocale.ko)
              .toLowerCase(),
        ),
      );
      expect(english, contains(projector.text(record.first).toLowerCase()));
      expect(english, isNot(korean));
    });
  });

  group('DisplayKey', () {
    test('rejects empty parts and the path separator', () {
      expect(() => DisplayKey('', 'id', 'field'), throwsArgumentError);
      expect(() => DisplayKey('pet', 'a/b', 'name'), throwsArgumentError);
      expect(DisplayKey('pet', 'pet-1', 'name').path, 'pet/pet-1/name');
      expect(DisplayKey('pet', 'pet-1', 'name').fieldKey, 'pet.name');
      expect(
        DisplayKey('pet', 'pet-1', 'name'),
        DisplayKey('pet', 'pet-1', 'name'),
      );
    });
  });
}

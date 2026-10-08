import 'package:co_faker/co_faker.dart';
import 'package:test/test.dart';

CoFaker _faker(
  String locale, {
  int seed = 7,
  Map<String, CoFakerLocale> locales = const <String, CoFakerLocale>{},
}) => CoFaker(
  locale: locale,
  seed: seed,
  now: DateTime.utc(2026),
  locales: locales,
);

/// A Spanish bundle for three keys: a custom locale needs no more to start.
const CoL10nBundle _spanish = CoL10nBundle(
  language: 'es',
  texts: <String, List<String>>{
    'dental.dentalProcedure': [
      'Limpieza dental',
      'Ejemplo de endodoncia',
      'Ejemplo de restauración con resina',
      'Ejemplo de plan de corona',
    ],
    'dental.chairName': [
      'Sillón dental 1',
      'Sillón dental 2',
      'Sillón dental 3',
    ],
    'workplace.sprintName': ['Sprint {n}'],
  },
);

Map<String, CoFakerLocale> get _spanishLocales => const {
  'es': CoFakerLocale(code: 'es', l10n: _spanish),
};

void main() {
  final english = CoL10nRegistry.english;
  final korean = CoL10nRegistry.bundleFor('ko')!;

  group('CoL10nRegistry', () {
    test('ships Korean and English text and registers the other languages', () {
      expect(english.language, 'en');
      expect(english.isNotEmpty, isTrue);
      expect(korean.language, 'ko');
      expect(korean.isNotEmpty, isTrue);
      for (final code in ['zh', 'ja', 'de', 'fr', 'ru', 'it', 'pt']) {
        final bundle = CoL10nRegistry.bundleFor(code);
        expect(bundle, isNotNull, reason: code);
        expect(bundle!.language, code);
      }
      expect(CoL10nRegistry.bundleFor('xx'), isNull);
    });

    test('holds every bundle under its own language code', () {
      for (final entry in CoL10nRegistry.bundles.entries) {
        expect(entry.value.language, entry.key);
      }
      expect(CoL10nRegistry.bundles.keys.first, 'ko');
      expect(
        () => CoL10nRegistry.bundles['xx'] = const CoL10nBundle(language: 'xx'),
        throwsUnsupportedError,
      );
    });

    test('keeps the Korean and English texts of 187 pairs aligned', () {
      // The 180 textRole and 7 taxonomyRole pairs of the packs, and the
      // dedicated generators' texts, are all keys of both bundles.
      expect(english.texts.length, greaterThanOrEqualTo(187));
      expect(korean.texts.keys.toSet(), english.texts.keys.toSet());
      for (final entry in english.texts.entries) {
        expect(
          korean.texts[entry.key]!.length,
          entry.value.length,
          reason: entry.key,
        );
      }
    });

    test('every shipped bundle is sound against English', () {
      for (final bundle in CoL10nRegistry.bundles.values) {
        expect(
          CoL10nRegistry.validate(bundle),
          isEmpty,
          reason: bundle.language,
        );
      }
    });

    test('validate reports unknown keys, misaligned lists, and empty text', () {
      expect(CoL10nRegistry.validate(_spanish), isEmpty);
      final problems = CoL10nRegistry.validate(
        const CoL10nBundle(
          language: 'xx',
          texts: {
            'dental.noSuchRole': ['a'],
            'dental.dentalProcedure': ['one', 'two'],
            'dental.chairName': ['a', '', 'c'],
            'workplace.sprintName': [],
          },
        ),
      );
      expect(problems, hasLength(5));
      expect(
        problems,
        contains('xx: "dental.noSuchRole" is not a key of the English bundle'),
      );
      expect(
        problems,
        contains('xx: "dental.dentalProcedure" has 2 texts, English has 4'),
      );
      expect(
        problems,
        contains('xx: "dental.chairName" has an empty text at index 1'),
      );
      expect(problems, contains('xx: "workplace.sprintName" has no text'));
      expect(
        problems,
        contains('xx: "workplace.sprintName" has 0 texts, English has 1'),
      );
    });

    test('computes a language\'s domain flag from its bundle', () {
      for (final language in CoFakerLanguages.all) {
        expect(
          language.domain,
          CoL10nRegistry.hasDomainData(language.code),
          reason: language.code,
        );
        expect(
          CoL10nRegistry.hasDomainData(language.code),
          CoL10nRegistry.bundleFor(language.code)?.isNotEmpty ?? false,
          reason: language.code,
        );
      }
      expect(CoFakerLanguages.korean.domain, isTrue);
      expect(CoFakerLanguages.english.domain, isTrue);
      expect(CoL10nRegistry.hasDomainData('xx'), isFalse);
    });
  });

  group('the language a generator reads', () {
    test('is its language when that language has domain text', () {
      expect(_faker('ko').l10n.language, 'ko');
      expect(_faker('en').l10n.language, 'en');
      for (final code in ['ko_KR', 'ko-KR', 'KO', 'ko_kr.utf_8']) {
        expect(_faker(code).l10n.language, 'ko', reason: code);
      }
      for (final code in ['en_US', 'en-GB', 'en_AU', 'en_IN']) {
        expect(_faker(code).l10n.language, 'en', reason: code);
      }
    });

    test('follows the bundle registry for every supported language', () {
      for (final language in CoFakerLanguages.all) {
        for (final code in [
          language.code,
          language.locale,
          '${language.code}_XX',
        ]) {
          expect(
            _faker(code).l10n.language,
            language.domain ? language.code : 'en',
            reason: code,
          );
        }
      }
    });

    test('is English for unsupported and custom codes', () {
      for (final code in [
        'ar',
        'nl',
        'und',
        'xx_YY',
        'acme',
        'kok',
        'ja.UTF-8',
      ]) {
        expect(_faker(code).l10n.language, 'en', reason: code);
      }
    });

    test('is never Chinese for Traditional Chinese', () {
      for (final code in [
        'zh_TW',
        'zh-TW',
        'zh_HK',
        'zh_MO',
        'zh-Hant',
        'zh_Hant_TW',
        'zh-Hant-HK',
        'ZH_tw',
      ]) {
        expect(_faker(code).l10n.language, 'en', reason: code);
      }
      for (final code in [
        'zh',
        'zh_CN',
        'zh-Hans',
        'zh_Hans_CN',
        'zh_Hans_TW',
      ]) {
        expect(
          _faker(code).l10n.language,
          CoFakerLanguages.chinese.domain ? 'zh' : 'en',
          reason: code,
        );
      }
    });

    test('reads English text for a language without domain text', () {
      for (final key in ['dental.dentalProcedure', 'workplace.sprintName']) {
        final expected = english.texts[key];
        for (final code in ['nl', 'xx_YY', 'zh_TW', 'zh_HK']) {
          expect(_faker(code).l10n.list(key), expected, reason: '$code $key');
        }
      }
    });

    test('keeps the Korean text for every code that starts with `ko`', () {
      final expected = korean.texts['dental.dentalProcedure'];
      for (final code in ['ko', 'ko_KR', 'ko-KR', 'KO_kr']) {
        expect(
          _faker(code).l10n.list('dental.dentalProcedure'),
          expected,
          reason: code,
        );
      }
    });
  });

  group('reading text', () {
    test('picks with the draw of faker.random.pick in every language', () {
      for (final entry in english.texts.entries) {
        final key = entry.key;
        // The index `faker.random.pick` draws from a seeded stream.
        final index = _faker('en').random.int(max: entry.value.length - 1);
        expect(_faker('en').l10n.pick(key), entry.value[index], reason: key);
        expect(
          _faker('ko').l10n.pick(key),
          korean.texts[key]![index],
          reason: 'one seed picks the same entry of $key in both languages',
        );
      }
    });

    test('cycles by index without drawing from the random stream', () {
      final f = _faker('ko');
      final texts = korean.texts['dental.chairName']!;
      for (var i = 0; i < 7; i++) {
        expect(f.l10n.pickBalanced('dental.chairName', i), texts[i % 3]);
      }
      expect(f.random.int(), _faker('ko').random.int());
      expect(
        () => f.l10n.pickBalanced('dental.chairName', -1),
        throwsArgumentError,
      );
    });

    test('text reads a key of one entry and refuses a key of several', () {
      expect(_faker('en').l10n.text('fx.currencyName.USD'), 'US dollar');
      expect(_faker('ko').l10n.text('fx.currencyName.USD'), '미국 달러');
      expect(
        () => _faker('en').l10n.text('dental.dentalProcedure'),
        throwsStateError,
      );
    });

    test('throws a StateError for a key that no bundle has', () {
      final f = _faker('ko');
      expect(() => f.l10n.list('dental.dentalProcedur'), throwsStateError);
      expect(() => f.l10n.pick('nope'), throwsStateError);
      expect(() => f.l10n.text(''), throwsStateError);
      expect(
        () => f.l10n.format('dental.noSuchRole', const {}),
        throwsStateError,
      );
    });
  });

  group('format', () {
    test('fills the placeholders of a template', () {
      expect(
        _faker('ko').l10n.format('workplace.sprintName', {'n': 3}),
        '스프린트 3',
      );
      expect(
        _faker('en').l10n.format('workplace.sprintName', {'n': 3}),
        'Sprint 3',
      );
      expect(
        _faker(
          'en',
        ).l10n.format('common.taxonomyChild', {'root': 'Fruit', 'n': 2}),
        'Fruit · subtopic 2',
      );
    });

    test('fills the placeholders in a single pass', () {
      expect(
        _faker(
          'en',
        ).l10n.format('common.taxonomyChild', {'root': '{n}', 'n': 5}),
        '{n} · subtopic 5',
      );
    });

    test('needs every placeholder the template uses', () {
      expect(
        () => _faker('en').l10n.format('workplace.sprintName', {'m': 3}),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            allOf(contains('{n}'), contains('{m}')),
          ),
        ),
      );
    });

    test('refuses a null value instead of printing it', () {
      expect(
        () => _faker('en').l10n.format('workplace.sprintName', {'n': null}),
        throwsStateError,
      );
      expect(
        () =>
            _faker('en').l10n.format('workplace.sprintName', {'n': () => null}),
        throwsStateError,
      );
    });

    test('ignores an argument the template does not use', () {
      expect(
        _faker('en').l10n.format('workplace.sprintName', {'n': 1, 'other': 2}),
        'Sprint 1',
      );
    });

    test('calls a lazy argument only when its placeholder occurs', () {
      final calls = <String>[];
      String lazy(String name, String value) {
        calls.add(name);
        return value;
      }

      final args = <String, Object?>{
        'lastName': () => lazy('lastName', 'Kim'),
        'initial': () => lazy('initial', 'J'),
      };
      expect(_faker('ko').l10n.format('common.maskedName', args), 'Kim○○');
      expect(calls, ['lastName']);
      calls.clear();
      expect(_faker('en').l10n.format('common.maskedName', args), 'J***');
      expect(calls, ['initial']);
    });

    test('draws only what the language\'s template names', () {
      final ko = _faker('ko');
      ko.l10n.format('common.maskedName', {
        'lastName': () => ko.person.lastName(),
        'initial': () => ko.person.firstName(),
      });
      final onlyLastName = _faker('ko')..person.lastName();
      expect(ko.random.int(), onlyLastName.random.int());
    });
  });

  group('a custom locale injects domain text', () {
    test('and its bundle answers before the shipped ones', () {
      final f = _faker('es', locales: _spanishLocales);
      expect(
        f.l10n.list('dental.dentalProcedure'),
        _spanish.texts['dental.dentalProcedure'],
      );
      expect(
        _spanish.texts['dental.dentalProcedure'],
        contains(f.l10n.pick('dental.dentalProcedure')),
      );
      expect(f.l10n.format('workplace.sprintName', {'n': 2}), 'Sprint 2');
    });

    test('and a key it lacks falls back to English, key by key', () {
      final f = _faker('es', locales: _spanishLocales);
      expect(
        f.l10n.list('dental.dentalMaterial'),
        english.texts['dental.dentalMaterial'],
      );
      expect(f.l10n.language, 'en');
    });

    test('and it overrides a shipped language for the keys it has', () {
      final f = _faker(
        'ko',
        locales: const {
          'ko': CoFakerLocale(
            code: 'ko',
            l10n: CoL10nBundle(
              language: 'ko',
              texts: {
                'dental.chairName': ['체어 가', '체어 나', '체어 다'],
              },
            ),
          ),
        },
      );
      expect(f.l10n.list('dental.chairName'), ['체어 가', '체어 나', '체어 다']);
      // Not in the custom bundle: the shipped Korean text answers.
      expect(
        f.l10n.list('dental.dentalMaterial'),
        korean.texts['dental.dentalMaterial'],
      );
      expect(f.l10n.language, 'ko');
    });

    test('and the other locales are not affected', () {
      expect(
        _faker('en', locales: _spanishLocales).l10n.list('dental.chairName'),
        english.texts['dental.chairName'],
      );
      expect(
        _faker('ko', locales: _spanishLocales).l10n.list('dental.chairName'),
        korean.texts['dental.chairName'],
      );
    });

    test('and CoFaker.forLanguage, derive, and localized keep it', () {
      final custom = _spanishLocales;
      final texts = _spanish.texts['dental.chairName'];
      expect(
        CoFaker.forLanguage(
          'es',
          seed: 7,
          locales: custom,
        ).l10n.list('dental.chairName'),
        texts,
      );
      expect(
        _faker(
          'es',
          locales: custom,
        ).derive('record/1').l10n.list('dental.chairName'),
        texts,
      );
      expect(
        _faker(
          'en',
          locales: custom,
        ).localized('es').l10n.list('dental.chairName'),
        texts,
      );
    });

    test('and a custom locale for another language serves its own keys', () {
      const acme = CoL10nBundle(
        language: 'xx',
        texts: {
          'acme.greeting': ['hello', 'hi'],
        },
      );
      final f = _faker(
        'acme',
        locales: const {'acme': CoFakerLocale(code: 'acme', l10n: acme)},
      );
      expect(f.l10n.list('acme.greeting'), ['hello', 'hi']);
      expect(f.l10n.language, 'en');
      // A key the custom bundle does not have is not invented for it.
      expect(() => _faker('en').l10n.list('acme.greeting'), throwsStateError);
    });

    test('and a list that is not as long as English\'s is refused', () {
      final f = _faker(
        'es',
        locales: const {
          'es': CoFakerLocale(
            code: 'es',
            l10n: CoL10nBundle(
              language: 'es',
              texts: {
                'dental.dentalProcedure': ['Limpieza dental'],
              },
            ),
          ),
        },
      );
      expect(
        () => f.l10n.list('dental.dentalProcedure'),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            allOf(
              contains('dental.dentalProcedure'),
              contains('1'),
              contains('4'),
            ),
          ),
        ),
      );
      // Other keys are not affected.
      expect(
        f.l10n.list('dental.chairName'),
        english.texts['dental.chairName'],
      );
    });

    test('and merge keeps the bundle of the locale, never English\'s', () {
      const custom = CoFakerLocale(code: 'es', l10n: _spanish);
      expect(custom.merge(CoFakerLocales.english).l10n, same(_spanish));
      expect(
        const CoFakerLocale(
          code: 'es',
        ).merge(const CoFakerLocale(code: 'en', l10n: _spanish)).l10n,
        isNull,
      );
      // A custom English locale with text does not answer for Korean.
      final f = _faker(
        'ko',
        locales: const {
          'en': CoFakerLocale(
            code: 'en',
            l10n: CoL10nBundle(
              language: 'en',
              texts: {
                'dental.chairName': ['A', 'B', 'C'],
              },
            ),
          ),
        },
      );
      expect(f.l10n.list('dental.chairName'), korean.texts['dental.chairName']);
    });
  });
}

import 'package:co_faker/co_faker.dart';
import 'package:test/test.dart';

import 'language_safety/language_safety.dart';
import 'language_safety/languages.dart';

CoFaker _faker({String locale = 'ko', int seed = 436}) => CoFaker(
  locale: locale,
  seed: seed,
  now: DateTime.utc(2026, 1, 15),
  domains: CoFakerDomains.all,
);

String _value(CoFaker f, String role, int index) =>
    f.schema.record(
          {'value': 'String'},
          roles: {'value': role},
          index: index,
        )['value']
        as String;

/// The locales whose authored text is scanned: every language that has domain
/// text, read from the registries, so that a language that is localized is
/// scanned with no edit here, and `nl`, a language that has none and never
/// will, which reads English.
final List<String> _scanned = <String>[
  'nl',
  for (final language in CoFakerLanguages.all)
    if (language.domain) language.code,
];

/// The declaration that the text of [locale] is read with: the one of its
/// language, or the English one for a locale that reads English.
LanguageSafety _safety(String locale) =>
    languageSafety[CoFakerLanguages.resolve(locale).language.code]!;

/// Every spelling of a brand, work, company, or medicine that any language
/// denies. A text of any language is scanned for all of them: a Latin brand in
/// Japanese text is as wrong as a Japanese one.
final RegExp _deniedBrands = safetyPattern(<String>[
  for (final safety in languageSafety.values) ...safety.deniedBrands,
]);

/// The phrases that [locale] may not promise with: its own and English's.
RegExp _deniedPromises(String locale) => safetyPattern(<String>[
  ..._safety(locale).deniedPromises,
  ...languageSafety['en']!.deniedPromises,
]);

void main() {
  test(
    'every language that has domain text declares its safety conventions',
    () {
      // The declaration of a language lives in test/language_safety/<code>.dart.
      // A language that has domain text and leaves it empty fails here, instead
      // of being skipped by the scans below.
      expect(
        languageSafety.keys,
        containsAll(CoL10nRegistry.bundles.keys),
        reason: 'a registered language has no entry in languages.dart',
      );
      for (final language in CoFakerLanguages.all) {
        if (!language.domain) continue;
        final declared = languageSafety[language.code];
        expect(declared, isNotNull, reason: language.code);
        final latin = language.script == CoFakerScript.latin;
        expect(
          declared!.isComplete(latin: latin),
          isTrue,
          reason:
              '${language.code} has domain text, but '
              'test/language_safety/${language.code}.dart does not declare: '
              '${declared.missing(latin: latin).join(', ')}',
        );
      }
    },
  );

  test(
    'authored medical labels exclude a curated real-brand list and identify fiction',
    () {
      // This is a bounded authored-data regression, not a claim to screen every
      // organization/trademark in the world. The scope is these new medicine roles.
      for (final locale in _scanned) {
        final f = _faker(locale: locale);
        final marker = _safety(locale).fictionalMarker;
        for (final role in [
          'vet.vetDrug',
          'vet.preventiveProduct',
          'daycare.drugLabel',
        ]) {
          final values = <String>{};
          for (var i = 0; i < 100; i++) {
            final text = _value(f, role, i);
            values.add(text);
            expect(
              _deniedBrands.hasMatch(text),
              isFalse,
              reason: '$locale $role: $text',
            );
            expect(
              text,
              contains(marker),
              reason: '$locale $role must carry the fictional marker',
            );
          }
          expect(values.length, greaterThan(1));
        }
      }
    },
  );

  test(
    'fictional works/prose/organizations exclude curated known titles and brands',
    () {
      const roles = [
        'content.seriesTitle',
        'content.audioTitle',
        'content.newsletterName',
        'content.articleHeadline',
        'content.chapterParagraph',
        'content.publisherName',
        'campaign.brandName',
        'brokerage.providerName',
        'remit.bankNameFictional',
        // The two creator names of a language are a bundle key like the
        // others, so a real artist's name there is caught like a real brand.
        'fandom.creatorName',
      ];
      for (final locale in _scanned) {
        final f = _faker(locale: locale);
        for (final role in roles) {
          for (var i = 0; i < 100; i++) {
            final text = _value(f, role, i);
            expect(
              _deniedBrands.hasMatch(text),
              isFalse,
              reason: '$locale $role: $text',
            );
          }
        }
      }
    },
  );

  test(
    'consultation content contains no result promises or actionable advice claims',
    () {
      for (final seed in [406, 777, 1119]) {
        for (final locale in _scanned) {
          final denied = _deniedPromises(locale);
          final prefix = _safety(locale).generalInfoPrefix;
          final f = _faker(seed: seed, locale: locale);
          for (final role in [
            'brokerage.qnaAnswerGeneric',
            'brokerage.consultNoteGeneric',
          ]) {
            for (var i = 0; i < 100; i++) {
              final text = _value(f, role, i);
              expect(
                denied.hasMatch(text),
                isFalse,
                reason: '$locale $role: $text',
              );
              expect(
                text,
                startsWith(prefix),
                reason:
                    '$locale $role must state that it is general information',
              );
            }
          }
        }
      }
    },
  );

  test('fandom creator names are exactly the two approved fictional names', () {
    // Korean and English write the two approved names as they always have, and
    // so does a language that has no domain text (`nl`, which reads English).
    for (final locale in ['ko', 'en', 'nl']) {
      final values = {
        for (var i = 0; i < 20; i++)
          _value(_faker(locale: locale), 'fandom.creatorName', i),
      };
      expect(values, {'모래시계 정원', '하늘결'}, reason: locale);
    }
    // The public constant of the pack is the same two names: nothing reads it
    // any more, and a test is what keeps it from drifting from the bundles.
    expect(CoFandomDomain.creatorNames, ['모래시계 정원', '하늘결']);
    for (final code in ['ko', 'en']) {
      expect(
        CoL10nRegistry.bundleFor(code)!.texts['fandom.creatorName'],
        CoFandomDomain.creatorNames,
        reason: code,
      );
    }
    // A language that is localized writes two fictional names of its own, in
    // the bundle, and the role cycles through exactly those two. They are not
    // the Korean names, and the scan above holds them to the denied names.
    for (final language in CoFakerLanguages.all) {
      if (!language.domain || language.code == 'ko' || language.code == 'en') {
        continue;
      }
      final names = CoL10nRegistry.bundleFor(
        language.code,
      )!.texts['fandom.creatorName'];
      expect(
        names,
        isNotNull,
        reason: '${language.code} must write fandom.creatorName',
      );
      expect(names, hasLength(2), reason: language.code);
      expect(names!.toSet(), hasLength(2), reason: language.code);
      expect(
        names.toSet().intersection(CoFandomDomain.creatorNames.toSet()),
        isEmpty,
        reason: '${language.code} writes names of its own, not the Korean ones',
      );
      final values = {
        for (var i = 0; i < 20; i++)
          _value(_faker(locale: language.code), 'fandom.creatorName', i),
      };
      expect(values, names.toSet(), reason: language.code);
    }
  });

  test('a bundle can write any creator name, and the scan finds a real one', () {
    // The names are a bundle key, so a bundle (a language, or a custom locale)
    // may write whatever it likes there: the denied-name scan is the safety
    // net, and it reads this role like the other authored names.
    final real = languageSafety['ko']!.deniedBrands.first;
    final f = CoFaker(
      locale: 'es',
      seed: 436,
      now: DateTime.utc(2026, 1, 15),
      domains: CoFakerDomains.all,
      locales: <String, CoFakerLocale>{
        'es': CoFakerLocale(
          code: 'es',
          l10n: CoL10nBundle(
            language: 'es',
            texts: <String, List<String>>{
              'fandom.creatorName': <String>[real, 'Nombre ficticio'],
            },
          ),
        ),
      },
    );
    final names = <String>{
      for (var i = 0; i < 4; i++) _value(f, 'fandom.creatorName', i),
    };
    expect(names, {real, 'Nombre ficticio'});
    expect(names.where(_deniedBrands.hasMatch), [real]);
    for (final approved in CoFandomDomain.creatorNames) {
      expect(_deniedBrands.hasMatch(approved), isFalse, reason: approved);
    }
  });

  test(
    'daycare is first-name-only and sensitive identity displays stay masked',
    () {
      final f = _faker();
      for (var i = 0; i < 100; i++) {
        expect(
          _value(f, 'daycare.childName', i),
          matches(RegExp(r'^[가-힣]{2}$')),
        );
        expect(
          _value(f, 'homecare.recipientName', i),
          matches(RegExp(r'^[가-힣]○○$')),
        );
        expect(
          _value(f, 'hospitality.guestName', i),
          matches(RegExp(r'^[가-힣]○○$')),
        );
        expect(_value(f, 'remit.romanizedNameMasked', i), contains('***'));
        expect(
          _value(f, 'fx.maskedAccount', i),
          matches(RegExp(r'^\*{4}-\*{2}-\d{4}$')),
        );
        expect(
          _value(f, 'travel_wallet.maskedCardNumber', i),
          matches(RegExp(r'^•••• \d{4}$')),
        );
        expect(_value(f, 'logistics.vehiclePlate', i), contains('●●'));
        expect(
          _value(f, 'logistics.entranceHint', i),
          isNot(matches(RegExp(r'#\d{4}'))),
        );
      }
    },
  );

  test('sensitive identity displays stay masked in every language', () {
    // Whatever language the text is in, a name, an account, a card, and a
    // plate is shown masked, and an entrance hint carries no door code.
    final mask = RegExp('[*○●◯•＊✱]');
    for (final locale in _scanned) {
      final f = _faker(locale: locale);
      for (var i = 0; i < 100; i++) {
        for (final role in [
          'homecare.recipientName',
          'hospitality.guestName',
        ]) {
          expect(
            _value(f, role, i),
            matches(mask),
            reason: '$locale $role must stay masked',
          );
        }
        expect(_value(f, 'remit.romanizedNameMasked', i), contains('***'));
        expect(
          _value(f, 'fx.maskedAccount', i),
          matches(RegExp(r'^\*{4}-\*{2}-\d{4}$')),
        );
        expect(
          _value(f, 'travel_wallet.maskedCardNumber', i),
          matches(RegExp(r'^•••• \d{4}$')),
        );
        expect(
          _value(f, 'logistics.vehiclePlate', i),
          contains('●●'),
          reason: '$locale logistics.vehiclePlate must stay masked',
        );
        expect(
          _value(f, 'logistics.entranceHint', i),
          isNot(matches(RegExp(r'#\d{4}'))),
          reason: locale,
        );
      }
    }
  });

  test(
    'new domain imagery uses the existing offline placeholder generator',
    () {
      final f = _faker();
      for (final pack in CoFakerDomains.all.skip(3)) {
        for (final entity in pack.entities.entries) {
          final images = entity.value.keys.where(
            (field) =>
                field.toLowerCase().contains('imageurl') ||
                field.toLowerCase().contains('photourl') ||
                field.toLowerCase().contains('avatarurl'),
          );
          if (images.isEmpty) continue;
          final row = f.schema.entity('${pack.name}.${entity.key}');
          for (final image in images) {
            expect(
              row[image],
              startsWith('data:image/'),
              reason: '${pack.name}.$image',
            );
          }
        }
      }
    },
  );
}

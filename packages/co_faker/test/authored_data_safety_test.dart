import 'package:co_faker/co_faker.dart';
import 'package:test/test.dart';

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

void main() {
  test(
    'authored medical labels exclude a curated real-brand list and identify fiction',
    () {
      // This is a bounded authored-data regression, not a claim to screen every
      // organization/trademark in the world. The scope is these new medicine roles.
      final denied = RegExp(
        r'넥스가드|브라벡토|하트가드|레볼루션|타이레놀|부루펜|NexGard|Bravecto|Heartgard|Tylenol|Advil|Pfizer',
        caseSensitive: false,
      );
      for (final locale in ['ko', 'en']) {
        final f = _faker(locale: locale);
        for (final role in [
          'vet.vetDrug',
          'vet.preventiveProduct',
          'daycare.drugLabel',
        ]) {
          final values = <String>{};
          for (var i = 0; i < 100; i++) {
            final text = _value(f, role, i);
            values.add(text);
            expect(denied.hasMatch(text), isFalse, reason: '$role: $text');
            expect(text, contains(locale == 'ko' ? '(가상)' : '(fictional)'));
          }
          expect(values.length, greaterThan(1));
        }
      }
    },
  );

  test(
    'fictional works/prose/organizations exclude curated known titles and brands',
    () {
      final denied = RegExp(
        r'해리\s*포터|원피스|나\s*혼자만\s*레벨업|미생|삼성|스타벅스|카카오|네이버|Harry Potter|One Piece|Solo Leveling|Samsung|Starbucks|Netflix|Marvel',
        caseSensitive: false,
      );
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
      ];
      for (final locale in ['ko', 'en']) {
        final f = _faker(locale: locale);
        for (final role in roles) {
          for (var i = 0; i < 100; i++) {
            final text = _value(f, role, i);
            expect(denied.hasMatch(text), isFalse, reason: '$role: $text');
          }
        }
      }
    },
  );

  test(
    'consultation content contains no result promises or actionable advice claims',
    () {
      final denied = RegExp(
        r'100\s*%|승소|무조건|반드시|확실히|보장합니다|절세됩니다|guaranteed|you should|must file|will win|recommend that',
        caseSensitive: false,
      );
      for (final seed in [406, 777, 1119]) {
        for (final locale in ['ko', 'en']) {
          final f = _faker(seed: seed, locale: locale);
          for (final role in [
            'brokerage.qnaAnswerGeneric',
            'brokerage.consultNoteGeneric',
          ]) {
            for (var i = 0; i < 100; i++) {
              final text = _value(f, role, i);
              expect(denied.hasMatch(text), isFalse, reason: text);
              expect(text, startsWith(locale == 'ko' ? '일반 정보 예시' : 'General'));
            }
          }
        }
      }
    },
  );

  test('fandom creator names are exactly the two approved fictional names', () {
    for (final locale in ['ko', 'en', 'pt']) {
      final values = {
        for (var i = 0; i < 20; i++)
          _value(_faker(locale: locale), 'fandom.creatorName', i),
      };
      expect(values, {'모래시계 정원', '하늘결'});
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

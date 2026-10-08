import 'dart:io';

import 'package:co_faker/co_faker.dart';
import 'package:test/test.dart';

import 'support/clinic_saas_snapshot.dart';
import 'support/virtual_language.dart';

/// Korean-only shapes that no value of a language without Korean values may
/// have: a masked resident registration number, a Korean mobile number, and a
/// business registration number.
final RegExp _koreanShapes = RegExp(
  r'\d{6}-[1-4]\*{6}|010-0\d{3}-\d{4}|\b\d{3}-\d{2}-\d{5}\b',
);

final RegExp _hangul = RegExp('[가-힣ㄱ-ㅎㅏ-ㅣ]');

/// The output of every public clinic and SaaS call of the safety-net table on
/// a fresh generator made by [make].
Map<String, String> _runAll(CoFaker Function() make) {
  return <String, String>{
    for (final entry in <String, ClinicSaasCall>{
      ...clinicCalls,
      ...saasCalls,
    }.entries)
      entry.key: '${entry.value(make())}',
  };
}

void main() {
  final now = DateTime.utc(2026, 10, 5, 9);
  CoFaker ko([int seed = 1]) => CoFaker(locale: 'ko', seed: seed, now: now);
  CoFaker en([int seed = 1]) => CoFaker(locale: 'en', seed: seed, now: now);

  group('price scale', () {
    final clinicScales = <(String, int Function(CoClinicPriceScale), int, int)>[
      ('priceRounding', (s) => s.priceRounding, 1000, 5),
      ('packageRounding', (s) => s.packageRounding, 10000, 10),
      ('prepaidStep', (s) => s.prepaidStep, 10000, 10),
      ('installmentMinimum', (s) => s.installmentMinimum, 500000, 500),
      ('splitMinimum', (s) => s.splitMinimum, 50000, 50),
      ('splitRounding', (s) => s.splitRounding, 1000, 1),
      ('adjustmentUnit', (s) => s.adjustmentUnit, 1000, 1),
      ('pointUnit', (s) => s.pointUnit, 100, 1),
      ('quoteMin', (s) => s.quoteMin, 50000, 50000),
      ('quoteMax', (s) => s.quoteMax, 300000, 300000),
    ];

    test('the built-in data carry what the generators used to hard-code', () {
      for (final (name, read, korean, english) in clinicScales) {
        expect(read(CoFakerClinicData.korean.priceScale), korean, reason: name);
        expect(
          read(CoFakerClinicData.english.priceScale),
          english,
          reason: name,
        );
      }
      expect(
        CoFakerClinicData.korean.priceScale,
        same(CoClinicPriceScale.korean),
      );
      expect(
        CoFakerClinicData.english.priceScale,
        same(CoClinicPriceScale.english),
      );
    });

    test('SaaS data carry the VAT rate and prepaid wallet amounts', () {
      for (final scale in <CoSaasPriceScale>[
        CoFakerSaasData.korean.priceScale,
        CoFakerSaasData.english.priceScale,
      ]) {
        expect(scale.vatRate, 0.1);
        expect(scale.prepaidTopUps, <int>[
          100000,
          300000,
          500000,
          1000000,
          3000000,
          5000000,
        ]);
        expect(scale.prepaidBonusTiers, CoFakerSaas.prepaidBonusTiers);
        expect(scale.prepaidLowBalance, 50000);
        expect(scale.prepaidUsageMin, 10000);
        expect(scale.prepaidUsageRounding, 1000);
        expect(scale.prepaidRefundMin, 1000);
        expect(scale.prepaidRefundRounding, 1000);
        for (final amount in <int>[99999, 100000, 1000000, 15000000]) {
          expect(scale.bonusFor(amount), CoFakerSaas.prepaidBonus(amount));
        }
      }
    });

    test('generated amounts follow the scale of the data', () {
      for (final faker in <CoFaker>[ko(3), en(3)]) {
        final scale = faker.clinic.data.priceScale;
        for (var i = 0; i < 60; i++) {
          final procedure = faker.clinic.procedure();
          final spec = faker.clinic.procedures.firstWhere(
            (s) => s.code == procedure.code,
          );
          expect(
            procedure.price % scale.priceRounding == 0 ||
                procedure.price == spec.minPrice,
            isTrue,
            reason: '${faker.locale} ${procedure.price}',
          );
          expect(faker.clinic.package().price % scale.packageRounding, 0);
          final prepaid = faker.clinic.prepaidBalance();
          expect(prepaid % scale.prepaidStep, 0);
          expect(prepaid, lessThanOrEqualTo(100 * scale.prepaidStep));
          final point = faker.clinic.pointTransaction();
          expect(point.amount.abs() % scale.pointUnit, 0);
          expect(point.amount.abs(), lessThanOrEqualTo(50 * scale.pointUnit));
          final adjustment = faker.clinic.adjustment(
            subtotal: 123 * scale.adjustmentUnit,
          );
          expect(adjustment.amount % scale.adjustmentUnit, 0);
        }
      }
    });

    test('payments split and use installments by the scale', () {
      for (final faker in <CoFaker>[ko(4), en(4)]) {
        final scale = faker.clinic.data.priceScale;
        for (var i = 0; i < 40; i++) {
          final small = faker.clinic.splitPayment(
            amount: scale.splitMinimum - 1,
          );
          expect(small, hasLength(1), reason: faker.locale);
          final card = faker.clinic.payment(
            amount: scale.installmentMinimum - 1,
            method: 'card',
          );
          expect(card.installmentMonths, 0, reason: faker.locale);
        }
        final large = <int>{
          for (var i = 0; i < 300; i++)
            faker.clinic
                    .payment(amount: scale.installmentMinimum, method: 'card')
                    .installmentMonths ??
                -1,
        };
        expect(large, containsAll(<int>[0, 2, 3, 6]), reason: faker.locale);
        final amount = scale.splitMinimum * 10;
        final parts = <int>{
          for (var i = 0; i < 300; i++)
            faker.clinic.splitPayment(amount: amount).length,
        };
        expect(parts, containsAll(<int>[1, 2, 3]), reason: faker.locale);
      }
    });
  });

  group('assembled texts', () {
    test('a clinic name follows the name format of the data', () {
      expect(ko().clinic.clinicName(specialty: '피부과'), endsWith('피부과의원'));
      expect(ko().clinic.clinicName(specialty: '피부과'), isNot(contains(' ')));
      expect(
        en().clinic.clinicName(specialty: 'Pediatrics'),
        contains(' Pediatrics'),
      );
      final german = virtualGerman.faker();
      for (var i = 0; i < 20; i++) {
        final name = german.clinic.clinicName();
        expect(
          german.clinic.data.specialties.any(
            (s) => name.startsWith('${s.clinicSuffix} '),
          ),
          isTrue,
          reason: name,
        );
      }
    });

    test('mentions and compound package names use the formats of the data', () {
      final korean = ko().clinic.teamNote(authors: ['김도윤'], mentions: ['박지현']);
      expect(korean.text, contains('@박지현님'));
      expect(ko().clinic.teamNote().text, matches(RegExp('@[가-힣]+ [가-힣]+님')));
      expect(en().clinic.teamNote(mentions: ['Cam']).text, contains('@Cam'));
      expect(
        en().clinic.teamNote(mentions: ['Cam']).text,
        isNot(contains('@Cam ')),
      );
      expect(ko().clinic.compoundPackageName(), matches(RegExp(r'\d+회')));
      expect(en().clinic.compoundPackageName(), matches(RegExp(r'\d+x')));

      final japanese = virtualJapanese.faker();
      expect(
        japanese.clinic.teamNote(authors: ['A'], mentions: ['B']).text,
        contains('@Bさん'),
      );
      expect(japanese.clinic.teamNote().text, matches(RegExp('@.+ .+さん')));
      expect(japanese.clinic.compoundPackageName(), matches(RegExp(r'\d+回')));
      final german = virtualGerman.faker();
      expect(german.clinic.compoundPackageName(), matches(RegExp(r'^\d+x ')));
      expect(german.clinic.teamNote(mentions: ['Cam']).text, contains('@Cam'));
      expect(german.clinic.teamNote().text, matches(RegExp(r'@.+ \(.+\)')));
    });

    test('closure notices write dates with the date format of the data', () {
      final korean = ko().clinic.closureNotice(
        date: DateTime.utc(2026, 9, 25),
        clinicName: '데모의원',
      );
      expect(korean.holiday, '추석 연휴');
      expect(korean.title, '9월 24일(목)~9월 27일(일) 휴진 안내');
      final english = en().clinic.closureNotice(
        date: DateTime.utc(2026, 11, 11),
      );
      expect(english.title, 'Closed 11/11');
      final japanese = virtualJapanese.faker().clinic.closureNotice(
        date: DateTime.utc(2026, 11, 11),
      );
      expect(japanese.title, 'Closed 11月11日(水)');
      final german = virtualGerman.faker().clinic.closureNotice(
        date: DateTime.utc(2026, 11, 11),
      );
      expect(german.title, 'Closed 11.11.');
    });

    test('holiday names come from the data', () {
      expect(
        ko().clinic.closureNotice(date: DateTime.utc(2027, 2, 6)).holiday,
        '설 연휴',
      );
      expect(
        en().clinic.closureNotice(date: DateTime.utc(2027, 2, 6)).holiday,
        'Lunar New Year',
      );
      expect(
        en().clinic.closureNotice(date: DateTime.utc(2026, 9, 25)).holiday,
        'Chuseok',
      );
    });

    test('SaaS texts come from the operations texts of the data', () {
      final labels = <String, Set<String>>{
        'ko': {'대표번호', '예약 문의', '상담실', '데스크'},
        'en': {'Main line', 'Bookings', 'Front desk'},
      };
      for (final entry in <String, CoFaker>{'ko': ko(), 'en': en()}.entries) {
        final saas = entry.value.saas;
        expect(<String>{
          for (var i = 0; i < 40; i++) saas.senderNumber().label,
        }, labels[entry.key]);
        final health = <String?>{
          for (var i = 0; i < 300; i++) saas.healthCheck().message,
        };
        expect(health, contains(saas.ops.healthMessages['degraded']));
        expect(health, contains(saas.ops.healthMessages['down']));
        final targets = <String>{
          for (var i = 0; i < 600; i++) saas.auditEvent().target,
        };
        expect(targets, containsAll(saas.ops.auditTargets.values.toSet()));
      }
      final japanese = virtualJapanese.faker().saas;
      expect(
        <String>{for (var i = 0; i < 40; i++) japanese.senderNumber().label},
        {'代表番号', '予約専用'},
      );
      final targets = <String>{
        for (var i = 0; i < 600; i++) japanese.auditEvent().target,
      };
      expect(targets, containsAll(<String>['アカウント', 'スタッフ権限', '通知']));
      expect(
        targets.where((t) => t.startsWith('患者 #') || t.startsWith('カルテ #')),
        isNotEmpty,
      );
    });
  });

  group('Korean-only values', () {
    test('Korean data generates every one of them', () {
      final faker = ko();
      expect(CoFakerClinicData.korean.koreanValues, CoKoreanValues.korean);
      expect(CoFakerSaasData.korean.koreanValues, CoKoreanValues.korean);
      final patient = faker.clinic.patient();
      expect(patient.rrnMasked, matches(RegExp(r'^\d{6}-[1-4]\*{6}$')));
      expect(patient.phone, matches(RegExp(r'^010-0\d{3}-\d{4}$')));
      expect(
        faker.clinic.payment(amount: 90000, method: 'card').approvalNo,
        matches(RegExp(r'^\d{8}$')),
      );
      expect(
        faker.clinic.payment(amount: 90000, method: 'cash').cashReceiptNo,
        matches(RegExp(r'^010-\*{4}-\d{4}$')),
      );
      expect(
        CoFakerKorea.isBusinessNumberChecksumValid(
          faker.saas.tenant().businessNumber,
        ),
        isFalse,
      );
      expect(
        faker.saas.tenant().businessNumber,
        matches(RegExp(r'^\d{3}-\d{2}-\d{5}$')),
      );
      expect(
        faker.saas.messageLog().recipient,
        matches(RegExp(r'^010-\*{4}-\d{4}$')),
      );
    });

    test('English data keeps the ones it has always generated', () {
      final faker = en();
      expect(CoFakerClinicData.english.koreanValues, CoKoreanValues.legacy);
      expect(CoFakerSaasData.english.koreanValues, CoKoreanValues.legacy);
      expect(
        faker.clinic.patient().rrnMasked,
        matches(RegExp(r'^\d{6}-[1-4]\*{6}$')),
      );
      expect(
        faker.clinic.payment(amount: 900, method: 'card').approvalNo,
        matches(RegExp(r'^\d{8}$')),
      );
      expect(
        faker.clinic.payment(amount: 900, method: 'cash').cashReceiptNo,
        isNotNull,
      );
      expect(
        faker.saas.tenant().businessNumber,
        matches(RegExp(r'^\d{3}-\d{2}-\d{5}$')),
      );
      expect(faker.saas.messageLog().recipient, isNot(contains('*')));
      // The calendar behind closure notices is the Korean one.
      expect(
        faker.clinic.closureNotice(date: DateTime.utc(2026, 9, 25)).holiday,
        'Chuseok',
      );
    });

    test('data written before the option existed behaves like English', () {
      const english = CoFakerClinicData.english;
      const legacy = CoFakerClinicData(
        specialties: <CoSpecialtySpec>[
          (name: 'Pediatrics', clinicSuffix: 'Pediatrics'),
        ],
        clinicNamePrefixes: <String>['Maple'],
        staffRoles: <String, String>{'doctor': 'Physician'},
        visitPurposes: <CoVisitPurposeSpec>[
          (name: 'Consultation', details: <String>['First consultation']),
        ],
        procedures: <CoProcedureSpec>[
          (
            code: 'CONS01',
            category: 'Consultation',
            name: 'Visit',
            unit: 'visit',
            minPrice: 30,
            maxPrice: 60,
            taxable: false,
          ),
        ],
        diagnoses: <CoDiagnosisSpec>[
          (code: 'Z00', name: 'Checkup', nameEn: 'Checkup'),
        ],
        drugStems: <String>['Lumi'],
        drugForms: <({String form, String unit, List<int> strengths})>[
          (form: ' tablet', unit: 'mg', strengths: <int>[10]),
        ],
        drugUsages: <String>['Once a day'],
        complaints: <String>['Cough'],
        findings: <String>['Clear'],
        plans: <String>['Rest'],
        memos: <String>['Note'],
        questions: <CoQuestionSpec>[
          (question: 'Allergies?', options: <String>['None']),
        ],
        cardIssuers: <String>['Visa'],
        labels: <String, String>{},
        packageNameFormat: '{name} x{sessions}',
      );
      expect(legacy.currency, same(CoCurrencyFormat.usd));
      expect(legacy.priceScale, same(CoClinicPriceScale.english));
      expect(legacy.koreanValues, CoKoreanValues.legacy);
      expect(legacy.clinicNameFormat, english.clinicNameFormat);
      expect(legacy.maskedIdFormat, english.maskedIdFormat);
      final custom = CoFaker(
        locale: 'acme',
        seed: 9,
        now: now,
        locales: <String, CoFakerLocale>{
          'acme': const CoFakerLocale(code: 'acme', clinic: legacy),
        },
      );
      expect(custom.clinic.money(1234), r'$1,234');
      expect(custom.clinic.clinicName(), 'Maple Pediatrics');
      expect(
        custom.clinic.payment(amount: 900, method: 'card').approvalNo,
        matches(RegExp(r'^\d{8}$')),
      );
    });

    test('a language without Korean values never generates one', () {
      for (final language in <VirtualLanguage>[
        virtualJapanese,
        virtualGerman,
      ]) {
        for (final seed in <int>[7, 20261005, 436]) {
          final output = _runAll(() => language.faker(seed: seed));
          final hits = <String>[
            for (final entry in output.entries)
              if (entry.key != 'clinic.maskName' &&
                  entry.key != 'clinic.inquiry' &&
                  (_hangul.hasMatch(entry.value) ||
                      _koreanShapes.hasMatch(entry.value)))
                entry.key,
          ];
          expect(hits, isEmpty, reason: '${language.locale} seed $seed');
        }
      }
    });

    test('a language without Korean values has no public holidays', () {
      for (final language in <VirtualLanguage>[
        virtualJapanese,
        virtualGerman,
      ]) {
        final faker = language.faker();
        final (first, last) = CoFakerKorea.holidayYears;
        for (var year = first; year <= last; year++) {
          for (final holiday in CoFakerKorea.holidays(year: year)) {
            final notice = faker.clinic.closureNotice(date: holiday.date);
            expect(notice.holiday, isNull, reason: '${holiday.date}');
            expect(notice.from, holiday.date);
            expect(notice.to, holiday.date);
            expect(notice.body, isNot(contains(holiday.name)));
          }
        }
      }
    });

    test('the patient, payment, and tenant values of a neutral language', () {
      final japanese = virtualJapanese.faker();
      expect(japanese.country?.code, 'JP');
      for (var i = 0; i < 30; i++) {
        final patient = japanese.clinic.patient();
        expect(patient.rrnMasked, matches(RegExp(r'^\d{8}$')));
        expect(patient.address1, contains(patient.postalCode));
        expect(patient.address1, startsWith('〒'));
        expect(patient.address2, isEmpty);
        final card = japanese.clinic.payment(amount: 80000, method: 'card');
        expect(card.approvalNo, matches(RegExp(r'^\d{6}$')));
        expect(
          japanese.clinic.payment(amount: 8000, method: 'cash').cashReceiptNo,
          isNull,
        );
        expect(
          japanese.clinic
              .payment(amount: 8000, method: 'transfer')
              .cashReceiptNo,
          isNull,
        );
        final tenant = japanese.saas.tenant();
        expect(tenant.businessNumber, matches(RegExp(r'^\d{13}$')));
        expect(tenant.address, startsWith('〒'));
        final recipient = japanese.saas.messageLog().recipient;
        expect(recipient, contains('*'));
        expect(RegExp(r'\d').allMatches(recipient), hasLength(4));
      }
      final german = virtualGerman.faker();
      expect(
        german.clinic.patient().rrnMasked,
        matches(RegExp(r'^\d{2}\.\d{2}\.\d{2}$')),
      );
      expect(
        german.saas.tenant().businessNumber,
        matches(RegExp(r'^DE\d{9}$')),
      );
    });

    test(
      'a neutral language on a language-only locale keeps simple addresses',
      () {
        final faker = CoFaker(
          locale: 'acme',
          seed: 5,
          now: now,
          locales: <String, CoFakerLocale>{
            'acme': CoFakerLocale(
              code: 'acme',
              clinic: virtualJapanese.clinic,
              saas: virtualJapanese.saas,
            ),
          },
        );
        expect(faker.country, isNull);
        final patient = faker.clinic.patient();
        expect(patient.postalCode, matches(RegExp(r'^\d{5}$')));
        expect(patient.address2, isEmpty);
        expect(faker.saas.tenant().address, isNotEmpty);
      },
    );
  });

  group('virtual language', () {
    test('amounts are written in the currency and scale of the data', () {
      final japanese = virtualJapanese.faker();
      expect(japanese.clinic.money(1234567), '¥1,234,567');
      expect(japanese.saas.money(99000), '¥99,000');
      final session = japanese.clinic.counselSession();
      expect(session.summary, contains('¥'));
      expect(session.summary, isNot(contains(r'$')));
      expect(
        session.summary,
        contains(japanese.clinic.money(session.quotedPrice)),
      );
      expect(
        session.summary,
        contains(japanese.clinic.money(session.packagePrice)),
      );
      expect(session.packagePrice % 1000, 0);
      final german = virtualGerman.faker();
      final quote = german.clinic.counselSession();
      expect(
        quote.turns.map((t) => t.text).join(' '),
        contains(german.clinic.money(quote.quotedPrice)),
      );
      expect(german.clinic.money(1234567), '1.234.567,00 €');
    });

    test('the price scale of the data decides the amounts', () {
      final faker = virtualJapanese.faker(seed: 11);
      final scale = virtualJapanese.scale;
      for (var i = 0; i < 40; i++) {
        expect(faker.clinic.package().price % scale.packageRounding, 0);
        expect(faker.clinic.prepaidBalance() % scale.prepaidStep, 0);
        expect(
          faker.clinic.pointTransaction().amount.abs() % scale.pointUnit,
          0,
        );
        expect(
          faker.clinic.adjustment(subtotal: 987 * scale.adjustmentUnit).amount %
              scale.adjustmentUnit,
          0,
        );
        expect(
          faker.clinic.splitPayment(amount: scale.splitMinimum - 1),
          hasLength(1),
        );
      }
    });

    test('the VAT rate of the data decides invoices', () {
      for (final language in <VirtualLanguage>[
        virtualJapanese,
        virtualGerman,
      ]) {
        final saas = language.faker().saas;
        for (var months = 0; months < 6; months++) {
          for (final supply in <int>[15, 1000, 99999]) {
            final invoice = saas.invoice(
              monthsAgo: months,
              supplyAmount: supply,
            );
            expect(invoice.vat, (supply * language.saasScale.vatRate).round());
            expect(invoice.total, supply + invoice.vat);
          }
        }
      }
    });

    test('the prepaid wallet follows the scale of the data', () {
      for (final language in <VirtualLanguage>[
        virtualJapanese,
        virtualGerman,
      ]) {
        final scale = language.saasScale;
        final ledger = language.faker(seed: 3).saas.prepaidLedger(count: 60);
        var balance = 0;
        for (final entry in ledger) {
          balance += entry.amount + entry.bonus;
          expect(entry.balanceAfter, balance);
          expect(entry.balanceAfter, greaterThanOrEqualTo(0));
          if (entry.kind == 'topUp') {
            expect(scale.prepaidTopUps, contains(entry.amount));
            expect(entry.bonus, scale.bonusFor(entry.amount));
          } else if (entry.kind == 'usage') {
            expect(entry.amount.abs() % scale.prepaidUsageRounding, 0);
          } else {
            expect(entry.amount.abs() % scale.prepaidRefundRounding, 0);
          }
        }
        expect(ledger.first.kind, 'topUp');
      }
    });

    test(
      'the data of a custom locale reaches the generators of derived fakers',
      () {
        final faker = virtualJapanese.faker();
        final derived = faker.derive('patients/1');
        expect(derived.clinic.money(5000), '¥5,000');
        expect(faker.localized('ja_jp').clinic.money(5000), '¥5,000');
      },
    );
  });

  group('the source', () {
    test('clinic and SaaS no longer read the locale code', () {
      for (final path in <String>['lib/src/clinic.dart', 'lib/src/saas.dart']) {
        final source = File(path).readAsStringSync();
        expect(source, isNot(contains('_korean')), reason: path);
        expect(source, isNot(contains("startsWith('ko')")), reason: path);
        expect(
          source,
          isNot(matches(RegExp(r'faker\.locale(?!Data)'))),
          reason: path,
        );
      }
    });
  });
}

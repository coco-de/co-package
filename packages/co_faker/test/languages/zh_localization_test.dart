import 'package:co_faker/co_faker.dart';
import 'package:co_faker/src/l10n/co_l10n_clinic.dart';
import 'package:co_faker/src/language_coverage/co_language_texts.dart';
import 'package:test/test.dart';

import '../language_safety/language_safety.dart';
import '../language_safety/languages.dart';
import '../support/clinic_saas_snapshot.dart';

final DateTime _now = DateTime.utc(2026, 10, 5, 9);

CoFaker _faker(String locale, {int seed = 436}) =>
    CoFaker(locale: locale, seed: seed, now: _now, domains: CoFakerDomains.all);

CoFaker _forLanguage(String tag, {int seed = 436}) => CoFaker.forLanguage(
  tag,
  seed: seed,
  now: _now,
  domains: CoFakerDomains.all,
);

/// The primitive type a role is generated with.
String _typeOf(CoDomainRole role) => role.supportedTypes?.first ?? 'String';

/// Every role of every pack for the first [records] records, by qualified name.
Map<String, List<Object?>> _roles(CoFaker f, {int records = 4}) {
  return <String, List<Object?>>{
    for (final pack in CoFakerDomains.all)
      for (final entry in pack.roles.entries)
        '${pack.name}.${entry.key}': <Object?>[
          for (var i = 0; i < records; i++)
            f.schema.record(
              <String, String>{'value': _typeOf(entry.value)},
              roles: <String, String>{'value': '${pack.name}.${entry.key}'},
              streamKey: '${pack.name}.${entry.key}',
              index: i,
            )['value'],
        ],
  };
}

Object? _role(CoFaker f, String role, [int index = 0]) => f.schema.record(
  <String, String>{'value': 'String'},
  roles: <String, String>{'value': role},
  streamKey: role,
  index: index,
)['value'];

/// The characters that only Traditional Chinese writes: the Traditional form
/// of a character whose Simplified form is another character. A text of the
/// Simplified language has none of them.
const String _traditionalOnly =
    '體麼這個們說後開關門醫藥診療護預約費'
    '號線網價單隻與為應業務區實觀歲點臺灣'
    '廣國東時會學對從來還過發現樣電話選項'
    '產經態氣處當總見進動機資訊給請問題設'
    '計運記錄書寫買賣種類團隊歷風龍馬魚鳥'
    '鳳貝車長陽陰階際隨難雖雙雜雲靈響頭顏'
    '願顯飛飯飲館驗鬱鹽麗齊齡無讀專準備興'
    '華裝裡檢測試藝術級結組織紀紙細終絡絕'
    '統維練縣績繼續規視親覺覽觸訪許訴註評'
    '詞詢該詳語誤課誰調論談諮讓證識變讚負'
    '財貨貢貴貼賓質贈贊趕軟輕較載輸轉辦農'
    '達遞遲鄉釋鋪錢鍵鎖鏡險霧靜頁順須領頻'
    '額養髮鬆鬧麥齒龜聯聽職聲壞壓畫異盡員'
    '圖獎嗎嚴歡歸殘殺毀漢滿潔濟濕濃營燈爐'
    '獨獲環畢確礙禮穩窮競筆節範築簡籌糧糾'
    '紅納純紗紛紮綁綠綢緊緒締編緩縮繪繫纖'
    '罰羅習聖聞聰腦腳腸臉臨舊艙艱藍蘋蟲蠟'
    '衛衝補襯訂託詩認誌誠諒諸諾謀謝譜譯議'
    '豐豬貓責販貪貧貫貸貿賀賃賊賞賢賤賦賭'
    '賴趙趨跡踐蹤躍輛輝輩輪轟辭邊遠遷遺鄰'
    '醬釀針鈴銀銅銷鋒鋼錯鍋鎮鑑閃閉閒間閱'
    '闊陣陳陸隱韓頂頓頗顧餘饑駐鮮鴨黃黨態';

final RegExp _hangul = RegExp(r'[\uac00-\ud7a3\u3131-\u318e]');
final RegExp _kana = RegExp(r'[\u3040-\u30ff\u31f0-\u31ff]');

/// A half-width mark next to a Chinese character: Chinese writes `，。：；！？（）`.
final RegExp _halfWidthMark = RegExp(r'[一-鿿][,;:!?().]|[,;:!?()][一-鿿]');

/// A space between a Chinese character and a digit or a Latin letter.
final RegExp _gap = RegExp(r'[一-鿿] +[0-9A-Za-z]|[0-9A-Za-z] +[一-鿿]');

typedef _Text = ({String where, String text});

/// Every text of the Chinese bundle, clinic data, and SaaS data that a person
/// reads (the codes are left out), with its place.
List<_Text> _texts() {
  final data = CoLanguageData.registered('zh');
  final tables = <CoTextTable>[
    CoLanguageTexts.ofBundle(data.bundle),
    CoLanguageTexts.ofClinic(data.clinic!),
    CoLanguageTexts.ofSaas(data.saas!),
  ];
  return <_Text>[
    for (final table in tables)
      for (final slot in table.slots.values)
        if (slot.kind == CoTextKind.text || slot.kind == CoTextKind.format)
          for (final row in slot.rows)
            for (final text in slot.cellsOf(row)!)
              (where: '${slot.name}[$row]', text: text),
  ];
}

/// [text] with its `{field}` and `#{variable}` replaced by a digit, the way a
/// generator fills them.
String _filled(String text) => text
    .replaceAll(RegExp(r'#\{[^{}]*\}'), '1')
    .replaceAll(RegExp(r'\{[^{}]*\}'), '1');

/// The places where [text] has a match of [pattern], for a failure message.
List<String> _where(RegExp pattern, {bool filled = true}) => <String>[
  for (final entry in _texts())
    if (pattern.hasMatch(filled ? _filled(entry.text) : entry.text))
      '${entry.where}: ${entry.text}',
];

void main() {
  final english = CoL10nRegistry.english;
  final bundle = CoL10nRegistry.bundleFor('zh')!;
  final clinic = CoL10nClinic.clinicOf('zh')!;
  final saas = CoL10nClinic.saasOf('zh')!;

  group('the data of Simplified Chinese', () {
    test('is registered: a bundle, clinic data, and SaaS data', () {
      expect(CoFakerLanguages.chinese.domain, isTrue);
      expect(CoLanguageData.registered('zh').level, CoLanguageLevel.localized);
      expect(bundle.language, 'zh');
      expect(bundle.texts, hasLength(english.texts.length));
    });

    test('has the keys of English, in the same order', () {
      expect(bundle.texts.keys.toList(), english.texts.keys.toList());
    });

    test('has as many texts as English for every key', () {
      for (final key in english.texts.keys) {
        expect(
          bundle.texts[key],
          hasLength(english.texts[key]!.length),
          reason: key,
        );
        expect(
          bundle.texts[key]!.every((text) => text.trim().isNotEmpty),
          isTrue,
          reason: key,
        );
      }
    });

    test('keeps the placeholders of the English texts', () {
      for (final key in english.texts.keys) {
        for (var i = 0; i < english.texts[key]!.length; i++) {
          final want = CoL10nBundle.placeholdersOf(english.texts[key]![i]);
          final got = CoL10nBundle.placeholdersOf(bundle.texts[key]![i]);
          // The names of the daycare and masked-name templates choose among
          // the names that the generator offers.
          if (key == 'common.maskedName' ||
              key == 'daycare.guardianLabel' ||
              key == 'daycare.teacherName') {
            expect(got, isNotEmpty, reason: '$key[$i]');
            continue;
          }
          expect(got, want, reason: '$key[$i]');
        }
      }
    });

    test('keeps the codes, the order, and the lists of the clinic data', () {
      const en = CoFakerClinicData.english;
      expect(
        clinic.procedures.map((p) => p.code),
        en.procedures.map((p) => p.code),
      );
      expect(
        clinic.diagnoses.map((d) => (d.code, d.nameEn)),
        en.diagnoses.map((d) => (d.code, d.nameEn)),
      );
      expect(clinic.staffRoles.keys, en.staffRoles.keys);
      expect(clinic.labels.keys, en.labels.keys);
      expect(clinic.specialties, hasLength(en.specialties.length));
      expect(clinic.drugStems, hasLength(en.drugStems.length));
      expect(clinic.questions, hasLength(en.questions.length));
      expect(
        clinic.texts!.counselTopics.map((t) => (t.topic, t.procedureCode)),
        en.texts!.counselTopics.map((t) => (t.topic, t.procedureCode)),
      );
      expect(
        clinic.texts!.integrationResults.map(
          (key, list) => MapEntry(key, list.map((r) => (r.code, r.ok))),
        ),
        en.texts!.integrationResults.map(
          (key, list) => MapEntry(key, list.map((r) => (r.code, r.ok))),
        ),
      );
      expect(
        clinic.ops!.rooms.map((r) => (r.kind, r.staffRole)),
        en.ops!.rooms.map((r) => (r.kind, r.staffRole)),
      );
      expect(clinic.ops!.labels.keys, en.ops!.labels.keys);
      expect(clinic.ops!.weekdayNames, hasLength(7));
    });

    test('keeps the codes, the order, and the lists of the SaaS data', () {
      const en = CoFakerSaasData.english;
      expect(saas.plans.map((p) => p.code), en.plans.map((p) => p.code));
      expect(
        saas.plans.map((p) => (p.seats, p.messageCredits)),
        en.plans.map((p) => (p.seats, p.messageCredits)),
      );
      expect(
        saas.messageTemplates.map((t) => t.code),
        en.messageTemplates.map((t) => t.code),
      );
      expect(
        saas.notices.map((n) => n.category),
        en.notices.map((n) => n.category),
      );
      expect(saas.labels.keys, en.labels.keys);
      expect(saas.failureReasons.keys, en.failureReasons.keys);
      expect(saas.ops!.operatorActions.keys, en.ops!.operatorActions.keys);
      expect(
        saas.ops!.alerts.map((a) => (a.level, a.code)),
        en.ops!.alerts.map((a) => (a.level, a.code)),
      );
      expect(
        saas.ops!.masterRows.map((k, v) => MapEntry(k, v.length)),
        en.ops!.masterRows.map((k, v) => MapEntry(k, v.length)),
      );
    });
  });

  group('the same seed picks the same record in English and Chinese', () {
    test('of every role of every domain pack', () {
      final en = _roles(_faker('en'));
      final zh = _roles(_faker('zh'));
      final chinese = bundle.texts;
      var compared = 0;
      for (final key in english.texts.keys) {
        final enValues = en[key];
        final zhValues = zh[key];
        if (enValues == null || zhValues == null) continue;
        final enTexts = english.texts[key]!;
        final zhTexts = chinese[key]!;
        for (var i = 0; i < enValues.length; i++) {
          final enIndex = enTexts.indexOf(enValues[i] as String? ?? '');
          if (enIndex < 0) continue;
          final zhIndex = zhTexts.indexOf(zhValues[i] as String? ?? '');
          expect(zhIndex >= 0, isTrue, reason: '$key $i is not a Chinese text');
          // A text that two entries share cannot say which one was picked.
          final unique =
              enTexts.where((text) => text == enTexts[enIndex]).length == 1 &&
              zhTexts.where((text) => text == zhTexts[zhIndex]).length == 1;
          if (unique) {
            expect(zhIndex, enIndex, reason: '$key $i');
            compared++;
          }
        }
      }
      expect(compared, greaterThan(500));
    });

    test('of the catalog, the questions, and the exam choices', () {
      // The entries of these lists are tied together by position: a product
      // and its unit, a question and its four choices, a unit of the exam.
      for (final key in <String>[
        'catalog.groceryName',
        'catalog.groceryUnit',
        'catalog.commerceName',
        'catalog.commerceUnit',
        'exam_prep.subjectName',
        'exam_prep.unitName',
        'exam_prep.questionStem',
        'exam_prep.correctChoice',
        'exam_prep.explanation',
        'logistics.itemName',
        'b2b_trade.itemSpec',
      ]) {
        expect(
          bundle.texts[key]!.length,
          english.texts[key]!.length,
          reason: key,
        );
      }
      final en = _faker('en').schema.entities('exam_prep.question', 9);
      final zh = _faker('zh').schema.entities('exam_prep.question', 9);
      for (var i = 0; i < 9; i++) {
        expect(zh[i]['answerKeys'], en[i]['answerKeys'], reason: 'question $i');
        // The explanation of a question names the right choice.
        final choices = (zh[i]['choices'] as String).split('|');
        final key = int.parse('${zh[i]['answerKeys']}');
        expect(
          zh[i]['explanation'] as String,
          contains(choices[key - 1].substring(1)),
          reason: 'question $i',
        );
        expect(choices.toSet(), hasLength(4), reason: 'question $i');
      }
    });

    test('of the clinic and SaaS generators', () {
      final en = CoFaker.forLanguage('en', seed: 7, now: _now);
      final zh = CoFaker.forLanguage('zh', seed: 7, now: _now);
      for (var i = 0; i < 12; i++) {
        expect(zh.clinic.procedure().code, en.clinic.procedure().code);
        expect(zh.clinic.diagnosis().code, en.clinic.diagnosis().code);
        final purposeZh = zh.clinic.visitPurpose();
        final purposeEn = en.clinic.visitPurpose();
        expect(purposeZh.purposeId, purposeEn.purposeId);
        expect(purposeZh.detailId, purposeEn.detailId);
        expect(zh.saas.plan().code, en.saas.plan().code);
        expect(zh.saas.messageTemplate().code, en.saas.messageTemplate().code);
      }
      for (final topic in <String>['toning', 'lifting']) {
        final a = en.clinic.counselSession(topic: topic);
        final b = zh.clinic.counselSession(topic: topic);
        expect(b.procedureCode, a.procedureCode);
        expect(b.sessions, a.sessions);
        expect(b.turns, hasLength(a.turns.length));
      }
    });
  });

  group('zh, zh-Hans, zh_CN, and the country CN give one set of data', () {
    // A fresh generator for each way of asking for the language.
    final makers = <String, CoFaker Function()>{
      "forLanguage('zh')": () => _forLanguage('zh'),
      "forLanguage('zh-Hans')": () => _forLanguage('zh-Hans'),
      "forLanguage('zh_Hans_CN')": () => _forLanguage('zh_Hans_CN'),
      "CoFaker(locale: 'zh')": () => _faker('zh'),
      "CoFaker(locale: 'zh_CN')": () => _faker('zh_CN'),
      "CoFaker.forCountry('CN')": () => CoFaker.forCountry(
        'CN',
        seed: 436,
        now: _now,
        domains: CoFakerDomains.all,
      ),
    };

    test('the domain text, the clinic data, and the SaaS data', () {
      for (final entry in makers.entries) {
        final f = entry.value();
        expect(f.l10n.language, 'zh', reason: entry.key);
        expect(f.clinic.data, same(clinic), reason: entry.key);
        expect(f.saas.data, same(saas), reason: entry.key);
        expect(f.clinic.money(1234), '¥1,234.00', reason: entry.key);
        expect(f.saas.money(1234), '¥1,234.00', reason: entry.key);
      }
    });

    test('the text of every role that reads the bundle only', () {
      final reference = _roles(makers.values.first());
      for (final entry in makers.entries) {
        final roles = _roles(entry.value());
        var compared = 0;
        for (final key in bundle.texts.keys) {
          // A template that a name fills draws its name from the locale.
          if (bundle.texts[key]!.any((text) => text.contains('{'))) continue;
          if (!reference.containsKey(key)) continue;
          expect(roles[key], reference[key], reason: '${entry.key} $key');
          compared++;
        }
        expect(compared, greaterThan(150), reason: entry.key);
      }
    });

    test('the picks of the clinic and the SaaS generators of one seed', () {
      // The generators of one seed pick from the lists of the same data,
      // whichever way the language is asked for.
      String sample(CoFaker f) => <String>[
        for (var i = 0; i < 4; i++) ...<String>[
          f.clinic.chartMemo(),
          f.clinic.procedure().name,
          f.clinic.counselSession().procedure,
          f.saas.notice().title,
          f.saas.messageTemplate().body,
        ],
      ].join('\n');
      final samples = <String, String>{
        for (final entry in makers.entries) entry.key: sample(entry.value()),
      };
      expect(samples.values.toSet(), hasLength(1));
      expect(samples.values.first, isNot(matches(_hangul)));
      expect(samples.values.first, matches(RegExp(r'[\u4e00-\u9fff]')));
    });

    test('Traditional Chinese never gets the Simplified text', () {
      for (final tag in <String>[
        'zh_TW',
        'zh-TW',
        'zh_HK',
        'zh_MO',
        'zh-Hant',
      ]) {
        expect(_forLanguage(tag).l10n.language, 'en', reason: tag);
        expect(_faker(tag).l10n.language, 'en', reason: tag);
        expect(_faker(tag).clinic.data, same(CoFakerClinicData.english));
        expect(_faker(tag).saas.data, same(CoFakerSaasData.english));
      }
    });
  });

  group('the writing of Simplified Chinese', () {
    test('uses Simplified characters only', () {
      final found = _where(RegExp('[$_traditionalOnly]'), filled: false);
      expect(found, isEmpty, reason: found.take(10).join('\n'));
    });

    test('has no Hangul and no kana', () {
      expect(_where(_hangul, filled: false), isEmpty);
      expect(_where(_kana, filled: false), isEmpty);
    });

    test('writes full-width punctuation, never a half-width mark', () {
      final found = _where(_halfWidthMark);
      expect(found, isEmpty, reason: found.take(10).join('\n'));
      // A quotation uses “ ”, and no text has a straight quote.
      final quotes = _where(RegExp('["\']'), filled: false);
      expect(quotes, isEmpty, reason: quotes.take(10).join('\n'));
      // The marks the Chinese data writes are the full-width ones.
      final all = _texts().map((entry) => entry.text).join();
      for (final mark in <String>['，', '。', '：', '（', '）', '？']) {
        expect(all, contains(mark), reason: mark);
      }
    });

    test(
      'puts no space between a Chinese character and a digit or a letter',
      () {
        final found = _where(_gap);
        expect(found, isEmpty, reason: found.take(10).join('\n'));
      },
    );

    test('marks a fictional name and an example in full-width brackets', () {
      final all = _texts().map((entry) => entry.text).toList();
      expect(
        all.where((text) => text.contains('（虚构）')),
        hasLength(greaterThan(80)),
      );
      expect(
        all.where((text) => text.contains('（示例）')),
        hasLength(greaterThan(80)),
      );
      expect(all.where((text) => text.contains('(虚构)')), isEmpty);
      expect(all.where((text) => text.contains('(示例)')), isEmpty);
      for (final key in <String>[
        'vet.vetDrug',
        'vet.preventiveProduct',
        'daycare.drugLabel',
      ]) {
        expect(
          bundle.texts[key]!.every((text) => text.endsWith('（虚构）')),
          isTrue,
          reason: key,
        );
      }
    });

    test(
      'addresses a patient or a customer with 您, and with 你 nowhere else',
      () {
        // The notification templates, the counselor, and the clinic notices
        // speak to the patient: 您. The only 你 is the patient's own line.
        for (final template in saas.messageTemplates) {
          expect(template.body, isNot(contains('你')), reason: template.code);
          // An advertisement does not address a person; the others do.
          if (template.code != 'AD_EVENT') {
            expect(template.body, contains('您'), reason: template.code);
          }
        }
        final script = clinic.texts!.counselScript;
        for (final line in <String>[
          script.greeting,
          script.bookYesReply,
          script.bookNoReply,
        ]) {
          expect(line, contains('您'));
          expect(line, isNot(contains('你')));
        }
        final informal = <String>[
          for (final entry in _texts())
            if (entry.text.replaceAll('迷你', '').contains('你')) entry.where,
        ];
        expect(informal, <String>['clinic.texts.counselScript.bookNo[0]']);
      },
    );

    test('counts with the measure words of the language', () {
      // 位 for a diner, 次 for a session, 个 for a piece, 岁 for an age.
      final party = bundle.texts['dining.partyLabel']!.single;
      expect(party.replaceAll('{n}', '3'), '3位用餐');
      expect(bundle.texts['daycare.ageLabel'], <String>[
        '1岁',
        '2岁',
        '3岁',
        '4岁',
        '5岁',
      ]);
      expect(clinic.procedures.where((p) => p.unit == '次'), isNotEmpty);
      expect(clinic.packageNameFormat, contains('次卡'));
      expect(clinic.ops!.compoundItemFormat, contains('次'));
      expect(
        bundle.texts['space_rental.equipmentOption']!.last,
        startsWith('1个'),
      );
      expect(bundle.texts['catalog.commerceUnit'], <String>[
        '1副',
        '1个',
        '3条',
        '1个',
        '200g',
      ]);
      final f = CoFaker.forLanguage('zh', seed: 5, now: _now);
      expect(
        f.clinic.package(procedureCode: 'LT-01').name,
        matches(RegExp(r'^皮秒激光嫩肤（(3|5|10)次卡）$')),
      );
      expect(
        f.clinic.compoundPackageName(),
        matches(RegExp(r'^.+×\d+次 \+ .+×\d+次( \+ .+×\d+次)? \+ 赠修复霜$')),
      );
      for (final alert in saas.ops!.alerts.take(3)) {
        expect(alert.message, matches(RegExp(r'\d+(家|张|条)')));
      }
    });

    test('keeps the notation of a Chinese date, plate, and mask', () {
      final f = _forLanguage('zh', seed: 5);
      // 2026-10-08 is a Thursday.
      final notice = f.clinic.closureNotice(
        date: DateTime.utc(2026, 10, 8),
        clinicName: '枫叶皮肤科诊所',
      );
      expect(notice.holiday, isNull);
      expect(notice.title, '10月8日（周四）停诊');
      expect(
        notice.body,
        matches(
          RegExp(
            r'^枫叶皮肤科诊所将于10月8日（周四）因(参加学术会议|装修施工|设备维护)停诊，'
            r'10月9日（周五）起恢复正常门诊。$',
          ),
        ),
      );
      expect(
        clinic.ops!.dateRangeFormat
            .replaceAll('{from}', '10月8日（周四）')
            .replaceAll('{to}', '10月10日（周六）'),
        '10月8日（周四）至10月10日（周六）',
      );
      expect(clinic.ops!.weekdayNames, <String>[
        '周一',
        '周二',
        '周三',
        '周四',
        '周五',
        '周六',
        '周日',
      ]);
      for (var i = 0; i < 6; i++) {
        expect(
          _role(f, 'logistics.vehiclePlate', i),
          matches(RegExp(r'^沪A·\d{2}●●\d{2}$')),
        );
        expect(
          _role(f, 'homecare.recipientName', i),
          matches(RegExp(r'^[一-鿿]\*\*$')),
        );
        expect(
          _role(f, 'hospitality.guestName', i),
          matches(RegExp(r'^[一-鿿]\*\*$')),
        );
      }
      expect(f.clinic.device(kind: 'picoLaser', number: 2).name, '皮秒激光仪2号机');
      expect(f.clinic.clinicName(), endsWith('诊所'));
    });

    test('writes the templates of a name in the order of Chinese', () {
      final f = _forLanguage('zh', seed: 5);
      for (var i = 0; i < 6; i++) {
        expect(
          _role(f, 'fitness.className', i),
          matches(RegExp(r'^(初级|中级|高级)(垫上普拉提|核心床普拉提|椅式普拉提|瑜伽)$')),
        );
        expect(
          _role(f, 'daycare.guardianLabel', i),
          matches(RegExp(r'^[一-鿿]+家长$')),
        );
        expect(
          _role(f, 'daycare.teacherName', i),
          matches(RegExp(r'^[一-鿿]+老师$')),
        );
        expect(_role(f, 'dining.partyLabel', i), matches(RegExp(r'^\d+位用餐$')));
        expect(
          _role(f, 'workplace.sprintName', i),
          matches(RegExp(r'^冲刺\d+$')),
        );
      }
      final children = f.schema.entities('grocery.produce_category', 9).skip(7);
      for (final row in children) {
        expect(row['name'], matches(RegExp(r'^.+·细分主题\d+$')));
      }
    });
  });

  group('the amounts of the clinic and the SaaS data are yuan', () {
    final china = CoFakerCountries.china;

    test('use the currency, the symbol, and the decimals of China', () {
      for (final currency in <CoCurrencyFormat>[
        clinic.currency,
        saas.currency,
      ]) {
        expect(currency.code, china.currencyCode);
        expect(currency.symbol, china.currencySymbol);
        expect(currency.fractionDigits, china.currencyMinorUnits);
        expect(currency.groupSeparator, ',');
        expect(currency.decimalSeparator, '.');
        // The symbol stands before the number: ¥1,234.00.
        expect(currency.pattern, '{symbol}{amount}');
      }
      final f = CoFaker.forLanguage('zh', seed: 5, now: _now);
      expect(f.clinic.money(1234), '¥1,234.00');
      expect(f.clinic.money(1234567), '¥1,234,567.00');
      expect(f.clinic.money(-50), '-¥50.00');
      expect(f.saas.money(99000), '¥99,000.00');
      final session = f.clinic.counselSession(topic: 'toning');
      expect(
        session.summary,
        contains('单次${f.clinic.money(session.quotedPrice)}'),
      );
      expect(
        session.summary,
        contains('次卡${f.clinic.money(session.packagePrice)}'),
      );
      expect(session.summary, isNot(contains(r'$')));
    });

    test('follow the scale of the yuan, not the dollar or the won', () {
      const en = CoFakerClinicData.english;
      const dollar = CoClinicPriceScale.english;
      const won = CoClinicPriceScale.korean;
      final scale = clinic.priceScale;
      expect(scale.priceRounding, 10);
      expect(scale.packageRounding, 100);
      expect(scale.prepaidStep, 100);
      expect(scale.installmentMinimum, 3000);
      expect(scale.splitMinimum, 500);
      expect(scale.adjustmentUnit, 10);
      expect(scale.pointUnit, 10);
      // Larger than the dollar scale and far below the won scale.
      for (final pair in <(int, int, int)>[
        (scale.priceRounding, dollar.priceRounding, won.priceRounding),
        (scale.packageRounding, dollar.packageRounding, won.packageRounding),
        (
          scale.installmentMinimum,
          dollar.installmentMinimum,
          won.installmentMinimum,
        ),
        (scale.quoteMax, dollar.quoteMax, won.quoteMax),
      ]) {
        expect(pair.$1, greaterThan(pair.$2));
        expect(pair.$1, lessThan(pair.$3));
      }
      // The price bands are the dollar bands at the price tags of a Chinese
      // clinic: two to ten times as large, and the bands of the same codes.
      for (var i = 0; i < clinic.procedures.length; i++) {
        final zh = clinic.procedures[i];
        final base = en.procedures[i];
        expect(
          zh.minPrice / base.minPrice,
          inInclusiveRange(2, 10),
          reason: zh.code,
        );
        expect(
          zh.maxPrice / base.maxPrice,
          inInclusiveRange(2, 10),
          reason: zh.code,
        );
        expect(zh.minPrice % scale.priceRounding, 0, reason: zh.code);
        expect(zh.maxPrice % scale.priceRounding, 0, reason: zh.code);
        expect(zh.taxable, base.taxable, reason: zh.code);
      }
    });

    test('are rounded to the units of the price tags of the data', () {
      final f = CoFaker.forLanguage('zh', seed: 11, now: _now);
      final scale = clinic.priceScale;
      for (var i = 0; i < 60; i++) {
        final procedure = f.clinic.procedure();
        final spec = clinic.procedures.firstWhere(
          (p) => p.code == procedure.code,
        );
        expect(procedure.price, inInclusiveRange(spec.minPrice, spec.maxPrice));
        expect(procedure.price % scale.priceRounding, 0);
        expect(f.clinic.package().price % scale.packageRounding, 0);
        expect(f.clinic.prepaidBalance() % scale.prepaidStep, 0);
        expect(f.clinic.pointTransaction().amount.abs() % scale.pointUnit, 0);
        expect(
          f.clinic.adjustment(subtotal: 987 * scale.adjustmentUnit).amount %
              scale.adjustmentUnit,
          0,
        );
        expect(
          f.clinic.splitPayment(amount: scale.splitMinimum - 1),
          hasLength(1),
        );
      }
    });

    test('carry a 6% VAT and a wallet in yuan', () {
      final f = CoFaker.forLanguage('zh', seed: 3, now: _now);
      final scale = saas.priceScale;
      expect(scale.vatRate, 0.06);
      for (final supply in <int>[499, 999, 1799, 3499, 100000]) {
        final invoice = f.saas.invoice(supplyAmount: supply);
        expect(invoice.vat, (supply * 0.06).round());
        expect(invoice.total, supply + invoice.vat);
      }
      expect(saas.plans.map((p) => p.monthlyPrice), <int>[
        499,
        999,
        1799,
        3499,
      ]);
      var balance = 0;
      final ledger = f.saas.prepaidLedger(count: 60);
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
    });
  });

  group('no Korean-only value appears', () {
    final shapes = RegExp(
      r'\d{6}-[1-4]\*{6}|010-0\d{3}-\d{4}|\b\d{3}-\d{2}-\d{5}\b',
    );

    test('in the generators of the clinic and the SaaS data', () {
      expect(clinic.koreanValues, CoKoreanValues.none);
      expect(saas.koreanValues, CoKoreanValues.none);
      for (final seed in clinicSaasSeeds) {
        for (final output in <Map<String, String>>[
          recordClinicSaas('zh', seed),
          recordClinicSaas('zh_CN', seed),
        ]) {
          for (final entry in output.entries) {
            // These two keep the Korean text of a Korean clinic's inbox.
            if (entry.key == 'clinic.maskName' ||
                entry.key == 'clinic.inquiry') {
              continue;
            }
            expect(
              entry.value,
              isNot(matches(_hangul)),
              reason: '${entry.key} seed $seed',
            );
            expect(
              entry.value,
              isNot(matches(shapes)),
              reason: '${entry.key} seed $seed',
            );
          }
        }
      }
    });

    test('in a patient, a payment, a tenant, and a closure notice', () {
      final f = CoFaker.forLanguage('zh', seed: 8, now: _now);
      expect(f.country?.code, 'CN');
      for (var i = 0; i < 30; i++) {
        final patient = f.clinic.patient();
        // A Chinese resident ID shows 6 digits, 8 masked, and 4 digits.
        expect(patient.rrnMasked, matches(RegExp(r'^\d{6}\*{8}\d{4}$')));
        expect(patient.address1, isNot(matches(_hangul)));
        expect(patient.address1, matches(RegExp(r'^[一-鿿]+\d+号$')));
        expect(patient.address2, isEmpty);
        expect(patient.phone, isNot(startsWith('010-')));
        final card = f.clinic.payment(amount: 8000, method: 'card');
        expect(card.approvalNo, matches(RegExp(r'^\d{6}$')));
        expect(
          f.clinic.payment(amount: 800, method: 'cash').cashReceiptNo,
          isNull,
        );
        final tenant = f.saas.tenant();
        // The 18 characters of a unified social credit code.
        expect(tenant.businessNumber, matches(RegExp(r'^91\d{16}$')));
        expect(tenant.name, endsWith('诊所'));
        expect(f.saas.messageLog().recipient, contains('*'));
      }
      final (first, last) = CoFakerKorea.holidayYears;
      for (var year = first; year <= last; year++) {
        for (final holiday in CoFakerKorea.holidays(year: year)) {
          final notice = f.clinic.closureNotice(date: holiday.date);
          expect(notice.holiday, isNull);
          expect(notice.body, isNot(contains(holiday.name)));
        }
      }
    });
  });

  group('the safety of the Chinese texts', () {
    final safety = languageSafety['zh']!;

    test('declares the conventions that the scan reads', () {
      expect(safety.isComplete(latin: false), isTrue);
      expect(safety.fictionalMarker, '（虚构）');
      expect(safety.generalInfoPrefix, '一般信息示例');
    });

    test(
      'no text names a real brand, work, company, or medicine of any language',
      () {
        final denied = safetyPattern(<String>[
          for (final entry in languageSafety.values) ...entry.deniedBrands,
        ]);
        final found = <String>[
          for (final entry in _texts())
            if (denied.hasMatch(entry.text)) '${entry.where}: ${entry.text}',
        ];
        expect(found, isEmpty, reason: found.take(10).join('\n'));
      },
    );

    test(
      'the consultation texts are general information and promise nothing',
      () {
        final promises = safetyPattern(<String>[
          ...safety.deniedPromises,
          ...languageSafety['en']!.deniedPromises,
        ]);
        for (final key in <String>[
          'brokerage.qnaAnswerGeneric',
          'brokerage.consultNoteGeneric',
        ]) {
          for (final text in bundle.texts[key]!) {
            expect(text, startsWith(safety.generalInfoPrefix), reason: key);
            expect(promises.hasMatch(text), isFalse, reason: '$key: $text');
          }
        }
      },
    );

    test('the two creators are names of the language, not the Korean ones', () {
      final names = bundle.texts['fandom.creatorName']!;
      expect(names, hasLength(2));
      expect(names.toSet(), hasLength(2));
      expect(
        names.toSet().intersection(CoFandomDomain.creatorNames.toSet()),
        isEmpty,
      );
      for (final name in names) {
        expect(name, isNot(matches(_hangul)));
        expect(name, matches(RegExp(r'^[一-鿿]+$')));
      }
      final values = <Object?>{
        for (var i = 0; i < 8; i++)
          _role(_faker('zh'), 'fandom.creatorName', i),
      };
      expect(values, names.toSet());
    });

    test('a person is shown masked and a door has no code', () {
      final f = _faker('zh');
      final mask = RegExp('[*○●◯•＊✱]');
      for (var i = 0; i < 40; i++) {
        expect(_role(f, 'homecare.recipientName', i), matches(mask));
        expect(_role(f, 'hospitality.guestName', i), matches(mask));
        expect(_role(f, 'logistics.vehiclePlate', i), contains('●●'));
        expect(
          _role(f, 'logistics.entranceHint', i),
          isNot(matches(RegExp(r'#\d{4}'))),
        );
      }
    });
  });
}

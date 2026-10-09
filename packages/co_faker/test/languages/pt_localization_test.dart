import 'dart:io';

import 'package:co_faker/co_faker.dart';
import 'package:co_faker/src/l10n/co_l10n_clinic.dart';
import 'package:co_faker/src/language_coverage/co_language_texts.dart';
import 'package:test/test.dart';

import '../language_safety/pt.dart';

/// What is particular to the Brazilian Portuguese data: that it is the
/// translation of the English records (the same seed picks the counterpart of
/// the same record), that the ways in read the same data, the writing (the
/// contractions of the prepositions, Brazilian and not European spelling and
/// words, the register `você`, the clock of 24 hours, the units), and the real
/// (the format and the scale of every amount).

/// The seeds the alignment checks run with.
const List<int> _seeds = <int>[7, 436, 20261005];

/// The no-break space that Portuguese writes between a number and its unit, and
/// after the symbol of the real.
const String _nbsp = '\u00A0';

final DateTime _now = DateTime.utc(2026, 10, 8, 9);

CoFaker _forLanguage(String tag, {int seed = 7}) => CoFaker.forLanguage(
  tag,
  seed: seed,
  now: _now,
  domains: CoFakerDomains.all,
);

CoFaker _faker(String locale, {int seed = 7}) =>
    CoFaker(locale: locale, seed: seed, now: _now, domains: CoFakerDomains.all);

String _value(CoFaker f, String role, int index) =>
    f.schema.record(
          <String, String>{'value': 'String'},
          roles: <String, String>{'value': role},
          streamKey: role,
          index: index,
        )['value']
        as String;

final CoL10nBundle _en = CoL10nRegistry.english;
final CoL10nBundle _pt = CoL10nRegistry.bundleFor('pt')!;
final CoFakerClinicData _enClinic = CoFakerClinicData.english;
final CoFakerClinicData _ptClinic = CoL10nClinic.clinicOf('pt')!;
final CoFakerSaasData _enSaas = CoFakerSaasData.english;
final CoFakerSaasData _ptSaas = CoL10nClinic.saasOf('pt')!;
final CoFakerClinicTexts _enTexts = _enClinic.texts!;
final CoFakerClinicTexts _ptTexts = _ptClinic.texts!;

typedef _Text = ({String where, String text, bool format});

/// Every text of Portuguese that a person reads, with its place: the domain
/// text bundle, the clinic data, and the SaaS data. A code is left out.
final List<_Text> _texts = <_Text>[
  for (final table in <CoTextTable>[
    CoLanguageTexts.ofBundle(_pt),
    CoLanguageTexts.ofClinic(_ptClinic),
    CoLanguageTexts.ofSaas(_ptSaas),
  ])
    for (final slot in table.slots.values)
      if (slot.kind == CoTextKind.text || slot.kind == CoTextKind.format)
        for (final row in slot.rows)
          for (final text in slot.cellsOf(row)!)
            (
              where: '${slot.name}[$row]',
              text: text,
              format: slot.kind == CoTextKind.format,
            ),
];

/// The places of the texts that match [pattern], to say what is wrong.
List<String> _matching(
  Iterable<_Text> texts,
  RegExp pattern, {
  Set<String> except = const <String>{},
}) => <String>[
  for (final text in texts)
    if (!except.any(text.where.startsWith) && pattern.hasMatch(text.text))
      '${text.where}: ${text.text}',
];

/// The slots of the English texts and of the Portuguese texts, by name: a slot
/// is a list or a map of the bundle, the clinic data, or the SaaS data.
final Map<String, CoTextSlot> _enSlots = <String, CoTextSlot>{
  ...CoLanguageTexts.ofBundle(_en).slots,
  ...CoLanguageTexts.ofClinic(_enClinic, resolveFallbacks: true).slots,
  ...CoLanguageTexts.ofSaas(_enSaas, resolveFallbacks: true).slots,
};
final Map<String, CoTextSlot> _ptSlots = <String, CoTextSlot>{
  ...CoLanguageTexts.ofBundle(_pt).slots,
  ...CoLanguageTexts.ofClinic(_ptClinic).slots,
  ...CoLanguageTexts.ofSaas(_ptSaas).slots,
};

/// The first text of every row of [slot], in the order of the data.
List<String> _column(Map<String, CoTextSlot> slots, String slot) {
  final found = slots[slot];
  expect(found, isNotNull, reason: 'no slot $slot');
  return <String>[for (final row in found!.rows) found.cellsOf(row)!.first];
}

/// The same index of two lists: the Portuguese counterpart of [english].
T _counterpart<T>(List<T> portuguese, List<T> english, T value) {
  final index = english.indexOf(value);
  expect(index, isNonNegative, reason: 'English has no $value');
  return portuguese[index];
}

/// Pairs that stand for the whole: a text of English, the Portuguese text that
/// translates it, and the slot they are in. The same position of the slot in
/// both languages is what makes one seed pick the same record, so a Portuguese
/// text on another position than its English text is a record that the seed no
/// longer translates, and a list of the same length would not show it.
final List<(String, String, String)> _anchors = <(String, String, String)>[
  ('fx.currencyName.USD', 'US dollar', 'Dólar americano'),
  ('fx.currencyName.NPR', 'Nepalese rupee', 'Rupia nepalesa'),
  (
    'fx.branchName',
    'Demo airport T1 exchange',
    'Casa de câmbio demo, aeroporto T1',
  ),
  ('fx.branchName', 'Demo Mulpare exchange', 'Casa de câmbio demo, Jacarandal'),
  ('fx.tierName', 'Silver', 'Prata'),
  ('fx.tierName', 'Gold', 'Ouro'),
  ('remit.countryName.VN', 'Vietnam', 'Vietnã'),
  ('remit.countryName.US', 'United States', 'Estados Unidos'),
  ('vet.petName', 'Barley', 'Cevada'),
  ('vet.petName', 'Tofu', 'Pudim'),
  ('vet.petName', 'Cloud', 'Nuvem'),
  ('vet.breed.dog', 'Maltese', 'Maltês'),
  ('vet.breed.dog', 'Mixed dog', 'Sem raça definida'),
  ('vet.breed.cat', 'Mixed cat', 'Gato sem raça definida'),
  ('vet.breed.reptile', 'Tortoise', 'Jabuti'),
  ('vet.coatColor', 'White', 'Branco'),
  ('vet.coatColor', 'Gray', 'Cinza'),
  ('vet.clinicRoom', 'Vaccination room', 'Sala de vacinação'),
  ('grocery.categoryName', 'Fruit', 'Frutas'),
  ('grocery.categoryName', 'Seafood', 'Peixes e frutos do mar'),
  ('grocery.categoryName', 'Dairy', 'Laticínios'),
  ('catalog.groceryName', 'Strawberries', 'Morangos'),
  ('catalog.groceryName', 'Milk', 'Leite'),
  ('catalog.commerceName', 'Ceramic cup', 'Xícara de cerâmica'),
  ('dental.dentalProcedure', 'Scaling', 'Limpeza dental'),
  (
    'dental.dentalProcedure',
    'Root canal example',
    'Exemplo de tratamento de canal',
  ),
  ('dental.dentalMaterial', 'Zirconia (example)', 'Zircônia (exemplo)'),
  ('homecare.careGrade', 'Care grade 5', 'Nível de cuidado 5'),
  ('homecare.careGrade', 'Cognitive support grade', 'Nível de apoio cognitivo'),
  ('homecare.careTaskLabel', 'Meal assistance', 'Auxílio na refeição'),
  ('travel_wallet.cityName', 'Hanoi', 'Hanói'),
  ('travel_wallet.tripName', 'Bangkok weekend', 'Fim de semana em Bangcoc'),
  (
    'b2b_trade.holdReason',
    'Delivery date check (example)',
    'Verificação da data de entrega (exemplo)',
  ),
  (
    'group_deal.dealTitle',
    'Cotton towel group deal',
    'Compra coletiva de toalhas de algodão',
  ),
  ('fitness.classLevelLabel', 'beginner', 'iniciante'),
  ('fitness.classLevelLabel', 'advanced', 'avançado'),
  ('fitness.classCategoryLabel', 'Mat', 'Solo'),
  ('fitness.classCategoryLabel', 'Chair', 'Cadeira'),
  ('fitness.classCategoryLabel', 'Yoga', 'Ioga'),
  ('space_rental.amenity', 'Water dispenser', 'Bebedouro'),
  ('dining.menuName', 'Tomato pasta', 'Massa ao molho de tomate'),
  ('dining.menuName', 'Warm tea', 'Chá quente'),
  ('daycare.className', 'Sun class', 'Turma do Sol'),
  ('daycare.className', 'Star class', 'Turma da Estrela'),
  ('daycare.ageLabel', 'Age 1', '1 ano'),
  ('daycare.ageLabel', 'Age 5', '5 anos'),
  ('daycare.snackMenu', 'Plain yogurt', 'Iogurte natural'),
  ('daycare.allergenLabel', 'Egg', 'Ovo'),
  ('daycare.allergenLabel', 'Wheat', 'Trigo'),
  ('exam_prep.subjectName', 'Networking', 'Redes'),
  ('exam_prep.unitName', 'Routing', 'Roteamento'),
  ('exam_prep.correctChoice', 'Primary key', 'Chave primária'),
  ('exam_prep.correctChoice', 'WHERE', 'WHERE'),
  ('exam_prep.correctChoice', 'TCP', 'TCP'),
  ('exam_prep.correctChoice', 'Router', 'Roteador'),
  ('exam_prep.correctChoice', 'HTTP', 'HTTP'),
  ('exam_prep.correctChoice', 'Variable', 'Variável'),
  ('exam_prep.correctChoice', 'Stack', 'Pilha'),
  ('exam_prep.correctChoice', 'Hash function', 'Função de hash'),
  ('exam_prep.correctChoice', 'Least privilege', 'Privilégio mínimo'),
  ('exam_prep.wrongChoice1', 'Speaker', 'Alto-falante'),
  ('exam_prep.wrongChoice2', 'Keyboard', 'Teclado'),
  ('exam_prep.wrongChoice3', 'Monitor', 'Monitor'),
  (
    'exam_prep.questionStem',
    'Which key distinguishes rows in a table?',
    'Qual chave distingue as linhas de uma tabela?',
  ),
  (
    'exam_prep.questionStem',
    'Which SQL clause selects rows by a condition?',
    'Qual cláusula SQL seleciona linhas por meio de uma condição?',
  ),
  (
    'exam_prep.questionStem',
    'Which transport protocol handles ordering and retransmission?',
    'Qual protocolo de transporte cuida da ordenação e da retransmissão?',
  ),
  (
    'exam_prep.questionStem',
    'Which device selects the next packet route?',
    'Qual equipamento escolhe a próxima rota de um pacote?',
  ),
  (
    'exam_prep.questionStem',
    'Which protocol expresses web requests and responses?',
    'Qual protocolo expressa requisições e respostas da web?',
  ),
  (
    'exam_prep.questionStem',
    'What stores a value under a program name?',
    'O que guarda um valor sob um nome no programa?',
  ),
  (
    'exam_prep.questionStem',
    'Which structure removes the last inserted value first?',
    'Qual estrutura remove primeiro o último valor inserido?',
  ),
  (
    'exam_prep.questionStem',
    'What computes a fixed-length summary of an input?',
    'O que calcula um resumo de tamanho fixo a partir de uma entrada?',
  ),
  (
    'exam_prep.questionStem',
    'Which principle grants only the permissions needed for a task?',
    'Qual princípio concede apenas as permissões necessárias para uma tarefa?',
  ),
  ('hrd.departmentName', 'Sales', 'Vendas'),
  ('hrd.departmentName', 'Production', 'Produção'),
  ('hrd.departmentName', 'Research', 'Pesquisa'),
  ('hrd.departmentName', 'Support', 'Suporte'),
  ('hrd.departmentName', 'Administration', 'Administração'),
  ('hrd.departmentName', 'Logistics', 'Logística'),
  ('hrd.jobTitle', 'Team lead', 'Líder de equipe'),
  ('hrd.courseKind', 'Mandatory', 'Obrigatório'),
  ('neighborhood.keyword', 'local news', 'notícias locais'),
  ('meetup.interestTag', 'Running', 'Corrida'),
  ('meetup.interestTag', 'Hiking', 'Trilhas'),
  (
    'meetup.cadenceLabel',
    'Alternate Sundays 10:00',
    'Domingos alternados, às 10h',
  ),
  ('content.genreName', 'Everyday life', 'Cotidiano'),
  ('content.genreName', 'Essay', 'Ensaio'),
  ('content.audioTaxonomy', 'Audiobook', 'Audiolivro'),
  ('helpdesk.topicName', 'Billing', 'Cobrança'),
  ('helpdesk.topicName', 'Integration', 'Integração'),
  (
    'campaign.failReason',
    'No marketing consent (example)',
    'Sem consentimento para marketing (exemplo)',
  ),
  ('workplace.department', 'Design team', 'Equipe de design'),
  ('workplace.department', 'HR team', 'Recursos humanos'),
  ('workplace.shiftName', 'Weekend duty', 'Plantão de fim de semana'),
  ('workplace.accountName', 'Travel (example)', 'Viagens (exemplo)'),
  ('brokerage.serviceTypeName', 'Cleaning', 'Limpeza'),
  ('brokerage.serviceTypeName', 'Lessons', 'Aulas'),
  ('brokerage.serviceCategory', 'Home service', 'Serviços residenciais'),
  ('brokerage.milestoneLabel', 'Handoff record', 'Registro de entrega'),
  ('logistics.scanEvent', 'Hub arrival', 'Chegada ao centro de distribuição'),
  ('logistics.scanEvent', 'Delivery not completed', 'Entrega não realizada'),
  ('logistics.freightType', 'Packaging', 'Embalagens'),
  ('logistics.freightType', 'Household goods', 'Utilidades domésticas'),
  ('logistics.itemName', 'Brown rice 2kg', 'Arroz integral 2${_nbsp}kg'),
  ('hospitality.hkCheckItem', 'Change bedding', 'Trocar a roupa de cama'),
  ('hospitality.hkCheckItem', 'Check minibar', 'Conferir o frigobar'),
  ('hospitality.lostItemName', 'Blue umbrella', 'Guarda-chuva azul'),
  ('hospitality.lostItemName', 'Water bottle', 'Garrafa de água'),
  ('hospitality.amenityName', 'Toothbrush', 'Escova de dentes'),
  (
    'hospitality.folioItem',
    'Room service (example)',
    'Serviço de quarto (exemplo)',
  ),
  ('clinic.specialties.name', 'Dermatology', 'Dermatologia'),
  ('clinic.specialties.name', 'Pediatrics', 'Pediatria'),
  ('clinic.specialties.name', 'Internal Medicine', 'Clínica Médica'),
  ('clinic.staffRoles', 'Front Desk', 'Recepção'),
  ('clinic.staffRoles', 'Registered Nurse', 'Enfermeiro(a)'),
  ('clinic.labels', 'No-show', 'Faltou'),
  ('clinic.labels', 'Male', 'Masculino'),
  ('clinic.labels', 'Self-pay', 'Particular'),
  ('clinic.procedures.name', 'Acne extraction', 'Extração de comedões'),
  ('clinic.procedures.name', 'Medical certificate', 'Atestado médico'),
  (
    'clinic.diagnoses.name',
    'Rosacea, unspecified',
    'Rosácea, não especificada',
  ),
  ('clinic.ops.patientTags.label', 'Package holder', 'Paciente com pacote'),
  ('clinic.ops.acquisitionChannels.label', 'Walk-in', 'Sem hora marcada'),
  ('clinic.drugStems', 'Seraton', 'Corvelin'),
  ('clinic.drugForms.form', ' ointment', ' pomada'),
  ('clinic.ops.weekdayNames', 'Mon', 'segunda-feira'),
  ('clinic.ops.weekdayNames', 'Sun', 'domingo'),
  ('clinic.texts.insurers', 'Clearbrook Health', 'Saúde Pinhalto'),
  ('clinic.texts.labels', 'Grandchild', 'Neto(a)'),
  ('clinic.ops.labels', 'Withdrawn', 'Revogado'),
  ('clinic.ops.rooms.name', 'Checkout', 'Caixa'),
  ('saas.plans.name', 'Enterprise', 'Empresarial'),
  ('saas.labels', 'Past due', 'Pagamento em atraso'),
  ('saas.labels', 'Sent via fallback', 'Enviado por canal alternativo'),
  ('saas.ops.operatorRoles', 'Viewer', 'Visualizador'),
  ('saas.failureReasons', 'Insufficient credits', 'Créditos insuficientes'),
  (
    'saas.ops.alerts.message',
    'The nightly backup completed.',
    'O backup noturno foi concluído.',
  ),
];

final RegExp _hangul = RegExp('[가-힣ㄱ-ㅎㅏ-ㅣ]');

/// Korean-only shapes that no value of Portuguese may have: a masked resident
/// registration number, a Korean mobile number, and a business registration
/// number.
final RegExp _krOnlyShapes = RegExp(
  r'\d{6}-[1-4]\*{6}|010-0\d{3}-\d{4}|\b\d{3}-\d{2}-\d{5}\b',
);

/// A weekday as the closure notices write it, and a date label.
const String _weekday =
    '(?:(?:segunda|terça|quarta|quinta|sexta)-feira|sábado|domingo)';
const String _dateLabel = '$_weekday \\(\\d{1,2}/\\d{1,2}\\)';

void main() {
  group('the entry points of Portuguese', () {
    // A language setting, a language code, and a country locale all read the
    // Portuguese domain text, clinic data, and SaaS data.
    final entries = <String, CoFaker Function()>{
      'CoFaker.forLanguage("pt")': () => _forLanguage('pt'),
      'CoFaker.forLanguage("pt-BR")': () => _forLanguage('pt-BR'),
      'CoFaker.forLanguage("pt_BR.UTF-8")': () => _forLanguage('pt_BR.UTF-8'),
      'CoFaker(locale: "pt")': () => _faker('pt'),
      'CoFaker(locale: "pt_BR")': () => _faker('pt_BR'),
      'CoFaker(locale: "pt-BR")': () => _faker('pt-BR'),
      'CoFaker(locale: "pt_br")': () => _faker('pt_br'),
    };

    for (final entry in entries.entries) {
      test(
        '${entry.key} reads the Portuguese bundle, clinic, and SaaS data',
        () {
          final f = entry.value();
          expect(f.l10n.language, 'pt');
          expect(identical(f.clinic.data, _ptClinic), isTrue);
          expect(identical(f.saas.data, _ptSaas), isTrue);
          for (final key in _pt.texts.keys) {
            expect(f.l10n.list(key), _pt.texts[key], reason: key);
          }
        },
      );
    }

    test('give the same domain text and the same record for a seed', () {
      final fakers = <CoFaker>[for (final entry in entries.values) entry()];
      for (final role in <String>[
        'dental.dentalProcedure',
        'vet.vetDrug',
        'exam_prep.questionStem',
        'neighborhood.postTitle',
        'hospitality.menuItem',
        'brokerage.qnaAnswerGeneric',
      ]) {
        for (var i = 0; i < 6; i++) {
          final values = <String>{for (final f in fakers) _value(f, role, i)};
          expect(values, hasLength(1), reason: '$role[$i]: $values');
        }
      }
      final summaries = <String>{
        for (final f in fakers)
          f.clinic.counselSession(topic: 'toning').summary,
      };
      expect(summaries, hasLength(1), reason: '$summaries');
      final notices = <String>{
        for (final f in fakers)
          f.clinic.closureNotice(date: DateTime.utc(2026, 11, 13)).body,
      };
      expect(notices, hasLength(1), reason: '$notices');
      // The gate runs `forLanguage` only, so the other ways in are held to the
      // same patient, with the same Brazilian phone, postal code, and address.
      final patients = <String>{
        for (final f in fakers) '${f.clinic.patient()}',
      };
      expect(patients, hasLength(1), reason: '$patients');
      final patient = fakers.first.clinic.patient();
      expect(patient.phone, matches(RegExp(r'^\(\d{2}\) 9\d{4}-\d{4}$')));
      expect(patient.postalCode, matches(RegExp(r'^\d{5}-\d{3}$')));
      expect(patient.address1, matches(RegExp(r'^.+, \d+ - .+ - [A-Z]{2}$')));
    });

    test('are the Portuguese data and not the English one', () {
      for (final tag in <String>['pt', 'pt_BR']) {
        final f = _faker(tag);
        expect(f.clinic.data, isNot(same(CoFakerClinicData.english)));
        expect(f.saas.data, isNot(same(CoFakerSaasData.english)));
        expect(_value(f, 'dental.dentalProcedure', 0), isNot('Scaling'));
        expect(f.clinic.money(1234), isNot(contains(r'$ ')));
      }
      // A language without data of its own keeps the English data: `nl` has
      // none and never will, whatever language is localized next.
      expect(_faker('nl').clinic.data, same(CoFakerClinicData.english));
      expect(_faker('nl').saas.data, same(CoFakerSaasData.english));
      expect(_faker('nl').l10n.language, 'en');
    });

    test('read the Brazilian data for the European tag too', () {
      // `pt-PT` is resolved to the one Portuguese of the package, which is
      // Brazilian: it has no European data.
      final f = _forLanguage('pt-PT');
      expect(f.l10n.language, 'pt');
      expect(identical(f.clinic.data, _ptClinic), isTrue);
    });
  });

  group('the bundle is the translation of the English one', () {
    test('has every key, with as many texts, and the codes stay', () {
      expect(_pt.texts.keys.toSet(), _en.texts.keys.toSet());
      for (final entry in _en.texts.entries) {
        expect(
          _pt.texts[entry.key],
          hasLength(entry.value.length),
          reason: entry.key,
        );
      }
      expect(_pt.language, 'pt');
    });

    test('writes the translation of a text at the position of that text', () {
      for (final (slot, english, portuguese) in _anchors) {
        final position = _column(_enSlots, slot).indexOf(english);
        expect(position, isNonNegative, reason: '$slot has no "$english"');
        expect(
          _column(_ptSlots, slot)[position],
          portuguese,
          reason: '$slot #$position is "$english" in English',
        );
      }
      expect(
        _anchors.map((anchor) => anchor.$1).toSet(),
        hasLength(greaterThan(75)),
      );
    });

    test('picks the translation of the English record, from the same seed', () {
      final keys = <String>{};
      for (final seed in _seeds) {
        final en = _forLanguage('en', seed: seed);
        final pt = _forLanguage('pt', seed: seed);
        for (final pack in CoFakerDomains.all) {
          for (final role in pack.roles.keys) {
            final key = '${pack.name}.$role';
            final english = _en.texts[key];
            // A template (`{n}`) is not a text that the seed picks.
            if (english == null || english.any((text) => text.contains('{'))) {
              continue;
            }
            for (var i = 0; i < 12; i++) {
              final enText = _value(en, key, i);
              final rows = <int>[
                for (var row = 0; row < english.length; row++)
                  if (english[row] == enText) row,
              ];
              final candidates = <String>[
                for (final row in rows) _pt.texts[key]![row],
              ];
              if (rows.isEmpty) {
                // A child of a taxonomy (`Fruit · subtopic 1`) is the name of
                // its root in the template of the language.
                final child = RegExp(
                  r'^(.+) · subtopic (\d+)$',
                ).firstMatch(enText);
                expect(child, isNotNull, reason: '$key #$i read "$enText"');
                final root = _pt.texts[key]![english.indexOf(child!.group(1)!)];
                candidates.add(
                  _pt.texts['common.taxonomyChild']!.single
                      .replaceAll('{root}', root)
                      .replaceAll('{n}', child.group(2)!),
                );
              }
              expect(
                _value(pt, key, i),
                isIn(candidates),
                reason: '$key #$i with seed $seed',
              );
            }
            keys.add(key);
          }
        }
      }
      // Most of the keys are read by a role of a pack: the rest are read by a
      // dedicated generator, which the next test checks.
      expect(keys.length, greaterThan(150));
    });

    test('is the same record in the dedicated generators', () {
      for (final seed in _seeds) {
        final en = _forLanguage('en', seed: seed);
        final pt = _forLanguage('pt', seed: seed);
        for (var i = 0; i < 12; i++) {
          final enPet = en.vet.pet();
          final ptPet = pt.vet.pet();
          expect(ptPet.animalKind, enPet.animalKind);
          expect(ptPet.weightKg, enPet.weightKg);
          expect(
            ptPet.name,
            _counterpart(
              _pt.texts['vet.petName']!,
              _en.texts['vet.petName']!,
              enPet.name,
            ),
          );
          expect(
            ptPet.breed,
            _counterpart(
              _pt.texts['vet.breed.${enPet.animalKind}']!,
              _en.texts['vet.breed.${enPet.animalKind}']!,
              enPet.breed,
            ),
          );
          expect(
            ptPet.coatColor,
            _counterpart(
              _pt.texts['vet.coatColor']!,
              _en.texts['vet.coatColor']!,
              enPet.coatColor,
            ),
          );
        }
        for (final code in <String>['USD', 'JPY', 'EUR', 'CNY', 'THB']) {
          expect(
            pt.fx.currency(code: code).name,
            _pt.texts['fx.currencyName.$code']!.single,
          );
        }
        for (var i = 0; i < 9; i++) {
          final enQuestion = en.examPrep.question(index: i);
          final ptQuestion = pt.examPrep.question(index: i);
          final row = _en.texts['exam_prep.questionStem']!.indexOf(
            enQuestion.stem,
          );
          final correct = _pt.texts['exam_prep.correctChoice']![row];
          expect(ptQuestion.stem, _pt.texts['exam_prep.questionStem']![row]);
          // The answer key follows the shuffle: the same position in English
          // and in Portuguese, and the choice there is the correct one.
          expect(ptQuestion.answerKeys, enQuestion.answerKeys);
          expect(ptQuestion.choices[ptQuestion.answerKeys.single - 1], correct);
          expect(ptQuestion.explanation, contains(correct));
          expect(ptQuestion.choices.toSet(), hasLength(4));
        }
      }
    });
  });

  group('the clinic data is the translation of the English data', () {
    test('has the lists of the English data, in the same order', () {
      expect(_ptClinic.specialties, hasLength(_enClinic.specialties.length));
      expect(
        _ptClinic.clinicNamePrefixes,
        hasLength(_enClinic.clinicNamePrefixes.length),
      );
      expect(_ptClinic.staffRoles.keys, _enClinic.staffRoles.keys);
      expect(_ptClinic.labels.keys, _enClinic.labels.keys);
      expect(
        <String>[for (final p in _ptClinic.procedures) p.code],
        <String>[for (final p in _enClinic.procedures) p.code],
      );
      expect(
        <String>[for (final d in _ptClinic.diagnoses) d.code],
        <String>[for (final d in _enClinic.diagnoses) d.code],
      );
      expect(
        <String>[for (final d in _ptClinic.diagnoses) d.nameEn],
        <String>[for (final d in _enClinic.diagnoses) d.nameEn],
      );
      for (final list in <(List<Object?>, List<Object?>)>[
        (_ptClinic.drugStems, _enClinic.drugStems),
        (_ptClinic.drugForms, _enClinic.drugForms),
        (_ptClinic.drugUsages, _enClinic.drugUsages),
        (_ptClinic.complaints, _enClinic.complaints),
        (_ptClinic.findings, _enClinic.findings),
        (_ptClinic.plans, _enClinic.plans),
        (_ptClinic.memos, _enClinic.memos),
        (_ptClinic.questions, _enClinic.questions),
        (_ptClinic.cardIssuers, _enClinic.cardIssuers),
        (_ptTexts.consentForms, _enTexts.consentForms),
        (_ptTexts.counselTopics, _enTexts.counselTopics),
        (_ptTexts.insurers, _enTexts.insurers),
        (_ptTexts.teamNotes, _enTexts.teamNotes),
      ]) {
        expect(list.$1, hasLength(list.$2.length));
      }
    });

    test('picks the counterpart of the English record from the same seed', () {
      for (final seed in _seeds) {
        final en = _forLanguage('en', seed: seed).clinic;
        final pt = _forLanguage('pt', seed: seed).clinic;
        for (var i = 0; i < 12; i++) {
          // A clinic name is a prefix and a specialty: the prefix comes first
          // in English, and last in Portuguese.
          final enName = en.clinicName();
          final ptName = pt.clinicName();
          final names = <String>[
            for (var p = 0; p < _enClinic.clinicNamePrefixes.length; p++)
              for (var s = 0; s < _enClinic.specialties.length; s++)
                if (enName ==
                    '${_enClinic.clinicNamePrefixes[p]} '
                        '${_enClinic.specialties[s].clinicSuffix}')
                  '${_ptClinic.specialties[s].clinicSuffix} '
                      '${_ptClinic.clinicNamePrefixes[p]}',
          ];
          expect(ptName, names.single);

          final enProcedure = en.procedure();
          final ptProcedure = pt.procedure();
          final spec = _ptClinic.procedures.firstWhere(
            (p) => p.code == enProcedure.code,
          );
          expect(ptProcedure.code, enProcedure.code);
          expect(ptProcedure.name, spec.name);
          expect(ptProcedure.unit, spec.unit);
          expect(ptProcedure.category, spec.category);
          expect(ptProcedure.taxable, enProcedure.taxable);

          final enDiagnosis = en.diagnosis();
          final ptDiagnosis = pt.diagnosis();
          expect(ptDiagnosis.code, enDiagnosis.code);
          expect(ptDiagnosis.nameEn, enDiagnosis.nameEn);
          expect(
            ptDiagnosis.name,
            _ptClinic.diagnoses
                .firstWhere((d) => d.code == enDiagnosis.code)
                .name,
          );

          // A drug is a stem, a form, and a strength.
          final enDrug = en.drugName();
          final ptDrug = pt.drugName();
          final drugs = <String>[
            for (var s = 0; s < _enClinic.drugStems.length; s++)
              for (var f = 0; f < _enClinic.drugForms.length; f++)
                for (final strength in _enClinic.drugForms[f].strengths)
                  if (enDrug ==
                      '${_enClinic.drugStems[s]}${_enClinic.drugForms[f].form} '
                          '$strength${_enClinic.drugForms[f].unit}')
                    '${_ptClinic.drugStems[s]}${_ptClinic.drugForms[f].form} '
                        '$strength${_ptClinic.drugForms[f].unit}',
          ];
          expect(ptDrug, drugs.first);

          expect(
            pt.chartMemo(),
            _counterpart(_ptClinic.memos, _enClinic.memos, en.chartMemo()),
          );
          final enSoap = en.soap();
          final ptSoap = pt.soap();
          expect(
            ptSoap.subjective,
            _counterpart(
              _ptClinic.complaints,
              _enClinic.complaints,
              enSoap.subjective,
            ),
          );
          expect(
            ptSoap.objective,
            _counterpart(
              _ptClinic.findings,
              _enClinic.findings,
              enSoap.objective,
            ),
          );
          expect(
            ptSoap.plan,
            _counterpart(_ptClinic.plans, _enClinic.plans, enSoap.plan),
          );
          expect(
            pt.insurerName(),
            _counterpart(
              _ptTexts.insurers,
              _enTexts.insurers,
              en.insurerName(),
            ),
          );
          expect(pt.staffRole().code, en.staffRole().code);
        }
      }
    });

    test('has a consent form, feedback, and counseling of the same kind', () {
      for (final seed in _seeds) {
        final en = _forLanguage('en', seed: seed).clinic;
        final pt = _forLanguage('pt', seed: seed).clinic;
        for (var i = 0; i < 12; i++) {
          final enForm = en.consentForm();
          final ptForm = pt.consentForm();
          final spec = _ptTexts.consentForms.firstWhere(
            (form) => form.kind == enForm.kind,
          );
          expect(ptForm.kind, enForm.kind);
          expect(ptForm.title, spec.title);
          expect(ptForm.clauses, spec.clauses);
          expect(ptForm.clauses, hasLength(enForm.clauses.length));
          expect(ptForm.disclaimer, _ptTexts.consentDisclaimer);

          final enFeedback = en.feedback();
          final ptFeedback = pt.feedback();
          expect(ptFeedback.sentiment, enFeedback.sentiment);
          expect(ptFeedback.score, enFeedback.score);
          expect(
            ptFeedback.comment,
            _counterpart(
              _ptTexts.feedback[enFeedback.sentiment]!,
              _enTexts.feedback[enFeedback.sentiment]!,
              enFeedback.comment,
            ),
          );

          final enSession = en.counselSession();
          final ptSession = pt.counselSession();
          final topic = _ptTexts.counselTopics.firstWhere(
            (t) => t.topic == enSession.topic,
          );
          expect(ptSession.topic, enSession.topic);
          expect(ptSession.procedureCode, enSession.procedureCode);
          expect(ptSession.procedure, topic.procedure);
          expect(ptSession.sessions, enSession.sessions);
          expect(ptSession.booked, enSession.booked);
          expect(ptSession.turns, hasLength(enSession.turns.length));
          expect(
            ptSession.turns.map((turn) => turn.speaker),
            enSession.turns.map((turn) => turn.speaker),
          );

          final enResult = en.integrationResult();
          final ptResult = pt.integrationResult();
          expect(ptResult.service, enResult.service);
          expect(ptResult.code, enResult.code);
          expect(ptResult.ok, enResult.ok);
          final english = _enTexts.integrationResults[enResult.service]!;
          final portuguese = _ptTexts.integrationResults[enResult.service]!;
          expect(
            ptResult.message,
            portuguese[english.indexWhere((r) => r.message == enResult.message)]
                .message,
          );

          final enDevice = en.device();
          final ptDevice = pt.device();
          expect(ptDevice.kind, enDevice.kind);
          expect(ptDevice.kindLabel, _ptTexts.labels[enDevice.kind]);
          expect(ptDevice.name, startsWith(ptDevice.kindLabel));
        }
      }
    });

    test('keeps the figures of its English text', () {
      // The figures of the alerts, the claim-check ROW_DELTA, and the codes of
      // the notification templates are the English ones.
      final enOps = CoFakerSaasOps.english;
      final ptOps = _ptSaas.ops!;
      for (var i = 0; i < enOps.alerts.length; i++) {
        expect(ptOps.alerts[i].code, enOps.alerts[i].code);
        expect(ptOps.alerts[i].level, enOps.alerts[i].level);
        expect(
          RegExp(r'\d+').allMatches(ptOps.alerts[i].message).map((m) => m[0]),
          RegExp(r'\d+').allMatches(enOps.alerts[i].message).map((m) => m[0]),
          reason: ptOps.alerts[i].code,
        );
      }
      expect(
        RegExp(r'\d+').firstMatch(ptOps.masterChecks['ROW_DELTA']!)![0],
        '5',
      );
      expect(
        <String>[for (final t in _ptSaas.messageTemplates) t.code],
        <String>[for (final t in _enSaas.messageTemplates) t.code],
      );
    });
  });

  group('the SaaS data is the translation of the English data', () {
    test('has the plans, templates, and notices of the English data', () {
      expect(
        <String>[for (final p in _ptSaas.plans) p.code],
        <String>[for (final p in _enSaas.plans) p.code],
      );
      for (var i = 0; i < _enSaas.plans.length; i++) {
        expect(_ptSaas.plans[i].seats, _enSaas.plans[i].seats);
        expect(
          _ptSaas.plans[i].messageCredits,
          _enSaas.plans[i].messageCredits,
        );
      }
      expect(_ptSaas.labels.keys, _enSaas.labels.keys);
      expect(_ptSaas.ops!.labels.keys, CoFakerSaasOps.english.labels.keys);
      // A notification template keeps the number of the variables of the
      // English one.
      final marker = RegExp(r'#\{\w+\}');
      for (var i = 0; i < _enSaas.messageTemplates.length; i++) {
        expect(
          marker.allMatches(_ptSaas.messageTemplates[i].body),
          hasLength(marker.allMatches(_enSaas.messageTemplates[i].body).length),
          reason: _enSaas.messageTemplates[i].code,
        );
      }
      expect(_ptSaas.ops!.masterCheckDetail, '{n} linha(s)');
    });

    test('picks the counterpart of the English record from the same seed', () {
      for (final seed in _seeds) {
        final en = _forLanguage('en', seed: seed).saas;
        final pt = _forLanguage('pt', seed: seed).saas;
        for (var i = 0; i < 12; i++) {
          final enPlan = en.plan();
          final ptPlan = pt.plan();
          final spec = _ptSaas.plans.firstWhere((p) => p.code == enPlan.code);
          expect(ptPlan.code, enPlan.code);
          expect(ptPlan.name, spec.name);
          expect(ptPlan.seats, enPlan.seats);
          expect(ptPlan.messageCredits, enPlan.messageCredits);

          final enTemplate = en.messageTemplate();
          final ptTemplate = pt.messageTemplate();
          expect(ptTemplate.code, enTemplate.code);
          expect(
            ptTemplate.name,
            _ptSaas.messageTemplates
                .firstWhere((t) => t.code == enTemplate.code)
                .name,
          );

          final enNotice = en.notice();
          final ptNotice = pt.notice();
          expect(ptNotice.category, enNotice.category);
          expect(
            ptNotice.title,
            _counterpart(
              <String>[for (final n in _ptSaas.notices) n.title],
              <String>[for (final n in _enSaas.notices) n.title],
              enNotice.title,
            ),
          );

          final enEvent = en.operatorEvent();
          final ptEvent = pt.operatorEvent();
          expect(ptEvent.action, enEvent.action);
          expect(
            ptEvent.actionLabel,
            _ptSaas.ops!.operatorActions[enEvent.action]!.label,
          );
          final role = CoFakerSaasOps.english.operatorRoles.entries
              .firstWhere((entry) => entry.value == enEvent.operatorRole)
              .key;
          expect(ptEvent.operatorRole, _ptSaas.ops!.operatorRoles[role]);
        }
      }
    });
  });

  group('the writing is Brazilian Portuguese', () {
    test('has texts to check', () {
      expect(_texts.length, greaterThan(1300));
    });

    test('writes a no-break space as an escape in its source files', () {
      // A literal no-break space is a character that no reviewer can see, so
      // the data files write `U+00A0` as an escape, and the tests above read
      // what the escapes make.
      for (final name in <String>['bundle', 'clinic', 'saas']) {
        final source = File('lib/src/l10n/pt/pt_$name.dart').readAsStringSync();
        expect(source, isNot(contains(_nbsp)), reason: 'pt_$name.dart');
        expect(source, isNot(contains('\u202F')), reason: 'pt_$name.dart');
        expect(source, contains(r'\u00A0'), reason: 'pt_$name.dart');
      }
    });

    test('has no Hangul and no placeholder that a text lost', () {
      for (final item in _texts) {
        expect(_hangul.hasMatch(item.text), isFalse, reason: item.where);
      }
    });

    test('puts no space before : ; ? and !, and no straight quote', () {
      expect(_matching(_texts, RegExp(r' [:;?!]')), isEmpty);
      // Portuguese quotes with the curly double marks, and has no apostrophe
      // in these texts.
      expect(_matching(_texts, RegExp('[\'"«»]')), isEmpty);
      for (final item in _texts) {
        expect(
          '“'.allMatches(item.text).length,
          '”'.allMatches(item.text).length,
          reason: '${item.where}: ${item.text}',
        );
      }
    });

    test('puts a no-break space between a number and its unit', () {
      // A unit follows its number after a no-break space (`500 g`), the percent
      // sign follows it with none (`10%`), and the hour is `18h`.
      const unit = r'(?:mg|g|kg|ml|mL|L|cm|mm|mmHg|°C|mg/dL)\b';
      expect(_matching(_texts, RegExp('\\d $unit|\\d$unit')), isEmpty);
      expect(_matching(_texts, RegExp(r'\d %|\d h\b')), isEmpty);
    });

    test('writes the clock in 24 hours, as `18h`', () {
      expect(
        _matching(_texts, RegExp(r'\b(?:AM|PM|am|pm)\b|\b\d{1,2}:\d{2}\b')),
        isEmpty,
      );
      expect(_pt.texts['neighborhood.openHours'], <String>[
        '8h às 21h',
        '9h às 18h',
        '10h às 20h',
      ]);
      expect(_pt.texts['grocery.slotLabel'], <String>[
        'Manhã cedo, 6h às 7h',
        'Noite, 18h às 20h',
      ]);
    });

    test('writes a decimal comma and a dot between thousands', () {
      // `1,000` and `3.5` are the English way.
      expect(_matching(_texts, RegExp(r'\d,\d{3}(?!\d)')), isEmpty);
      expect(_matching(_texts, RegExp(r'\d\.\d{1,2}(?!\d)')), isEmpty);
      expect(
        _pt.texts['b2b_trade.itemSpec']!.first,
        contains('1.000 unidades'),
      );
    });

    test('writes the months in lower case and the weekdays in a list', () {
      expect(
        _matching(
          _texts,
          RegExp(
            r'\b(?:Janeiro|Fevereiro|Março|Abril|Maio|Junho|Julho|Agosto|'
            r'Setembro|Outubro|Novembro|Dezembro)\b',
          ),
        ),
        isEmpty,
      );
      final ops = _ptClinic.ops!;
      expect(ops.weekdayNames, hasLength(7));
      expect(
        ops.weekdayNames,
        everyElement(matches(RegExp(r'^[\p{Ll}-]+$', unicode: true))),
      );
      expect(ops.weekdayNames.first, 'segunda-feira');
      expect(ops.weekdayNames.last, 'domingo');
    });

    test('is Brazilian: no European spelling and no European word', () {
      // The 2009 orthography of Brazil, and the words of Brazil: `equipe`,
      // `tela`, `arquivo`, `banheiro`, `café da manhã`, `parcelas`.
      final european = RegExp(
        r'\b(?:utentes?|ecrãs?|ecrã|telemóveis|telemóvel|ficheiros?|'
        r'autocarros?|frigoríficos?|contactos?|factos?|equipas?|registos?|'
        r'receção|acção|acções|direcção|projecto|objectivo|óptimo|actual|'
        r'actividades?|prestações|gelados?|raparigas?|miúdos?|sumos?|'
        r'comboios?|bilhetes?|electrónic\p{L}*|eletrónic\p{L}*)\b|'
        r'casa de banho|pequeno[- ]almoço|n\.º|fim-de-semana',
        caseSensitive: false,
        unicode: true,
      );
      expect(_matching(_texts, european), isEmpty);
      // The European progressive, `estou a ver`, is `estou vendo` in Brazil.
      expect(
        _matching(
          _texts,
          RegExp(
            r'\b(?:estou|estás|está|estamos|estão) a \p{L}+[aei]r\b',
            caseSensitive: false,
            unicode: true,
          ),
        ),
        isEmpty,
      );
    });

    test('speaks to the reader with `você`, never `tu`', () {
      expect(
        _matching(
          _texts,
          RegExp(
            r'\b(?:tu|teu|tua|teus|tuas|contigo|vós|vosso|vossa)\b',
            caseSensitive: false,
            unicode: true,
          ),
        ),
        isEmpty,
      );
      // A notice asks with `Por favor,` and the imperative of `você`.
      final polite = <String>[
        ..._pt.texts['space_rental.houseRule']!,
        ..._pt.texts['meetup.ruleText']!,
        ..._pt.texts['logistics.deliveryNote']!.skip(1),
        ..._pt.texts['hospitality.houseRule']!,
      ];
      for (final text in polite) {
        expect(text, startsWith('Por favor, '), reason: text);
      }
      expect(_ptTexts.counselScript.greeting, 'Olá, em que posso ajudar hoje?');
      expect(
        _ptTexts.counselScript.questions['downtime'],
        isNot(contains('tu')),
      );
    });

    test('contracts the prepositions with the articles', () {
      // `de a` is `da`, `em o` is `no`, `a o` is `ao`, `por a` is `pela`, and
      // `de ele` is `dele`: a pair that stays apart is a text that was not
      // written for Portuguese.
      const before = r'(?<![\p{L}])';
      const after = r'(?![\p{L}])';
      final bad = <RegExp>[
        RegExp(
          '$before(?:de|em|por|a) (?:o|a|os|as)$after',
          caseSensitive: false,
          unicode: true,
        ),
        RegExp(
          '$before(?:de|em) (?:este|esta|estes|estas|esse|essa|esses|essas|'
          'aquele|aquela|aqueles|aquelas|isto|isso|aquilo|ele|ela|eles|elas)'
          '$after',
          caseSensitive: false,
          unicode: true,
        ),
        RegExp(
          '$before(?:a) (?:aquele|aquela|aqueles|aquelas|aquilo)$after',
          caseSensitive: false,
          unicode: true,
        ),
      ];
      for (final pattern in bad) {
        expect(_matching(_texts, pattern), isEmpty, reason: '$pattern');
      }
    });

    test(
      'puts no contracting preposition before a value that a template fills',
      () {
        // A value that a template fills may be masculine or feminine, so `de`,
        // `do`, `da`, `em`, `no`, `na`, `a`, `ao`, `à`, `por`, `pelo`, and
        // `pela` never stand right before one, because the article decides the
        // contraction. A number never contracts, and the given name of a person
        // takes no article (`por Lia`, `em Ana Souza`). The range of a closure
        // is the one place: its values are weekdays, which take no article
        // (`de sábado a segunda-feira`).
        const allowed =
            '(?:n|m|sessions|price|packagePrice|sys|dia|pulse|spo2|temp|'
            'glucose|number|day|month|version|patient|name1|name2|mention)';
        final pattern = RegExp(
          '(?<![\\p{L}])(?:de|do|da|dos|das|em|no|na|nos|nas|a|ao|à|aos|às|por|'
          'pelo|pela|pelos|pelas|num|numa)\\s*\\{(?!$allowed\\})',
          caseSensitive: false,
          unicode: true,
        );
        expect(
          _matching(
            _texts,
            pattern,
            except: const <String>{'clinic.ops.dateRangeFormat'},
          ),
          isEmpty,
        );
      },
    );

    test('marks a fictional name with one tag, and a sample with another', () {
      expect(
        _matching(_texts, RegExp(r'\(fictícia\)|fictional|\(example\)')),
        isEmpty,
      );
      // The fictional places are Brazilian inventions, not the Korean ones of
      // the English data.
      expect(
        _matching(
          _texts,
          RegExp(
            'Solbit|Garam|Mulpare|Solnae|Onsae|Mildam|Nuri',
            caseSensitive: false,
          ),
        ),
        isEmpty,
      );
    });

    test('writes the variables of a notification template in Portuguese', () {
      final names = <String>{
        for (final template in _ptSaas.messageTemplates)
          for (final match in RegExp(r'#\{([^}]*)\}').allMatches(template.body))
            match.group(1)!,
      };
      expect(names, <String>{'nome', 'clinica', 'data_hora', 'hora', 'link'});
      final f = _forLanguage('pt');
      for (final code in <String>['RSV_CREATED', 'SURVEY', 'AD_EVENT']) {
        final body = f.saas.messageTemplate(code: code).body;
        expect(body, startsWith(code == 'AD_EVENT' ? '[Publicidade]' : 'Olá'));
        expect(body, contains('#{'));
      }
    });
  });

  group('the amounts of Portuguese are reais', () {
    final f = _forLanguage('pt');

    test('are written R\$ 1.234,56 with a no-break space', () {
      for (final writer in <String Function(num)>[
        f.clinic.money,
        f.saas.money,
      ]) {
        expect(writer(1234.56), 'R\$${_nbsp}1.234,56');
        expect(writer(1234), 'R\$${_nbsp}1.234,00');
        expect(writer(20), 'R\$${_nbsp}20,00');
        expect(writer(999), 'R\$${_nbsp}999,00');
        expect(writer(-80), '-R\$${_nbsp}80,00');
        expect(writer(2400000), 'R\$${_nbsp}2.400.000,00');
        expect(writer(0), 'R\$${_nbsp}0,00');
      }
    });

    test('have the code, the symbol, and the minor units of Brazil', () {
      const brazil = CoFakerCountries.brazil;
      for (final currency in <CoCurrencyFormat>[
        _ptClinic.currency,
        _ptSaas.currency,
      ]) {
        expect(currency.code, brazil.currencyCode);
        expect(currency.symbol, brazil.currencySymbol);
        expect(currency.fractionDigits, brazil.currencyMinorUnits);
        expect(currency.decimalSeparator, ',');
        expect(currency.groupSeparator, '.');
        expect(currency.pattern, '{symbol}$_nbsp{amount}');
      }
    });

    test('are the price of a procedure inside its band, in reais', () {
      final scale = _ptClinic.priceScale;
      expect(scale.priceRounding, 10);
      final bands = {for (final p in _ptClinic.procedures) p.code: p};
      final seen = <String>{};
      for (var i = 0; i < 160; i++) {
        final procedure = f.derive('procedure/$i').clinic.procedure();
        final band = bands[procedure.code]!;
        seen.add(procedure.code);
        expect(procedure.price, inInclusiveRange(band.minPrice, band.maxPrice));
        expect(procedure.price % scale.priceRounding, 0);
        expect(procedure.price, lessThanOrEqualTo(12000));
      }
      expect(seen, bands.keys.toSet());
      // The bands are the English dollar bands at three to five times:
      // a Brazilian price is not a dollar price.
      for (final spec in _ptClinic.procedures) {
        final english = _enClinic.procedures.firstWhere(
          (p) => p.code == spec.code,
        );
        expect(spec.taxable, english.taxable, reason: spec.code);
        expect(spec.minPrice, greaterThanOrEqualTo(english.minPrice * 3));
        expect(spec.minPrice % scale.priceRounding, 0, reason: spec.code);
        expect(spec.maxPrice, greaterThan(spec.minPrice), reason: spec.code);
      }
    });

    test('are the price of a package, a prepaid balance, and a payment', () {
      final scale = _ptClinic.priceScale;
      expect(scale.packageRounding, 50);
      expect(scale.prepaidStep, 50);
      for (var i = 0; i < 60; i++) {
        final g = f.derive('scale/$i');
        final package = g.clinic.package();
        expect(package.price % scale.packageRounding, 0);
        expect(package.price, lessThan(110000));
        expect(package.sessions, isIn(<int>[3, 5, 10]));
        final balance = g.clinic.prepaidBalance();
        expect(balance % scale.prepaidStep, 0);
        expect(balance, lessThanOrEqualTo(100 * scale.prepaidStep));
        final small = g.clinic.payment(amount: 120, method: 'card');
        expect(small.installmentMonths, 0);
        final split = g.clinic.splitPayment(amount: 40);
        expect(split, hasLength(1));
      }
      var installments = 0;
      for (var i = 0; i < 80; i++) {
        final months = f
            .derive('installment/$i')
            .clinic
            .payment(amount: 1250, method: 'card')
            .installmentMonths;
        if (months != null && months > 0) installments++;
      }
      expect(installments, greaterThan(0));
      // A discount, a coupon, a point, and a rounding are in units of R$ 5.
      for (var i = 0; i < 30; i++) {
        final g = f.derive('adjust/$i').clinic;
        for (final kind in <String>['discount', 'coupon', 'point']) {
          final line = g.adjustment(subtotal: 12340, kind: kind);
          expect(line.amount % 5, 0, reason: kind);
          expect(line.amount, lessThanOrEqualTo(0));
        }
        expect(g.pointTransaction().amount % 5, 0);
      }
      expect(f.clinic.adjustment(subtotal: 12347, kind: 'rounding').amount, -2);
    });

    test('write the price in a counseling quote in reais', () {
      for (var i = 0; i < 12; i++) {
        final session = f.derive('quote/$i').clinic.counselSession();
        expect(session.summary, contains('R\$$_nbsp'));
        expect(session.summary, contains(f.clinic.money(session.quotedPrice)));
        expect(session.summary, isNot(contains(r'$ ')));
        for (final turn in session.turns) {
          expect(turn.text, isNot(matches(RegExp('[₩원]|\\\$\\d'))));
        }
      }
    });

    test(
      'follow the plans, the tax, and the wallet of a Brazilian back office',
      () {
        expect(
          {for (final plan in _ptSaas.plans) plan.monthlyPrice},
          {299, 599, 1099, 2199},
        );
        expect(_ptSaas.priceScale.vatRate, 0.05);
        for (var i = 0; i < 40; i++) {
          final invoice = f.derive('invoice/$i').saas.invoice();
          expect(invoice.vat, (invoice.supplyAmount * 0.05).round());
          expect(invoice.total, invoice.supplyAmount + invoice.vat);
        }
        final scale = _ptSaas.priceScale;
        for (var i = 0; i < 20; i++) {
          final ledger = f.derive('wallet/$i').saas.prepaidLedger(count: 16);
          for (final entry in ledger) {
            if (entry.kind == 'topUp') {
              expect(scale.prepaidTopUps, contains(entry.amount));
              expect(entry.bonus, scale.bonusFor(entry.amount));
            } else {
              expect(entry.amount.abs(), lessThan(5000));
              expect(entry.amount % 5, 0);
            }
            expect(entry.balanceAfter, greaterThanOrEqualTo(0));
          }
        }
        for (final rows in _ptSaas.ops!.masterRows.values) {
          for (final row in rows) {
            expect(row.price == null || row.price! < 1000, isTrue);
          }
        }
      },
    );
  });

  group('Portuguese generates no value of the Korean data', () {
    final f = _forLanguage('pt');

    test('the data of the language says none', () {
      expect(_ptClinic.koreanValues, CoKoreanValues.none);
      expect(_ptSaas.koreanValues, CoKoreanValues.none);
    });

    test('masks an ID as a CPF', () {
      final shape = RegExp(r'^\*\*\*\.\d{3}\.\d{3}-\*\*$');
      for (var i = 0; i < 20; i++) {
        final patient = f.derive('patient/$i').clinic.patient();
        expect(patient.rrnMasked, matches(shape));
      }
    });

    test('shapes the business number of a tenant as a CNPJ', () {
      for (var i = 0; i < 20; i++) {
        final tenant = f.derive('tenant/$i').saas.tenant();
        expect(
          tenant.businessNumber,
          matches(RegExp(r'^\d{2}\.\d{3}\.\d{3}/\d{4}-\d{2}$')),
        );
      }
    });

    test('gives a plain authorization code, and no cash receipt number', () {
      for (var i = 0; i < 20; i++) {
        final card = f
            .derive('card/$i')
            .clinic
            .payment(amount: 900, method: 'card');
        expect(card.approvalNo, matches(RegExp(r'^\d{6}$')));
        expect(card.cashReceiptNo, isNull);
        final cash = f
            .derive('cash/$i')
            .clinic
            .payment(amount: 900, method: 'cash');
        expect(cash.cashReceiptNo, isNull);
      }
    });

    test('gives the phone number and the address of Brazil', () {
      for (var i = 0; i < 20; i++) {
        final g = f.derive('patient/$i').clinic;
        final patient = g.patient();
        expect(patient.phone, matches(RegExp(r'^\(\d{2}\) 9\d{4}-\d{4}$')));
        expect(patient.postalCode, matches(RegExp(r'^\d{5}-\d{3}$')));
        expect(
          patient.address1,
          matches(RegExp(r'^.+, \d+ - .+ - [A-Z]{2}$')),
          reason: patient.address1,
        );
        expect(_krOnlyShapes.hasMatch('$patient'), isFalse);
        expect(_hangul.hasMatch('$patient'), isFalse);
        expect(_hangul.hasMatch('${g.staff()}'), isFalse);
      }
    });

    test('names no Korean holiday in a closure notice', () {
      // Chuseok, Seollal, and Children’s Day of the Korean calendar.
      for (final date in <DateTime>[
        DateTime.utc(2026, 9, 25),
        DateTime.utc(2027, 2, 6),
        DateTime.utc(2026, 5, 5),
        DateTime.utc(2026, 10, 9),
      ]) {
        final notice = f.clinic.closureNotice(date: date);
        expect(notice.holiday, isNull);
        expect(notice.from, notice.to);
        expect(notice.body, contains('Motivo: '));
        expect(notice.body, isNot(contains('Chuseok')));
        expect(
          notice.body,
          anyOf(
            contains('congresso médico'),
            contains('reforma'),
            contains('manutenção de equipamentos'),
          ),
        );
      }
    });
  });

  group('the clinic and the SaaS of Portuguese read as Portuguese', () {
    final f = _forLanguage('pt');

    test('names a clinic by its kind first and its name after it', () {
      final suffixes = [for (final s in _ptClinic.specialties) s.clinicSuffix];
      final prefixes = _ptClinic.clinicNamePrefixes;
      final seen = <String>{};
      for (var i = 0; i < 80; i++) {
        final name = f.derive('clinic/$i').clinic.clinicName();
        seen.add(name);
        expect(suffixes.any(name.startsWith), isTrue, reason: name);
        expect(prefixes.any(name.endsWith), isTrue, reason: name);
      }
      expect(seen.length, greaterThan(20));
      expect(
        f.clinic.clinicName(specialty: 'Pediatria'),
        startsWith('Clínica de Pediatria '),
      );
      // Every kind of place is a `Clínica`.
      expect(suffixes, everyElement(startsWith('Clínica')));
    });

    test('writes a closure notice with a date, a reason, and a reopening', () {
      for (var i = 0; i < 12; i++) {
        final day = DateTime.utc(2026, 3, 1).add(Duration(days: i * 11));
        final notice = f.derive('closure/$i').clinic.closureNotice(date: day);
        expect(
          notice.title,
          matches(RegExp('^Aviso de fechamento: $_dateLabel\$')),
        );
        expect(
          notice.body,
          matches(
            RegExp(
              '^.+\\. Fechamento: $_dateLabel\\. Motivo: [^.]+\\. Retorno ao '
              'atendimento normal: $_dateLabel\\.\$',
            ),
          ),
        );
        expect(
          _ptClinic.ops!.closureReasons.any(notice.body.contains),
          isTrue,
          reason: notice.body,
        );
      }
      // October 8, 2026 is a Thursday.
      expect(
        f.clinic.closureNotice(date: DateTime.utc(2026, 10, 8)).title,
        'Aviso de fechamento: quinta-feira (8/10)',
      );
    });

    test('writes a date range with `de` and `a`', () {
      final ops = _ptClinic.ops!;
      expect(ops.dateRangeFormat, 'de {from} a {to}');
      expect(ops.dateFormat, '{weekday} ({day}/{month})');
    });

    test('mentions a staff member with the role after a dot', () {
      for (var i = 0; i < 12; i++) {
        final note = f.derive('note/$i').clinic.teamNote(patient: 'Ana Souza');
        expect(note.text, contains('Ana Souza'));
        expect(note.text, matches(RegExp(r'@[^@·]+ · [^,.]+')));
        expect(note.text, isNot(contains('{')));
      }
      final named = f.clinic.teamNote(
        patient: 'Ana Souza',
        authors: <String>['Léa Martin'],
        mentions: <String>['Hugo Petit'],
      );
      expect(named.text, contains('@Hugo Petit'));
      expect(named.text, isNot(contains('@Hugo Petit ·')));
    });

    test('names a device with `nº` and a no-break space', () {
      for (var i = 0; i < 12; i++) {
        final device = f.derive('device/$i').clinic.device(number: 2);
        expect(device.name, '${device.kindLabel} nº${_nbsp}2');
      }
    });

    test('names a package by its sessions, and a compound one with a gift', () {
      for (var i = 0; i < 12; i++) {
        final g = f.derive('package/$i');
        final package = g.clinic.package();
        expect(package.name, endsWith(' · ${package.sessions} sessões'));
        final compound = g.clinic.compoundPackageName();
        expect(compound, endsWith(' + creme reparador de brinde'));
        expect(
          RegExp(r' \((?:3|5|10) sessões\)').allMatches(compound),
          hasLength(greaterThanOrEqualTo(2)),
        );
      }
    });

    test('names an operator action and an incident with the name first', () {
      final ops = _ptSaas.ops!;
      expect(
        ops.operatorActions['tenant.approve']!.summary,
        '{target}: cadastro aprovado.',
      );
      expect(
        ops.operatorActions['notice.publish']!.summary,
        'Aviso “{target}” publicado.',
      );
      for (var i = 0; i < 12; i++) {
        final incident = f.derive('incident/$i').saas.incidents().first;
        expect(incident.title, contains(': '));
        expect(incident.title, isNot(contains('{')));
        final activity = f.derive('activity/$i').saas.tenantActivity();
        expect(activity.text, matches(RegExp(r'^[^:]+: \d+$')));
      }
    });

    test('has a Portuguese label for every code', () {
      expect(f.clinic.label('noShow'), 'Faltou');
      expect(f.clinic.label('prepaid'), 'Saldo pré-pago');
      expect(f.clinic.label('counseling'), 'Orientação');
      expect(f.clinic.label('uninsured'), 'Particular');
      expect(f.clinic.label('desk'), 'Balcão');
      expect(f.saas.label('pastDue'), 'Pagamento em atraso');
      expect(f.saas.label('revealRrn'), 'Exibição do número de identificação');
    });

    test('names a title with both genders with `(a)`', () {
      for (final role in _ptClinic.staffRoles.entries) {
        if (role.value.contains('(a)')) {
          expect(role.value, isNot(contains('/')), reason: role.key);
        }
      }
      expect(_ptClinic.staffRoles['nurse'], 'Enfermeiro(a)');
      expect(_ptClinic.staffRoles['skincare'], 'Esteticista');
    });
  });

  group('the safety conventions of Portuguese', () {
    final f = _forLanguage('pt');

    test('a fictional drug, product, and event name carries (fictício)', () {
      expect(ptSafety.fictionalMarker, '(fictício)');
      for (final role in <String>[
        'vet.vetDrug',
        'vet.preventiveProduct',
        'daycare.drugLabel',
        'remit.bankNameFictional',
        'content.seriesTitle',
        'campaign.brandName',
      ]) {
        for (var i = 0; i < 12; i++) {
          expect(
            _value(f, role, i),
            endsWith(ptSafety.fictionalMarker),
            reason: role,
          );
        }
      }
    });

    test('the two creators are Portuguese names of fiction', () {
      expect(_pt.texts['fandom.creatorName'], <String>[
        'Jardim da Ampulheta',
        'Brisa de Linho',
      ]);
      final seen = <String>{
        for (var i = 0; i < 6; i++) _value(f, 'fandom.creatorName', i),
      };
      expect(seen, <String>{'Jardim da Ampulheta', 'Brisa de Linho'});
    });

    test('a masked name, a card, and a plate stay masked', () {
      for (var i = 0; i < 20; i++) {
        expect(
          _value(f, 'homecare.recipientName', i),
          matches(RegExp(r'^\p{Lu}\*\*\*$', unicode: true)),
        );
        expect(
          _value(f, 'hospitality.guestName', i),
          matches(RegExp(r'^\p{Lu}\*\*\*$', unicode: true)),
        );
        expect(
          _value(f, 'logistics.vehiclePlate', i),
          matches(RegExp(r'^●●C-\d{4}$')),
        );
        expect(
          _value(f, 'logistics.entranceHint', i),
          isNot(matches(RegExp(r'#\d{4}'))),
        );
      }
    });

    test('a general-information text starts with its prefix', () {
      expect(ptSafety.generalInfoPrefix, 'Informação geral');
      for (final key in <String>[
        'brokerage.qnaAnswerGeneric',
        'brokerage.consultNoteGeneric',
      ]) {
        for (final text in _pt.texts[key]!) {
          expect(text, startsWith(ptSafety.generalInfoPrefix), reason: key);
        }
      }
    });

    test('an entrance hint and a guardian label take no door code', () {
      final hints = _pt.texts['logistics.entranceHint']!;
      expect(hints.where((text) => text.contains('••••')), isNotEmpty);
      for (final text in hints) {
        expect(text, isNot(matches(RegExp(r'\d{4}'))));
      }
      for (final key in <String>[
        'daycare.guardianLabel',
        'daycare.teacherName',
      ]) {
        expect(_pt.texts[key]!.single, contains('{name1}'));
      }
    });

    test('the drug stems are the invented ones, not the English stems', () {
      // `Lumisol` of the English data is the name of a marketed product, so the
      // Portuguese stems are eight names that were searched for and not found.
      expect(
        _ptClinic.drugStems.toSet().intersection(_enClinic.drugStems.toSet()),
        isEmpty,
      );
      expect(_ptClinic.drugStems, hasLength(8));
    });
  });

  group('the language is finished', () {
    test('is localized and passes the completion gate', () {
      final data = CoLanguageData.registered('pt');
      expect(data.level, CoLanguageLevel.localized);
      final report = CoLanguageCoverage().check(data);
      expect(report.issues, isEmpty, reason: report.toMarkdown());
    });
  });
}

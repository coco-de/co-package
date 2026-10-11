import 'package:co_faker/co_faker.dart';
import 'package:test/test.dart';

/// Supply defects the W1 consumption measurement found (coco-de/cocode
/// `docs/projects/637/faker-support-w1.md` §4 · §5, co_faker a66629f6): every
/// expectation below is a field of a W1 design record (#662 · #665 · #669 ·
/// #671 · #674 · #677 · #680 · #683 · #686) generated the way the demos do —
/// `CoFakerDomains.all`, one record per display key, the entity as context.
///
/// * S-5 — `saas.tenantName` gave a clinic name to a helpdesk customer
///   company.
/// * S-6 — an A code field took the display label role (`냉장 보관` /
///   `Refrigerate` in a `room` · `fridge` field).
/// * S-7 — a role of a pack earlier in `CoFakerDomains.all` took the field
///   (`unitPrice` → `clinic.procedurePrice`, whose amount follows the UI
///   language; `employee.name` → `hrd.employeeName`).
/// * S-8 — a role the pack has but does not map to the entity (a name read as
///   a title and back).
/// * S-10 — the Korean vehicle plate followed the UI language.
/// * L-4 — an A (business) value is the same in every UI language.

/// The eleven demo UI languages as co_faker locales (co_demo_world
/// `DemoFakerLocales.table`).
const List<String> _languages = [
  'ko',
  'en_US',
  'zh_CN',
  'ja_JP',
  'de_DE',
  'fr_FR',
  'es_ES',
  'pt_BR',
  'it_IT',
  'ru_RU',
  'ar_SA',
];

/// The A (business value) fields of the nine W1 design records: entity,
/// field and type. The UI language must not change any of them.
const List<(String, String, String)> _businessFields = [
  // coco-de/cocode#674 helpdesk
  ('help_topic', 'parentId', 'String'),
  ('ticket', 'category', 'String'),
  ('ticket', 'ticketNo', 'String'),
  ('ticket_message', 'visibility', 'String'),
  ('crm_contact', 'mobilePhone', 'String'),
  // coco-de/cocode#680 brokerage
  ('service_request', 'workMode', 'String'),
  ('dispute_case', 'reason', 'String'),
  ('business', 'businessNumber', 'String'),
  // coco-de/cocode#665 daycare
  ('child', 'classCode', 'String'),
  ('child', 'guardianContactMasked', 'String'),
  ('child', 'attendedDays', 'int'),
  ('child', 'noteCount', 'int'),
  ('child', 'photoCount', 'int'),
  ('daily_note', 'moodLabel', 'String'),
  ('daily_note', 'mealLevel', 'String'),
  ('medication_request', 'storage', 'String'),
  ('pickup_permit', 'relation', 'String'),
  ('pickup_permit', 'contactLast4', 'String'),
  // coco-de/cocode#677 workplace
  ('employee', 'extension', 'String'),
  ('work_day', 'workMinutes', 'int'),
  ('shift', 'headcount', 'int'),
  ('leave_request', 'leaveType', 'String'),
  ('approval_line', 'decision', 'String'),
  ('employee', 'mobilePhone', 'String'),
  // coco-de/cocode#686 hospitality
  ('campsite', 'category', 'String'),
  ('campsite', 'weekdayPrice', 'int'),
  ('stay_night', 'capacity', 'int'),
  ('stay_night', 'remaining', 'int'),
  ('stay_booking', 'bookingNo', 'String'),
  ('stay_booking', 'arrivalEta', 'String'),
  ('stay_booking', 'totalAmount', 'int'),
  ('stay_booking', 'phoneMasked', 'String'),
  ('campsite_review', 'stayMonth', 'String'),
  // coco-de/cocode#669 meetup
  ('club', 'interest', 'String'),
  ('club', 'joinPolicy', 'String'),
  ('club', 'memberCount', 'int'),
  ('club_member', 'availableDays', 'String'),
  ('club_member', 'experienceLevel', 'String'),
  ('gathering', 'capacity', 'int'),
  ('gathering', 'allowGuest', 'bool'),
  ('club_due', 'unitPrice', 'int'),
  // coco-de/cocode#683 logistics
  ('delivery_route', 'routeCode', 'String'),
  ('delivery_route', 'vehiclePlate', 'String'),
  ('load_item', 'trackingNo', 'String'),
  ('load_item', 'sizeClass', 'String'),
  ('load_item', 'shelfSlot', 'String'),
  ('delivery_stop', 'timeWindow', 'String'),
  ('delivery_exception', 'reasonCode', 'String'),
  ('courier', 'vehicleType', 'String'),
  // coco-de/cocode#671 content
  ('series', 'genre', 'String'),
  ('series', 'section', 'String'),
  ('series', 'releaseWeekday', 'String'),
  ('series_genre', 'parentId', 'String'),
  ('episode', 'commentCount', 'int'),
  ('coin_wallet', 'balance', 'int'),
  ('series_follow', 'hasUpdate', 'bool'),
  // coco-de/cocode#662 fitness
  ('class_session', 'category', 'String'),
  ('class_session', 'level', 'String'),
  ('class_session', 'capacity', 'int'),
  ('membership_pass', 'totalSessions', 'int'),
  ('pass_line', 'unitPrice', 'int'),
  ('instructor', 'totalClassCount', 'int'),
  ('fitness_member', 'phone', 'String'),
];

/// W1 fields whose role the entity context did not reach: entity, field,
/// type and the role of the design record.
const List<(String, String, String, String)> _recordRoles = [
  // S-5 · S-8 coco-de/cocode#674 helpdesk
  ('tenant', 'companyName', 'String', 'saas.tenantName'),
  ('help_article', 'title', 'String', 'helpdesk.helpArticleTitle'),
  ('csat_response', 'comment', 'String', 'helpdesk.csatComment'),
  ('ai_draft', 'templateBody', 'String', 'helpdesk.aiDraftText'),
  ('desk_macro', 'name', 'String', 'helpdesk.macroName'),
  // S-8 coco-de/cocode#680 brokerage
  ('delivery_milestone', 'label', 'String', 'brokerage.milestoneLabel'),
  ('dispute_case', 'reason', 'String', 'brokerage.disputeReason'),
  // S-8 coco-de/cocode#665 daycare
  ('child', 'allergyNote', 'String', 'daycare.allergenLabel'),
  ('album_photo', 'title', 'String', 'daycare.albumCaption'),
  ('album_group', 'title', 'String', 'daycare.activityTitle'),
  ('day_plan', 'title', 'String', 'daycare.mealMenu'),
  ('day_plan', 'allergenNote', 'String', 'daycare.allergenLabel'),
  // S-7 · S-8 coco-de/cocode#677 workplace
  ('employee', 'name', 'String', 'workplace.employeeName'),
  ('department', 'name', 'String', 'workplace.department'),
  ('shift', 'title', 'String', 'workplace.shiftName'),
  ('shift', 'place', 'String', 'workplace.workPlace'),
  ('leave_request', 'leaveType', 'String', 'workplace.leaveType'),
  ('approval_line', 'comment', 'String', 'workplace.approvalComment'),
  ('approval_line', 'decision', 'String', 'workplace.approvalDecision'),
  ('approval_line', 'actionLabel', 'String', 'saas.auditAction'),
  // S-8 coco-de/cocode#686 hospitality
  ('campsite', 'category', 'String', 'hospitality.siteType'),
  ('stay_extra', 'name', 'String', 'hospitality.stayOption'),
  ('stay_booking', 'phoneMasked', 'String', 'korea.mobilePhone'),
  ('campsite_review', 'body', 'String', 'hospitality.reviewSnippet'),
  ('season_rate', 'seasonName', 'String', 'hospitality.seasonName'),
  ('property', 'addressDisplay', 'String', 'korea.address1'),
  // S-7 · S-8 coco-de/cocode#669 meetup
  ('club_member', 'intro', 'String', 'meetup.joinAnswer'),
  ('club_due', 'title', 'String', 'meetup.duesItem'),
  ('club_due', 'unitPrice', 'int', 'price'),
  // S-8 coco-de/cocode#683 logistics
  ('load_item', 'sizeClass', 'String', 'logistics.parcelSize'),
  ('delivery_stop', 'addressLine', 'String', 'korea.address1'),
  ('delivery_stop', 'requestNote', 'String', 'logistics.deliveryNote'),
  ('delivery_exception', 'reasonCode', 'String', 'logistics.exceptionReason'),
  ('parcel_scan', 'title', 'String', 'logistics.scanEvent'),
  ('parcel_scan', 'areaLabel', 'String', 'logistics.hubName'),
  ('driver_settlement', 'itemName', 'String', 'logistics.fareItem'),
  ('courier', 'name', 'String', 'logistics.driverName'),
  // S-8 coco-de/cocode#671 content
  ('episode_cut', 'altText', 'String', 'content.cutAltText'),
  ('novel_chapter', 'title', 'String', 'content.episodeTitle'),
  ('novel_chapter', 'body', 'String', 'content.chapterParagraph'),
  ('coin_wallet', 'balance', 'int', 'quantity'),
  ('episode_comment', 'body', 'String', 'content.commentLine'),
  // S-7 · S-8 coco-de/cocode#662 fitness
  ('pass_product', 'name', 'String', 'fitness.passName'),
  ('pass_line', 'unitPrice', 'int', 'price'),
];

/// W1 A code fields (S-6): entity, field and the codes of the record.
const List<(String, String, List<String>)> _codeFields = [
  ('child', 'classCode', ['sun', 'moon', 'star']),
  ('medication_request', 'storage', ['room', 'fridge']),
  (
    'club',
    'interest',
    ['running', 'reading', 'boardgame', 'photo', 'cooking', 'hiking'],
  ),
  (
    'club_member',
    'availableDays',
    ['weekday_evening', 'weekend', 'tue_thu', 'sat_morning', 'any_day'],
  ),
  ('club_member', 'experienceLevel', ['first', 'sometimes', 'regular']),
  (
    'series',
    'genre',
    ['fantasy', 'daily_life', 'adventure', 'science', 'essay'],
  ),
  ('series', 'section', ['weekly', 'new', 'completed', 'daily', 'short']),
];

/// The W1 measurement seed of #674 and its fixed clock.
const int _seed = 436;
final DateTime _now = DateTime.utc(2026, 1, 15);

final Map<String, CoFaker> _roots = {};

CoFaker _root(String locale) => _roots.putIfAbsent(
  locale,
  () => CoFaker(
    locale: locale,
    seed: _seed,
    now: _now,
    domains: CoFakerDomains.all,
  ),
);

/// The value a demo projects for sample [n] of `entity.field` in [locale]:
/// one record per display key, the entity as context.
Object? _value(
  String locale,
  String entity,
  String field,
  String type,
  int n, {
  Map<String, String> roles = const {},
}) => _root(locale)
    .derive('$entity/sample-${n.toString().padLeft(3, '0')}/$field')
    .schema
    .record(
      {field: type},
      roles: roles,
      entity: entity,
      streamKey: entity,
    )[field];

/// The twelve samples of `entity.field` in [locale].
List<Object?> _samples(
  String locale,
  String entity,
  String field,
  String type, {
  Map<String, String> roles = const {},
}) => [
  for (var n = 1; n <= 12; n++)
    _value(locale, entity, field, type, n, roles: roles),
];

String _role(String entity, String field, String type) =>
    CoFakerCoverage(_root('ko'))
        .check([
          CoCoverageEntity(entity, fields: {field: type}),
        ])
        .rows
        .single
        .role;

void main() {
  group('S-5 saas.tenantName in a helpdesk', () {
    final clinic = RegExp(
      '의원|병원|치과|한의원|클리닉|Clinic|Pediatrics|Dermatology|Dental|'
      'Medical|Hospital|Orthopedic|Ophthalmology',
    );

    test('a customer company name is a company, not a clinic', () {
      for (final locale in ['ko', 'en_US']) {
        for (final name in _samples(
          locale,
          'tenant',
          'companyName',
          'String',
          roles: const {'companyName': 'saas.tenantName'},
        )) {
          expect(name, isNot(matches(clinic)), reason: locale);
        }
      }
    });

    test('the clinic SaaS tenant keeps its clinic name', () {
      final names = _samples(
        'ko',
        'tenant',
        'name',
        'String',
        roles: const {'name': 'saas.tenantName'},
      );
      expect(names.where((name) => clinic.hasMatch('$name')), isNotEmpty);
    });
  });

  group('S-6 A code fields take codes, not display labels', () {
    for (final (entity, field, codes) in _codeFields) {
      test('$entity.$field infers one of its codes in every language', () {
        final role = _role(entity, field, 'String');
        expect(
          role == 'status' ||
              _root('ko').domains.findRole(role)!.role.languageNeutral,
          isTrue,
          reason: '$role is not a code role',
        );
        final ko = _samples('ko', entity, field, 'String');
        expect(ko, everyElement(isIn(codes)));
        for (final locale in _languages) {
          expect(_samples(locale, entity, field, 'String'), ko, reason: locale);
        }
      });
    }

    test('content.seriesSection is a code and its label a separate role', () {
      final f = _root('en_US');
      expect(
        f.domains.findRole('content.seriesSection')!.role.languageNeutral,
        isTrue,
      );
      final codes = _samples(
        'en_US',
        'series',
        'section',
        'String',
        roles: const {'section': 'content.seriesSection'},
      );
      expect(
        codes,
        everyElement(isIn(['weekly', 'new', 'completed', 'daily', 'short'])),
      );
      expect(
        _samples(
          'ko',
          'series',
          'sectionLabel',
          'String',
          roles: const {'sectionLabel': 'content.seriesSectionLabel'},
        ),
        everyElement(isIn(['주간 연재', '신작', '완결', '매일 연재', '단편'])),
      );
    });
  });

  group('S-7 an earlier pack does not take a W1 field', () {
    for (final (entity, field) in [
      ('club_due', 'unitPrice'),
      ('pass_line', 'unitPrice'),
    ]) {
      test('$entity.$field is a price the UI language does not change', () {
        expect(_role(entity, field, 'int'), 'price');
        final ko = _samples('ko', entity, field, 'int');
        for (final locale in _languages) {
          expect(_samples(locale, entity, field, 'int'), ko, reason: locale);
        }
      });
    }

    test('an unqualified employee is the workplace employee', () {
      expect(_role('employee', 'name', 'String'), 'workplace.employeeName');
      expect(
        _role('hrd.employee', 'name', 'String'),
        'hrd.employeeName',
        reason: 'the training pack keeps its qualified employee',
      );
    });
  });

  group('S-8 W1 fields resolve to the role of their design record', () {
    for (final (entity, field, type, role) in _recordRoles) {
      test('$entity.$field → $role', () {
        expect(_role(entity, field, type), role);
      });
    }

    test('a thing name is a title, not a person', () {
      expect(_role('stay_charge', 'itemName', 'String'), 'title');
      expect(_role('season', 'seasonName', 'String'), 'title');
      expect(
        _role('operator', 'name', 'String'),
        'name',
        reason: 'an operator is a person',
      );
    });
  });

  group('S-10 the Korean vehicle plate', () {
    test('is the same plate in every UI language', () {
      final ko = _samples('ko', 'delivery_route', 'vehiclePlate', 'String');
      expect(ko, everyElement(matches(RegExp(r'^\d{2}가●●\d{2}$'))));
      for (final locale in _languages) {
        expect(
          _samples(locale, 'delivery_route', 'vehiclePlate', 'String'),
          ko,
          reason: locale,
        );
      }
    });

    test('a local plate stays available as its own role', () {
      expect(
        _samples(
          'ja_JP',
          'vehicle',
          'plate',
          'String',
          roles: const {'plate': 'logistics.localVehiclePlate'},
        ),
        everyElement(contains('あ')),
      );
    });
  });

  group('L-4 an A value is the same in every UI language', () {
    for (final (entity, field, type) in _businessFields) {
      test('W1 $entity.$field', () {
        final ko = _samples('ko', entity, field, type);
        for (final locale in _languages) {
          expect(_samples(locale, entity, field, type), ko, reason: locale);
        }
      });
    }

    test('every language-neutral role of every pack', () {
      final checked = <String>[];
      for (final pack in CoFakerDomains.all) {
        for (final entry in pack.roles.entries) {
          if (!entry.value.languageNeutral) continue;
          final role = '${pack.name}.${entry.key}';
          final type = entry.value.supportedTypes?.first ?? 'String';
          final ko = _samples(
            'ko',
            'record',
            'value',
            type,
            roles: {'value': role},
          );
          for (final locale in _languages) {
            expect(
              _samples(locale, 'record', 'value', type, roles: {'value': role}),
              ko,
              reason: '$role in $locale',
            );
          }
          checked.add(role);
        }
      }
      expect(
        checked,
        containsAll(<String>[
          'logistics.vehiclePlate',
          'content.seriesSection',
          'helpdesk.ticketNo',
          'workplace.leaveType',
        ]),
      );
    });
  });
}

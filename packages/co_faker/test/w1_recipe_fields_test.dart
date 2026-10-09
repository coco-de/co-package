import 'package:co_faker/co_faker.dart';
import 'package:test/test.dart';

/// The 34 fields of the demo W1 recipes that co_faker did not cover
/// (co-package#78): every one resolves to a domain role, a business
/// identifier is the same in every language, and a display text is the
/// translation of the English record in each of the eleven languages.

/// entity → field → the role it resolves to, and whether it is a business
/// identifier (A) or a display text (B).
const Map<String, Map<String, (String, String)>> _fields =
    <String, Map<String, (String, String)>>{
      'instructor': {
        'specialty': ('fitness.instructorSpecialty', 'B'),
        'career': ('fitness.instructorCareer', 'B'),
      },
      'child': {
        'guardianContactMasked': ('daycare.guardianContactMasked', 'A'),
      },
      'medication_request': {
        'storage': ('daycare.medicationStorage', 'B'),
        'symptom': ('daycare.symptom', 'B'),
        'guardianSignature': ('daycare.guardianSignature', 'A'),
      },
      'pickup_permit': {
        'relation': ('daycare.pickupRelation', 'A'),
        'contactLast4': ('daycare.contactLast4', 'A'),
        'guardianSignature': ('daycare.guardianSignature', 'A'),
      },
      'club_member': {'availableDays': ('meetup.availableDays', 'B')},
      'meetup_member': {'interests': ('meetup.interestTag', 'B')},
      'series': {
        'section': ('content.seriesSection', 'B'),
        'releaseWeekday': ('content.releaseWeekday', 'A'),
      },
      'ticket': {'ticketNo': ('helpdesk.ticketNo', 'A')},
      'ticket_message': {
        'ticketNo': ('helpdesk.ticketNo', 'A'),
        'visibility': ('helpdesk.visibility', 'A'),
      },
      'csat_response': {'ticketNo': ('helpdesk.ticketNo', 'A')},
      'shift': {'department': ('workplace.department', 'B')},
      'approval_line': {'approverRole': ('workplace.approverRole', 'B')},
      'employee': {'extension': ('workplace.extension', 'A')},
      'month_close_item': {'section': ('workplace.closeSection', 'B')},
      'provider_profile': {'skills': ('brokerage.skillTag', 'B')},
      'load_item': {
        'trackingNo': ('logistics.trackingNo', 'A'),
        'recipientArea': ('logistics.recipientArea', 'B'),
        'shelfSlot': ('logistics.shelfSlot', 'A'),
      },
      'delivery_proof': {'signatureData': ('logistics.signatureData', 'A')},
      'delivery_exception': {'detail': ('logistics.exceptionDetail', 'B')},
      'parcel_scan': {'trackingNo': ('logistics.trackingNo', 'A')},
      'courier': {
        'vehicleType': ('logistics.vehicleType', 'A'),
        'vehiclePlate': ('logistics.vehiclePlate', 'B'),
      },
      'stay_booking': {'arrivalEta': ('hospitality.arrivalEta', 'A')},
      'stay_guide': {
        'bbqRule': ('hospitality.bbqRule', 'B'),
        'wifiHint': ('hospitality.wifiHint', 'B'),
      },
      'campsite_review': {'stayMonth': ('hospitality.stayMonth', 'A')},
    };

const List<String> _languages = <String>[
  'ko',
  'en',
  'zh',
  'ja',
  'de',
  'fr',
  'es',
  'pt',
  'it',
  'ru',
  'ar',
];

final DateTime _now = DateTime.utc(2026, 10, 9, 9);

CoFaker _faker(String language, {int seed = 436}) => CoFaker.forLanguage(
  language,
  seed: seed,
  now: _now,
  domains: CoFakerDomains.all,
);

/// The value of [field] of [entity] at [index], inferred from the entity
/// and the field name alone, as a recipe asks for it.
String _value(CoFaker f, String entity, String field, int index) =>
    '${f.schema.record({field: 'String'}, entity: entity, streamKey: 'w1/$entity', index: index)[field]}';

/// The keys of the bundle whose texts a display role picks.
const Map<String, String> _textKeys = <String, String>{
  'fitness.instructorSpecialty': 'fitness.instructorSpecialty',
  'fitness.instructorCareer': 'fitness.instructorCareer',
  'daycare.medicationStorage': 'daycare.medicationStorage',
  'daycare.symptom': 'daycare.symptom',
  'meetup.availableDays': 'meetup.availableDays',
  'meetup.interestTag': 'meetup.interestTag',
  'content.seriesSection': 'content.seriesSection',
  'workplace.department': 'workplace.department',
  'workplace.approverRole': 'workplace.approverRole',
  'workplace.closeSection': 'workplace.closeSection',
  'brokerage.skillTag': 'brokerage.skillTag',
  'logistics.exceptionDetail': 'logistics.exceptionDetail',
  'hospitality.bbqRule': 'hospitality.bbqRule',
  'hospitality.wifiHint': 'hospitality.wifiHint',
};

void main() {
  test('the 34 fields are 34, and each resolves to its role', () {
    final requests = <CoCoverageEntity>[
      for (final entry in _fields.entries)
        CoCoverageEntity(
          entry.key,
          fields: {for (final field in entry.value.keys) field: 'String'},
        ),
    ];
    final report = CoFakerCoverage(
      CoFaker(locale: 'ko', seed: 0, domains: CoFakerDomains.all),
    ).check(requests);
    expect(report.rows, hasLength(34));
    expect(report.complete, isTrue, reason: report.toMarkdown());
    for (final row in report.rows) {
      expect(row.status, CoCoverageStatus.supported, reason: row.field);
      expect(row.role, _fields[row.entity]![row.field]!.$1, reason: row.field);
    }
  });

  test('a business identifier is the same in every language', () {
    for (final entry in _fields.entries) {
      for (final field in entry.value.entries) {
        if (field.value.$2 != 'A') continue;
        for (var index = 0; index < 6; index++) {
          final english = _value(_faker('en'), entry.key, field.key, index);
          expect(english, isNotEmpty);
          for (final language in _languages) {
            expect(
              _value(_faker(language), entry.key, field.key, index),
              english,
              reason: '$language ${entry.key}.${field.key} #$index',
            );
          }
          // The same seed gives the same value again.
          expect(_value(_faker('en'), entry.key, field.key, index), english);
        }
      }
    }
  });

  test('the identifiers have the shapes a recipe expects', () {
    final f = _faker('ko');
    final ticket = _value(f, 'ticket', 'ticketNo', 4);
    expect(ticket, matches(RegExp(r'^TK-\d{6}-\d{4}$')));
    // A message and a survey of the same record carry the ticket's number.
    expect(_value(f, 'ticket_message', 'ticketNo', 4), ticket);
    expect(_value(f, 'csat_response', 'ticketNo', 4), ticket);
    expect(
      _value(f, 'child', 'guardianContactMasked', 2),
      matches(RegExp(r'^\*\*\*-\*\*\*\*-\d{4}$')),
    );
    expect(_value(f, 'pickup_permit', 'contactLast4', 2), matches(r'^\d{4}$'));
    expect(_value(f, 'employee', 'extension', 1), matches(r'^[1-9]\d{3}$'));
    expect(
      _value(f, 'load_item', 'shelfSlot', 7),
      matches(RegExp(r'^[A-F]-\d{2}-[1-4]$')),
    );
    expect(
      _value(f, 'stay_booking', 'arrivalEta', 3),
      matches(r'^\d{2}:\d{2}$'),
    );
    expect(
      _value(f, 'series', 'releaseWeekday', 3),
      isIn(['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun']),
    );
    expect(
      _value(f, 'ticket_message', 'visibility', 1),
      isIn(['public', 'internal']),
    );
    for (var index = 0; index < 12; index++) {
      final month = _value(f, 'campsite_review', 'stayMonth', index);
      expect(month, matches(r'^\d{4}-\d{2}$'));
      expect(month.compareTo('2026-10'), lessThan(0), reason: month);
    }
    for (final (entity, field) in [
      ('medication_request', 'guardianSignature'),
      ('pickup_permit', 'guardianSignature'),
      ('delivery_proof', 'signatureData'),
    ]) {
      expect(
        _value(f, entity, field, 0),
        startsWith('data:image/svg+xml'),
        reason: '$entity.$field',
      );
      expect(
        _value(f, entity, field, 0),
        isNot(_value(f, entity, field, 1)),
        reason: '$entity.$field',
      );
    }
  });

  test('a display text is the translation of the English record', () {
    final english = CoL10nRegistry.english;
    for (final entry in _fields.entries) {
      for (final field in entry.value.entries) {
        final key = _textKeys[field.value.$1];
        if (key == null) continue;
        for (var index = 0; index < 8; index++) {
          final enText = _value(_faker('en'), entry.key, field.key, index);
          final row = english.texts[key]!.indexOf(enText);
          expect(row, isNonNegative, reason: '$key "$enText"');
          for (final language in _languages) {
            final bundle = CoL10nRegistry.bundleFor(language)!;
            expect(bundle.texts[key], hasLength(english.texts[key]!.length));
            expect(
              _value(_faker(language), entry.key, field.key, index),
              bundle.texts[key]![row],
              reason: '$language ${entry.key}.${field.key} #$index',
            );
          }
        }
      }
    }
  });

  test('the recipient area and the plate follow the language', () {
    for (final language in _languages) {
      final f = _faker(language);
      expect(
        f.localeData.cities,
        contains(_value(f, 'load_item', 'recipientArea', 0)),
        reason: language,
      );
      expect(_value(f, 'courier', 'vehiclePlate', 0), contains('●●'));
    }
  });
}

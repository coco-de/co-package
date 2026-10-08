import '../domain.dart';
import 'authored_roles.dart';

/// Brand-free restaurant and queue labels.
class CoDiningDomain extends CoFakerDomain {
  /// Creates this pack.
  const CoDiningDomain();
  @override
  String get name => 'dining';
  @override
  Map<String, CoDomainRole> get roles => {
    'restaurantName': textRole('dining.restaurantName'),
    'cuisine': enumRole(['korean', 'western', 'japanese', 'cafe']),
    'menuName': textRole('dining.menuName'),
    'seatType': enumRole(['hall', 'bar', 'room']),
    'tableCode': authoredRole(
      (f, c) => '${['H', 'B', 'R'][c.index % 3]}${1 + c.index ~/ 3}',
    ),
    'partyLabel': authoredRole(
      (f, c) => f.l10n.format('dining.partyLabel', {'n': 1 + c.index % 8}),
    ),
    'waitTicketNo': codeRole('WAIT', width: 3),
    'noShowNote': textRole('dining.noShowNote'),
    'loyaltyBenefit': textRole('dining.loyaltyBenefit'),
    'districtName': textRole('dining.districtName'),
  };
  @override
  Map<String, Map<String, String>> get entities => const {
    'dining_place': {
      'id': 'int',
      'name': 'String',
      'category': 'String',
      'district': 'String',
      'imageUrl': 'String',
    },
    'waitlist_ticket': {
      'id': 'int',
      'placeId': 'int',
      'ticketNo': 'String',
      'seatType': 'String',
      'status': 'String',
    },
    'table_reservation': {
      'id': 'int',
      'placeId': 'int',
      'reservationNo': 'String',
      'seatType': 'String',
      'status': 'String',
    },
  };
  @override
  Map<String, Map<String, String>> get entityRoles => const {
    'dining_place': {
      'name': 'restaurantName',
      'category': 'cuisine',
      'district': 'districtName',
    },
    'waitlist_ticket': {'ticketNo': 'waitTicketNo', 'seatType': 'seatType'},
    'table_reservation': {
      'reservationNo': 'booking.reservationNo',
      'seatType': 'seatType',
    },
  };
  @override
  Map<String, Map<String, List<String>>> get enums => const {
    'waitlist_ticket': {
      'status': ['waiting', 'called', 'seated', 'skipped', 'cancelled'],
    },
    'table_reservation': {
      'status': [
        'confirmed',
        'arrived',
        'completed',
        'no_show',
        'cancelled',
        'late_cancelled',
      ],
    },
  };
}

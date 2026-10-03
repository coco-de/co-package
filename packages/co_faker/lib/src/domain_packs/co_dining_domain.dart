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
    'restaurantName': textRole(
      ['들기름 국숫집(가상)', '골목 파스타집(가상)', '솔빛 찻집(가상)'],
      [
        'Perilla noodle shop (fictional)',
        'Lane pasta shop (fictional)',
        'Solbit tea room (fictional)',
      ],
    ),
    'cuisine': enumRole(['korean', 'western', 'japanese', 'cafe']),
    'menuName': textRole(
      ['들기름 국수', '토마토 파스타', '채소 덮밥', '따뜻한 차'],
      ['Perilla noodles', 'Tomato pasta', 'Vegetable rice bowl', 'Warm tea'],
    ),
    'seatType': enumRole(['hall', 'bar', 'room']),
    'tableCode': authoredRole(
      (f, c) => '${['H', 'B', 'R'][c.index % 3]}${1 + c.index ~/ 3}',
    ),
    'partyLabel': authoredRole(
      (f, c) =>
          localized(f, '${1 + c.index % 8}인 일행', 'Party of ${1 + c.index % 8}'),
    ),
    'waitTicketNo': codeRole('WAIT', width: 3),
    'noShowNote': textRole(
      ['도착 확인이 없는 예시 대기 기록입니다.', '안내 시각 이후 미방문으로 표시했습니다.'],
      [
        'Example queue record without arrival confirmation.',
        'Example absence after the announced time.',
      ],
    ),
    'loyaltyBenefit': textRole(
      ['다섯 번째 방문 음료(예시)', '단골 디저트 쿠폰(예시)'],
      ['Fifth visit drink (example)', 'Regular guest dessert coupon (example)'],
    ),
    'districtName': textRole(
      ['가상시 솔빛동', '가상시 가람동'],
      ['Fictional city, Solbit district', 'Fictional city, Garam district'],
    ),
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

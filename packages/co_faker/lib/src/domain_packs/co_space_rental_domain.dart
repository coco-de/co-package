import '../domain.dart';
import 'authored_roles.dart';

/// Fictional neighborhoods, rental spaces, house rules and host messages.
class CoSpaceRentalDomain extends CoFakerDomain {
  /// Creates this pack.
  const CoSpaceRentalDomain();
  @override
  String get name => 'space_rental';
  @override
  Map<String, CoDomainRole> get roles => {
    'spaceName': textRole(
      ['오후네시 파티룸(가상)', '솔빛 스터디룸(가상)', '가람 연습실(가상)'],
      [
        'Four oclock party room (fictional)',
        'Solbit study room (fictional)',
        'Garam rehearsal room (fictional)',
      ],
    ),
    'spaceCategory': enumRole(['study', 'party', 'practice']),
    'districtName': textRole(
      ['가상시 솔빛동', '가상시 가람동', '가상시 물푸레동'],
      [
        'Fictional city, Solbit district',
        'Fictional city, Garam district',
        'Fictional city, Mulpare district',
      ],
    ),
    'amenity': textRole(
      ['무선 인터넷', '화이트보드', '정수기'],
      ['Wi-Fi', 'Whiteboard', 'Water dispenser'],
    ),
    'equipmentOption': textRole(
      ['빔프로젝터(예시)', '음향 장비(예시)', '주차 1대(예시)'],
      [
        'Projector (example)',
        'Sound equipment (example)',
        'One parking spot (example)',
      ],
    ),
    'houseRule': textRole(
      ['이용 후 물품을 제자리에 놓아 주세요.', '예약한 이용 시간을 지켜 주세요.'],
      ['Please return equipment after use.', 'Please keep to the booked time.'],
    ),
    'refundPolicyLabel': enumRole(['standard', 'flexible', 'strict']),
    'hostName': firstNameRole(),
    'bookingPurpose': textRole(
      ['스터디 모임', '친구 모임', '합주 연습'],
      ['Study gathering', 'Friends gathering', 'Band rehearsal'],
    ),
    'guestMessage': textRole(
      ['장비 이용 방법을 확인하고 싶어요.', '입실 안내를 부탁드립니다.'],
      [
        'Could I check how to use the equipment?',
        'Please share the entry instructions.',
      ],
    ),
    'hostReply': textRole(
      ['예약 화면의 장비 안내를 확인해 주세요.', '입실 안내는 예약 상세에 표시됩니다.'],
      [
        'Please see the equipment guide on the booking page.',
        'Entry instructions appear in the booking details.',
      ],
    ),
  };
  @override
  Map<String, Map<String, String>> get entities => const {
    'rental_space': {
      'id': 'int',
      'name': 'String',
      'category': 'String',
      'district': 'String',
      'refundPolicy': 'String',
      'hostName': 'String',
      'imageUrl': 'String',
    },
    'space_booking': {
      'id': 'int',
      'spaceId': 'int',
      'bookingNo': 'String',
      'purpose': 'String',
      'status': 'String',
    },
  };
  @override
  Map<String, Map<String, String>> get entityRoles => const {
    'rental_space': {
      'name': 'spaceName',
      'category': 'spaceCategory',
      'district': 'districtName',
      'refundPolicy': 'refundPolicyLabel',
      'hostName': 'hostName',
    },
    'space_booking': {
      'bookingNo': 'booking.bookingNo',
      'purpose': 'bookingPurpose',
    },
  };
  @override
  Map<String, Map<String, List<String>>> get enums => const {
    'space_booking': {
      'status': [
        'requested',
        'approved',
        'declined',
        'cancelled',
        'expired',
        'completed',
      ],
    },
  };
}

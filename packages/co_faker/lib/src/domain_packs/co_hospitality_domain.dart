import '../domain.dart';
import 'authored_roles.dart';

/// Fictional stay/housekeeping/concierge labels, masked guests and generic menus.
class CoHospitalityDomain extends CoFakerDomain {
  /// Creates the shared hospitality pack.
  const CoHospitalityDomain();
  @override
  String get name => 'hospitality';
  @override
  Map<String, CoDomainRole> get roles => {
    'propertyName': textRole(
      ['솔숲 머묾터(가상)', '가람 쉼터호텔(가상)', '물푸레 작은숙소(가상)'],
      [
        'Pine stay grounds (fictional)',
        'Garam rest hotel (fictional)',
        'Mulpare small lodge (fictional)',
      ],
    ),
    'siteName': textRole(
      ['솔바람 A동(가상)', '솔향 B동(가상)', '솔방울 C동(가상)'],
      [
        'Pine Breeze site A (fictional)',
        'Pine Scent site B (fictional)',
        'Pine Cone site C (fictional)',
      ],
    ),
    'siteType': enumRole(['glamping', 'caravan', 'auto_camping']),
    'amenity': textRole(
      ['개별 바비큐 공간', '공용 샤워실', '무선 인터넷'],
      ['Private barbecue area', 'Shared shower room', 'Wi-Fi'],
    ),
    'stayOption': textRole(
      ['바비큐 그릴 세트(예시)', '장작 묶음(예시)', '조기 체크인(예시)'],
      [
        'Barbecue grill set (example)',
        'Firewood bundle (example)',
        'Early check-in (example)',
      ],
    ),
    'seasonName': textRole(
      ['기본 기간', '명절 성수기(예시)', '주중 특가 기간(예시)'],
      [
        'Regular season',
        'Holiday high season (example)',
        'Weekday offer season (example)',
      ],
    ),
    'ratePlan': textRole(
      ['기본 예시 요금', '조식 포함 예시 요금', '주중 예시 요금'],
      [
        'Standard example rate',
        'Breakfast example rate',
        'Weekday example rate',
      ],
    ),
    'guestName': maskedNameRole(),
    'bookingNo': codeRole('DEMO-STAY', dated: true),
    'houseRule': textRole(
      ['밤에는 공용 공간에서 조용히 이용해 주세요.', '퇴실할 때 예시 체크리스트를 확인해 주세요.'],
      [
        'Please keep shared spaces quiet at night.',
        'Please review the example departure checklist.',
      ],
    ),
    'reviewSnippet': textRole(
      ['예시 객실 안내를 편하게 확인했어요.', '가상 숙소의 이용 안내가 정리되어 있어요.'],
      [
        'The example room instructions were easy to read.',
        'The fictional property instructions are organized.',
      ],
    ),
    'roomNo': authoredRole(
      (f, c) =>
          '${3 + c.index ~/ 12 % 10}${(1 + c.index % 12).toString().padLeft(2, '0')}',
    ),
    'roomType': enumRole([
      'standard_double',
      'standard_twin',
      'deluxe',
      'suite',
    ]),
    'bedType': authoredRole(
      (f, c) => ['double', 'twin', 'double', 'double'][c.index % 4],
      coherent: true,
    ),
    'housekeepingStatus': enumRole([
      'occupied',
      'vacant_ready',
      'vacant_dirty',
      'cleaning',
      'inspection',
      'out_of_order',
    ]),
    'cleanType': enumRole(['checkout_clean', 'stayover_clean', 'turndown']),
    'hkCheckItem': textRole(
      ['침구 교체', '욕실 정리', '어메니티 확인', '미니바 확인'],
      ['Change bedding', 'Clean bathroom', 'Check amenities', 'Check minibar'],
    ),
    'maintenanceCategory': enumRole([
      'plumbing',
      'electrical',
      'hvac',
      'furniture',
      'other',
    ]),
    'maintenanceIssue': textRole(
      ['욕실 누수 확인(예시)', '전등 점검 요청(예시)', '냉난방 표시 확인(예시)', '가구 파손 확인(예시)'],
      [
        'Bathroom leak check (example)',
        'Light inspection request (example)',
        'Heating display check (example)',
        'Furniture damage check (example)',
      ],
    ),
    'lostItemName': textRole(
      ['파란 우산', '회색 목도리', '책 한 권', '물병'],
      ['Blue umbrella', 'Gray scarf', 'One book', 'Water bottle'],
    ),
    'confirmationNo': codeRole('DEMO-CONF', dated: true),
    'specialRequest': textRole(
      ['고층 · 금연(예시)', '추가 베개 요청(예시)', '조용한 객실 요청(예시)'],
      [
        'High floor, non-smoking (example)',
        'Extra pillow request (example)',
        'Quiet room request (example)',
      ],
    ),
    'menuItem': textRole(
      ['미역국 정식', '채소 파스타', '과일 요거트', '따뜻한 차'],
      ['Seaweed soup meal', 'Vegetable pasta', 'Fruit yogurt', 'Warm tea'],
    ),
    'menuOption': textRole(
      ['밥 적게', '밥 보통', '반찬 추가(예시)', '얼음 없음'],
      ['Less rice', 'Regular rice', 'Extra side dish (example)', 'No ice'],
    ),
    'requestType': enumRole([
      'amenity',
      'housekeeping',
      'wake_up',
      'repair',
      'other',
    ]),
    'amenityName': textRole(
      ['수건', '생수', '칫솔', '베개'],
      ['Towel', 'Water', 'Toothbrush', 'Pillow'],
    ),
    'localSpot': textRole(
      ['아침 국밥집(가상)', '골목 카페(가상)', '솔빛 산책길(가상)'],
      [
        'Morning soup shop (fictional)',
        'Lane cafe (fictional)',
        'Solbit walking path (fictional)',
      ],
    ),
    'conciergeReply': textRole(
      [
        '가상 숙소의 이용 안내는 투숙 상세에서 확인할 수 있습니다.',
        '요청 내용을 예시 대장에 기록했습니다.',
        '주변 장소는 모두 데모용 가상 장소입니다.',
      ],
      [
        'Fictional property instructions appear in stay details.',
        'Recorded the request in the example register.',
        'Nearby places are all fictional demo locations.',
      ],
    ),
    'folioItem': textRole(
      ['객실료(예시)', '룸서비스(예시)', '추가 옵션(예시)'],
      [
        'Room charge (example)',
        'Room service (example)',
        'Extra option (example)',
      ],
    ),
  };
  @override
  Map<String, Map<String, String>> get entities => const {
    'campsite': {
      'id': 'int',
      'name': 'String',
      'siteType': 'String',
      'status': 'String',
    },
    'stay_booking': {
      'id': 'int',
      'siteId': 'int',
      'bookingNo': 'String',
      'guestName': 'String',
      'status': 'String',
    },
    'hotel_room': {
      'id': 'int',
      'roomNo': 'String',
      'roomType': 'String',
      'bedType': 'String',
      'status': 'String',
    },
    'guest_request': {
      'id': 'int',
      'stayId': 'int',
      'requestType': 'String',
      'amenityName': 'String',
      'status': 'String',
    },
  };
  @override
  Map<String, Map<String, String>> get entityRoles => const {
    'campsite': {'name': 'siteName', 'siteType': 'siteType'},
    'stay_booking': {'bookingNo': 'bookingNo', 'guestName': 'guestName'},
    'hotel_room': {
      'roomNo': 'roomNo',
      'roomType': 'roomType',
      'bedType': 'bedType',
      'status': 'housekeepingStatus',
    },
    'guest_request': {
      'requestType': 'requestType',
      'amenityName': 'amenityName',
    },
  };
  @override
  Map<String, Map<String, List<String>>> get enums => const {
    'campsite': {
      'status': ['on_sale', 'paused'],
    },
    'stay_booking': {
      'status': [
        'requested',
        'confirmed',
        'completed',
        'canceled',
        'declined',
        'no_show',
      ],
    },
    'guest_request': {
      'status': [
        'submitted',
        'acknowledged',
        'in_progress',
        'done',
        'canceled',
      ],
    },
  };
}

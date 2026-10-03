import '../domain.dart';
import 'authored_roles.dart';

/// Fictional campaign brand/coupon copy and recipe-aligned delivery enums.
class CoCampaignDomain extends CoFakerDomain {
  /// Creates this pack.
  const CoCampaignDomain();
  @override
  String get name => 'campaign';
  @override
  Map<String, CoDomainRole> get roles => {
    'brandName': textRole(
      ['봄빛베이커리(가상)', '달빛책방(가상)', '초록정원카페(가상)'],
      [
        'Springlight bakery (fictional)',
        'Moonlight bookshop (fictional)',
        'Green Garden cafe (fictional)',
      ],
    ),
    'campaignTitle': textRole(
      ['겨울 예시 혜택 안내', '첫 방문 예시 소식', '주말 예시 소식'],
      [
        'Winter example offer',
        'First visit example news',
        'Weekend example news',
      ],
    ),
    'offerCopy': textRole(
      [
        '(광고) 가상 겨울 메뉴의 예시 쿠폰입니다. 수신 거부는 데모 설정에서 확인해 주세요.',
        '(광고) 가상 상품의 예시 혜택을 안내합니다. 수신 거부는 데모 설정에 있습니다.',
      ],
      [
        '(Ad) Example coupon for a fictional winter menu. See demo settings for opt-out.',
        '(Ad) Example offer for a fictional product. Opt-out is in demo settings.',
      ],
    ),
    'couponTitle': textRole(
      ['겨울 20% 예시 쿠폰', '첫 방문 10% 예시 쿠폰'],
      ['Winter 20% example coupon', 'First visit 10% example coupon'],
    ),
    'segmentName': textRole(
      ['최근 30일 예시 구매자', '광고 동의 예시 그룹', '주말 소식 예시 그룹'],
      [
        'Example buyers in the last 30 days',
        'Example opted-in group',
        'Example weekend-news group',
      ],
    ),
    'failReason': textRole(
      ['수신 번호 없음(예시)', '광고 동의 없음(예시)', '야간 동의 없음(예시)'],
      [
        'Missing recipient number (example)',
        'No marketing consent (example)',
        'No night-time consent (example)',
      ],
    ),
    'messageChannel': enumRole(['alimtalk', 'sms', 'push']),
    'messageStatus': enumRole(['queued', 'delivered', 'failed', 'excluded']),
  };
  @override
  Map<String, Map<String, String>> get entities => const {
    'campaign': {
      'id': 'int',
      'title': 'String',
      'brandName': 'String',
      'channel': 'String',
      'status': 'String',
    },
    'send_log': {
      'id': 'int',
      'campaignId': 'int',
      'channel': 'String',
      'messageStatus': 'String',
    },
  };
  @override
  Map<String, Map<String, String>> get entityRoles => const {
    'campaign': {
      'title': 'campaignTitle',
      'brandName': 'brandName',
      'channel': 'messageChannel',
    },
    'send_log': {'channel': 'messageChannel', 'messageStatus': 'messageStatus'},
  };
  @override
  Map<String, Map<String, List<String>>> get enums => const {
    'campaign': {
      'status': [
        'draft',
        'in_review',
        'scheduled',
        'sending',
        'completed',
        'stopped',
      ],
    },
  };
}

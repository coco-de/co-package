import '../domain.dart';
import 'authored_roles.dart';

/// Generic, brand-free group deals and illustrative benefit text.
class CoGroupDealDomain extends CoFakerDomain {
  /// Creates this pack.
  const CoGroupDealDomain();
  @override
  String get name => 'group_deal';
  @override
  Map<String, CoDomainRole> get roles => {
    'dealTitle': textRole(
      ['겨울 감귤 공동구매', '무선 이어폰 공동구매', '면 수건 세트 공동구매'],
      [
        'Winter citrus group deal',
        'Wireless earphone group deal',
        'Cotton towel group deal',
      ],
    ),
    'dealCategory': enumRole([
      'fresh',
      'pantry',
      'living',
      'digital',
      'beauty',
    ]),
    'optionLabel': textRole(
      ['일반 크기', '선물 포장', '기본 색상'],
      ['Regular size', 'Gift wrapping', 'Standard color'],
    ),
    'inviteCode': authoredRole(
      (f, _) =>
          'MOA-${f.random.string(4, alphabet: 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789')}',
    ),
    'rewardLabel': textRole(
      ['참여 스탬프', '모의 적립 포인트', '배송 혜택'],
      ['Participation stamp', 'Illustrative reward points', 'Shipping benefit'],
    ),
    'benefitTitle': textRole(
      ['무료배송 예시 쿠폰', '다음 참여 예시 쿠폰'],
      ['Example free shipping coupon', 'Example next deal coupon'],
    ),
    'tierName': enumRole(['bronze', 'silver', 'gold']),
    'settleNote': textRole(
      ['성사한 참여 건을 집계한 예시입니다.', '취소한 참여 건은 집계에서 뺀 예시입니다.'],
      [
        'Example total of successful participations.',
        'Example total excluding canceled participations.',
      ],
    ),
  };
  @override
  Map<String, Map<String, String>> get entities => const {
    'group_deal': {
      'id': 'int',
      'title': 'String',
      'category': 'String',
      'imageUrl': 'String',
      'status': 'String',
    },
    'deal_participation': {
      'id': 'int',
      'dealId': 'int',
      'inviteCode': 'String',
      'status': 'String',
    },
  };
  @override
  Map<String, Map<String, String>> get entityRoles => const {
    'group_deal': {'title': 'dealTitle', 'category': 'dealCategory'},
    'deal_participation': {'inviteCode': 'inviteCode'},
  };
  @override
  Map<String, Map<String, List<String>>> get enums => const {
    'group_deal': {
      'status': [
        'scheduled',
        'open',
        'succeeded',
        'shipping',
        'closed',
        'failed',
        'cancelled',
      ],
    },
    'deal_participation': {
      'status': [
        'joined',
        'confirmed',
        'shipped',
        'delivered',
        'refunded',
        'cancelled',
      ],
    },
  };
}

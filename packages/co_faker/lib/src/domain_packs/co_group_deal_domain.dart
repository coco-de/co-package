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
    'dealTitle': textRole('group_deal.dealTitle'),
    'dealCategory': enumRole([
      'fresh',
      'pantry',
      'living',
      'digital',
      'beauty',
    ]),
    'optionLabel': textRole('group_deal.optionLabel'),
    'inviteCode': authoredRole(
      (f, _) =>
          'MOA-${f.random.string(4, alphabet: 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789')}',
    ),
    'rewardLabel': textRole('group_deal.rewardLabel'),
    'benefitTitle': textRole('group_deal.benefitTitle'),
    'tierName': enumRole(['bronze', 'silver', 'gold']),
    'settleNote': textRole('group_deal.settleNote'),
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

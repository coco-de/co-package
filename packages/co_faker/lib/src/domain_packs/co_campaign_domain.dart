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
    'brandName': textRole('campaign.brandName'),
    'campaignTitle': textRole('campaign.campaignTitle'),
    'offerCopy': textRole('campaign.offerCopy'),
    'couponTitle': textRole('campaign.couponTitle'),
    'segmentName': textRole('campaign.segmentName'),
    'failReason': textRole('campaign.failReason'),
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

import '../domain.dart';
import 'authored_roles.dart';

/// Fictional local-community text and explicitly fictional place labels.
class CoNeighborhoodDomain extends CoFakerDomain {
  /// Creates this pack.
  const CoNeighborhoodDomain();
  @override
  String get name => 'neighborhood';
  @override
  Map<String, CoDomainRole> get roles => {
    'neighborhoodName': textRole('neighborhood.neighborhoodName'),
    'districtName': textRole('neighborhood.districtName'),
    'nickname': textRole('neighborhood.nickname'),
    'postKind': enumRole([
      'news',
      'question',
      'lost_found',
      'local_shop',
      'giveaway',
    ]),
    'postTitle': textRole('neighborhood.postTitle'),
    'postBody': textRole('neighborhood.postBody'),
    'commentBody': textRole('neighborhood.commentBody'),
    'placeName': textRole('neighborhood.placeName'),
    'placeKind': enumRole([
      'shop',
      'lost_spot',
      'news_spot',
      'public_facility',
    ]),
    'openHours': textRole('neighborhood.openHours'),
    'reportReason': enumRole([
      'spam_ad',
      'abuse',
      'contact_exposed',
      'false_info',
      'other',
    ]),
    'bannedWord': textRole('neighborhood.bannedWord'),
    'keyword': textRole('neighborhood.keyword'),
  };
  @override
  Map<String, Map<String, String>> get entities => const {
    'neighborhood': {'id': 'int', 'name': 'String', 'districtName': 'String'},
    'local_post': {
      'id': 'int',
      'neighborhoodId': 'int',
      'title': 'String',
      'body': 'String',
      'kind': 'String',
      'authorNickname': 'String',
      'status': 'String',
    },
    'local_place': {
      'id': 'int',
      'neighborhoodId': 'int',
      'name': 'String',
      'kind': 'String',
      'openHours': 'String',
    },
    'post_comment': {
      'id': 'int',
      'postId': 'int',
      'body': 'String',
      'authorNickname': 'String',
    },
  };
  @override
  Map<String, Map<String, String>> get entityRoles => const {
    'neighborhood': {
      'name': 'neighborhoodName',
      'districtName': 'districtName',
    },
    'local_post': {
      'title': 'postTitle',
      'body': 'postBody',
      'kind': 'postKind',
      'authorNickname': 'nickname',
    },
    'local_place': {
      'name': 'placeName',
      'kind': 'placeKind',
      'openHours': 'openHours',
    },
    'post_comment': {'body': 'commentBody', 'authorNickname': 'nickname'},
  };
  @override
  Map<String, Map<String, List<String>>> get enums => const {
    'local_post': {
      'status': ['published', 'resolved', 'hidden', 'deleted'],
    },
  };
}

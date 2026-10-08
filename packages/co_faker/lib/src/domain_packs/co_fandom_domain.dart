import '../domain.dart';
import 'authored_roles.dart';

/// Fandom text restricted to the two explicitly approved fictional creators.
class CoFandomDomain extends CoFakerDomain {
  /// Creates this pack.
  const CoFandomDomain();
  @override
  String get name => 'fandom';

  /// The approved names of the Korean and English bundles, which both write
  /// them as they always have.
  ///
  /// The role `creatorName` reads the key `fandom.creatorName` of the language
  /// bundle, so another language writes two fictional creator names of its own
  /// there. This constant stays for code that already reads it.
  static const creatorNames = ['모래시계 정원', '하늘결'];
  @override
  Map<String, CoDomainRole> get roles => {
    'creatorName': authoredRole(
      (f, c) => indexedText(f, 'fandom.creatorName', c.index, rows: 2),
      description:
          'One of the two approved fictional creator names, by record index',
    ),
    'fanNickname': textRole('fandom.fanNickname'),
    'tierName': enumRole(['bronze', 'silver', 'gold', 'platinum']),
    'benefitTitle': textRole('fandom.benefitTitle'),
    'postCaption': textRole('fandom.postCaption'),
    'clipTitle': textRole('fandom.clipTitle'),
    'letterBody': textRole('fandom.letterBody'),
    'eventTitle': textRole('fandom.eventTitle'),
    'agendaTitle': textRole('fandom.agendaTitle'),
    'venueLabel': textRole('fandom.venueLabel'),
  };
  @override
  Map<String, Map<String, String>> get entities => const {
    'artist_post': {
      'id': 'int',
      'creatorName': 'String',
      'body': 'String',
      'category': 'String',
      'minTier': 'String',
      'imageUrl': 'String',
      'status': 'String',
    },
    'fan_letter': {
      'id': 'int',
      'creatorName': 'String',
      'body': 'String',
      'status': 'String',
    },
    'membership_card': {'id': 'int', 'tierName': 'String'},
    'fan_event': {'id': 'int', 'title': 'String', 'status': 'String'},
  };
  @override
  Map<String, Map<String, String>> get entityRoles => const {
    'artist_post': {
      'creatorName': 'creatorName',
      'body': 'postCaption',
      'minTier': 'tierName',
    },
    'fan_letter': {'creatorName': 'creatorName', 'body': 'letterBody'},
    'membership_card': {'tierName': 'tierName'},
    'fan_event': {'title': 'eventTitle'},
  };
  @override
  Map<String, Map<String, List<String>>> get enums => const {
    'artist_post': {
      'category': ['notice', 'photo', 'daily', 'clip'],
      'status': ['draft', 'scheduled', 'published', 'archived'],
    },
    'fan_letter': {
      'status': ['submitted', 'screening', 'delivered', 'rejected'],
    },
    'fan_event': {
      'status': ['open', 'closed', 'drawn', 'announced'],
    },
  };
}

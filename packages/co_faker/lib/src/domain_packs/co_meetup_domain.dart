import '../domain.dart';
import 'authored_roles.dart';

/// Fictional clubs, gathering labels, example dues and authored community rules.
class CoMeetupDomain extends CoFakerDomain {
  /// Creates this pack.
  const CoMeetupDomain();
  @override
  String get name => 'meetup';
  @override
  Map<String, CoDomainRole> get roles => {
    'clubName': textRole('meetup.clubName'),
    'interestTag': textRole('meetup.interestTag'),
    'clubIntro': textRole('meetup.clubIntro'),
    'gatheringTitle': textRole('meetup.gatheringTitle'),
    'venueName': textRole('meetup.venueName'),
    'nickname': textRole('meetup.nickname'),
    'duesItem': textRole('meetup.duesItem'),
    'duesAmount': intRole(1000, 20000, step: 1000),
    'joinAnswer': textRole('meetup.joinAnswer'),
    'ruleText': textRole('meetup.ruleText'),
    'cadenceLabel': textRole('meetup.cadenceLabel'),
  };
  @override
  Map<String, Map<String, String>> get entities => const {
    'club': {
      'id': 'int',
      'name': 'String',
      'intro': 'String',
      'interest': 'String',
      'cadenceLabel': 'String',
      'joinPolicy': 'String',
    },
    'gathering': {
      'id': 'int',
      'clubId': 'int',
      'title': 'String',
      'venueLabel': 'String',
      'status': 'String',
    },
    'club_member': {
      'id': 'int',
      'clubId': 'int',
      'memberName': 'String',
      'status': 'String',
    },
  };
  @override
  Map<String, Map<String, String>> get entityRoles => const {
    'club': {
      'name': 'clubName',
      'intro': 'clubIntro',
      'interest': 'interestTag',
      'cadenceLabel': 'cadenceLabel',
    },
    'gathering': {'title': 'gatheringTitle', 'venueLabel': 'venueName'},
    'club_member': {'memberName': 'nickname'},
  };
  @override
  Map<String, Map<String, List<String>>> get enums => const {
    'club': {
      'joinPolicy': ['approval', 'open'],
    },
    'gathering': {
      'status': ['draft', 'open', 'closed', 'done', 'canceled'],
    },
    'club_member': {
      'status': [
        'applied',
        'approved',
        'rejected',
        'withdrawn',
        'left',
        'removed',
      ],
    },
  };
}

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
    'clubName': textRole(
      ['솔빛 아침 러닝(가상)', '가람 책 모임(가상)', '물푸레 보드게임(가상)'],
      [
        'Solbit morning run (fictional)',
        'Garam reading group (fictional)',
        'Mulpare board games (fictional)',
      ],
    ),
    'interestTag': textRole(
      ['러닝', '독서', '보드게임', '사진', '요리', '등산'],
      ['Running', 'Reading', 'Board games', 'Photography', 'Cooking', 'Hiking'],
    ),
    'clubIntro': textRole(
      ['처음 참여하는 이웃도 함께하는 가상 모임입니다.', '작은 활동을 함께 나누는 예시 모임입니다.'],
      [
        'Fictional group welcoming first-time neighbors.',
        'Example group sharing small activities together.',
      ],
    ),
    'gatheringTitle': textRole(
      ['1월 셋째 주 정모(가상)', '주말 책 이야기(가상)', '겨울 산책 모임(가상)'],
      [
        'Third January gathering (fictional)',
        'Weekend book conversation (fictional)',
        'Winter walk gathering (fictional)',
      ],
    ),
    'venueName': textRole(
      ['가람 산책길 입구(가상)', '솔빛 작은모임방(가상)', '물푸레 쉼터(가상)'],
      [
        'Garam walking path entrance (fictional)',
        'Solbit gathering room (fictional)',
        'Mulpare shelter (fictional)',
      ],
    ),
    'nickname': textRole(
      ['새벽콩(가상)', '책구름(가상)', '작은별(가상)'],
      [
        'DawnBean (fictional)',
        'BookCloud (fictional)',
        'SmallStar (fictional)',
      ],
    ),
    'duesItem': textRole(
      ['정모 참가비(예시)', '음료 분담(예시)', '장비 대여 분담(예시)'],
      [
        'Gathering fee (example)',
        'Shared drinks (example)',
        'Shared equipment hire (example)',
      ],
    ),
    'duesAmount': intRole(1000, 20000, step: 1000),
    'joinAnswer': textRole(
      ['이번 달부터 함께 활동해 보고 싶어요.', '주말 오전에 참여할 수 있어요.'],
      [
        'I would like to join activities this month.',
        'I can participate on weekend mornings.',
      ],
    ),
    'ruleText': textRole(
      ['서로의 시간을 존중해 주세요.', '연락처 공개 없이 모임 안에서 이야기해 주세요.', '취소할 때 모임에 알려 주세요.'],
      [
        'Please respect each others time.',
        'Please chat within the group without publishing contact details.',
        'Please tell the group when canceling.',
      ],
    ),
    'cadenceLabel': textRole(
      ['매주 토 07:00', '격주 일 10:00', '매월 첫째 토 14:00'],
      [
        'Every Saturday 07:00',
        'Alternate Sundays 10:00',
        'First Saturday each month 14:00',
      ],
    ),
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

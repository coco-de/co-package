import '../domain.dart';
import 'authored_roles.dart';

/// Fandom text restricted to the two explicitly approved fictional creators.
class CoFandomDomain extends CoFakerDomain {
  /// Creates this pack.
  const CoFandomDomain();
  @override
  String get name => 'fandom';

  /// Exact approved names, unchanged across locales.
  static const creatorNames = ['모래시계 정원', '하늘결'];
  @override
  Map<String, CoDomainRole> get roles => {
    'creatorName': enumRole(creatorNames),
    'fanNickname': textRole(
      ['별님', '새싹', '달콩', '빛방울'],
      ['Star', 'Sprout', 'MoonBean', 'LightDrop'],
    ),
    'tierName': enumRole(['bronze', 'silver', 'gold', 'platinum']),
    'benefitTitle': textRole(
      ['멤버 전용 예시 사진', '모의 이벤트 응모', '가상 클립 먼저 보기'],
      [
        'Example member-only picture',
        'Simulated event entry',
        'Early fictional clip preview',
      ],
    ),
    'postCaption': textRole(
      ['겨울 작업실을 그린 가상 일러스트', '연습 시간을 기록한 예시 게시물'],
      [
        'Fictional illustration of a winter studio',
        'Example post about rehearsal time',
      ],
    ),
    'clipTitle': textRole(
      ['리허설 30초(가상)', '작업실 인사(가상)', '겨울 소리 메모(가상)'],
      [
        'Thirty-second rehearsal (fictional)',
        'Studio greeting (fictional)',
        'Winter sound note (fictional)',
      ],
    ),
    'letterBody': textRole(
      [
        '오늘의 예시 게시물을 즐겁게 봤어요. 다음 소식도 기다릴게요.',
        '겨울 작업실 일러스트가 따뜻하게 느껴졌어요. 응원의 마음을 남깁니다.',
      ],
      [
        'I enjoyed todays example post and look forward to the next update.',
        'The winter studio illustration felt warm. Sending encouragement.',
      ],
    ),
    'eventTitle': textRole(
      ['겨울 팬 모임 응모(가상)', '작업실 이야기 이벤트(가상)'],
      ['Winter fan gathering (fictional)', 'Studio stories event (fictional)'],
    ),
    'agendaTitle': textRole(
      ['겨울 소극장 일정(가상)', '가상 방송 이야기', '새 게시물 공개 일정'],
      [
        'Winter small theater schedule (fictional)',
        'Fictional broadcast conversation',
        'New post release schedule',
      ],
    ),
    'venueLabel': textRole(
      ['겨울 소극장(가상)', '솔빛 작업실(가상)', '온라인 예시 공간'],
      [
        'Winter small theater (fictional)',
        'Solbit studio (fictional)',
        'Online example space',
      ],
    ),
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

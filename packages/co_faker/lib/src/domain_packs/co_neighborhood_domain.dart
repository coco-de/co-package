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
    'neighborhoodName': textRole(
      ['솔빛동(가상)', '은행나무동(가상)', '물푸레동(가상)'],
      [
        'Solbit neighborhood (fictional)',
        'Ginkgo neighborhood (fictional)',
        'Mulpare neighborhood (fictional)',
      ],
    ),
    'districtName': textRole(
      ['가상시 가람구', '가상시 솔내구'],
      ['Fictional city, Garam district', 'Fictional city, Solnae district'],
    ),
    'nickname': textRole(
      ['솔빛콩(가상)', '물푸레별(가상)', '골목구름(가상)'],
      [
        'SolbitBean (fictional)',
        'MulpareStar (fictional)',
        'LaneCloud (fictional)',
      ],
    ),
    'postKind': enumRole([
      'news',
      'question',
      'lost_found',
      'local_shop',
      'giveaway',
    ]),
    'postTitle': textRole(
      ['놀이터에서 파란 장갑을 찾았어요(예시)', '동네 산책길을 함께 알아봐요(예시)', '작은 화분을 나눠요(예시)'],
      [
        'Blue glove found at the playground (example)',
        'Exploring a neighborhood walk (example)',
        'Sharing a small planter (example)',
      ],
    ),
    'postBody': textRole(
      [
        '가상의 동네 소식입니다. 자세한 내용은 글 안에서 확인해 주세요.',
        '이웃과 나누기 위한 예시 글입니다. 연락처나 실제 주소는 없습니다.',
      ],
      [
        'Fictional neighborhood news. Details are in this post.',
        'Example post for neighbors; no phone number or real address is included.',
      ],
    ),
    'commentBody': textRole(
      ['소식 알려 주셔서 고마워요.', '확인하고 글에 답글을 남길게요.', '저녁 시간에 확인할 수 있어요.'],
      [
        'Thanks for sharing the update.',
        'I will check and reply in the post.',
        'I can check in the evening.',
      ],
    ),
    'placeName': textRole(
      ['솔빛제과(가상)', '가람공원 쉼터(가상)', '물푸레 작은도서관(가상)'],
      [
        'Solbit bakery (fictional)',
        'Garam park shelter (fictional)',
        'Mulpare small library (fictional)',
      ],
    ),
    'placeKind': enumRole([
      'shop',
      'lost_spot',
      'news_spot',
      'public_facility',
    ]),
    'openHours': textRole(
      ['08:00~21:00', '09:00~18:00', '10:00~20:00'],
      ['08:00–21:00', '09:00–18:00', '10:00–20:00'],
    ),
    'reportReason': enumRole([
      'spam_ad',
      'abuse',
      'contact_exposed',
      'false_info',
      'other',
    ]),
    'bannedWord': textRole(
      ['광고예시', '욕설예시', '금칙어예시'],
      ['advertising-example', 'abuse-example', 'blocked-word-example'],
    ),
    'keyword': textRole(
      ['장갑', '산책', '나눔', '동네 소식'],
      ['glove', 'walk', 'sharing', 'local news'],
    ),
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

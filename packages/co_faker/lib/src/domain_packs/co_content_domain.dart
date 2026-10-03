import '../domain.dart';
import 'authored_roles.dart';

/// Authored fictional works and prose, shared by comics, audio and newsletters.
class CoContentDomain extends CoFakerDomain {
  /// Creates this pack.
  const CoContentDomain();
  @override
  String get name => 'content';
  @override
  Map<String, CoDomainRole> get roles => {
    'seriesTitle': textRole(
      ['종이등대의 우편 섬(가상)', '구름연못의 작은 지도(가상)', '느린 시계의 화원(가상)'],
      [
        'Postal island of the paper lighthouse (fictional)',
        'Small map of the cloud pond (fictional)',
        'Garden of the slow clock (fictional)',
      ],
    ),
    'penName': textRole(
      ['글콩(가상)', '종이별(가상)', '구름펜(가상)'],
      ['WordBean (fictional)', 'PaperStar (fictional)', 'CloudPen (fictional)'],
    ),
    'synopsisLine': textRole(
      ['작은 섬에서 편지를 정리하는 가상 인물들의 이야기입니다.', '지도에 없는 연못을 함께 그려 보는 가상의 이야기입니다.'],
      [
        'Fictional characters organize letters on a small island.',
        'A fictional story about drawing a pond absent from the map.',
      ],
    ),
    'genreName': textRole(
      ['판타지', '일상', '모험', '과학 이야기', '에세이'],
      ['Fantasy', 'Everyday life', 'Adventure', 'Science stories', 'Essay'],
    ),
    'episodeTitle': textRole(
      ['첫 번째 종이 배(가상)', '연못의 작은 점(가상)', '시계 없는 오후(가상)'],
      [
        'The first paper boat (fictional)',
        'A small dot on the pond (fictional)',
        'An afternoon without a clock (fictional)',
      ],
    ),
    'cutAltText': textRole(
      ['가상 인물이 종이 배를 접는 일러스트', '연못 옆 가상 인물 둘의 일러스트'],
      [
        'Illustration of a fictional character folding a paper boat',
        'Illustration of two fictional characters beside a pond',
      ],
    ),
    'commentLine': textRole(
      ['종이 배 장면이 기억에 남아요.', '다음 예시 회차도 읽어 보고 싶어요.'],
      [
        'The paper boat scene stayed with me.',
        'I would like to read the next example episode.',
      ],
    ),
    'chapterParagraph': textRole(
      [
        '섬의 우편함에는 빈 종이 한 장이 놓여 있었다. 아이는 종이를 반으로 접고, 연못을 닮은 작은 배를 만들었다. 이 단락은 데모를 위해 직접 쓴 가상 문장이다.',
        '느린 시계 옆에는 작은 화분이 있었다. 두 친구는 화분 이름을 정하는 대신 오늘 본 구름을 그림으로 남겼다. 이 단락은 직접 작성한 가상 예시다.',
      ],
      [
        'A blank sheet lay in the island mailbox. A child folded it into a small boat shaped like the pond. This paragraph is an original fictional demo example.',
        'A small planter stood beside the slow clock. Two friends drew the clouds they had seen instead of naming the plant. This is an original fictional example paragraph.',
      ],
    ),
    'publisherName': textRole(
      ['종이등대 출판소(가상)', '구름연못 출판소(가상)'],
      [
        'Paper Lighthouse publishing (fictional)',
        'Cloud Pond publishing (fictional)',
      ],
    ),
    'narratorName': firstNameRole(),
    'audioTitle': textRole(
      ['종이 배를 접는 오후(가상)', '작은 연못의 소리 메모(가상)'],
      [
        'An afternoon folding paper boats (fictional)',
        'Sound notes of a small pond (fictional)',
      ],
    ),
    'newsletterName': textRole(
      ['종이등대 주간 메모(가상)', '구름연못 작은 편지(가상)'],
      [
        'Paper Lighthouse weekly notes (fictional)',
        'Cloud Pond small letters (fictional)',
      ],
    ),
    'articleHeadline': textRole(
      ['일상 기록을 작은 묶음으로 정리하기(가상)', '겨울 산책의 색을 남기는 방법(가상)'],
      [
        'Organizing everyday notes into small groups (fictional)',
        'Recording colors from a winter walk (fictional)',
      ],
    ),
    'topicName': textRole(
      ['일상 기록', '겨울 산책', '작은 과학', '읽기 습관'],
      ['Everyday notes', 'Winter walks', 'Small science', 'Reading habits'],
    ),
    'genreParent': parentRole(5),
    'audioGenreParent': parentRole(2),
    'topicParent': parentRole(5),
    'genreTaxonomy': taxonomyRole(
      ['판타지', '일상', '모험', '과학 이야기', '에세이'],
      ['Fantasy', 'Everyday life', 'Adventure', 'Science stories', 'Essay'],
    ),
    'audioTaxonomy': taxonomyRole(['오디오북', '팟캐스트'], ['Audiobook', 'Podcast']),
    'topicTaxonomy': taxonomyRole(
      ['일상 기록', '겨울 산책', '작은 과학', '읽기 습관', '생활 관찰'],
      [
        'Everyday notes',
        'Winter walks',
        'Small science',
        'Reading habits',
        'Life observations',
      ],
    ),
  };
  @override
  Map<String, Map<String, String>> get entities => const {
    'series': {
      'id': 'int',
      'title': 'String',
      'authorName': 'String',
      'synopsis': 'String',
      'genre': 'String',
    },
    'episode': {
      'id': 'int',
      'seriesId': 'int',
      'title': 'String',
      'status': 'String',
    },
    'audiobook': {'id': 'int', 'title': 'String', 'narratorName': 'String'},
    'letter_article': {
      'id': 'int',
      'authorId': 'int',
      'title': 'String',
      'body': 'String',
    },
    'series_genre': {'id': 'int', 'name': 'String', 'parentId': 'int'},
    'audio_genre': {'id': 'int', 'name': 'String', 'parentId': 'int'},
    'letter_topic': {'id': 'int', 'name': 'String', 'parentId': 'int'},
  };
  @override
  Map<String, Map<String, String>> get entityRoles => const {
    'series': {
      'title': 'seriesTitle',
      'authorName': 'penName',
      'synopsis': 'synopsisLine',
      'genre': 'genreName',
    },
    'episode': {'title': 'episodeTitle'},
    'audiobook': {'title': 'audioTitle', 'narratorName': 'narratorName'},
    'letter_article': {'title': 'articleHeadline', 'body': 'chapterParagraph'},
    'series_genre': {'name': 'genreTaxonomy', 'parentId': 'genreParent'},
    'audio_genre': {'name': 'audioTaxonomy', 'parentId': 'audioGenreParent'},
    'letter_topic': {'name': 'topicTaxonomy', 'parentId': 'topicParent'},
  };
  @override
  Map<String, Map<String, List<String>>> get enums => const {
    'episode': {
      'status': ['draft', 'in_review', 'published', 'archived'],
    },
  };
}

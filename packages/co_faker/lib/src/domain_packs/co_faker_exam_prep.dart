import '../co_faker.dart';
import 'co_fake_exam_question.dart';

/// General IT questions authored for the package, not copied from exams/books.
class CoFakerExamPrep {
  /// Uses only the supplied faker.
  const CoFakerExamPrep(this.faker);

  /// Locale and shuffle source.
  final CoFaker faker;

  /// Complete recipe section set.
  static const sections = [
    'db_model',
    'db_sql',
    'nw_transport',
    'nw_routing',
    'nw_app',
    'pg_basic',
    'pg_struct',
    'sec_crypto',
    'sec_access',
  ];
  static const _ko = <(String, String, String, List<String>, String)>[
    (
      '데이터베이스',
      '데이터 모델',
      '표의 각 행을 구분하는 키는 무엇인가요?',
      ['기본 키', '글꼴', '배경색', '화면 너비'],
      '기본 키는 표의 각 행을 구분하는 식별자입니다.',
    ),
    (
      '데이터베이스',
      'SQL 기초',
      '조건에 맞는 행을 조회할 때 쓰는 SQL 절은 무엇인가요?',
      ['WHERE', '글꼴', '여백', '아이콘'],
      'WHERE 절은 조회할 행의 조건을 표현합니다.',
    ),
    (
      '네트워크',
      '전송 계층',
      '순서와 재전송을 제공하는 전송 프로토콜은 무엇인가요?',
      ['TCP', 'JPEG', 'CSS', 'SVG'],
      'TCP는 바이트 스트림의 순서와 재전송을 처리합니다.',
    ),
    (
      '네트워크',
      '경로 선택',
      '목적지에 따라 패킷의 다음 경로를 고르는 장비는 무엇인가요?',
      ['라우터', '스피커', '키보드', '모니터'],
      '라우터는 목적지 주소를 바탕으로 다음 경로를 선택합니다.',
    ),
    (
      '네트워크',
      '응용 계층',
      '웹 요청과 응답을 주고받는 프로토콜은 무엇인가요?',
      ['HTTP', 'PNG', 'MP3', 'TTF'],
      'HTTP는 웹 요청과 응답을 표현하는 응용 프로토콜입니다.',
    ),
    (
      '프로그래밍 기초',
      '변수',
      '프로그램에서 값을 이름으로 보관하는 요소는 무엇인가요?',
      ['변수', '테두리', '페이지 여백', '배경 이미지'],
      '변수는 프로그램에서 값을 이름으로 참조하도록 합니다.',
    ),
    (
      '프로그래밍 기초',
      '자료 구조',
      '나중에 넣은 값부터 꺼내는 자료 구조는 무엇인가요?',
      ['스택', '선입선출 큐', '이미지', '음성 파일'],
      '스택은 나중에 넣은 값을 먼저 꺼내는 구조입니다.',
    ),
    (
      '정보보안',
      '암호 기초',
      '고정 길이 요약 값을 만드는 함수는 무엇인가요?',
      ['해시 함수', '글꼴 선택', '화면 확대', '배경 채우기'],
      '해시 함수는 입력으로부터 고정 길이 요약 값을 계산합니다.',
    ),
    (
      '정보보안',
      '접근 제어',
      '업무에 필요한 권한만 부여하는 원칙은 무엇인가요?',
      ['최소 권한', '전체 공개', '공유 비밀번호', '검사 생략'],
      '최소 권한은 업무에 필요한 권한만 부여하는 원칙입니다.',
    ),
  ];
  static const _en = <(String, String, String, List<String>, String)>[
    (
      'Database',
      'Data modeling',
      'Which key distinguishes rows in a table?',
      ['Primary key', 'Font', 'Background color', 'Screen width'],
      'A Primary key identifies each row in a table.',
    ),
    (
      'Database',
      'SQL basics',
      'Which SQL clause selects rows by a condition?',
      ['WHERE', 'Font', 'Margin', 'Icon'],
      'The WHERE clause expresses a condition for selected rows.',
    ),
    (
      'Networking',
      'Transport layer',
      'Which transport protocol handles ordering and retransmission?',
      ['TCP', 'JPEG', 'CSS', 'SVG'],
      'TCP handles ordering and retransmission of a byte stream.',
    ),
    (
      'Networking',
      'Routing',
      'Which device selects the next packet route?',
      ['Router', 'Speaker', 'Keyboard', 'Monitor'],
      'A Router selects the next route using the destination address.',
    ),
    (
      'Networking',
      'Application layer',
      'Which protocol expresses web requests and responses?',
      ['HTTP', 'PNG', 'MP3', 'TTF'],
      'HTTP expresses web requests and responses.',
    ),
    (
      'Programming basics',
      'Variables',
      'What stores a value under a program name?',
      ['Variable', 'Border', 'Page margin', 'Background image'],
      'A Variable lets a program refer to a value by name.',
    ),
    (
      'Programming basics',
      'Data structures',
      'Which structure removes the last inserted value first?',
      ['Stack', 'FIFO queue', 'Image', 'Audio file'],
      'A Stack removes the last inserted value first.',
    ),
    (
      'Information security',
      'Cryptography basics',
      'What computes a fixed-length summary of an input?',
      ['Hash function', 'Font selection', 'Screen zoom', 'Background fill'],
      'A Hash function computes a fixed-length summary of an input.',
    ),
    (
      'Information security',
      'Access control',
      'Which principle grants only the permissions needed for a task?',
      ['Least privilege', 'Public access', 'Shared password', 'Skipped checks'],
      'Least privilege grants only the permissions needed for a task.',
    ),
  ];

  /// Returns a question with a seeded choice shuffle and matching answer keys.
  CoFakeExamQuestion question({int? index}) {
    if (index != null && index < 0) {
      throw ArgumentError.value(index, 'index');
    }
    final slot = index == null
        ? faker.random.int(max: sections.length - 1)
        : index % sections.length;
    final spec = (faker.locale.startsWith('ko') ? _ko : _en)[slot];
    final order = [0, 1, 2, 3];
    for (var i = order.length - 1; i > 0; i--) {
      final other = faker.random.int(max: i);
      final temp = order[i];
      order[i] = order[other];
      order[other] = temp;
    }
    return CoFakeExamQuestion(
      subjectName: spec.$1,
      unitName: spec.$2,
      section: sections[slot],
      stem: spec.$3,
      choices: List.unmodifiable(order.map((i) => spec.$4[i])),
      answerKeys: List.unmodifiable([order.indexOf(0) + 1]),
      explanation: spec.$5,
      difficulty: ['easy', 'normal', 'hard'][slot % 3],
    );
  }
}

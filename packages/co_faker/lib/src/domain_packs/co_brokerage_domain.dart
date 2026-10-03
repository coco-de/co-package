import '../domain.dart';
import 'authored_roles.dart';

/// Fictional service providers and general-information-only consultation text.
class CoBrokerageDomain extends CoFakerDomain {
  /// Creates the three-recipe brokerage pack.
  const CoBrokerageDomain();
  @override
  String get name => 'brokerage';
  @override
  Map<String, CoDomainRole> get roles => {
    'projectTitle': textRole(
      ['예시 고객 포털 제작', '가상 서비스 화면 정비', '예시 예약 화면 제작'],
      [
        'Example customer portal build',
        'Fictional service screen refresh',
        'Example booking screen build',
      ],
    ),
    'serviceCategory': textRole(
      ['웹 화면 제작', '앱 화면 제작', '업무 디자인', '생활 서비스'],
      ['Web interface', 'App interface', 'Workplace design', 'Home service'],
    ),
    'providerName': textRole(
      ['코드다락 스튜디오(가상)', '솔빛 화면공방(가상)', '가람 생활공방(가상)'],
      [
        'Code Attic studio (fictional)',
        'Solbit interface workshop (fictional)',
        'Garam home workshop (fictional)',
      ],
    ),
    'providerHeadline': textRole(
      ['예시 화면과 작업 기록을 소개하는 가상 파트너', '가상 프로젝트의 범위를 함께 확인하는 예시 프로필'],
      [
        'Fictional partner showing example screens and work records',
        'Example profile for reviewing a fictional project scope',
      ],
    ),
    'skillTag': textRole(
      ['Dart', '화면 설계', '데이터 정리', '문구 작성'],
      ['Dart', 'Interface planning', 'Data organization', 'Copy writing'],
    ),
    'proposalMessage': textRole(
      ['예시 작업 범위와 일정 확인 항목을 정리했습니다.', '가상 프로젝트의 단계별 확인 항목을 제안합니다.'],
      [
        'Prepared scope and schedule checkpoints for the example.',
        'Proposing checkpoints for the fictional project stages.',
      ],
    ),
    'portfolioTitle': textRole(
      ['가상 고객 포털 예시', '예시 예약 화면 기록', '가상 업무 표 개선'],
      [
        'Fictional customer portal example',
        'Example booking screen record',
        'Fictional work table improvement',
      ],
    ),
    'milestoneLabel': textRole(
      ['범위 확인', '화면 초안 확인', '예시 기능 확인', '인계 기록'],
      [
        'Scope check',
        'Screen draft check',
        'Example function check',
        'Handoff record',
      ],
    ),
    'disputeReason': enumRole([
      'scope_change',
      'delay',
      'payment',
      'quality',
      'other',
    ]),
    'quoteAmount': intRole(50000, 60000000, step: 10000),
    'responseTime': intRole(5, 360, step: 5),
    'workMode': enumRole(['remote', 'onsite', 'hybrid']),
    'homeServiceName': textRole(
      ['에어컨 청소(예시)', '작은 이사(예시)', '수전 확인(예시)', '기초 악기 레슨(예시)'],
      [
        'Air-conditioner cleaning (example)',
        'Small move (example)',
        'Tap check (example)',
        'Beginner instrument lesson (example)',
      ],
    ),
    'requestAnswer': textRole(
      ['방문 전 작업 범위를 확인하고 싶어요.', '예시 일정은 주말 오전입니다.'],
      [
        'I would like to check the scope before a visit.',
        'The example schedule is a weekend morning.',
      ],
    ),
    'regionDong': textRole(
      ['가상시 솔빛동', '가상시 가람동', '가상시 물푸레동'],
      [
        'Fictional city, Solbit district',
        'Fictional city, Garam district',
        'Fictional city, Mulpare district',
      ],
    ),
    'reviewText': textRole(
      ['예시 작업 기록과 안내를 확인했습니다.', '예시 일정 안내가 이해하기 쉬웠어요.'],
      [
        'Reviewed the example work record and instructions.',
        'The example schedule instructions were easy to follow.',
      ],
    ),
    'creditLabel': textRole(
      ['견적 제출 크레딧(예시)', '미열람 환급 크레딧(예시)', '충전 크레딧(예시)'],
      [
        'Quote submission credit (example)',
        'Unviewed quote refund credit (example)',
        'Top-up credit (example)',
      ],
    ),
    'abuseReason': enumRole([
      'overcharge',
      'no_show',
      'rude',
      'fake_profile',
      'other',
    ]),
    'advisorTitle': textRole(
      ['가상 세무 전문가', '가상 법률 전문가', '가상 노무 전문가'],
      [
        'Fictional tax specialist',
        'Fictional legal specialist',
        'Fictional labor specialist',
      ],
    ),
    'adviceField': enumRole([
      'vat',
      'income_tax',
      'transfer_tax',
      'inheritance',
      'lease',
      'labor',
      'family',
      'consumer',
    ]),
    'consultTopic': textRole(
      ['제도 용어 안내 예시', '상담 전 확인 항목 예시', '서류 목록 설명 예시'],
      [
        'Example explanation of terminology',
        'Example pre-consultation checklist',
        'Example document list explanation',
      ],
    ),
    'qnaQuestion': textRole(
      ['제도 용어는 어떤 뜻인가요?(가상 질문)', '상담 기록에는 어떤 항목이 있나요?(가상 질문)'],
      [
        'What does this system term mean? (fictional question)',
        'What fields appear in a consultation record? (fictional question)',
      ],
    ),
    'qnaAnswerGeneric': textRole(
      [
        '일반 정보 예시입니다. 제도 안내에는 용어, 대상 범위, 확인 자료 등의 항목이 있습니다. 개별 사안에 대한 판단은 포함하지 않습니다.',
        '일반 정보 예시입니다. 상담 기록은 질문과 확인 자료를 구분해 적는 형식으로 구성됩니다. 특정 결과나 처리 방법을 제시하지 않습니다.',
      ],
      [
        'General information example. A system overview may list terms, scope and documents. This contains no judgment about an individual case.',
        'General information example. A consultation record separates questions from reference materials. No specific result or course of action is given.',
      ],
    ),
    'consultNoteGeneric': textRole(
      [
        '일반 정보 예시 기록: 질문 주제와 제도 용어를 소개했습니다. 자료 목록은 설명을 위한 가상 항목입니다.',
        '일반 정보 예시 기록: 상담 화면의 기록 형식을 살펴봤습니다. 개별 사건의 결론이나 조언은 없습니다.',
      ],
      [
        'General example note: introduced the question topic and system terms. The document list consists of fictional explanatory items.',
        'General example note: reviewed the consultation record format. There is no conclusion or advice about an individual case.',
      ],
    ),
    'officeName': textRole(
      ['솔빛 상담사무소(가상)', '가람 기록사무소(가상)'],
      [
        'Solbit consultation office (fictional)',
        'Garam records office (fictional)',
      ],
    ),
    'serviceParent': parentRole(4),
    'serviceTypeName': taxonomyRole(
      ['청소', '이사', '수리', '레슨'],
      ['Cleaning', 'Moving', 'Repair', 'Lessons'],
    ),
  };
  @override
  Map<String, Map<String, String>> get entities => const {
    'service_request': {
      'id': 'int',
      'title': 'String',
      'categoryName': 'String',
      'workMode': 'String',
      'status': 'String',
    },
    'provider_profile': {
      'id': 'int',
      'name': 'String',
      'headline': 'String',
      'status': 'String',
    },
    'home_service_type': {'id': 'int', 'name': 'String', 'parentId': 'int'},
    'qna_post': {
      'id': 'int',
      'question': 'String',
      'answer': 'String',
      'fieldName': 'String',
    },
    'consult_note': {'id': 'int', 'consultationId': 'int', 'summary': 'String'},
    'consultation': {
      'id': 'int',
      'advisorId': 'int',
      'topic': 'String',
      'status': 'String',
    },
  };
  @override
  Map<String, Map<String, String>> get entityRoles => const {
    'service_request': {
      'title': 'projectTitle',
      'categoryName': 'serviceCategory',
      'workMode': 'workMode',
    },
    'provider_profile': {
      'name': 'providerName',
      'headline': 'providerHeadline',
    },
    'home_service_type': {
      'name': 'serviceTypeName',
      'parentId': 'serviceParent',
    },
    'qna_post': {
      'question': 'qnaQuestion',
      'answer': 'qnaAnswerGeneric',
      'fieldName': 'adviceField',
    },
    'consult_note': {'summary': 'consultNoteGeneric'},
    'consultation': {'topic': 'consultTopic'},
  };
  @override
  Map<String, Map<String, List<String>>> get enums => const {
    'service_request': {
      'status': ['draft', 'open', 'offered', 'matched', 'closed', 'canceled'],
    },
    'provider_profile': {
      'status': ['draft', 'published', 'hidden'],
    },
    'consultation': {
      'status': ['requested', 'confirmed', 'completed', 'canceled', 'no_show'],
    },
  };
}

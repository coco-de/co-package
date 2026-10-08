/// A vendor operator action: a localized [label] and a [summary] template
/// with a `{target}` placeholder.
typedef CoOperatorActionSpec = ({String label, String summary});

/// A sample claim master row: a [name] and, for priced kinds, a typical
/// unit price in won.
typedef CoMasterRowSpec = ({String name, int? price});

/// An operations alert: a [level] (`info`, `warning`, `critical`), a stable
/// [code], and a [message].
typedef CoOpsAlertSpec = ({String level, String code, String message});

/// Vendor back-office texts used by `faker.saas` for the operations
/// console: operator actions and roles, autopay failures, claim master
/// sample rows and validation checks, incidents, alerts, announcements, and
/// tenant activity.
///
/// All texts are examples for demos and tests.
class CoFakerSaasOps {
  /// Creates an operations text set.
  const CoFakerSaasOps({
    required this.operatorActions,
    required this.operatorRoles,
    required this.autopayFailures,
    required this.masterRows,
    required this.masterChecks,
    required this.incidentTitles,
    required this.alerts,
    required this.releaseItems,
    required this.regulationItems,
    required this.releaseTitle,
    required this.regulationTitle,
    required this.tenantActivities,
    required this.templateRejectReason,
    required this.labels,
    this.senderLabels = const <String>[],
    this.healthMessages = const <String, String>{},
    this.auditTargets = const <String, String>{},
    this.auditRecords = const <String>[],
  });

  /// Operator actions keyed by console action key (`tenant.approve`, ...).
  final Map<String, CoOperatorActionSpec> operatorActions;

  /// Operator roles keyed by code (`owner`, `admin`, ...).
  final Map<String, String> operatorRoles;

  /// Card autopay failure reasons keyed by code.
  final Map<String, String> autopayFailures;

  /// Sample claim master rows keyed by kind (`fee`, `drug`, `material`,
  /// `diagnosis`).
  final Map<String, List<CoMasterRowSpec>> masterRows;

  /// Claim master validation checks keyed by code.
  final Map<String, String> masterChecks;

  /// Incident titles keyed by kind (`outage`, `degraded`, `maintenance`),
  /// with a `{service}` placeholder.
  final Map<String, String> incidentTitles;

  /// Operations alerts.
  final List<CoOpsAlertSpec> alerts;

  /// Release note bullet points.
  final List<String> releaseItems;

  /// Regulation (notice, fee schedule) update bullet points.
  final List<String> regulationItems;

  /// Release note title template with `{version}`.
  final String releaseTitle;

  /// Regulation notice title template with `{month}` (`YYYY-MM`).
  final String regulationTitle;

  /// Tenant activity templates with `{n}` (a count) placeholders.
  final List<String> tenantActivities;

  /// Review rejection reason for advertising notification templates.
  final String templateRejectReason;

  /// Labels for operator statuses, audiences, channels, incident kinds,
  /// alert levels, prepaid ledger kinds, and payment methods.
  final Map<String, String> labels;

  /// Names of the sender numbers a tenant registers (`senderNumber`): a main
  /// line, a booking line, ... Empty falls back to English.
  final List<String> senderLabels;

  /// The message of a degraded or failing health check (`healthCheck`),
  /// keyed by status: `degraded` and `down`. A status without an entry reads
  /// the English message.
  final Map<String, String> healthMessages;

  /// What an audit event (`auditEvent`) acts on when the action has no
  /// numbered record, keyed by action code: `login`, `loginFailed`
  /// (the target of `login` when missing), `roleChange`, and `send`. An
  /// action without an entry reads the English target.
  final Map<String, String> auditTargets;

  /// The kinds of record that the remaining audit actions act on; the target
  /// reads `patient #123`. Empty falls back to English.
  final List<String> auditRecords;

  /// Korean operations texts.
  static const CoFakerSaasOps korean = CoFakerSaasOps(
    operatorActions: <String, CoOperatorActionSpec>{
      'tenant.approve': (label: '의원 가입 승인', summary: '{target} 가입 신청을 승인했습니다.'),
      'tenant.suspend': (
        label: '의원 이용 정지',
        summary: '{target} 이용을 정지했습니다 (결제 연체).',
      ),
      'tenant.resume': (label: '의원 이용 재개', summary: '{target} 이용 정지를 해제했습니다.'),
      'plan.change': (
        label: '요금제 변경',
        summary: '{target} 요금제를 스탠다드에서 프로로 변경했습니다.',
      ),
      'invoice.issue': (
        label: '청구서 발행',
        summary: '{target} 월 이용료 청구서를 발행했습니다.',
      ),
      'invoice.refund': (
        label: '청구서 환불',
        summary: '{target} 청구서 1건을 부분 환불했습니다.',
      ),
      'credit.grant': (
        label: '크레딧 지급',
        summary: '{target}에 알림톡 크레딧 1,000건을 지급했습니다.',
      ),
      'template.approve': (
        label: '템플릿 승인',
        summary: '{target} 알림톡 템플릿을 승인했습니다.',
      ),
      'template.reject': (
        label: '템플릿 반려',
        summary: '{target} 광고성 템플릿을 반려했습니다.',
      ),
      'senderNumber.approve': (
        label: '발신번호 승인',
        summary: '{target} 발신번호 등록을 승인했습니다.',
      ),
      'master.publish': (
        label: '청구 마스터 배포',
        summary: '청구 마스터 새 버전을 배포했습니다 ({target}).',
      ),
      'notice.publish': (label: '공지 게시', summary: '공지 “{target}”을(를) 게시했습니다.'),
      'operator.invite': (
        label: '운영자 초대',
        summary: '{target}을(를) 운영자로 초대했습니다.',
      ),
      'operator.roleChange': (
        label: '운영자 권한 변경',
        summary: '{target} 권한을 지원에서 관리자로 변경했습니다.',
      ),
      'impersonate.start': (
        label: '의원 대리 접속',
        summary: '장애 확인을 위해 {target}에 대리 접속했습니다.',
      ),
    },
    operatorRoles: <String, String>{
      'owner': '최고 관리자',
      'admin': '관리자',
      'billing': '정산 담당',
      'support': '고객 지원',
      'viewer': '조회 전용',
    },
    autopayFailures: <String, String>{
      'LIMIT_EXCEEDED': '카드 한도 초과',
      'CARD_EXPIRED': '카드 유효기간 만료',
      'INSUFFICIENT_FUNDS': '잔액 부족',
      'CARD_LOST': '분실·도난 신고 카드',
      'CARD_SUSPENDED': '거래 정지 카드',
      'ISSUER_TIMEOUT': '카드사 응답 지연',
    },
    masterRows: <String, List<CoMasterRowSpec>>{
      'fee': <CoMasterRowSpec>[
        (name: '초진 진찰료', price: 18000),
        (name: '재진 진찰료', price: 12900),
        (name: '피부 절개 및 배농', price: 24500),
        (name: '냉동 치료 (1부위)', price: 9800),
        (name: '광선 치료', price: 7400),
        (name: '단순 처치 (드레싱)', price: 3600),
      ],
      'drug': <CoMasterRowSpec>[
        (name: '루미솔정 10mg', price: 180),
        (name: '케라펜연고 15g', price: 2400),
        (name: '미노벨캡슐 50mg', price: 310),
        (name: '디오클린크림 20g', price: 3100),
      ],
      'material': <CoMasterRowSpec>[
        (name: '멸균 거즈 (10매)', price: 420),
        (name: '봉합사 (흡수성)', price: 5600),
        (name: '주사기 1ml', price: 90),
        (name: '폼 드레싱 10x10', price: 7800),
      ],
      'diagnosis': <CoMasterRowSpec>[
        (name: '보통여드름', price: null),
        (name: '기미', price: null),
        (name: '바이러스사마귀', price: null),
        (name: '상세불명의 피부염', price: null),
      ],
    },
    masterChecks: <String, String>{
      'DUPLICATE_CODE': '코드 중복 없음',
      'NEGATIVE_PRICE': '단가 음수·0원 없음',
      'EFFECTIVE_DATE': '적용일자 역전 없음',
      'REQUIRED_COLUMNS': '필수 컬럼 누락 없음',
      'ROW_DELTA': '전 버전 대비 행 수 변동 5% 이내',
      'REMOVED_IN_USE': '삭제 코드가 진행 중 청구에 쓰이지 않음',
    },
    incidentTitles: <String, String>{
      'outage': '{service} 연결 장애',
      'degraded': '{service} 응답 지연',
      'maintenance': '{service} 정기 점검',
    },
    alerts: <CoOpsAlertSpec>[
      (
        level: 'warning',
        code: 'SYNC_DELAY',
        message: '오프라인 동기화가 15분 이상 지연된 의원이 3곳 있습니다.',
      ),
      (
        level: 'critical',
        code: 'AUTOPAY_FAILED',
        message: '이번 달 자동결제 실패 청구서가 7건 있습니다.',
      ),
      (
        level: 'warning',
        code: 'LOW_CREDIT',
        message: '알림톡 크레딧이 100건 미만인 의원이 5곳 있습니다.',
      ),
      (level: 'info', code: 'BACKUP_DONE', message: '야간 백업이 정상 완료되었습니다.'),
      (
        level: 'warning',
        code: 'CERT_EXPIRING',
        message: '공동인증서 만료가 30일 이내인 의원이 2곳 있습니다.',
      ),
      (
        level: 'critical',
        code: 'MASTER_PENDING',
        message: '이번 달 청구 마스터가 아직 배포되지 않았습니다.',
      ),
    ],
    releaseItems: <String>[
      '예약 화면에서 대기 순번을 바로 확인할 수 있습니다.',
      '수납 화면에서 선수금 차감과 분할 결제를 함께 처리합니다.',
      '알림톡 발송 실패 시 문자로 자동 대체 발송합니다.',
      '차트 협업 메모에 @멘션 알림이 추가되었습니다.',
      '동의서 전자서명 PDF 다운로드 속도를 개선했습니다.',
      '태블릿 문진표 글자 크기를 키웠습니다.',
    ],
    regulationItems: <String>[
      '건강보험 요양급여비용 고시 개정분을 반영했습니다.',
      '약제 급여 목록 및 상한금액표 변경분을 반영했습니다.',
      '치료재료 급여 목록 변경분을 반영했습니다.',
      '상병 분류 개정에 따른 코드 매핑을 갱신했습니다.',
    ],
    releaseTitle: 'EMR {version} 업데이트 안내',
    regulationTitle: '{month} 고시 반영 안내',
    tenantActivities: <String>[
      '신규 환자 {n}명 등록',
      '청구 명세 {n}건 전송',
      '알림톡 {n}건 발송',
      '예약 {n}건 접수',
      '직원 계정 {n}명 추가',
      '동의서 {n}건 전자서명',
      '수납 {n}건 마감',
    ],
    templateRejectReason: '광고성 정보가 포함되어 알림톡으로 발송할 수 없습니다 (친구톡·광고 문자 이용).',
    labels: <String, String>{
      'active': '활성',
      'invited': '초대됨',
      'suspended': '정지',
      'allTenants': '전체 의원',
      'proAndAbove': '프로 이상 요금제',
      'dermatology': '피부과 의원',
      'inApp': '앱 내 공지',
      'email': '이메일',
      'alimtalk': '알림톡',
      'outage': '장애',
      'degraded': '지연',
      'maintenance': '점검',
      'info': '정보',
      'warning': '경고',
      'critical': '긴급',
      'topUp': '충전',
      'usage': '사용',
      'refund': '환불',
      'card': '카드',
      'transfer': '계좌이체',
      'virtualAccount': '가상계좌',
      'release': '업데이트',
      'regulation': '고시 반영',
      'failed': '결제 실패',
      'added': '추가',
      'updated': '변경',
      'removed': '삭제',
    },
    senderLabels: <String>['대표번호', '예약 문의', '상담실', '데스크'],
    healthMessages: <String, String>{'degraded': '응답 지연', 'down': '연결 시간 초과'},
    auditTargets: <String, String>{
      'login': '계정',
      'loginFailed': '계정',
      'roleChange': '직원 권한',
      'send': '알림톡',
    },
    auditRecords: <String>['환자', '차트', '수납', '예약'],
  );

  /// English operations texts, the fallback for every other locale.
  static const CoFakerSaasOps english = CoFakerSaasOps(
    operatorActions: <String, CoOperatorActionSpec>{
      'tenant.approve': (
        label: 'Approve tenant',
        summary: 'Approved the sign-up of {target}.',
      ),
      'tenant.suspend': (
        label: 'Suspend tenant',
        summary: 'Suspended {target} (past due).',
      ),
      'tenant.resume': (
        label: 'Resume tenant',
        summary: 'Lifted the suspension of {target}.',
      ),
      'plan.change': (
        label: 'Change plan',
        summary: 'Moved {target} from Standard to Pro.',
      ),
      'invoice.issue': (
        label: 'Issue invoice',
        summary: 'Issued the monthly invoice of {target}.',
      ),
      'invoice.refund': (
        label: 'Refund invoice',
        summary: 'Partially refunded an invoice of {target}.',
      ),
      'credit.grant': (
        label: 'Grant credits',
        summary: 'Granted 1,000 message credits to {target}.',
      ),
      'template.approve': (
        label: 'Approve template',
        summary: 'Approved a template of {target}.',
      ),
      'template.reject': (
        label: 'Reject template',
        summary: 'Rejected an advertising template of {target}.',
      ),
      'senderNumber.approve': (
        label: 'Approve sender number',
        summary: 'Approved a sender number of {target}.',
      ),
      'master.publish': (
        label: 'Publish claim master',
        summary: 'Published a new claim master ({target}).',
      ),
      'notice.publish': (
        label: 'Publish notice',
        summary: 'Published the notice "{target}".',
      ),
      'operator.invite': (
        label: 'Invite operator',
        summary: 'Invited {target} as an operator.',
      ),
      'operator.roleChange': (
        label: 'Change operator role',
        summary: 'Changed the role of {target} to admin.',
      ),
      'impersonate.start': (
        label: 'Impersonate tenant',
        summary: 'Signed in as {target} to investigate an issue.',
      ),
    },
    operatorRoles: <String, String>{
      'owner': 'Owner',
      'admin': 'Admin',
      'billing': 'Billing',
      'support': 'Support',
      'viewer': 'Viewer',
    },
    autopayFailures: <String, String>{
      'LIMIT_EXCEEDED': 'Card limit exceeded',
      'CARD_EXPIRED': 'Card expired',
      'INSUFFICIENT_FUNDS': 'Insufficient funds',
      'CARD_LOST': 'Card reported lost or stolen',
      'CARD_SUSPENDED': 'Card suspended',
      'ISSUER_TIMEOUT': 'Issuer timeout',
    },
    masterRows: <String, List<CoMasterRowSpec>>{
      'fee': <CoMasterRowSpec>[
        (name: 'New patient visit', price: 18000),
        (name: 'Follow-up visit', price: 12900),
        (name: 'Cryotherapy (one site)', price: 9800),
      ],
      'drug': <CoMasterRowSpec>[
        (name: 'Lumisol tablet 10mg', price: 180),
        (name: 'Keraphen ointment 15g', price: 2400),
      ],
      'material': <CoMasterRowSpec>[
        (name: 'Sterile gauze (10)', price: 420),
        (name: 'Syringe 1 ml', price: 90),
      ],
      'diagnosis': <CoMasterRowSpec>[
        (name: 'Acne vulgaris', price: null),
        (name: 'Viral warts', price: null),
      ],
    },
    masterChecks: <String, String>{
      'DUPLICATE_CODE': 'No duplicate codes',
      'NEGATIVE_PRICE': 'No zero or negative prices',
      'EFFECTIVE_DATE': 'Effective dates in order',
      'REQUIRED_COLUMNS': 'No missing required columns',
      'ROW_DELTA': 'Row count within 5% of the previous version',
      'REMOVED_IN_USE': 'Removed codes are not used by open claims',
    },
    incidentTitles: <String, String>{
      'outage': '{service} outage',
      'degraded': '{service} slow responses',
      'maintenance': '{service} scheduled maintenance',
    },
    alerts: <CoOpsAlertSpec>[
      (
        level: 'warning',
        code: 'SYNC_DELAY',
        message: '3 clinics have offline sync delayed by over 15 minutes.',
      ),
      (
        level: 'critical',
        code: 'AUTOPAY_FAILED',
        message: '7 invoices failed autopay this month.',
      ),
      (
        level: 'warning',
        code: 'LOW_CREDIT',
        message: '5 clinics have fewer than 100 message credits.',
      ),
      (
        level: 'info',
        code: 'BACKUP_DONE',
        message: 'The nightly backup completed.',
      ),
    ],
    releaseItems: <String>[
      'See the waiting number directly on the booking screen.',
      'Split payments and prepaid balance on one screen.',
      'Failed notifications fall back to SMS automatically.',
      'Mention teammates with @ in chart notes.',
    ],
    regulationItems: <String>[
      'Applied the revised fee schedule.',
      'Applied the updated drug price list.',
      'Updated diagnosis code mappings.',
    ],
    releaseTitle: 'EMR {version} release notes',
    regulationTitle: '{month} regulatory updates',
    tenantActivities: <String>[
      '{n} new patients registered',
      '{n} claims submitted',
      '{n} notifications sent',
      '{n} appointments booked',
      '{n} staff accounts added',
    ],
    templateRejectReason:
        'Contains advertising; send it as a marketing message instead.',
    labels: <String, String>{
      'active': 'Active',
      'invited': 'Invited',
      'suspended': 'Suspended',
      'allTenants': 'All clinics',
      'proAndAbove': 'Pro plans and above',
      'dermatology': 'Dermatology clinics',
      'inApp': 'In-app',
      'email': 'Email',
      'alimtalk': 'Notification talk',
      'outage': 'Outage',
      'degraded': 'Degraded',
      'maintenance': 'Maintenance',
      'info': 'Info',
      'warning': 'Warning',
      'critical': 'Critical',
      'topUp': 'Top-up',
      'usage': 'Usage',
      'refund': 'Refund',
      'card': 'Card',
      'transfer': 'Bank transfer',
      'virtualAccount': 'Virtual account',
      'release': 'Release',
      'regulation': 'Regulatory update',
      'failed': 'Payment failed',
      'added': 'Added',
      'updated': 'Updated',
      'removed': 'Removed',
    },
    senderLabels: <String>['Main line', 'Bookings', 'Front desk'],
    healthMessages: <String, String>{
      'degraded': 'Slow responses',
      'down': 'Connection timed out',
    },
    auditTargets: <String, String>{
      'login': 'account',
      'loginFailed': 'account',
      'roleChange': 'staff role',
      'send': 'notification',
    },
    auditRecords: <String>['patient', 'chart', 'invoice', 'reservation'],
  );
}

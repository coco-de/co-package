import 'currency_format.dart';
import 'korean_values.dart';
import 'saas_ops.dart';

/// A subscription plan with its monthly price and included quotas.
typedef CoPlanSpec = ({
  String code,
  String name,
  int monthlyPrice,
  int seats,
  int messageCredits,
});

/// A message template: a stable [code], a display [name], and a [body] with
/// `#{variable}` placeholders in the style of KakaoTalk notification
/// templates.
typedef CoMessageTemplateSpec = ({String code, String name, String body});

/// A service notice: a [category] code with its title and body.
typedef CoNoticeSpec = ({String category, String title, String body});

/// The price scale of a SaaS data set: the VAT rate of invoices and the
/// amounts of the prepaid wallet, in the currency of the data
/// ([CoFakerSaasData.currency]).
///
/// The defaults are what `faker.saas` has always generated for every locale,
/// English included: a 10% VAT and a prepaid wallet in amounts of the won
/// ([korean] and [english] are the same scale). The subscription plans
/// (`CoPlanSpec.monthlyPrice`) and the claim master rows
/// (`CoMasterRowSpec.price`) are data in the currency of the locale. A
/// language with another currency sets its own VAT rate and wallet amounts.
class CoSaasPriceScale {
  /// Creates a price scale. The defaults are [korean].
  const CoSaasPriceScale({
    this.vatRate = 0.1,
    this.prepaidTopUps = const <int>[
      100000,
      300000,
      500000,
      1000000,
      3000000,
      5000000,
    ],
    this.prepaidBonusTiers = koreanBonusTiers,
    this.prepaidLowBalance = 50000,
    this.prepaidUsageMin = 10000,
    this.prepaidUsageRounding = 1000,
    this.prepaidRefundMin = 1000,
    this.prepaidRefundRounding = 1000,
  }) : assert(vatRate >= 0, 'vatRate must not be negative'),
       assert(
         prepaidUsageRounding > 0,
         'prepaidUsageRounding must be positive',
       ),
       assert(
         prepaidRefundRounding > 0,
         'prepaidRefundRounding must be positive',
       ),
       assert(
         prepaidLowBalance >= 2 * prepaidUsageMin,
         'prepaidLowBalance must be at least twice prepaidUsageMin',
       ),
       assert(
         prepaidLowBalance >= 4 * prepaidRefundMin,
         'prepaidLowBalance must be at least four times prepaidRefundMin',
       );

  /// The scale of the Korean data: a 10% VAT and a wallet in won.
  static const CoSaasPriceScale korean = CoSaasPriceScale();

  /// The scale of the English data. English has always shared the Korean
  /// wallet amounts, so it equals [korean]; it is kept so that English output
  /// stays byte for byte stable.
  static const CoSaasPriceScale english = CoSaasPriceScale();

  /// The Korean top-up bonus tiers, `(minimum amount, bonus percent)` in won,
  /// lowest first: 100,000 won earns 10% up to 60% from 15,000,000 won.
  static const List<(int, int)> koreanBonusTiers = <(int, int)>[
    (100000, 10),
    (300000, 15),
    (500000, 20),
    (1000000, 25),
    (3000000, 35),
    (5000000, 45),
    (10000000, 55),
    (15000000, 60),
  ];

  /// The VAT of an invoice as a fraction of the supply amount: `0.1` for
  /// 10%, `0.19` for 19% (`invoice`).
  final double vatRate;

  /// The amounts a prepaid wallet is topped up with (`prepaidLedger`). Must
  /// not be empty.
  final List<int> prepaidTopUps;

  /// Top-up bonus tiers `(minimum amount, bonus percent)`, lowest first
  /// ([bonusFor]).
  final List<(int, int)> prepaidBonusTiers;

  /// A wallet below this balance is always topped up before it is used. It
  /// must be at least twice [prepaidUsageMin] and four times
  /// [prepaidRefundMin].
  final int prepaidLowBalance;

  /// The smallest usage entry of a wallet; the largest is half the balance.
  final int prepaidUsageMin;

  /// Usage entries are rounded to a multiple of this.
  final int prepaidUsageRounding;

  /// The smallest refund entry of a wallet; the largest is a quarter of the
  /// balance.
  final int prepaidRefundMin;

  /// Refund entries are rounded to a multiple of this.
  final int prepaidRefundRounding;

  /// The bonus earned by a top-up of [amount]: the percent of the highest
  /// tier that [amount] reaches.
  int bonusFor(int amount) {
    var percent = 0;
    for (final tier in prepaidBonusTiers) {
      if (amount >= tier.$1) percent = tier.$2;
    }
    return amount * percent ~/ 100;
  }
}

/// SaaS back-office data used by `faker.saas`.
///
/// Status, action, and service codes are locale independent; only the
/// labels, names, and texts are localized. Every list must be non-empty.
///
/// The data also decides how amounts and a few values are generated, so a
/// language only has to add data: [currency] and [priceScale] give the
/// currency format, the VAT rate, and the prepaid wallet amounts, and
/// [koreanValues] says whether the Korean-only values (the business
/// registration number, Korean phone numbers and addresses) are generated.
/// The texts that the generators assemble (health messages, audit targets,
/// sender number labels) are fields of [CoFakerSaasOps].
///
/// A language that has no data of its own gets the English data: see
/// `CoFaker`.
class CoFakerSaasData {
  /// Creates a SaaS data set.
  const CoFakerSaasData({
    required this.plans,
    required this.messageTemplates,
    required this.notices,
    required this.failureReasons,
    required this.labels,
    this.ops,
    this.currency = CoCurrencyFormat.usd,
    this.priceScale = CoSaasPriceScale.english,
    this.koreanValues = CoKoreanValues.legacy,
    this.businessNumberFormat = '##########',
  });

  /// Subscription plans, cheapest first.
  final List<CoPlanSpec> plans;

  /// Notification message templates.
  final List<CoMessageTemplateSpec> messageTemplates;

  /// Service notices. [CoNoticeSpec.category] is `notice`, `release`, or
  /// `maintenance`.
  final List<CoNoticeSpec> notices;

  /// Message delivery failure reasons keyed by failure code.
  final Map<String, String> failureReasons;

  /// Labels for the locale independent codes used by the SaaS module:
  /// subscription and invoice statuses, message channels and statuses,
  /// template statuses, integration services, health statuses, audit
  /// actions, notice categories, and claim master kinds.
  final Map<String, String> labels;

  /// Operations console texts, or `null` to use [CoFakerSaasOps.english].
  final CoFakerSaasOps? ops;

  /// How amounts are written: `$1,234` for [CoCurrencyFormat.usd], `1,234`
  /// for [CoCurrencyFormat.korean]. See `faker.saas.money`.
  final CoCurrencyFormat currency;

  /// The VAT rate of invoices and the amounts of the prepaid wallet, in
  /// [currency].
  final CoSaasPriceScale priceScale;

  /// Which Korean-only values the generators produce:
  /// [CoKoreanValues.korean] for the Korean data, [CoKoreanValues.legacy]
  /// (the default) for the English data, and [CoKoreanValues.none] for new
  /// language data.
  final CoKoreanValues koreanValues;

  /// The business number of a tenant (`tenant().businessNumber`) when
  /// [koreanValues] is [CoKoreanValues.none]: `#` is a random digit and any
  /// other character is written as it is, so `##-#######` gives
  /// `48-1920374`. Korean and legacy data generate a business registration
  /// number (사업자등록번호) that fails its checksum instead.
  final String businessNumberFormat;

  /// Korean SaaS data for a clinic software vendor back office, in won, with
  /// every Korean-only value ([CoKoreanValues.korean]).
  static const CoFakerSaasData korean = CoFakerSaasData(
    plans: <CoPlanSpec>[
      (
        code: 'starter',
        name: '스타터',
        monthlyPrice: 99000,
        seats: 3,
        messageCredits: 500,
      ),
      (
        code: 'standard',
        name: '스탠다드',
        monthlyPrice: 199000,
        seats: 10,
        messageCredits: 2000,
      ),
      (
        code: 'pro',
        name: '프로',
        monthlyPrice: 349000,
        seats: 25,
        messageCredits: 5000,
      ),
      (
        code: 'enterprise',
        name: '엔터프라이즈',
        monthlyPrice: 690000,
        seats: 100,
        messageCredits: 20000,
      ),
    ],
    messageTemplates: <CoMessageTemplateSpec>[
      (
        code: 'RSV_CREATED',
        name: '예약 완료',
        body: '#{환자명}님, #{예약일시} #{병원명} 예약이 완료되었습니다.\n문의: #{병원전화}',
      ),
      (
        code: 'RSV_CHANGED',
        name: '예약 변경',
        body: '#{환자명}님, 예약이 #{예약일시}(으)로 변경되었습니다.',
      ),
      (
        code: 'RSV_CANCELLED',
        name: '예약 취소',
        body: '#{환자명}님, #{예약일시} 예약이 취소되었습니다.',
      ),
      (
        code: 'RSV_REMIND_D1',
        name: '전날 리마인드',
        body: '#{환자명}님, 내일 #{예약시간} #{병원명} 예약이 있습니다.',
      ),
      (
        code: 'RECEPTION',
        name: '접수 안내',
        body: '#{환자명}님, #{병원명}에 접수되었습니다. 현재 대기 #{대기순번}번입니다.',
      ),
      (
        code: 'AFTERCARE',
        name: '시술 후 안내',
        body: '#{환자명}님, 오늘 받으신 #{시술명} 후 주의사항을 안내드립니다.\n#{안내링크}',
      ),
      (
        code: 'PKG_EXPIRE',
        name: '회차권 만료 예정',
        body: '#{환자명}님, #{회차권명} 잔여 #{잔여회수}회가 #{만료일}에 만료됩니다.',
      ),
      (
        code: 'QUESTIONNAIRE',
        name: '사전 문진 안내',
        body: '#{환자명}님, 내원 전 사전 문진을 작성해 주세요.\n#{문진링크}',
      ),
      (
        code: 'SURVEY',
        name: '만족도 조사',
        body: '#{환자명}님, #{병원명} 진료는 어떠셨나요? 1분 설문에 참여해 주세요.\n#{설문링크}',
      ),
      (
        code: 'AD_EVENT',
        name: '이벤트 안내 (광고성)',
        body: '(광고) #{병원명} 이달의 이벤트! 피코 토닝 10회 특가를 안내드립니다.\n수신거부: #{수신거부링크}',
      ),
    ],
    notices: <CoNoticeSpec>[
      (
        category: 'maintenance',
        title: '정기 점검 안내',
        body: '서비스 안정화를 위해 새벽 2시부터 4시까지 점검이 진행됩니다. 점검 중에는 접속이 제한됩니다.',
      ),
      (
        category: 'release',
        title: '새 기능 업데이트 안내',
        body: '예약 화면에서 대기 순번을 바로 확인할 수 있도록 개선했습니다.',
      ),
      (
        category: 'notice',
        title: '청구 마스터 갱신 안내',
        body: '이번 달 수가·약가 마스터가 반영되었습니다. 청구 전 변경 내역을 확인해 주세요.',
      ),
      (
        category: 'notice',
        title: '알림톡 발송 지연 안내',
        body: '일부 통신사 사정으로 알림톡 발송이 지연되고 있습니다. 문자로 대체 발송됩니다.',
      ),
      (
        category: 'notice',
        title: '개인정보 처리방침 개정 안내',
        body: '개정된 개인정보 처리방침이 다음 달 1일부터 적용됩니다.',
      ),
      (
        category: 'notice',
        title: '요금제 개편 안내',
        body: '다음 결제일부터 새 요금제가 적용됩니다. 기존 고객은 현재 요금이 유지됩니다.',
      ),
      (
        category: 'release',
        title: '수납 화면 개선 안내',
        body: '분할 수납과 선수금 차감을 한 화면에서 처리할 수 있습니다.',
      ),
    ],
    failureReasons: <String, String>{
      'INVALID_NUMBER': '수신 번호 오류',
      'NOT_FRIEND': '카카오톡 미사용자',
      'TEMPLATE_MISMATCH': '템플릿 불일치',
      'NO_CREDIT': '크레딧 부족',
      'CARRIER_TIMEOUT': '통신사 응답 지연',
      'OPTED_OUT': '수신 거부',
    },
    labels: <String, String>{
      'trialing': '체험 중',
      'active': '이용 중',
      'pastDue': '결제 연체',
      'paused': '일시 정지',
      'cancelled': '해지',
      'draft': '작성 중',
      'open': '청구됨',
      'paid': '결제 완료',
      'overdue': '미납',
      'void': '무효',
      'refunded': '환불',
      'alimtalk': '알림톡',
      'sms': 'SMS',
      'lms': 'LMS',
      'queued': '대기',
      'sent': '발송 성공',
      'failed': '발송 실패',
      'fallbackSent': '대체 발송',
      'approved': '승인',
      'reviewing': '검수 중',
      'rejected': '반려',
      'pending': '심사 중',
      'eligibility': '자격조회',
      'dur': 'DUR',
      'ePrescription': '전자처방',
      'insuranceClaim': '보험청구',
      'identityQr': '본인확인 QR',
      'alimtalkGateway': '알림톡 게이트웨이',
      'payment': 'PG 결제',
      'up': '정상',
      'degraded': '지연',
      'down': '장애',
      'login': '로그인',
      'loginFailed': '로그인 실패',
      'view': '조회',
      'revealRrn': '주민번호 열람',
      'create': '생성',
      'update': '수정',
      'delete': '삭제',
      'print': '출력',
      'exportData': '내보내기',
      'send': '발송',
      'roleChange': '권한 변경',
      'notice': '공지',
      'maintenance': '점검',
      'release': '업데이트',
      'fee': '수가',
      'drug': '약가',
      'material': '치료재료',
      'diagnosis': '상병',
      'current': '적용 중',
      'scheduled': '적용 예정',
      'archived': '만료',
      'purchase': '충전',
      'usage': '사용',
      'refund': '환불',
      'grant': '지급',
    },
    ops: CoFakerSaasOps.korean,
    currency: CoCurrencyFormat.korean,
    priceScale: CoSaasPriceScale.korean,
    koreanValues: CoKoreanValues.korean,
  );

  /// English SaaS data, used as the fallback for every locale whose language
  /// has no SaaS data of its own.
  ///
  /// It is the model of the data of a new language: translate every list and
  /// text, then set [currency], [priceScale], and [koreanValues] (`none`) for
  /// the language.
  static const CoFakerSaasData english = CoFakerSaasData(
    plans: <CoPlanSpec>[
      (
        code: 'starter',
        name: 'Starter',
        monthlyPrice: 79,
        seats: 3,
        messageCredits: 500,
      ),
      (
        code: 'standard',
        name: 'Standard',
        monthlyPrice: 159,
        seats: 10,
        messageCredits: 2000,
      ),
      (
        code: 'pro',
        name: 'Pro',
        monthlyPrice: 279,
        seats: 25,
        messageCredits: 5000,
      ),
      (
        code: 'enterprise',
        name: 'Enterprise',
        monthlyPrice: 549,
        seats: 100,
        messageCredits: 20000,
      ),
    ],
    messageTemplates: <CoMessageTemplateSpec>[
      (
        code: 'RSV_CREATED',
        name: 'Appointment booked',
        body: 'Hi #{name}, your visit at #{clinic} on #{dateTime} is booked.',
      ),
      (
        code: 'RSV_CANCELLED',
        name: 'Appointment cancelled',
        body: 'Hi #{name}, your visit on #{dateTime} was cancelled.',
      ),
      (
        code: 'RSV_REMIND_D1',
        name: 'Reminder',
        body: 'Hi #{name}, see you tomorrow at #{time} at #{clinic}.',
      ),
      (
        code: 'QUESTIONNAIRE',
        name: 'Pre-visit questionnaire',
        body:
            'Hi #{name}, please fill in the questionnaire before your visit: #{link}',
      ),
      (
        code: 'SURVEY',
        name: 'Satisfaction survey',
        body: 'Hi #{name}, how was your visit to #{clinic}? #{link}',
      ),
      (
        code: 'AD_EVENT',
        name: 'Promotion (advertising)',
        body:
            '[Ad] #{clinic} monthly offer: 10 laser toning sessions on sale. Opt out: #{link}',
      ),
    ],
    notices: <CoNoticeSpec>[
      (
        category: 'maintenance',
        title: 'Scheduled maintenance',
        body:
            'The service will be unavailable from 2 AM to 4 AM for maintenance.',
      ),
      (
        category: 'release',
        title: 'New features released',
        body:
            'You can now see the waiting number directly on the booking screen.',
      ),
      (
        category: 'notice',
        title: 'Pricing update',
        body: 'New plans apply from your next billing date.',
      ),
      (
        category: 'notice',
        title: 'Delayed notifications',
        body: 'Some notifications are delayed and will be sent as SMS instead.',
      ),
    ],
    failureReasons: <String, String>{
      'INVALID_NUMBER': 'Invalid recipient number',
      'NOT_FRIEND': 'Recipient does not use the messenger',
      'TEMPLATE_MISMATCH': 'Template mismatch',
      'NO_CREDIT': 'Insufficient credits',
      'CARRIER_TIMEOUT': 'Carrier timeout',
      'OPTED_OUT': 'Recipient opted out',
    },
    labels: <String, String>{
      'trialing': 'Trial',
      'active': 'Active',
      'pastDue': 'Past due',
      'paused': 'Paused',
      'cancelled': 'Cancelled',
      'draft': 'Draft',
      'open': 'Open',
      'paid': 'Paid',
      'overdue': 'Overdue',
      'void': 'Void',
      'refunded': 'Refunded',
      'alimtalk': 'Notification talk',
      'sms': 'SMS',
      'lms': 'LMS',
      'queued': 'Queued',
      'sent': 'Sent',
      'failed': 'Failed',
      'fallbackSent': 'Sent via fallback',
      'approved': 'Approved',
      'reviewing': 'In review',
      'rejected': 'Rejected',
      'pending': 'Pending',
      'eligibility': 'Eligibility check',
      'dur': 'Drug utilization review',
      'ePrescription': 'E-prescription',
      'insuranceClaim': 'Insurance claim',
      'identityQr': 'Identity QR',
      'alimtalkGateway': 'Messaging gateway',
      'payment': 'Payment gateway',
      'up': 'Operational',
      'degraded': 'Degraded',
      'down': 'Outage',
      'login': 'Sign-in',
      'loginFailed': 'Failed sign-in',
      'view': 'View',
      'revealRrn': 'Reveal ID number',
      'create': 'Create',
      'update': 'Update',
      'delete': 'Delete',
      'print': 'Print',
      'exportData': 'Export',
      'send': 'Send',
      'roleChange': 'Role change',
      'notice': 'Notice',
      'maintenance': 'Maintenance',
      'release': 'Release',
      'fee': 'Fee schedule',
      'drug': 'Drug prices',
      'material': 'Materials',
      'diagnosis': 'Diagnoses',
      'current': 'Current',
      'scheduled': 'Scheduled',
      'archived': 'Archived',
      'purchase': 'Purchase',
      'usage': 'Usage',
      'refund': 'Refund',
      'grant': 'Grant',
    },
    ops: CoFakerSaasOps.english,
    currency: CoCurrencyFormat.usd,
    priceScale: CoSaasPriceScale.english,
    koreanValues: CoKoreanValues.legacy,
    businessNumberFormat: '##########',
  );
}

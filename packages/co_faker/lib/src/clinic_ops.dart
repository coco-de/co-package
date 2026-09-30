/// A labeled code with a display color (`#RRGGBB`).
typedef CoColoredLabelSpec = ({String code, String label, String color});

/// A room template: name, kind code, and the staff role that usually works
/// there (or `null` for unattended rooms).
typedef CoRoomSpec = ({String name, String kind, String? staffRole});

/// A claim review rule example.
typedef CoClaimRuleSpec = ({
  String ruleId,
  String severity,
  String diagnosisCode,
  String feeCode,
  String message,
});

/// An AI counseling evidence item: its kind and a rule name.
typedef CoEvidenceSpec = ({String kind, String rule});

/// Front-desk, chart, billing, operations, and CRM texts used by
/// `faker.clinic`: patient tags and acquisition channels, special notes,
/// rooms, queue and reception sources, consent history, vitals-free labels,
/// adjustments, points, tasks, kiosk purposes, AI counseling evidence,
/// claim review rules, and CRM delivery failures.
///
/// All texts are examples for demos and tests.
class CoFakerClinicOps {
  /// Creates a clinic operations text set.
  const CoFakerClinicOps({
    required this.patientTags,
    required this.acquisitionChannels,
    required this.specialNotes,
    required this.rooms,
    required this.termsChanges,
    required this.consentDispatch,
    required this.adjustments,
    required this.pointReasons,
    required this.paymentMessages,
    required this.tasks,
    required this.taskMemos,
    required this.kioskPurposes,
    required this.evidence,
    required this.counselFailures,
    required this.claimRules,
    required this.crmFailures,
    required this.packageBonus,
    required this.labels,
  });

  /// Patient tags with colors.
  final List<CoColoredLabelSpec> patientTags;

  /// Acquisition channels with colors.
  final List<CoColoredLabelSpec> acquisitionChannels;

  /// Special notes on a patient chart (allergies, cautions).
  final List<String> specialNotes;

  /// A typical room layout.
  final List<CoRoomSpec> rooms;

  /// Terms revision notes.
  final List<String> termsChanges;

  /// Consent request dispatch messages keyed by status (`sent`, `opened`,
  /// `signed`, `expired`, `failed`).
  final Map<String, String> consentDispatch;

  /// Adjustment line labels keyed by kind (`discount`, `coupon`, `point`,
  /// `rounding`).
  final Map<String, List<String>> adjustments;

  /// Point transaction reasons keyed by code (`earn`, `use`, `bonus`,
  /// `expire`, `refund`, `adjust`).
  final Map<String, String> pointReasons;

  /// Payment result messages keyed by code, with a `{reason}` placeholder
  /// for declines.
  final Map<String, String> paymentMessages;

  /// In-clinic task titles.
  final List<String> tasks;

  /// In-clinic task memos.
  final List<String> taskMemos;

  /// Kiosk visit purposes keyed by code.
  final Map<String, String> kioskPurposes;

  /// AI counseling evidence items.
  final List<CoEvidenceSpec> evidence;

  /// AI counseling failure messages keyed by code.
  final Map<String, String> counselFailures;

  /// Claim review rule examples.
  final List<CoClaimRuleSpec> claimRules;

  /// CRM delivery failure reasons keyed by code.
  final Map<String, String> crmFailures;

  /// The gift line appended to compound package names.
  final String packageBonus;

  /// Labels for queue statuses, reception sources, consent kinds and
  /// channels, consent actions, evidence kinds, and severities.
  final Map<String, String> labels;

  /// Korean clinic operations texts.
  static const CoFakerClinicOps korean = CoFakerClinicOps(
    patientTags: <CoColoredLabelSpec>[
      (code: 'vip', label: 'VIP', color: '#F59E0B'),
      (code: 'lifting', label: '리프팅', color: '#6366F1'),
      (code: 'referral', label: '지인추천', color: '#10B981'),
      (code: 'staffFamily', label: '직원가족', color: '#0EA5E9'),
      (code: 'caution', label: '주의환자', color: '#EF4444'),
      (code: 'package', label: '회차권 보유', color: '#8B5CF6'),
      (code: 'toning', label: '토닝', color: '#EC4899'),
      (code: 'foreigner', label: '외국인', color: '#14B8A6'),
    ],
    acquisitionChannels: <CoColoredLabelSpec>[
      (code: 'naverBooking', label: '네이버 예약', color: '#03C75A'),
      (code: 'referral', label: '지인 소개', color: '#10B981'),
      (code: 'instagramAd', label: '인스타그램 광고', color: '#E1306C'),
      (code: 'beautyApp', label: '미용 정보 앱', color: '#FF5A5F'),
      (code: 'blogSearch', label: '블로그 검색', color: '#7C3AED'),
      (code: 'event', label: '이벤트', color: '#F59E0B'),
      (code: 'walkIn', label: '간판·워크인', color: '#64748B'),
    ],
    specialNotes: <String>[
      '리도카인 알러지',
      '켈로이드 체질 — 레이저 강도 주의',
      '항응고제 복용 중 — 시술 전 확인',
      '페니실린 알러지',
      '임신 가능성 있음 — 시술 전 확인',
      '금속 알러지',
      '통증에 예민함 — 마취크림 충분히',
      '광과민성 약물 복용 중',
    ],
    rooms: <CoRoomSpec>[
      (name: '상담실1', kind: 'counseling', staffRole: 'counselor'),
      (name: '진료실1', kind: 'consultation', staffRole: 'director'),
      (name: '진료실2', kind: 'consultation', staffRole: 'doctor'),
      (name: '시술실1', kind: 'procedure', staffRole: 'nurse'),
      (name: '시술실2', kind: 'procedure', staffRole: 'nurse'),
      (name: '관리실1', kind: 'care', staffRole: 'skincare'),
      (name: '수납실', kind: 'payment', staffRole: 'coordinator'),
      (name: '태블릿접수', kind: 'reception', staffRole: null),
    ],
    termsChanges: <String>[
      '제3조 개인정보 보유 기간 문구를 정비했습니다.',
      '제5조 제3자 제공 항목에 전자처방 전송 기관을 추가했습니다.',
      '제7조 AI 상담 녹음 보관 기간(90일)을 명시했습니다.',
      '야간 광고성 정보 수신 동의 항목을 분리했습니다.',
      '사진 활용 범위에 원내 교육 목적을 추가했습니다.',
    ],
    consentDispatch: <String, String>{
      'sent': '알림톡으로 서명 요청을 보냈습니다.',
      'opened': '환자가 서명 요청을 열람했습니다.',
      'signed': '전자서명이 완료되었습니다.',
      'expired': '서명 요청이 만료되었습니다 (24시간).',
      'failed': '서명 요청 발송에 실패했습니다 — 번호를 확인해 주세요.',
    },
    adjustments: <String, List<String>>{
      'discount': <String>[
        '재방문 10% 할인',
        '직원가족 20% 할인',
        '패키지 동시 결제 할인',
        '원장 재량 할인',
      ],
      'coupon': <String>['첫방문 20% 쿠폰', '생일 축하 1만원 쿠폰', '이달의 토닝 15% 쿠폰'],
      'point': <String>['포인트 사용'],
      'rounding': <String>['끝전 절사'],
    },
    pointReasons: <String, String>{
      'earn': '결제 금액 3% 적립',
      'use': '수납 시 포인트 사용',
      'bonus': '리뷰 작성 보너스',
      'expire': '유효기간 만료 소멸',
      'refund': '결제 취소로 적립 회수',
      'adjust': '관리자 수동 조정',
    },
    paymentMessages: <String, String>{
      'approved': '카드 승인이 완료되었습니다.',
      'cashReceipt': '현금영수증이 발행되었습니다.',
      'partialCancel': '부분 취소가 완료되었습니다.',
      'prepaidUsed': '선수금에서 차감했습니다.',
      'declined': '카드 승인이 거절되었습니다 — {reason}',
    },
    tasks: <String>[
      '레이저 팁 재고 확인',
      '소모품 발주',
      '일일 마감 정산',
      '냉장 보관 약품 온도 기록',
      '장비 주간 점검',
      '대기실 태블릿 충전',
      '미수금 환자 연락',
      '내일 예약 리마인드 확인',
    ],
    taskMemos: <String>[
      '오후 3시 전까지 완료 부탁드립니다.',
      '재고 5개 이하이면 바로 발주해 주세요.',
      '완료 후 사진 첨부 부탁드려요.',
      '지난주 누락분 포함해서 확인해 주세요.',
    ],
    kioskPurposes: <String, String>{
      'checkin': '진료 접수',
      'reservation': '예약 확인',
      'payment': '수납',
      'document': '서류 발급',
    },
    evidence: <CoEvidenceSpec>[
      (kind: 'chartHistory', rule: '최근 3개월 동일 시술 이력 확인'),
      (kind: 'procedureHistory', rule: '직전 시술 후 권장 간격 경과 여부'),
      (kind: 'priceRule', rule: '회차권 보유 시 단건 결제보다 회차권 우선 안내'),
      (kind: 'contraindication', rule: '리도카인 알러지 시 마취크림 제외'),
      (kind: 'guideline', rule: '임신 가능성 있으면 레이저 시술 보류'),
      (kind: 'preference', rule: '다운타임 최소 희망 시 비침습 시술 우선'),
    ],
    counselFailures: <String, String>{
      'CONSENT_MISSING': '녹음 동의가 없어 AI 상담을 시작할 수 없습니다.',
      'STT_FAILED': '음성 인식에 실패했습니다. 마이크 연결을 확인해 주세요.',
      'TOO_SHORT': '녹취가 너무 짧아 요약할 수 없습니다 (30초 미만).',
      'MODEL_TIMEOUT': '요약 생성이 지연되고 있습니다. 잠시 후 다시 시도해 주세요.',
      'NETWORK': '네트워크 연결이 끊겨 업로드하지 못했습니다.',
    },
    claimRules: <CoClaimRuleSpec>[
      (
        ruleId: 'R-DX-001',
        severity: 'error',
        diagnosisCode: 'Z41.1',
        feeCode: 'CONS01',
        message: '미용 목적 상병에는 급여 진찰료를 청구할 수 없습니다.',
      ),
      (
        ruleId: 'R-DX-014',
        severity: 'warning',
        diagnosisCode: 'L70.0',
        feeCode: 'ACN-03',
        message: '광역동 치료는 비급여 — 급여 명세에서 제외하세요.',
      ),
      (
        ruleId: 'R-FE-203',
        severity: 'error',
        diagnosisCode: 'B07',
        feeCode: 'WART-01',
        message: '냉동 치료 부위 수가 산정 기준(1일 최대 5부위)을 넘었습니다.',
      ),
      (
        ruleId: 'R-FE-118',
        severity: 'warning',
        diagnosisCode: 'L20.9',
        feeCode: 'CONS02',
        message: '같은 날 재진 진찰료가 두 번 산정되었습니다.',
      ),
      (
        ruleId: 'R-RX-042',
        severity: 'warning',
        diagnosisCode: 'L30.9',
        feeCode: 'DRG-01',
        message: '외용제 처방 일수가 상병 기준을 초과합니다.',
      ),
    ],
    crmFailures: <String, String>{
      'NIGHT_AD_NO_CONSENT': '야간(21시~8시) 광고성 정보 수신 동의 없음',
      'MARKETING_NO_CONSENT': '마케팅 수신 동의 없음',
      'OPTED_OUT': '수신 거부 번호',
      'INVALID_NUMBER': '수신 번호 오류',
      'DUPLICATE_LIMIT': '동일 캠페인 중복 발송 제한',
      'NO_CREDIT': '크레딧 부족',
    },
    packageBonus: '재생 크림 50ml 증정',
    labels: <String, String>{
      'requested': '접수신청',
      'waiting': '대기',
      'priority': '우선',
      'inProgress': '진행중',
      'done': '완료',
      'tablet': '태블릿',
      'online': '온라인',
      'app': '앱',
      'kiosk': '키오스크',
      'desk': '데스크',
      'paper': '종이',
      'privacyRequired': '개인정보 필수',
      'marketingOptional': '마케팅 수신(선택)',
      'sensitiveInfo': '민감정보',
      'photoUse': '사진 활용',
      'thirdParty': '제3자 제공',
      'aiRecording': 'AI 상담 녹음',
      'nightAdvertising': '야간 광고 수신',
      'agreed': '동의',
      'withdrawn': '철회',
      'chartHistory': '차트 이력',
      'procedureHistory': '시술 이력',
      'priceRule': '가격 규칙',
      'contraindication': '금기',
      'guideline': '진료 지침',
      'preference': '환자 선호',
      'error': '오류',
      'warning': '경고',
      'discount': '할인',
      'coupon': '쿠폰',
      'point': '포인트',
      'rounding': '절사',
    },
  );

  /// English clinic operations texts, the fallback for other locales.
  static const CoFakerClinicOps english = CoFakerClinicOps(
    patientTags: <CoColoredLabelSpec>[
      (code: 'vip', label: 'VIP', color: '#F59E0B'),
      (code: 'lifting', label: 'Lifting', color: '#6366F1'),
      (code: 'referral', label: 'Referral', color: '#10B981'),
      (code: 'caution', label: 'Caution', color: '#EF4444'),
      (code: 'package', label: 'Package holder', color: '#8B5CF6'),
    ],
    acquisitionChannels: <CoColoredLabelSpec>[
      (code: 'onlineBooking', label: 'Online booking', color: '#03C75A'),
      (code: 'referral', label: 'Referral', color: '#10B981'),
      (code: 'instagramAd', label: 'Instagram ad', color: '#E1306C'),
      (code: 'search', label: 'Search', color: '#7C3AED'),
      (code: 'walkIn', label: 'Walk-in', color: '#64748B'),
    ],
    specialNotes: <String>[
      'Lidocaine allergy',
      'Keloid-prone: lower laser settings',
      'On blood thinners: check before procedures',
      'Penicillin allergy',
    ],
    rooms: <CoRoomSpec>[
      (name: 'Counseling 1', kind: 'counseling', staffRole: 'counselor'),
      (name: 'Exam 1', kind: 'consultation', staffRole: 'director'),
      (name: 'Exam 2', kind: 'consultation', staffRole: 'doctor'),
      (name: 'Procedure 1', kind: 'procedure', staffRole: 'nurse'),
      (name: 'Care 1', kind: 'care', staffRole: 'skincare'),
      (name: 'Checkout', kind: 'payment', staffRole: 'coordinator'),
      (name: 'Tablet check-in', kind: 'reception', staffRole: null),
    ],
    termsChanges: <String>[
      'Clarified the data retention period.',
      'Added the e-prescription network as a recipient.',
      'Stated the 90-day retention of AI counseling recordings.',
    ],
    consentDispatch: <String, String>{
      'sent': 'Signature request sent.',
      'opened': 'The patient opened the request.',
      'signed': 'Signed electronically.',
      'expired': 'The request expired (24 hours).',
      'failed': 'Could not send the request; check the number.',
    },
    adjustments: <String, List<String>>{
      'discount': <String>['Returning patient 10%', 'Staff family 20%'],
      'coupon': <String>['First visit 20% coupon', 'Birthday coupon'],
      'point': <String>['Points used'],
      'rounding': <String>['Rounding'],
    },
    pointReasons: <String, String>{
      'earn': '3% of payment earned',
      'use': 'Used at checkout',
      'bonus': 'Review bonus',
      'expire': 'Expired',
      'refund': 'Reversed after a refund',
      'adjust': 'Manual adjustment',
    },
    paymentMessages: <String, String>{
      'approved': 'Card approved.',
      'cashReceipt': 'Cash receipt issued.',
      'partialCancel': 'Partially cancelled.',
      'prepaidUsed': 'Charged to the prepaid balance.',
      'declined': 'Card declined: {reason}',
    },
    tasks: <String>[
      'Check laser tip stock',
      'Order supplies',
      'Daily closing',
      'Log fridge temperature',
    ],
    taskMemos: <String>[
      'Please finish before 3 PM.',
      'Order right away if fewer than 5 remain.',
    ],
    kioskPurposes: <String, String>{
      'checkin': 'Check in',
      'reservation': 'Find my booking',
      'payment': 'Pay',
      'document': 'Documents',
    },
    evidence: <CoEvidenceSpec>[
      (kind: 'chartHistory', rule: 'Same procedure within 3 months'),
      (
        kind: 'priceRule',
        rule: 'Suggest owned packages before single sessions',
      ),
      (
        kind: 'contraindication',
        rule: 'Skip numbing cream for lidocaine allergy',
      ),
    ],
    counselFailures: <String, String>{
      'CONSENT_MISSING': 'No recording consent; AI counseling cannot start.',
      'STT_FAILED': 'Speech recognition failed. Check the microphone.',
      'TOO_SHORT': 'The recording is too short to summarize.',
      'MODEL_TIMEOUT': 'The summary is delayed. Try again shortly.',
    },
    claimRules: <CoClaimRuleSpec>[
      (
        ruleId: 'R-DX-001',
        severity: 'error',
        diagnosisCode: 'Z41.1',
        feeCode: 'CONS01',
        message: 'Cosmetic diagnoses cannot bill an insured visit fee.',
      ),
      (
        ruleId: 'R-FE-118',
        severity: 'warning',
        diagnosisCode: 'L20.9',
        feeCode: 'CONS02',
        message: 'Follow-up fee billed twice on the same day.',
      ),
    ],
    crmFailures: <String, String>{
      'NIGHT_AD_NO_CONSENT': 'No consent for night-time advertising',
      'MARKETING_NO_CONSENT': 'No marketing consent',
      'OPTED_OUT': 'Opted out',
      'INVALID_NUMBER': 'Invalid number',
    },
    packageBonus: 'free recovery cream',
    labels: <String, String>{
      'requested': 'Requested',
      'waiting': 'Waiting',
      'priority': 'Priority',
      'inProgress': 'In progress',
      'done': 'Done',
      'tablet': 'Tablet',
      'online': 'Online',
      'app': 'App',
      'kiosk': 'Kiosk',
      'desk': 'Desk',
      'paper': 'Paper',
      'privacyRequired': 'Privacy (required)',
      'marketingOptional': 'Marketing (optional)',
      'sensitiveInfo': 'Sensitive data',
      'photoUse': 'Photo use',
      'thirdParty': 'Third-party sharing',
      'aiRecording': 'AI recording',
      'nightAdvertising': 'Night-time ads',
      'agreed': 'Agreed',
      'withdrawn': 'Withdrawn',
      'chartHistory': 'Chart history',
      'procedureHistory': 'Procedure history',
      'priceRule': 'Pricing rule',
      'contraindication': 'Contraindication',
      'guideline': 'Guideline',
      'preference': 'Preference',
      'error': 'Error',
      'warning': 'Warning',
      'discount': 'Discount',
      'coupon': 'Coupon',
      'point': 'Points',
      'rounding': 'Rounding',
    },
  );

  /// Schedule and staff colors (`#RRGGBB`) that read well on light and
  /// dark surfaces.
  static const List<String> palette = <String>[
    '#4F46E5',
    '#0EA5E9',
    '#EC4899',
    '#F59E0B',
    '#10B981',
    '#8B5CF6',
    '#EF4444',
    '#14B8A6',
    '#F97316',
    '#64748B',
    '#84CC16',
    '#06B6D4',
  ];
}

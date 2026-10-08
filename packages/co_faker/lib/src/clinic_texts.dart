/// A consent form template: a [kind] code, a [title], and its clauses.
typedef CoConsentFormSpec = ({String kind, String title, List<String> clauses});

/// A counseling topic: the patient's concern and the counselor's answers
/// about one procedure of the clinic catalog ([procedureCode]).
typedef CoCounselTopicSpec = ({
  String topic,
  String procedureCode,
  String procedure,
  String concern,
  String recommend,
  String pain,
  String interval,
  String downtime,
  int sessions,
});

/// The fixed lines of a counseling conversation.
///
/// [priceAnswer] and [summary] use `{price}`, `{sessions}`,
/// `{packagePrice}`, `{procedure}`, and `{outcome}` placeholders.
typedef CoCounselScriptSpec = ({
  String greeting,
  Map<String, String> questions,
  String priceAnswer,
  String bookYes,
  String bookYesReply,
  String bookNo,
  String bookNoReply,
  String summary,
  String booked,
  String pending,
});

/// A public integration response example: a result [code], a [message],
/// and whether the call succeeded.
typedef CoIntegrationResultSpec = ({String code, String message, bool ok});

/// A patient inquiry and the clinic's reply, in one language.
typedef CoInquirySpec = ({String question, String answer});

/// Longer clinic texts used by `faker.clinic`: consent forms, satisfaction
/// feedback, counseling transcripts, public integration responses,
/// insurers, device kinds, collaboration notes, and family relations.
///
/// Every text is an example for demos and tests. Consent forms in
/// particular are **not** legally reviewed documents.
class CoFakerClinicTexts {
  /// Creates a clinic text set.
  const CoFakerClinicTexts({
    required this.consentForms,
    required this.consentDisclaimer,
    required this.feedback,
    required this.counselTopics,
    required this.counselScript,
    required this.integrationResults,
    required this.insurers,
    required this.teamNotes,
    required this.deviceNameFormat,
    required this.labels,
    this.staffMentionFormat = '@{name} {role}',
    this.nameMentionFormat = '@{name}',
  });

  /// Consent form templates.
  final List<CoConsentFormSpec> consentForms;

  /// The notice attached to every generated consent form stating that it
  /// is an example and not a legal document.
  final String consentDisclaimer;

  /// Satisfaction comments keyed by sentiment: `positive`, `neutral`,
  /// `negative`.
  final Map<String, List<String>> feedback;

  /// Counseling topics.
  final List<CoCounselTopicSpec> counselTopics;

  /// Fixed counseling lines.
  final CoCounselScriptSpec counselScript;

  /// Public integration responses keyed by service code (`eligibility`,
  /// `dur`, `insuranceClaim`, `ePrescription`, `identityQr`).
  final Map<String, List<CoIntegrationResultSpec>> integrationResults;

  /// Fictional private insurer names.
  final List<String> insurers;

  /// Collaboration note templates with `{mention}` (an `@name title`),
  /// and `{patient}` placeholders.
  final List<String> teamNotes;

  /// Device display name template with `{kind}` and `{number}`.
  final String deviceNameFormat;

  /// Labels for relation codes, device kinds, sentiments, speakers, and
  /// consent kinds.
  final Map<String, String> labels;

  /// How `teamNote` mentions an invented staff member: `{name}` is the
  /// staff name and `{role}` the role label. English writes `@{name} {role}`
  /// (`@Ann Author Nurse`); Korean adds the honorific, `@{name} {role}님`.
  final String staffMentionFormat;

  /// How `teamNote` mentions a staff member whose name the caller passed:
  /// `@{name}` in English, `@{name}님` in Korean.
  final String nameMentionFormat;

  /// Korean clinic texts.
  static const CoFakerClinicTexts korean = CoFakerClinicTexts(
    consentForms: <CoConsentFormSpec>[
      (
        kind: 'procedure',
        title: '시술 동의서',
        clauses: <String>[
          '본인은 시술의 목적·방법·예상 효과에 대해 설명을 들었습니다.',
          '시술 후 붉은기·부기·멍·일시적 색소침착 등이 나타날 수 있음을 안내받았습니다.',
          '효과에는 개인차가 있으며 결과를 보장하지 않음을 이해합니다.',
          '복용 중인 약·알레르기·임신 여부를 사실대로 알렸습니다.',
          '시술 후 주의사항을 지키지 않아 생긴 문제는 본인에게 책임이 있음을 이해합니다.',
        ],
      ),
      (
        kind: 'privacy',
        title: '개인정보 수집·이용 동의서',
        clauses: <String>[
          '수집 항목: 성명, 생년월일, 연락처, 주소, 진료 기록',
          '수집 목적: 진료, 예약 안내, 수납',
          '보유 기간: 관계 법령에 따른 진료기록 보존 기간',
          '동의를 거부할 수 있으나, 거부 시 예약 서비스 이용이 제한될 수 있습니다.',
        ],
      ),
      (
        kind: 'photo',
        title: '사진 촬영·활용 동의서',
        clauses: <String>[
          '시술 전후 경과 확인을 위해 사진을 촬영합니다.',
          '촬영한 사진은 진료 목적으로만 사용하며 외부에 공개하지 않습니다.',
          '학술·홍보 목적 사용은 별도 동의를 받습니다.',
        ],
      ),
      (
        kind: 'marketing',
        title: '마케팅 정보 수신 동의서',
        clauses: <String>[
          '이벤트·할인 소식을 문자·알림톡으로 받습니다.',
          '수신 동의는 언제든 철회할 수 있습니다.',
          '동의하지 않아도 진료에는 영향이 없습니다.',
        ],
      ),
      (
        kind: 'anesthesia',
        title: '국소 마취 동의서',
        clauses: <String>[
          '국소 마취제(마취크림·주사) 사용에 대한 설명을 들었습니다.',
          '드물게 과민 반응이 나타날 수 있음을 안내받았습니다.',
          '과거 마취 관련 이상 반응 이력을 사실대로 알렸습니다.',
        ],
      ),
    ],
    consentDisclaimer: '※ 데모용 예시 문구입니다. 법률 검토를 거친 서식이 아니며 실제 동의서로 사용할 수 없습니다.',
    feedback: <String, List<String>>{
      'positive': <String>[
        '원장님이 꼼꼼하게 설명해 주셔서 안심됐어요.',
        '대기 시간이 짧고 직원분들이 친절했어요.',
        '시술 후 관리 안내 문자가 도움이 됐어요.',
        '토닝 3회 만에 톤이 밝아졌어요. 만족합니다.',
        '예약부터 수납까지 빠르게 진행돼서 좋았어요.',
        '상담실장님이 부담 없이 필요한 것만 추천해 주셨어요.',
      ],
      'neutral': <String>[
        '효과는 좋은데 가격이 조금 부담돼요.',
        '주차가 조금 불편했어요.',
        '대기실이 붐벼서 조금 기다렸어요.',
        '설명은 좋았지만 상담 시간이 짧았어요.',
      ],
      'negative': <String>[
        '예약 시간보다 40분 넘게 기다렸어요.',
        '시술 후 붉은기가 오래가서 걱정됐어요.',
        '상담 때 안내받은 가격과 수납 금액이 달랐어요.',
        '전화 연결이 잘 안 돼요.',
      ],
    },
    counselTopics: <CoCounselTopicSpec>[
      (
        topic: 'toning',
        procedureCode: 'LT-01',
        procedure: '피코 레이저 토닝',
        concern: '양쪽 볼에 기미가 짙어져서 고민이에요.',
        recommend: '색소 고민에는 피코 레이저 토닝을 권해 드려요. 색소를 잘게 부숴 톤을 정리합니다.',
        pain: '따끔한 정도라 마취 없이도 대부분 받으세요.',
        interval: '2주 간격으로 10회 정도 받으시면 좋아요.',
        downtime: '붉은기가 몇 시간 정도 있고 당일 세안 가능합니다.',
        sessions: 10,
      ),
      (
        topic: 'lifting',
        procedureCode: 'HIFU-300',
        procedure: '고강도 초음파 리프팅',
        concern: '턱선이 처지고 볼살이 내려온 느낌이에요.',
        recommend: '고강도 초음파 리프팅으로 깊은 층을 당겨 드리는 방법이 있어요.',
        pain: '뼈 가까운 부위는 뻐근할 수 있어서 마취크림을 발라 드려요.',
        interval: '6개월에서 1년에 한 번이면 충분해요.',
        downtime: '일상생활 바로 가능하고 가벼운 부기 정도만 있어요.',
        sessions: 3,
      ),
      (
        topic: 'botox',
        procedureCode: 'BTX-J',
        procedure: '사각턱 보톡스',
        concern: '얼굴이 각져 보여서 턱 라인을 갸름하게 하고 싶어요.',
        recommend: '씹는 근육이 발달하셔서 사각턱 보톡스가 잘 맞으실 거예요.',
        pain: '가는 바늘이라 따끔한 정도예요.',
        interval: '4~6개월 간격으로 맞으시면 유지돼요.',
        downtime: '당일 일상생활 가능하고 한 시간 정도만 누르지 않으시면 돼요.',
        sessions: 3,
      ),
      (
        topic: 'acne',
        procedureCode: 'ACN-01',
        procedure: '여드름 압출 + 진정관리',
        concern: '턱이랑 볼에 여드름이 계속 올라와요.',
        recommend: '염증성 여드름이라 압출 후 진정관리를 같이 해 드릴게요.',
        pain: '압출할 때 조금 아플 수 있어요.',
        interval: '1~2주 간격으로 5회 정도 권해 드려요.',
        downtime: '하루 이틀 붉은 자국이 남을 수 있어요.',
        sessions: 5,
      ),
      (
        topic: 'booster',
        procedureCode: 'SB-PN',
        procedure: 'PN 스킨부스터',
        concern: '피부가 푸석하고 잔주름이 늘었어요.',
        recommend: 'PN 스킨부스터로 피부 재생과 탄력을 올려 드릴 수 있어요.',
        pain: '마취크림을 바르고 진행해서 참을 만하세요.',
        interval: '4주 간격 3회가 기본이에요.',
        downtime: '주사 자국이 하루 정도 남을 수 있어요.',
        sessions: 3,
      ),
    ],
    counselScript: (
      greeting: '안녕하세요, 오늘 어떤 부분이 고민이셔서 오셨어요?',
      questions: <String, String>{
        'pain': '많이 아픈가요?',
        'interval': '얼마나 자주 받아야 해요?',
        'downtime': '끝나고 바로 출근해도 되나요?',
        'price': '가격은 어떻게 돼요?',
      },
      priceAnswer: '1회 {price}원이고, {sessions}회 패키지로 하시면 {packagePrice}원이에요.',
      bookYes: '그럼 이번 주에 예약할게요.',
      bookYesReply: '네, 예약 도와드릴게요. 시술 전 주의사항은 문자로 보내 드릴게요.',
      bookNo: '조금 더 생각해 보고 연락드릴게요.',
      bookNoReply: '네, 궁금한 점 있으시면 언제든 연락 주세요.',
      summary:
          '{procedure} 권유 — 1회 {price}원, {sessions}회 패키지 {packagePrice}원 견적. {outcome}',
      booked: '예약 진행.',
      pending: '결정 보류, 재연락 예정.',
    ),
    integrationResults: <String, List<CoIntegrationResultSpec>>{
      'eligibility': <CoIntegrationResultSpec>[
        (code: 'OK', message: '건강보험 자격 확인 — 직장가입자', ok: true),
        (code: 'OK', message: '건강보험 자격 확인 — 지역가입자', ok: true),
        (code: 'OK', message: '의료급여 1종 수급권자 확인', ok: true),
        (code: 'LOST', message: '자격 상실자 — 본인 확인 필요', ok: false),
        (code: 'RESTRICTED', message: '급여 제한 대상자', ok: false),
        (code: 'NOT_FOUND', message: '조회 결과 없음 — 입력 정보 확인', ok: false),
      ],
      'dur': <CoIntegrationResultSpec>[
        (code: 'OK', message: 'DUR 점검 완료 — 금기 없음', ok: true),
        (code: 'WARN_COMBINATION', message: '병용금기 경고 — 처방 사유 입력 필요', ok: false),
        (code: 'WARN_AGE', message: '연령금기 경고', ok: false),
        (code: 'WARN_DUPLICATE', message: '동일성분 중복 처방', ok: false),
      ],
      'insuranceClaim': <CoIntegrationResultSpec>[
        (code: 'ACCEPTED', message: '청구 접수 완료', ok: true),
        (code: 'REVIEWED', message: '심사 완료 — 조정 없음', ok: true),
        (code: 'ADJUSTED', message: '심사 조정 — 산정 기준 초과', ok: false),
        (code: 'ADJUSTED', message: '심사 조정 — 상병과 처치 불일치', ok: false),
        (code: 'RETURNED', message: '반송 — 필수 기재 사항 누락', ok: false),
      ],
      'ePrescription': <CoIntegrationResultSpec>[
        (code: 'SENT', message: '전자처방전 전송 완료', ok: true),
        (code: 'FAILED', message: '약국 수신 실패 — 재전송 필요', ok: false),
      ],
      'identityQr': <CoIntegrationResultSpec>[
        (code: 'OK', message: '본인 확인 완료 (모바일 신분증)', ok: true),
        (code: 'EXPIRED', message: 'QR 유효 시간 만료 — 다시 발급 필요', ok: false),
      ],
    },
    insurers: <String>['한결생명', '다온손해보험', '새빛화재', '바른누리생명', '하늘결손해보험', '미래든생명'],
    teamNotes: <String>[
      '{mention}, {patient}님 레이저 강도 한 단계 낮춰서 진행 부탁드려요.',
      '{mention}, {patient}님 상담 내용 차트에 정리해 두었습니다. 확인 부탁드립니다.',
      '인계: {patient}님 마취크림 도포 완료. {mention} 시술 들어가시면 됩니다.',
      '{mention}, {patient}님 회차권 1회 남았습니다. 재구매 안내 부탁드려요.',
      '{patient}님 시술 후 홍반 있어 진정관리 추가했습니다. {mention} 참고해 주세요.',
      '{mention}, {patient}님 보호자 동반 내원 — 보호자 서명 필요합니다.',
      '인계: {patient}님 예약 30분 지연 예정, {mention} 일정 조정 부탁드립니다.',
    ],
    deviceNameFormat: '{kind} {number}호기',
    staffMentionFormat: '@{name} {role}님',
    nameMentionFormat: '@{name}님',
    labels: <String, String>{
      'self': '본인',
      'spouse': '배우자',
      'parent': '부모',
      'child': '자녀',
      'sibling': '형제자매',
      'grandparent': '조부모',
      'grandchild': '손자녀',
      'legalGuardian': '법정대리인',
      'other': '기타',
      'picoLaser': '피코 레이저',
      'hifu': 'HIFU',
      'rf': '고주파',
      'ipl': 'IPL',
      'ledTherapy': 'LED 관리기',
      'skinAnalyzer': '피부 분석기',
      'photoCamera': '임상 사진 카메라',
      'labelPrinter': '라벨 프린터',
      'cardTerminal': '카드 단말기',
      'signaturePad': '서명 패드',
      'kiosk': '접수 키오스크',
      'bridgePc': '브리지 PC',
      'positive': '긍정',
      'neutral': '보통',
      'negative': '부정',
      'counselor': '상담사',
      'patientSpeaker': '환자',
      'life': '생명보험',
      'nonLife': '손해보험',
    },
  );

  /// English clinic texts, the fallback for every other locale.
  static const CoFakerClinicTexts english = CoFakerClinicTexts(
    consentForms: <CoConsentFormSpec>[
      (
        kind: 'procedure',
        title: 'Procedure consent',
        clauses: <String>[
          'I was told the purpose, method, and expected effect of the procedure.',
          'I understand redness, swelling, or bruising may follow.',
          'I understand results vary and are not guaranteed.',
          'I disclosed my medication, allergies, and pregnancy status.',
        ],
      ),
      (
        kind: 'privacy',
        title: 'Privacy consent',
        clauses: <String>[
          'Collected: name, date of birth, contact details, medical records.',
          'Purpose: treatment, appointment reminders, billing.',
          'I may refuse, but online booking may then be unavailable.',
        ],
      ),
      (
        kind: 'photo',
        title: 'Photography consent',
        clauses: <String>[
          'Before and after photos are taken to track progress.',
          'Photos are used for treatment only and never published.',
        ],
      ),
    ],
    consentDisclaimer:
        'Example text for demos only. Not legally reviewed; do not use as a '
        'real consent form.',
    feedback: <String, List<String>>{
      'positive': <String>[
        'The doctor explained everything carefully.',
        'Short wait and a friendly team.',
        'My skin tone improved after three sessions.',
      ],
      'neutral': <String>[
        'Good results, but a bit pricey.',
        'Parking was inconvenient.',
      ],
      'negative': <String>[
        'I waited over 40 minutes past my appointment.',
        'The final bill differed from the quote.',
      ],
    },
    counselTopics: <CoCounselTopicSpec>[
      (
        topic: 'toning',
        procedureCode: 'LT-01',
        procedure: 'picosecond laser toning',
        concern: 'The dark patches on my cheeks are getting worse.',
        recommend: 'For pigmentation I recommend picosecond laser toning.',
        pain: 'It stings a little; most people need no anesthetic.',
        interval: 'About ten sessions, two weeks apart.',
        downtime: 'Some redness for a few hours; you can wash the same day.',
        sessions: 10,
      ),
      (
        topic: 'lifting',
        procedureCode: 'HIFU-300',
        procedure: 'focused ultrasound lifting',
        concern: 'My jawline feels saggy.',
        recommend: 'Focused ultrasound lifting tightens the deeper layers.',
        pain: 'It can ache near the bone, so we apply a numbing cream.',
        interval: 'Once every six to twelve months.',
        downtime: 'You can go back to work right away.',
        sessions: 3,
      ),
    ],
    counselScript: (
      greeting: 'Hello, what brings you in today?',
      questions: <String, String>{
        'pain': 'Does it hurt?',
        'interval': 'How often do I need it?',
        'downtime': 'Can I go to work right after?',
        'price': 'How much is it?',
      },
      priceAnswer:
          'It is {price} per session, or {packagePrice} for a '
          '{sessions}-session package.',
      bookYes: "Great, I'd like to book this week.",
      bookYesReply: "Sure, I'll book it and text you the aftercare notes.",
      bookNo: "I'll think about it and get back to you.",
      bookNoReply: 'Of course, reach out any time.',
      summary:
          'Recommended {procedure}: {price} per session, {packagePrice} for '
          '{sessions}. {outcome}',
      booked: 'Booked.',
      pending: 'Undecided, follow up later.',
    ),
    integrationResults: <String, List<CoIntegrationResultSpec>>{
      'eligibility': <CoIntegrationResultSpec>[
        (code: 'OK', message: 'Coverage verified', ok: true),
        (code: 'LOST', message: 'Coverage terminated', ok: false),
        (code: 'NOT_FOUND', message: 'No matching member', ok: false),
      ],
      'dur': <CoIntegrationResultSpec>[
        (code: 'OK', message: 'No interactions found', ok: true),
        (
          code: 'WARN_COMBINATION',
          message: 'Drug interaction warning',
          ok: false,
        ),
      ],
      'insuranceClaim': <CoIntegrationResultSpec>[
        (code: 'ACCEPTED', message: 'Claim received', ok: true),
        (code: 'ADJUSTED', message: 'Claim adjusted on review', ok: false),
        (
          code: 'RETURNED',
          message: 'Claim returned: missing fields',
          ok: false,
        ),
      ],
      'ePrescription': <CoIntegrationResultSpec>[
        (code: 'SENT', message: 'E-prescription sent', ok: true),
        (code: 'FAILED', message: 'Pharmacy did not receive it', ok: false),
      ],
      'identityQr': <CoIntegrationResultSpec>[
        (code: 'OK', message: 'Identity verified', ok: true),
        (code: 'EXPIRED', message: 'QR code expired', ok: false),
      ],
    },
    insurers: <String>[
      'Northwind Mutual',
      'Harborview Life',
      'Summitline Assurance',
      'Clearbrook Health',
    ],
    teamNotes: <String>[
      '{mention}, please lower the laser setting one step for {patient}.',
      'Handoff: {patient} has numbing cream on. {mention}, ready when you are.',
      '{mention}, {patient} has one package session left.',
      '{patient} needs a guardian signature. {mention}, please check.',
    ],
    deviceNameFormat: '{kind} #{number}',
    staffMentionFormat: '@{name} {role}',
    nameMentionFormat: '@{name}',
    labels: <String, String>{
      'self': 'Self',
      'spouse': 'Spouse',
      'parent': 'Parent',
      'child': 'Child',
      'sibling': 'Sibling',
      'grandparent': 'Grandparent',
      'grandchild': 'Grandchild',
      'legalGuardian': 'Legal guardian',
      'other': 'Other',
      'picoLaser': 'Pico laser',
      'hifu': 'HIFU',
      'rf': 'RF',
      'ipl': 'IPL',
      'ledTherapy': 'LED therapy',
      'skinAnalyzer': 'Skin analyzer',
      'photoCamera': 'Clinical camera',
      'labelPrinter': 'Label printer',
      'cardTerminal': 'Card terminal',
      'signaturePad': 'Signature pad',
      'kiosk': 'Check-in kiosk',
      'bridgePc': 'Bridge PC',
      'positive': 'Positive',
      'neutral': 'Neutral',
      'negative': 'Negative',
      'counselor': 'Counselor',
      'patientSpeaker': 'Patient',
      'life': 'Life',
      'nonLife': 'Non-life',
    },
  );

  /// Foreign-patient inquiries and replies keyed by language code (`ko`,
  /// `en`, `ja`, `zh`, `vi`). Independent of the faker locale: a Korean
  /// clinic inbox receives messages in many languages.
  ///
  /// The lists are index-aligned: item `i` of every language is a
  /// translation of item `i` of `ko`, which `clinic.inquiry` uses for the
  /// Korean translation of each turn.
  static const Map<String, List<CoInquirySpec>> inquiries =
      <String, List<CoInquirySpec>>{
        'ko': <CoInquirySpec>[
          (
            question: '안녕하세요, 다음 주에 피코 토닝 예약 가능할까요?',
            answer: '문의 감사합니다. 원하시는 날짜와 시간을 알려 주세요.',
          ),
          (
            question: '기미 치료 가격이 궁금해요.',
            answer: '1회 99,000원(부가세 포함)이며 상담 후 정확히 안내해 드립니다.',
          ),
          (question: '외국어가 가능한 직원이 있나요?', answer: '네, 통역 가능한 코디네이터가 도와드립니다.'),
          (
            question: '회복 기간은 얼마나 걸리나요?',
            answer: '대부분 당일 일상생활이 가능하고 붉은기는 몇 시간 내 가라앉아요.',
          ),
          (question: '시술 후 바로 화장해도 되나요?', answer: '시술 후 24시간은 화장을 피해 주세요.'),
        ],
        'en': <CoInquirySpec>[
          (
            question: 'Hi, can I book pico toning next week?',
            answer: 'Thanks for reaching out. Which day and time work for you?',
          ),
          (
            question: 'How much is melasma treatment?',
            answer: 'It is 99,000 KRW per session, VAT included.',
          ),
          (
            question: 'Do you have English-speaking staff?',
            answer: 'Yes, an English-speaking coordinator will assist you.',
          ),
          (
            question: 'How long is the downtime?',
            answer: 'Almost none. You can wash your face the same day.',
          ),
          (
            question: 'Can I wear makeup right after?',
            answer: 'Please avoid makeup for 24 hours after the treatment.',
          ),
        ],
        'ja': <CoInquirySpec>[
          (
            question: 'こんにちは。来週ピコトーニングの予約はできますか？',
            answer: 'お問い合わせありがとうございます。ご希望の日時を教えてください。',
          ),
          (question: 'シミ治療の料金を教えてください。', answer: '1回99,000ウォン（税込）です。'),
          (question: '日本語が話せるスタッフはいますか？', answer: '日本語通訳スタッフが対応いたします。'),
          (question: 'ダウンタイムはどのくらいですか？', answer: 'ほとんどありません。当日から洗顔可能です。'),
          (question: '施術後すぐにメイクできますか？', answer: '施術後24時間はメイクをお控えください。'),
        ],
        'zh': <CoInquirySpec>[
          (question: '你好，我想预约下周的皮秒激光。', answer: '感谢您的咨询，请告诉我们您方便的时间。'),
          (question: '请问祛斑的价格是多少？', answer: '单次价格为99,000韩元（含税）。'),
          (question: '有会说中文的工作人员吗？', answer: '我们有中文翻译人员为您服务。'),
          (question: '恢复期需要多久？', answer: '基本没有恢复期，当天即可洗脸。'),
          (question: '做完可以马上化妆吗？', answer: '术后24小时内请不要化妆。'),
        ],
        'vi': <CoInquirySpec>[
          (
            question: 'Xin chào, tôi muốn đặt lịch laser pico vào tuần sau.',
            answer:
                'Cảm ơn bạn đã liên hệ. Vui lòng cho biết thời gian bạn muốn '
                'đặt lịch.',
          ),
          (
            question: 'Cho tôi hỏi giá điều trị nám là bao nhiêu?',
            answer: 'Giá một lần là 99.000 won (đã gồm thuế).',
          ),
          (
            question: 'Có nhân viên nói tiếng Việt không?',
            answer: 'Chúng tôi có nhân viên phiên dịch hỗ trợ bạn.',
          ),
          (
            question: 'Thời gian hồi phục mất bao lâu?',
            answer: 'Hầu như không có, bạn có thể rửa mặt ngay trong ngày.',
          ),
          (
            question: 'Sau khi làm có trang điểm ngay được không?',
            answer: 'Vui lòng không trang điểm trong 24 giờ sau khi điều trị.',
          ),
        ],
      };

  /// The messenger channel most used by patients of each language.
  static const Map<String, String> preferredChannels = <String, String>{
    'ko': 'kakao',
    'en': 'whatsapp',
    'ja': 'line',
    'zh': 'wechat',
    'vi': 'zalo',
  };
}

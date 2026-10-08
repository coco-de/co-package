import 'clinic_ops.dart';
import 'clinic_texts.dart';
import 'currency_format.dart';
import 'korean_values.dart';

/// A billable procedure, product, or fee line with a typical price band.
///
/// Prices are whole units of the currency of the data set
/// ([CoFakerClinicData.currency]): won for Korean, dollars for English. They
/// include VAT where [taxable] is `true`.
typedef CoProcedureSpec = ({
  String code,
  String category,
  String name,
  String unit,
  int minPrice,
  int maxPrice,
  bool taxable,
});

/// A diagnosis entry: an ICD-10 style [code] with localized and English names.
typedef CoDiagnosisSpec = ({String code, String name, String nameEn});

/// A questionnaire item with the answers a patient can pick from.
typedef CoQuestionSpec = ({String question, List<String> options});

/// A visit purpose with its more specific sub-purposes.
typedef CoVisitPurposeSpec = ({String name, List<String> details});

/// A clinic specialty and the suffix used to build clinic names.
typedef CoSpecialtySpec = ({String name, String clinicSuffix});

/// The price scale of a clinic data set: the units generated amounts are
/// rounded to and the thresholds that decide when a payment can be split or
/// paid in installments, all in the currency of the data
/// ([CoFakerClinicData.currency]).
///
/// The defaults are the scale of a US-dollar clinic ([english]); [korean] is
/// the scale of the won, where the same prices are roughly a thousand times
/// larger. A language with another currency sets every value in its own
/// currency: a rounding unit that a price tag in that currency uses, and
/// thresholds that sit where dollar prices would, converted. The procedure
/// price bands ([CoProcedureSpec.minPrice]) belong to the same currency.
class CoClinicPriceScale {
  /// Creates a price scale. The defaults are [english].
  const CoClinicPriceScale({
    this.priceRounding = 5,
    this.packageRounding = 10,
    this.prepaidStep = 10,
    this.installmentMinimum = 500,
    this.splitMinimum = 50,
    this.splitRounding = 1,
    this.adjustmentUnit = 1,
    this.pointUnit = 1,
    this.quoteMin = 50000,
    this.quoteMax = 300000,
  }) : assert(priceRounding > 0, 'priceRounding must be positive'),
       assert(packageRounding > 0, 'packageRounding must be positive'),
       assert(prepaidStep > 0, 'prepaidStep must be positive'),
       assert(splitRounding > 0, 'splitRounding must be positive'),
       assert(adjustmentUnit > 0, 'adjustmentUnit must be positive'),
       assert(pointUnit > 0, 'pointUnit must be positive'),
       assert(quoteMin <= quoteMax, 'quoteMin must not exceed quoteMax');

  /// The scale of US dollars: the scale of the English data.
  static const CoClinicPriceScale english = CoClinicPriceScale();

  /// The scale of Korean won: the scale of the Korean data.
  static const CoClinicPriceScale korean = CoClinicPriceScale(
    priceRounding: 1000,
    packageRounding: 10000,
    prepaidStep: 10000,
    installmentMinimum: 500000,
    splitMinimum: 50000,
    splitRounding: 1000,
    adjustmentUnit: 1000,
    pointUnit: 100,
  );

  /// Procedure prices are rounded to a multiple of this (`procedure`).
  final int priceRounding;

  /// Session package prices are rounded to a multiple of this (`package`
  /// and the package quote of `counselSession`).
  final int packageRounding;

  /// A prepaid balance is a multiple of this, up to a hundred of them
  /// (`prepaidBalance`).
  final int prepaidStep;

  /// The smallest card payment that may be paid in installments
  /// (`payment`).
  final int installmentMinimum;

  /// The smallest payment that `splitPayment` splits into several; a smaller
  /// one stays a single payment.
  final int splitMinimum;

  /// The shares of a split payment are rounded to a multiple of this
  /// (`splitPayment`).
  final int splitRounding;

  /// Discounts, coupons, and rounding adjustments are multiples of this, and
  /// the `rounding` adjustment cuts the remainder below it (`adjustment`).
  final int adjustmentUnit;

  /// A point transaction is one to fifty times this (`pointTransaction`).
  final int pointUnit;

  /// The lowest price of a counseling quote for a topic whose procedure is
  /// not in the catalog (`counselSession`). The built-in catalogs list every
  /// topic procedure, so only partial custom data reaches it.
  final int quoteMin;

  /// The highest price of such a quote; see [quoteMin].
  final int quoteMax;
}

/// Clinic and EMR domain data used by `faker.clinic`.
///
/// Codes such as staff role, insurance, visit stage, reservation status, and
/// payment method codes are locale independent; only their labels are
/// localized. Every list must be non-empty. Build a partial locale by
/// copying one of the built-in data sets with the fields you need.
///
/// The data also decides how amounts and a few values are generated, so a
/// language only has to add data. [currency] and [priceScale] give the
/// currency format and the price units, [clinicNameFormat] the order of a
/// clinic name, and [koreanValues] says whether the Korean-only values
/// (resident registration numbers, card approval and cash receipt numbers,
/// the Korean holiday calendar, Korean phone numbers and addresses) are
/// generated. Texts that the generators assemble (the `회` of a package, the
/// `님` of a mention, holiday names, date labels) are fields of
/// [CoFakerClinicTexts] and [CoFakerClinicOps].
///
/// A language that has no data of its own gets the English data: see
/// `CoFaker`.
class CoFakerClinicData {
  /// Creates a clinic data set.
  const CoFakerClinicData({
    required this.specialties,
    required this.clinicNamePrefixes,
    required this.staffRoles,
    required this.visitPurposes,
    required this.procedures,
    required this.diagnoses,
    required this.drugStems,
    required this.drugForms,
    required this.drugUsages,
    required this.complaints,
    required this.findings,
    required this.plans,
    required this.memos,
    required this.questions,
    required this.cardIssuers,
    required this.labels,
    required this.packageNameFormat,
    this.texts,
    this.ops,
    this.clinicNameFormat = '{prefix} {suffix}',
    this.currency = CoCurrencyFormat.usd,
    this.priceScale = CoClinicPriceScale.english,
    this.koreanValues = CoKoreanValues.legacy,
    this.maskedIdFormat = '***-**-####',
  });

  /// Specialties and their clinic name suffixes.
  final List<CoSpecialtySpec> specialties;

  /// Words placed before the specialty suffix in clinic names.
  final List<String> clinicNamePrefixes;

  /// Staff roles keyed by a stable code (`director`, `nurse`, ...).
  final Map<String, String> staffRoles;

  /// Visit purposes and their sub-purposes.
  final List<CoVisitPurposeSpec> visitPurposes;

  /// Procedures, products, drugs, materials, and documents with price bands.
  final List<CoProcedureSpec> procedures;

  /// An illustrative subset of public ICD-10 / KCD diagnosis codes.
  final List<CoDiagnosisSpec> diagnoses;

  /// Fictional drug name stems. They are invented and must not match a
  /// marketed product.
  final List<String> drugStems;

  /// Dosage forms: `(form suffix, strength unit, strengths)`.
  final List<({String form, String unit, List<int> strengths})> drugForms;

  /// Usage instructions for prescriptions.
  final List<String> drugUsages;

  /// Chief complaints for the subjective part of a SOAP note.
  final List<String> complaints;

  /// Examination findings for the objective part of a SOAP note.
  final List<String> findings;

  /// Treatment plans for the plan part of a SOAP note.
  final List<String> plans;

  /// Short free-form chart memos.
  final List<String> memos;

  /// Intake questionnaire items.
  final List<CoQuestionSpec> questions;

  /// Card issuer display names.
  final List<String> cardIssuers;

  /// Labels for the locale independent codes used by the clinic module:
  /// insurance types, visit stages, reservation statuses, and payment
  /// methods (`nhis`, `waiting`, `noShow`, `prepaid`, ...).
  final Map<String, String> labels;

  /// Package name template with `{name}` and `{sessions}` placeholders.
  final String packageNameFormat;

  /// Longer texts (consent forms, feedback, counseling, notes, ...), or
  /// `null` to use [CoFakerClinicTexts.english].
  final CoFakerClinicTexts? texts;

  /// Front-desk, billing, operations, and CRM texts, or `null` to use
  /// [CoFakerClinicOps.english].
  final CoFakerClinicOps? ops;

  /// Clinic name template with `{prefix}` (one of [clinicNamePrefixes]) and
  /// `{suffix}` ([CoSpecialtySpec.clinicSuffix]) placeholders. English writes
  /// `{prefix} {suffix}` (`Maple Pediatrics`); Korean writes the words
  /// together with `{prefix}{suffix}` (`맑은피부과의원`), as other languages
  /// without word spaces do.
  final String clinicNameFormat;

  /// How amounts are written in texts: `$1,234` for [CoCurrencyFormat.usd],
  /// `1,234` for [CoCurrencyFormat.korean]. See `faker.clinic.money`.
  final CoCurrencyFormat currency;

  /// The rounding units and thresholds of generated prices, in [currency].
  final CoClinicPriceScale priceScale;

  /// Which Korean-only values the generators produce:
  /// [CoKoreanValues.korean] for the Korean data, [CoKoreanValues.legacy]
  /// (the default) for the English data, and [CoKoreanValues.none] for new
  /// language data.
  final CoKoreanValues koreanValues;

  /// The masked ID number of a patient (`patient().rrnMasked`) when
  /// [koreanValues] is [CoKoreanValues.none]: `#` is a random digit and any
  /// other character is written as it is, so `***-**-####` gives
  /// `***-**-4821`. Korean and legacy data generate a masked resident
  /// registration number (`YYMMDD-G******`) instead.
  final String maskedIdFormat;

  /// Korean clinic data: dermatology and aesthetic clinics first, in won,
  /// with every Korean-only value ([CoKoreanValues.korean]).
  static const CoFakerClinicData korean = CoFakerClinicData(
    specialties: <CoSpecialtySpec>[
      (name: '피부과', clinicSuffix: '피부과의원'),
      (name: '성형외과', clinicSuffix: '성형외과의원'),
      (name: '가정의학과', clinicSuffix: '의원'),
      (name: '내과', clinicSuffix: '내과의원'),
      (name: '정형외과', clinicSuffix: '정형외과의원'),
      (name: '이비인후과', clinicSuffix: '이비인후과의원'),
      (name: '안과', clinicSuffix: '안과의원'),
      (name: '소아청소년과', clinicSuffix: '소아청소년과의원'),
    ],
    clinicNamePrefixes: <String>[
      '맑은',
      '바른',
      '새봄',
      '하늘빛',
      '미소',
      '라온',
      '온담',
      '고운',
      '봄날',
      '해맑은',
      '결',
      '청아',
      '데모',
      '예시',
      '다온',
      '윤슬',
    ],
    staffRoles: <String, String>{
      'director': '원장',
      'doctor': '의사',
      'counselor': '상담실장',
      'coordinator': '코디네이터',
      'nurse': '간호사',
      'nurseAide': '간호조무사',
      'skincare': '피부관리사',
      'desk': '데스크',
    },
    visitPurposes: <CoVisitPurposeSpec>[
      (name: '상담', details: <String>['첫 상담', '재상담', '시술 상담']),
      (name: '시술', details: <String>['보톡스·필러', '레이저', '리프팅', '스킨부스터']),
      (name: '진료', details: <String>['여드름', '피부질환', '점·사마귀']),
      (name: '관리', details: <String>['피부관리', '진정관리']),
    ],
    procedures: <CoProcedureSpec>[
      (
        code: 'CONS01',
        category: '진찰/진찰료',
        name: '비급여 초진 진찰료',
        unit: '회',
        minPrice: 10000,
        maxPrice: 20000,
        taxable: false,
      ),
      (
        code: 'CONS02',
        category: '진찰/진찰료',
        name: '비급여 재진 진찰료',
        unit: '회',
        minPrice: 5000,
        maxPrice: 15000,
        taxable: false,
      ),
      (
        code: 'BTX-F',
        category: '보톡스/주름',
        name: '주름 보톡스 이마',
        unit: '부위',
        minPrice: 30000,
        maxPrice: 90000,
        taxable: true,
      ),
      (
        code: 'BTX-G',
        category: '보톡스/주름',
        name: '주름 보톡스 미간',
        unit: '부위',
        minPrice: 20000,
        maxPrice: 60000,
        taxable: true,
      ),
      (
        code: 'BTX-J',
        category: '보톡스/윤곽',
        name: '사각턱 보톡스',
        unit: '부위',
        minPrice: 50000,
        maxPrice: 250000,
        taxable: true,
      ),
      (
        code: 'BTX-S',
        category: '보톡스/스킨',
        name: '스킨 보톡스 얼굴 전체',
        unit: '회',
        minPrice: 100000,
        maxPrice: 250000,
        taxable: true,
      ),
      (
        code: 'FIL-N',
        category: '필러/부위',
        name: '히알루론산 필러 코 1cc',
        unit: 'cc',
        minPrice: 150000,
        maxPrice: 350000,
        taxable: true,
      ),
      (
        code: 'FIL-L',
        category: '필러/부위',
        name: '히알루론산 필러 입술 1cc',
        unit: 'cc',
        minPrice: 200000,
        maxPrice: 400000,
        taxable: true,
      ),
      (
        code: 'LT-01',
        category: '레이저/토닝',
        name: '피코 레이저 토닝',
        unit: '회',
        minPrice: 59000,
        maxPrice: 150000,
        taxable: true,
      ),
      (
        code: 'LT-02',
        category: '레이저/토닝',
        name: '레이저 토닝 (색소)',
        unit: '회',
        minPrice: 49000,
        maxPrice: 120000,
        taxable: true,
      ),
      (
        code: 'IPL-01',
        category: '레이저/색소',
        name: 'IPL 광치료 얼굴 전체',
        unit: '회',
        minPrice: 70000,
        maxPrice: 150000,
        taxable: true,
      ),
      (
        code: 'CO2-01',
        category: '레이저/점',
        name: '점 제거 (CO2, 개당)',
        unit: '개',
        minPrice: 5000,
        maxPrice: 20000,
        taxable: true,
      ),
      (
        code: 'HIFU-300',
        category: '리프팅/HIFU',
        name: '고강도 초음파 리프팅 300샷',
        unit: '회',
        minPrice: 190000,
        maxPrice: 1800000,
        taxable: true,
      ),
      (
        code: 'RF-300',
        category: '리프팅/RF',
        name: '고주파 리프팅 300샷',
        unit: '회',
        minPrice: 900000,
        maxPrice: 2000000,
        taxable: true,
      ),
      (
        code: 'LIFT-01',
        category: '리프팅/실',
        name: '실 리프팅 (1줄)',
        unit: '줄',
        minPrice: 100000,
        maxPrice: 200000,
        taxable: true,
      ),
      (
        code: 'SB-PN',
        category: '스킨부스터/주사',
        name: 'PN 스킨부스터 2cc',
        unit: '회',
        minPrice: 250000,
        maxPrice: 450000,
        taxable: true,
      ),
      (
        code: 'SB-HA',
        category: '스킨부스터/주사',
        name: '물광 주사 2cc',
        unit: '회',
        minPrice: 100000,
        maxPrice: 250000,
        taxable: true,
      ),
      (
        code: 'CTR-01',
        category: '윤곽/주사',
        name: '윤곽 주사',
        unit: '회',
        minPrice: 50000,
        maxPrice: 150000,
        taxable: true,
      ),
      (
        code: 'ACN-01',
        category: '여드름/치료',
        name: '여드름 압출',
        unit: '회',
        minPrice: 20000,
        maxPrice: 50000,
        taxable: false,
      ),
      (
        code: 'ACN-02',
        category: '여드름/치료',
        name: '여드름 염증 주사 (부위당)',
        unit: '부위',
        minPrice: 5000,
        maxPrice: 20000,
        taxable: false,
      ),
      (
        code: 'ACN-03',
        category: '여드름/치료',
        name: '여드름 광역동 치료',
        unit: '회',
        minPrice: 100000,
        maxPrice: 200000,
        taxable: false,
      ),
      (
        code: 'WART-01',
        category: '피부질환/치료',
        name: '사마귀 냉동치료 (부위당)',
        unit: '부위',
        minPrice: 10000,
        maxPrice: 30000,
        taxable: false,
      ),
      (
        code: 'PEEL-01',
        category: '관리/필링',
        name: '아쿠아 필링',
        unit: '회',
        minPrice: 30000,
        maxPrice: 80000,
        taxable: true,
      ),
      (
        code: 'CARE-01',
        category: '관리/진정',
        name: '진정관리 (LED + 모델링팩)',
        unit: '회',
        minPrice: 30000,
        maxPrice: 70000,
        taxable: true,
      ),
      (
        code: 'HR-01',
        category: '제모/부위',
        name: '겨드랑이 레이저 제모',
        unit: '회',
        minPrice: 10000,
        maxPrice: 50000,
        taxable: true,
      ),
      (
        code: 'MAT-01',
        category: '재료/마취',
        name: '마취크림 도포',
        unit: '회',
        minPrice: 5000,
        maxPrice: 15000,
        taxable: true,
      ),
      (
        code: 'MAT-02',
        category: '판매/화장품',
        name: '재생 크림 50ml',
        unit: '개',
        minPrice: 15000,
        maxPrice: 45000,
        taxable: true,
      ),
      (
        code: 'DOC-01',
        category: '제증명/진단서',
        name: '일반 진단서',
        unit: '매',
        minPrice: 10000,
        maxPrice: 20000,
        taxable: false,
      ),
      (
        code: 'DOC-03',
        category: '제증명/확인서',
        name: '진료확인서',
        unit: '매',
        minPrice: 1000,
        maxPrice: 3000,
        taxable: false,
      ),
    ],
    diagnoses: <CoDiagnosisSpec>[
      (code: 'L70.0', name: '보통여드름', nameEn: 'Acne vulgaris'),
      (code: 'L70.9', name: '상세불명의 여드름', nameEn: 'Acne, unspecified'),
      (code: 'L71.9', name: '상세불명의 주사', nameEn: 'Rosacea, unspecified'),
      (code: 'L81.1', name: '기미', nameEn: 'Chloasma'),
      (code: 'L81.2', name: '주근깨', nameEn: 'Freckles'),
      (code: 'L82', name: '지루각화증', nameEn: 'Seborrhoeic keratosis'),
      (
        code: 'D22.9',
        name: '상세불명의 멜라닌세포모반',
        nameEn: 'Melanocytic naevi, unspecified',
      ),
      (code: 'B07', name: '바이러스사마귀', nameEn: 'Viral warts'),
      (code: 'L91.0', name: '비대흉터', nameEn: 'Hypertrophic scar'),
      (
        code: 'L20.9',
        name: '상세불명의 아토피피부염',
        nameEn: 'Atopic dermatitis, unspecified',
      ),
      (code: 'L30.9', name: '상세불명의 피부염', nameEn: 'Dermatitis, unspecified'),
      (code: 'L50.9', name: '상세불명의 두드러기', nameEn: 'Urticaria, unspecified'),
      (
        code: 'L63.9',
        name: '상세불명의 원형탈모증',
        nameEn: 'Alopecia areata, unspecified',
      ),
      (code: 'L74.5', name: '국소성 다한증', nameEn: 'Focal hyperhidrosis'),
      (code: 'L85.3', name: '피부건조증', nameEn: 'Xerosis cutis'),
      (
        code: 'Z41.1',
        name: '용납되지 않는 미용 외모에 대한 기타 성형수술',
        nameEn: 'Other plastic surgery for unacceptable cosmetic appearance',
      ),
    ],
    drugStems: <String>[
      '에이덤',
      '루미솔',
      '케라펜',
      '디오클린',
      '나비록스',
      '세라톤',
      '미노벨',
      '아크로진',
      '하이드라엘',
      '테라클',
      '포비렌',
      '클라리덤',
    ],
    drugForms: <({String form, String unit, List<int> strengths})>[
      (form: '정', unit: 'mg', strengths: <int>[5, 10, 20, 50, 100]),
      (form: '캡슐', unit: 'mg', strengths: <int>[10, 25, 50, 100]),
      (form: '연고', unit: 'g', strengths: <int>[10, 15, 20]),
      (form: '크림', unit: 'g', strengths: <int>[15, 20, 30]),
      (form: '겔', unit: 'g', strengths: <int>[15, 30]),
    ],
    drugUsages: <String>[
      '1일 1회 취침 전',
      '1일 2회 아침·저녁 식후 30분',
      '1일 3회 식후 30분',
      '1일 2회 환부에 얇게 도포',
      '1일 1회 세안 후 환부에 도포',
      '가려울 때 1회 1정',
    ],
    complaints: <String>[
      '양 볼 기미가 짙어졌다고 함',
      '턱 주변 여드름이 반복된다고 함',
      '이마 주름이 신경 쓰인다고 함',
      '팔자 주름 개선을 원함',
      '얼굴 전체 톤이 칙칙하다고 호소',
      '목 주변 쥐젖 제거 원함',
      '손등 사마귀가 번지는 것 같다고 함',
      '턱선 처짐 개선 상담 원함',
      '모공이 넓어졌다고 호소',
      '시술 후 붉은기가 남았다고 함',
    ],
    findings: <String>[
      '양측 광대 부위 경계 불명확한 갈색 반점',
      '턱·볼 부위 염증성 구진 다수, 면포 동반',
      '이마 동적 주름 2단계',
      '비순구 깊이 중등도',
      '안면 홍반 경미, 각질 없음',
      '경부 연성 섬유종 5개 내외',
      '좌측 손등 과각화성 구진 3개',
      '하안면 탄력 저하 중등도',
      '코·볼 모공 확장 관찰',
      '시술 부위 경미한 홍반, 부종 없음',
    ],
    plans: <String>[
      '피코 토닝 10회 권유, 2주 간격',
      '압출 후 진정관리, 외용제 처방',
      '보톡스 시술 후 2주 뒤 경과 확인',
      'HIFU 리프팅 300샷 진행',
      '냉동치료 2주 간격 반복',
      'CO2 레이저 제거 후 재생 크림 안내',
      '스킨부스터 3회 패키지 상담',
      '자외선 차단 교육, 4주 뒤 재진',
      '진정관리 병행, 1주 뒤 재평가',
      '경과 관찰, 악화 시 내원',
    ],
    memos: <String>[
      '시술 부위 24시간 세안·화장 자제 안내함.',
      '3일간 사우나·음주 자제 안내함.',
      '마취크림 도포 30분 후 시술 진행.',
      '시술 전 사진 촬영 완료.',
      '회차권 할인 안내, 환자 고민 후 결정 예정.',
      '리도카인 과민 반응 이력 확인함.',
      '다음 예약 2주 뒤로 안내함.',
      '보호자 동반 내원.',
      '진정관리 LED 15분 + 모델링팩 진행.',
      '비대칭 확인 시 터치업 예정.',
    ],
    questions: <CoQuestionSpec>[
      (
        question: '약물 알레르기가 있나요?',
        options: <String>['없음', '리도카인', '페니실린', '아스피린', '모름'],
      ),
      (
        question: '현재 복용 중인 약이 있나요?',
        options: <String>['없음', '항응고제', '여드름 약', '호르몬제', '기타'],
      ),
      (
        question: '임신 또는 수유 중인가요?',
        options: <String>['아니오', '임신 중', '수유 중', '해당 없음'],
      ),
      (question: '켈로이드 체질인가요?', options: <String>['아니오', '예', '모름']),
      (
        question: '최근 3개월 내 시술 이력이 있나요?',
        options: <String>['없음', '보톡스', '필러', '레이저', '리프팅'],
      ),
      (
        question: '가장 개선하고 싶은 고민은?',
        options: <String>['기미·잡티', '여드름', '주름', '탄력', '모공', '홍조'],
      ),
      (
        question: '어떻게 알고 오셨나요?',
        options: <String>['지인 소개', '검색', 'SNS', '간판', '이벤트'],
      ),
    ],
    cardIssuers: <String>['신한', '국민', '현대', '삼성', '하나', '롯데', '우리', 'BC'],
    labels: <String, String>{
      'nhis': '건강보험',
      'medicalAid1': '의료급여 1종',
      'medicalAid2': '의료급여 2종',
      'uninsured': '비급여',
      'reception': '접수',
      'waiting': '대기',
      'consultation': '진료',
      'counseling': '상담',
      'procedure': '시술',
      'care': '관리',
      'payment': '수납',
      'done': '완료',
      'requested': '예약 요청',
      'reserved': '예약',
      'confirmed': '예약 확정',
      'checkedIn': '내원',
      'completed': '완료',
      'cancelled': '취소',
      'noShow': '노쇼',
      'rejected': '요청 거절',
      'card': '카드',
      'cash': '현금',
      'transfer': '계좌이체',
      'prepaid': '선수금',
      'package': '회차권',
      'female': '여성',
      'male': '남성',
    },
    packageNameFormat: '{name} {sessions}회',
    texts: CoFakerClinicTexts.korean,
    ops: CoFakerClinicOps.korean,
    clinicNameFormat: '{prefix}{suffix}',
    currency: CoCurrencyFormat.korean,
    priceScale: CoClinicPriceScale.korean,
    koreanValues: CoKoreanValues.korean,
  );

  /// English clinic data, used as the fallback for every locale whose language
  /// has no clinic data of its own.
  ///
  /// It is a general dermatology and aesthetic clinic in US dollars and the
  /// model of the data of a new language: translate every list and text,
  /// then set [currency], [priceScale], [clinicNameFormat], and
  /// [koreanValues] (`none`) for the language.
  static const CoFakerClinicData english = CoFakerClinicData(
    specialties: <CoSpecialtySpec>[
      (name: 'Dermatology', clinicSuffix: 'Dermatology Clinic'),
      (name: 'Plastic Surgery', clinicSuffix: 'Plastic Surgery'),
      (name: 'Family Medicine', clinicSuffix: 'Family Clinic'),
      (name: 'Internal Medicine', clinicSuffix: 'Internal Medicine'),
      (name: 'Pediatrics', clinicSuffix: 'Pediatrics'),
    ],
    clinicNamePrefixes: <String>[
      'Clearview',
      'Brightside',
      'Maple',
      'Riverside',
      'Evergreen',
      'Sample',
      'Demo',
      'Northgate',
    ],
    staffRoles: <String, String>{
      'director': 'Medical Director',
      'doctor': 'Physician',
      'counselor': 'Patient Counselor',
      'coordinator': 'Care Coordinator',
      'nurse': 'Registered Nurse',
      'nurseAide': 'Nurse Assistant',
      'skincare': 'Aesthetician',
      'desk': 'Front Desk',
    },
    visitPurposes: <CoVisitPurposeSpec>[
      (
        name: 'Consultation',
        details: <String>['First consultation', 'Follow-up consultation'],
      ),
      (name: 'Procedure', details: <String>['Injectables', 'Laser', 'Lifting']),
      (name: 'Treatment', details: <String>['Acne', 'Skin condition', 'Warts']),
      (name: 'Care', details: <String>['Facial care', 'Soothing care']),
    ],
    procedures: <CoProcedureSpec>[
      (
        code: 'CONS01',
        category: 'Visit/Fee',
        name: 'New patient visit',
        unit: 'visit',
        minPrice: 80,
        maxPrice: 200,
        taxable: false,
      ),
      (
        code: 'BTX-F',
        category: 'Neurotoxin/Wrinkles',
        name: 'Forehead neurotoxin',
        unit: 'area',
        minPrice: 150,
        maxPrice: 450,
        taxable: true,
      ),
      (
        code: 'FIL-L',
        category: 'Filler/Area',
        name: 'Hyaluronic filler lips 1 ml',
        unit: 'ml',
        minPrice: 500,
        maxPrice: 900,
        taxable: true,
      ),
      (
        code: 'LT-01',
        category: 'Laser/Toning',
        name: 'Picosecond laser toning',
        unit: 'session',
        minPrice: 200,
        maxPrice: 500,
        taxable: true,
      ),
      (
        code: 'HIFU-300',
        category: 'Lifting/HIFU',
        name: 'Focused ultrasound lift 300 lines',
        unit: 'session',
        minPrice: 900,
        maxPrice: 3000,
        taxable: true,
      ),
      (
        code: 'ACN-01',
        category: 'Acne/Treatment',
        name: 'Acne extraction',
        unit: 'session',
        minPrice: 60,
        maxPrice: 150,
        taxable: false,
      ),
      (
        code: 'CARE-01',
        category: 'Care/Soothing',
        name: 'LED soothing facial',
        unit: 'session',
        minPrice: 60,
        maxPrice: 140,
        taxable: true,
      ),
      (
        code: 'DOC-01',
        category: 'Documents',
        name: 'Medical certificate',
        unit: 'copy',
        minPrice: 10,
        maxPrice: 30,
        taxable: false,
      ),
    ],
    diagnoses: <CoDiagnosisSpec>[
      (code: 'L70.0', name: 'Acne vulgaris', nameEn: 'Acne vulgaris'),
      (code: 'L81.1', name: 'Chloasma', nameEn: 'Chloasma'),
      (code: 'B07', name: 'Viral warts', nameEn: 'Viral warts'),
      (
        code: 'L20.9',
        name: 'Atopic dermatitis, unspecified',
        nameEn: 'Atopic dermatitis, unspecified',
      ),
      (
        code: 'L30.9',
        name: 'Dermatitis, unspecified',
        nameEn: 'Dermatitis, unspecified',
      ),
      (
        code: 'L71.9',
        name: 'Rosacea, unspecified',
        nameEn: 'Rosacea, unspecified',
      ),
    ],
    drugStems: <String>[
      'Adermex',
      'Lumisol',
      'Keraphen',
      'Dioclin',
      'Navirox',
      'Seraton',
      'Minobel',
      'Acrozine',
    ],
    drugForms: <({String form, String unit, List<int> strengths})>[
      (form: ' tablet', unit: 'mg', strengths: <int>[5, 10, 20, 50]),
      (form: ' capsule', unit: 'mg', strengths: <int>[25, 50, 100]),
      (form: ' ointment', unit: 'g', strengths: <int>[15, 30]),
      (form: ' cream', unit: 'g', strengths: <int>[15, 30]),
    ],
    drugUsages: <String>[
      'Once daily at bedtime',
      'Twice daily after meals',
      'Apply a thin layer twice daily',
      'Apply once daily after cleansing',
    ],
    complaints: <String>[
      'Reports darker patches on both cheeks',
      'Recurrent acne along the jawline',
      'Concerned about forehead lines',
      'Wants to improve skin laxity',
      'Redness persisting after a procedure',
    ],
    findings: <String>[
      'Ill-defined brown macules on both malar areas',
      'Multiple inflammatory papules on the chin',
      'Dynamic forehead lines, grade 2',
      'Moderate lower-face laxity',
      'Mild erythema, no edema',
    ],
    plans: <String>[
      'Laser toning every two weeks',
      'Extraction and topical therapy',
      'Review two weeks after injection',
      'Sun protection education, follow up in four weeks',
      'Observe, return if worse',
    ],
    memos: <String>[
      'Advised no makeup for 24 hours.',
      'Topical anesthetic applied 30 minutes before the procedure.',
      'Before photos taken.',
      'Package pricing explained; patient will decide later.',
      'Next visit booked in two weeks.',
    ],
    questions: <CoQuestionSpec>[
      (
        question: 'Do you have any drug allergies?',
        options: <String>['None', 'Lidocaine', 'Penicillin', 'Not sure'],
      ),
      (
        question: 'Are you taking any medication?',
        options: <String>['None', 'Blood thinners', 'Acne medication', 'Other'],
      ),
      (
        question: 'Are you pregnant or breastfeeding?',
        options: <String>['No', 'Pregnant', 'Breastfeeding', 'Not applicable'],
      ),
      (
        question: 'What would you most like to improve?',
        options: <String>['Pigmentation', 'Acne', 'Wrinkles', 'Firmness'],
      ),
    ],
    cardIssuers: <String>['Visa', 'Mastercard', 'Amex', 'Discover'],
    labels: <String, String>{
      'nhis': 'National insurance',
      'medicalAid1': 'Medical aid (type 1)',
      'medicalAid2': 'Medical aid (type 2)',
      'uninsured': 'Self-pay',
      'reception': 'Check-in',
      'waiting': 'Waiting',
      'consultation': 'Consultation',
      'counseling': 'Counseling',
      'procedure': 'Procedure',
      'care': 'Care',
      'payment': 'Payment',
      'done': 'Done',
      'requested': 'Requested',
      'reserved': 'Booked',
      'confirmed': 'Confirmed',
      'checkedIn': 'Checked in',
      'completed': 'Completed',
      'cancelled': 'Cancelled',
      'noShow': 'No-show',
      'rejected': 'Rejected',
      'card': 'Card',
      'cash': 'Cash',
      'transfer': 'Bank transfer',
      'prepaid': 'Prepaid balance',
      'package': 'Package',
      'female': 'Female',
      'male': 'Male',
    },
    packageNameFormat: '{name} x{sessions}',
    texts: CoFakerClinicTexts.english,
    ops: CoFakerClinicOps.english,
    clinicNameFormat: '{prefix} {suffix}',
    currency: CoCurrencyFormat.usd,
    priceScale: CoClinicPriceScale.english,
    koreanValues: CoKoreanValues.legacy,
    maskedIdFormat: '***-**-####',
  );
}

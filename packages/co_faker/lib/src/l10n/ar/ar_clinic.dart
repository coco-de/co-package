import '../../clinic_data.dart';
import '../../clinic_ops.dart';
import '../../clinic_texts.dart';
import '../../currency_format.dart';
import '../../korean_values.dart';

/// Arabic (Saudi Arabia, `ar`) clinic data for `faker.clinic`.
///
/// A general dermatology and aesthetic clinic in Saudi riyals that follows
/// `CoFakerClinicData.english`: every list has the length of the English one,
/// in the same order, so that one seed picks the same record in both
/// languages. `ar`, `ar_SA`, and `CoFaker.forLanguage('ar')` read it.
///
/// What makes the data Arabic and not a translation only:
///
/// - the amounts are riyals written `1,234.00 ر.س`: Western digits, a comma
///   between thousands, a point before the halalas, and the symbol after a
///   no-break space. The price bands are about four times the euros of the
///   French data, rounded to what a private clinic in Riyadh or Jeddah asks;
/// - a clinic name is the kind of place first and the name in guillemets after
///   it (`عيادة الأطفال «الأفق الصافي»`), and a date is `الأربعاء 25/11`
///   (day/month, Gregorian, with 24-hour times);
/// - the texts are Modern Standard Arabic in a formal register: the patient is
///   addressed in the plural of respect (`لديكم`, `موعدكم`), a staff line is
///   written in the passive or as a noun, which needs no gender, and a value
///   that fills a template stands after a colon or in parentheses, so that no
///   case ending or number agreement has to fit it (`عدد الجلسات: {sessions}`);
/// - the Arabic punctuation (`،` `؛` `؟`) is used;
/// - no value of the Korean data appears (`CoKoreanValues.none`): the ID is
///   masked in the shape of a ten-digit Saudi national ID, the phones and
///   addresses are those of Saudi Arabia, and a closure notice gives a reason.
///
/// An AI draft that a native speaker reviews.
const CoFakerClinicData arClinic = CoFakerClinicData(
  specialties: <CoSpecialtySpec>[
    (name: 'الأمراض الجلدية', clinicSuffix: 'عيادة الجلدية'),
    (name: 'الجراحة التجميلية', clinicSuffix: 'عيادة الجراحة التجميلية'),
    (name: 'طب الأسرة', clinicSuffix: 'عيادة طب الأسرة'),
    (name: 'الأمراض الباطنية', clinicSuffix: 'عيادة الباطنية'),
    (name: 'طب الأطفال', clinicSuffix: 'عيادة الأطفال'),
  ],
  // They stand in guillemets after the kind of place: `عيادة الأطفال «السدرة»`,
  // or `عيادة الأطفال «نموذج»`. Invented names, as in the English data.
  clinicNamePrefixes: <String>[
    'الأفق الصافي',
    'الإشراقة',
    'السدرة',
    'ضفاف الوادي',
    'الخزامى',
    'نموذج',
    'تجريبي',
    'البوابة الشمالية',
  ],
  // A role is a generic title in the masculine, as a Saudi form writes it.
  staffRoles: <String, String>{
    'director': 'المدير الطبي',
    'doctor': 'طبيب',
    'counselor': 'مستشار المرضى',
    'coordinator': 'منسق الرعاية',
    'nurse': 'أخصائي تمريض',
    'nurseAide': 'مساعد تمريض',
    'skincare': 'أخصائي العناية بالبشرة',
    'desk': 'موظف الاستقبال',
  },
  visitPurposes: <CoVisitPurposeSpec>[
    (name: 'استشارة', details: <String>['استشارة أولى', 'استشارة متابعة']),
    (name: 'إجراء', details: <String>['الحقن التجميلية', 'الليزر', 'الشد']),
    (name: 'علاج', details: <String>['حب الشباب', 'مرض جلدي', 'الثآليل']),
    (name: 'عناية', details: <String>['العناية بالوجه', 'عناية مهدئة']),
  ],
  // Prices are riyals, about four times the euros of the French data and
  // rounded: a first visit 280 to 720 ر.س, a laser session 720 to 1 800 ر.س.
  procedures: <CoProcedureSpec>[
    (
      code: 'CONS01',
      category: 'كشف/رسوم',
      name: 'كشف مريض جديد',
      unit: 'كشف',
      minPrice: 280,
      maxPrice: 720,
      taxable: false,
    ),
    (
      code: 'BTX-F',
      category: 'توكسين عصبي/التجاعيد',
      name: 'حقن توكسين عصبي للجبهة',
      unit: 'منطقة',
      minPrice: 560,
      maxPrice: 1600,
      taxable: true,
    ),
    (
      code: 'FIL-L',
      category: 'فيلر/المنطقة',
      name: 'فيلر هيالورونيك للشفاه 1 مل',
      unit: 'مل',
      minPrice: 1800,
      maxPrice: 3200,
      taxable: true,
    ),
    (
      code: 'LT-01',
      category: 'ليزر/توحيد اللون',
      name: 'توحيد لون البشرة بليزر البيكو',
      unit: 'جلسة',
      minPrice: 720,
      maxPrice: 1800,
      taxable: true,
    ),
    (
      code: 'HIFU-300',
      category: 'شد/الموجات فوق الصوتية المركزة',
      name: 'شد بالموجات فوق الصوتية المركزة، 300 خط',
      unit: 'جلسة',
      minPrice: 3200,
      maxPrice: 10800,
      taxable: true,
    ),
    (
      code: 'ACN-01',
      category: 'حب الشباب/علاج',
      name: 'تنظيف حب الشباب واستخراج الرؤوس',
      unit: 'جلسة',
      minPrice: 200,
      maxPrice: 520,
      taxable: false,
    ),
    (
      code: 'CARE-01',
      category: 'عناية/تهدئة',
      name: 'عناية مهدئة للوجه بالعلاج الضوئي',
      unit: 'جلسة',
      minPrice: 200,
      maxPrice: 480,
      taxable: true,
    ),
    (
      code: 'DOC-01',
      category: 'مستندات',
      name: 'تقرير طبي',
      unit: 'نسخة',
      minPrice: 40,
      maxPrice: 120,
      taxable: false,
    ),
  ],
  // The codes and the English names are the ones of the English data; the
  // Arabic names follow the Arabic usage of ICD-10.
  diagnoses: <CoDiagnosisSpec>[
    (code: 'L70.0', name: 'حب الشباب الشائع', nameEn: 'Acne vulgaris'),
    (code: 'L81.1', name: 'الكلف', nameEn: 'Chloasma'),
    (code: 'B07', name: 'الثآليل الفيروسية', nameEn: 'Viral warts'),
    (
      code: 'L20.9',
      name: 'التهاب الجلد التأتبي، غير محدد',
      nameEn: 'Atopic dermatitis, unspecified',
    ),
    (
      code: 'L30.9',
      name: 'التهاب الجلد، غير محدد',
      nameEn: 'Dermatitis, unspecified',
    ),
    (code: 'L71.9', name: 'الوردية، غير محددة', nameEn: 'Rosacea, unspecified'),
  ],
  // Invented names that no marketed product has, as in the English data,
  // written in Arabic letters.
  drugStems: <String>[
    'أديرمكس',
    'لوميسول',
    'كيرافين',
    'ديوكلين',
    'نافيروكس',
    'سيراتون',
    'مينوبيل',
    'أكروزين',
  ],
  // A drug reads `أديرمكس أقراص 10 ملجم`: the form has its leading space, and
  // the unit a no-break one. The units are the Saudi ones (`ملجم`, `جم`).
  drugForms: <({String form, String unit, List<int> strengths})>[
    (form: ' أقراص', unit: ' ملجم', strengths: <int>[5, 10, 20, 50]),
    (form: ' كبسولات', unit: ' ملجم', strengths: <int>[25, 50, 100]),
    (form: ' مرهم', unit: ' جم', strengths: <int>[15, 30]),
    (form: ' كريم', unit: ' جم', strengths: <int>[15, 30]),
  ],
  drugUsages: <String>[
    'مرة واحدة يوميًا قبل النوم',
    'مرتان يوميًا بعد الوجبات',
    'تُدهن طبقة رقيقة مرتين يوميًا',
    'يُدهن مرة واحدة يوميًا بعد تنظيف البشرة',
  ],
  // A complaint is written as a noun, which needs no gender.
  complaints: <String>[
    'شكوى من بقع داكنة على الخدين',
    'حب شباب متكرر على امتداد خط الفك',
    'انزعاج من خطوط الجبهة',
    'رغبة في تحسين ترهل البشرة',
    'احمرار مستمر بعد إجراء سابق',
  ],
  findings: <String>[
    'بقع بنية غير واضحة الحدود على الوجنتين',
    'حطاطات التهابية متعددة على الذقن',
    'خطوط جبهة ديناميكية، الدرجة 2',
    'ترهل متوسط في الجزء السفلي من الوجه',
    'حمامى خفيفة دون وذمة',
  ],
  plans: <String>[
    'توحيد اللون بالليزر كل أسبوعين',
    'استخراج الرؤوس وعلاج موضعي',
    'مراجعة بعد أسبوعين من الحقن',
    'توعية بالوقاية من الشمس، ومتابعة بعد أربعة أسابيع',
    'ملاحظة الحالة، والعودة عند تفاقمها',
  ],
  memos: <String>[
    'نُصح بعدم وضع المكياج لمدة 24 ساعة.',
    'وُضع مخدر موضعي قبل الإجراء بـ30 دقيقة.',
    'التُقطت صور ما قبل الإجراء.',
    'شُرحت أسعار الباقة؛ وسيُتخذ القرار لاحقًا.',
    'حُجز الموعد التالي بعد أسبوعين.',
  ],
  // The patient is asked in the plural of respect.
  questions: <CoQuestionSpec>[
    (
      question: 'هل لديكم حساسية من أي أدوية؟',
      options: <String>['لا يوجد', 'ليدوكايين', 'بنسلين', 'لا أعلم'],
    ),
    (
      question: 'هل تتناولون أي أدوية حاليًا؟',
      options: <String>['لا يوجد', 'مميعات الدم', 'أدوية حب الشباب', 'أخرى'],
    ),
    (
      question: 'هل يوجد حمل أو رضاعة طبيعية؟',
      options: <String>['لا', 'حامل', 'مرضع', 'لا ينطبق'],
    ),
    (
      question: 'ما الذي تودون تحسينه أكثر من غيره؟',
      options: <String>['التصبغات', 'حب الشباب', 'التجاعيد', 'شد البشرة'],
    ),
  ],
  // Card networks, with the Saudi domestic one in place of the fourth.
  cardIssuers: <String>['Visa', 'Mastercard', 'Amex', 'مدى'],
  labels: <String, String>{
    'nhis': 'التأمين الصحي الإلزامي',
    'medicalAid1': 'إعانة طبية (الفئة 1)',
    'medicalAid2': 'إعانة طبية (الفئة 2)',
    'uninsured': 'على نفقة المريض',
    'reception': 'تسجيل الوصول',
    'waiting': 'انتظار',
    'consultation': 'كشف',
    'counseling': 'استشارة',
    'procedure': 'إجراء',
    'care': 'عناية',
    'payment': 'دفع',
    'done': 'تم',
    'requested': 'مطلوب',
    'reserved': 'محجوز',
    'confirmed': 'مؤكد',
    'checkedIn': 'تم تسجيل الوصول',
    'completed': 'مكتمل',
    'cancelled': 'ملغى',
    'noShow': 'عدم حضور',
    'rejected': 'مرفوض',
    'card': 'بطاقة',
    'cash': 'نقدًا',
    'transfer': 'تحويل بنكي',
    'prepaid': 'رصيد مدفوع مسبقًا',
    'package': 'باقة',
    'female': 'أنثى',
    'male': 'ذكر',
  },
  // A package is `توحيد لون البشرة بليزر البيكو ×5`: the count follows the
  // name with a sign, so that no noun has to agree with it.
  packageNameFormat: '{name} ×{sessions}',
  texts: CoFakerClinicTexts(
    consentForms: <CoConsentFormSpec>[
      (
        kind: 'procedure',
        title: 'الموافقة على الإجراء',
        clauses: <String>[
          'شُرح لي الغرض من الإجراء وطريقته والنتيجة المتوقعة.',
          'أدرك أن احمرارًا أو تورمًا أو كدمات قد تظهر بعد الإجراء.',
          'أدرك أن النتائج تختلف من شخص لآخر وأنها غير مضمونة.',
          'أفصحت عن الأدوية التي أتناولها وعن أي حساسية أو حمل.',
        ],
      ),
      (
        kind: 'privacy',
        title: 'الموافقة على جمع البيانات الشخصية واستخدامها',
        clauses: <String>[
          'البيانات المجمّعة: الاسم، وتاريخ الميلاد، وبيانات التواصل، والسجلات الطبية.',
          'الغرض: العلاج، وتذكيرات المواعيد، والفوترة.',
          'يحق لي الرفض، وقد لا يتوفر الحجز الإلكتروني عندئذٍ.',
        ],
      ),
      (
        kind: 'photo',
        title: 'الموافقة على التصوير',
        clauses: <String>[
          'تُلتقط صور قبل الإجراء وبعده لمتابعة التقدم.',
          'تُستخدم الصور للعلاج فقط ولا تُنشر مطلقًا.',
        ],
      ),
    ],
    consentDisclaimer:
        'نص نموذجي لأغراض العرض فقط. لم يخضع لمراجعة قانونية؛ '
        'فلا يُستخدم نموذجَ موافقة فعليًا.',
    feedback: <String, List<String>>{
      'positive': <String>[
        'شرح الطبيب كل شيء بعناية.',
        'انتظار قصير وفريق ودود.',
        'تحسّن لون البشرة بعد ثلاث جلسات.',
      ],
      'neutral': <String>[
        'نتيجة جيدة، لكنها مكلفة بعض الشيء.',
        'كان إيجاد موقف للسيارة صعبًا.',
      ],
      'negative': <String>[
        'استمر الانتظار أكثر من 40 دقيقة بعد الموعد المحدد.',
        'اختلف المبلغ النهائي عن السعر المعلن.',
      ],
    },
    counselTopics: <CoCounselTopicSpec>[
      (
        topic: 'toning',
        procedureCode: 'LT-01',
        procedure: 'توحيد لون البشرة بليزر البيكو',
        concern: 'البقع الداكنة على الخدين أصبحت أوضح.',
        recommend: 'للتصبغات، ننصح بتوحيد لون البشرة بليزر البيكو.',
        pain: 'وخز خفيف؛ ولا يحتاج معظم الأشخاص إلى تخدير.',
        interval: 'نحو عشر جلسات بفاصل أسبوعين بين كل جلسة وأخرى.',
        downtime: 'يستمر الاحمرار بضع ساعات، ويمكن غسل الوجه في اليوم نفسه.',
        sessions: 10,
      ),
      (
        topic: 'lifting',
        procedureCode: 'HIFU-300',
        procedure: 'الشد بالموجات فوق الصوتية المركزة',
        concern: 'يبدو خط الفك مترهلًا.',
        recommend:
            'يشد العلاج بالموجات فوق الصوتية المركزة الطبقات العميقة من الجلد.',
        pain: 'قد يُشعر بألم خفيف قرب العظام، لذا نضع كريمًا مخدرًا.',
        interval: 'مرة كل ستة إلى اثني عشر شهرًا.',
        downtime: 'يمكن العودة إلى العمل فورًا.',
        sessions: 3,
      ),
    ],
    counselScript: (
      greeting: 'أهلًا وسهلًا، كيف يمكننا مساعدتكم اليوم؟',
      questions: <String, String>{
        'pain': 'هل هو مؤلم؟',
        'interval': 'كم مرة يلزم إجراؤه؟',
        'downtime': 'هل يمكن العودة إلى العمل مباشرة بعده؟',
        'price': 'كم التكلفة؟',
      },
      // The number of sessions follows its label, so that no noun has to agree
      // with it.
      priceAnswer:
          'سعر الجلسة الواحدة {price}، وسعر الباقة {packagePrice} '
          '(عدد الجلسات: {sessions}).',
      bookYes: 'ممتاز، أود الحجز هذا الأسبوع.',
      bookYesReply:
          'بكل سرور، سنحجز لكم الموعد ونرسل لكم رسالة نصية بتعليمات ما بعد '
          'الإجراء.',
      bookNo: 'سأفكر في الأمر وأتواصل معكم.',
      bookNoReply: 'بالتأكيد، يسعدنا تواصلكم في أي وقت.',
      summary:
          'التوصية: {procedure}؛ سعر الجلسة {price}؛ الباقة (عدد الجلسات: '
          '{sessions}) بسعر {packagePrice}. {outcome}',
      booked: 'تم الحجز.',
      pending: 'لم يُتخذ قرار بعد؛ يُعاد التواصل لاحقًا.',
    ),
    integrationResults: <String, List<CoIntegrationResultSpec>>{
      'eligibility': <CoIntegrationResultSpec>[
        (code: 'OK', message: 'تم التحقق من التغطية التأمينية', ok: true),
        (code: 'LOST', message: 'انتهت التغطية التأمينية', ok: false),
        (code: 'NOT_FOUND', message: 'لم يُعثر على المؤمَّن عليه', ok: false),
      ],
      'dur': <CoIntegrationResultSpec>[
        (code: 'OK', message: 'لا توجد تداخلات دوائية', ok: true),
        (code: 'WARN_COMBINATION', message: 'تحذير من تداخل دوائي', ok: false),
      ],
      'insuranceClaim': <CoIntegrationResultSpec>[
        (code: 'ACCEPTED', message: 'قُبلت المطالبة', ok: true),
        (code: 'ADJUSTED', message: 'عُدّلت المطالبة عند المراجعة', ok: false),
        (
          code: 'RETURNED',
          message: 'أُعيدت المطالبة: حقول إلزامية ناقصة',
          ok: false,
        ),
      ],
      'ePrescription': <CoIntegrationResultSpec>[
        (code: 'SENT', message: 'أُرسلت الوصفة الإلكترونية', ok: true),
        (code: 'FAILED', message: 'لم تستلم الصيدلية الوصفة', ok: false),
      ],
      'identityQr': <CoIntegrationResultSpec>[
        (code: 'OK', message: 'تم التحقق من الهوية', ok: true),
        (code: 'EXPIRED', message: 'انتهت صلاحية رمز QR', ok: false),
      ],
    },
    // Invented names of insurers; no Saudi insurer has them.
    insurers: <String>[
      'شركة الشراع الشمالي للتأمين',
      'شركة واحة الحياة للتأمين',
      'شركة قمم الجبال للتأمين',
      'شركة الجدول الصافي للتأمين',
    ],
    // `{mention}` stands at the start of a sentence, and `{patient}` after a
    // colon or in parentheses.
    teamNotes: <String>[
      '{mention}، يُرجى خفض طاقة الليزر درجة واحدة. المريض: {patient}.',
      'تسليم: وُضع الكريم المخدر (المريض: {patient}). '
          '{mention}، يمكن البدء عند الجاهزية.',
      '{mention}، تبقّت جلسة واحدة في الباقة (المريض: {patient}).',
      'يلزم توقيع الولي القانوني. المريض: {patient}. '
          '{mention}، يُرجى المراجعة.',
    ],
    // `ليزر البيكو رقم 2`.
    deviceNameFormat: '{kind} رقم {number}',
    staffMentionFormat: '@{name} ({role})',
    nameMentionFormat: '@{name}',
    labels: <String, String>{
      'self': 'المريض نفسه',
      'spouse': 'الزوج / الزوجة',
      'parent': 'أحد الوالدين',
      'child': 'الابن / الابنة',
      'sibling': 'الأخ / الأخت',
      'grandparent': 'الجد / الجدة',
      'grandchild': 'الحفيد / الحفيدة',
      'legalGuardian': 'الولي القانوني',
      'other': 'أخرى',
      'picoLaser': 'ليزر البيكو',
      'hifu': 'جهاز الموجات فوق الصوتية المركزة',
      'rf': 'جهاز الترددات الراديوية',
      'ipl': 'جهاز الضوء النبضي المكثف',
      'ledTherapy': 'جهاز العلاج الضوئي',
      'skinAnalyzer': 'جهاز تحليل البشرة',
      'photoCamera': 'كاميرا التصوير السريري',
      'labelPrinter': 'طابعة الملصقات',
      'cardTerminal': 'جهاز نقاط البيع',
      'signaturePad': 'لوح التوقيع الإلكتروني',
      'kiosk': 'جهاز الخدمة الذاتية',
      'bridgePc': 'حاسوب الربط',
      'positive': 'إيجابي',
      'neutral': 'محايد',
      'negative': 'سلبي',
      'counselor': 'المستشار',
      'patientSpeaker': 'المريض',
      'life': 'التأمين على الحياة',
      'nonLife': 'التأمين العام',
    },
  ),
  ops: CoFakerClinicOps(
    patientTags: <CoColoredLabelSpec>[
      (code: 'vip', label: 'كبار العملاء', color: '#F59E0B'),
      (code: 'lifting', label: 'شد', color: '#6366F1'),
      (code: 'referral', label: 'بإحالة', color: '#10B981'),
      (code: 'caution', label: 'عناية خاصة', color: '#EF4444'),
      (code: 'package', label: 'مشترك في باقة', color: '#8B5CF6'),
    ],
    acquisitionChannels: <CoColoredLabelSpec>[
      (code: 'onlineBooking', label: 'الحجز الإلكتروني', color: '#03C75A'),
      (code: 'referral', label: 'بإحالة', color: '#10B981'),
      (code: 'instagramAd', label: 'إعلان على وسائل التواصل', color: '#E1306C'),
      (code: 'search', label: 'البحث على الإنترنت', color: '#7C3AED'),
      (code: 'walkIn', label: 'حضور دون موعد', color: '#64748B'),
    ],
    specialNotes: <String>[
      'حساسية من الليدوكايين',
      'قابلية لتكوّن الجدرة: تُخفض طاقة الليزر',
      'يتناول مميعات الدم: يُتحقق من ذلك قبل الإجراءات',
      'حساسية من البنسلين',
    ],
    rooms: <CoRoomSpec>[
      (name: 'غرفة الاستشارات 1', kind: 'counseling', staffRole: 'counselor'),
      (name: 'غرفة الكشف 1', kind: 'consultation', staffRole: 'director'),
      (name: 'غرفة الكشف 2', kind: 'consultation', staffRole: 'doctor'),
      (name: 'غرفة الإجراءات 1', kind: 'procedure', staffRole: 'nurse'),
      (name: 'غرفة العناية 1', kind: 'care', staffRole: 'skincare'),
      (name: 'مكتب الدفع', kind: 'payment', staffRole: 'coordinator'),
      (
        name: 'تسجيل الوصول عبر الجهاز اللوحي',
        kind: 'reception',
        staffRole: null,
      ),
    ],
    termsChanges: <String>[
      'توضيح مدة الاحتفاظ بالبيانات.',
      'إضافة شبكة الوصفات الإلكترونية إلى الجهات المستلمة.',
      'تحديد مدة الاحتفاظ بتسجيلات الاستشارة بالذكاء الاصطناعي بـ90 يومًا.',
    ],
    consentDispatch: <String, String>{
      'sent': 'أُرسل طلب التوقيع.',
      'opened': 'فتح المريض الطلب.',
      'signed': 'تم التوقيع إلكترونيًا.',
      'expired': 'انتهت صلاحية الطلب (24 ساعة).',
      'failed': 'تعذر إرسال الطلب؛ يُرجى التحقق من الرقم.',
    },
    adjustments: <String, List<String>>{
      'discount': <String>['مريض عائد، 10%', 'عائلات الموظفين، 20%'],
      'coupon': <String>['قسيمة الزيارة الأولى، 20%', 'قسيمة يوم الميلاد'],
      'point': <String>['استخدام النقاط'],
      'rounding': <String>['تقريب المبلغ'],
    },
    pointReasons: <String, String>{
      'earn': 'اكتساب 3% من قيمة الدفع',
      'use': 'استخدام عند الدفع',
      'bonus': 'مكافأة على التقييم',
      'expire': 'انتهاء الصلاحية',
      'refund': 'خصم بعد استرداد الدفعة',
      'adjust': 'تعديل يدوي',
    },
    paymentMessages: <String, String>{
      'approved': 'تمت الموافقة على الدفع بالبطاقة.',
      'cashReceipt': 'صدر إيصال الدفع النقدي.',
      'partialCancel': 'أُلغي جزئيًا.',
      'prepaidUsed': 'خُصم من الرصيد المدفوع مسبقًا.',
      'declined': 'رُفض الدفع بالبطاقة: {reason}',
    },
    tasks: <String>[
      'التحقق من مخزون رؤوس الليزر',
      'طلب المستلزمات',
      'إقفال اليومية',
      'تسجيل درجة حرارة الثلاجة',
    ],
    taskMemos: <String>[
      'يُرجى الإنجاز قبل الساعة 15:00.',
      'إذا تبقى أقل من 5، فيُرجى الطلب فورًا.',
    ],
    kioskPurposes: <String, String>{
      'checkin': 'تسجيل الوصول',
      'reservation': 'البحث عن موعدي',
      'payment': 'الدفع',
      'document': 'المستندات',
    },
    evidence: <CoEvidenceSpec>[
      (kind: 'chartHistory', rule: 'الإجراء نفسه خلال آخر 3 أشهر'),
      (
        kind: 'priceRule',
        rule: 'تُعرض الباقات القائمة أولًا ثم الجلسات المفردة',
      ),
      (
        kind: 'contraindication',
        rule: 'لا يُستخدم الكريم المخدر عند وجود حساسية من الليدوكايين',
      ),
    ],
    counselFailures: <String, String>{
      'CONSENT_MISSING':
          'لا توجد موافقة على التسجيل؛ لا يمكن بدء الاستشارة بالذكاء الاصطناعي.',
      'STT_FAILED': 'تعذر التعرف على الكلام. يُرجى التحقق من الميكروفون.',
      'TOO_SHORT': 'التسجيل أقصر من أن يُلخَّص.',
      'MODEL_TIMEOUT': 'يستغرق إعداد الملخص وقتًا أطول. يُرجى المحاولة لاحقًا.',
    },
    claimRules: <CoClaimRuleSpec>[
      (
        ruleId: 'R-DX-001',
        severity: 'error',
        diagnosisCode: 'Z41.1',
        feeCode: 'CONS01',
        message: 'لا يجوز احتساب رسوم الكشف التأميني للتشخيصات التجميلية.',
      ),
      (
        ruleId: 'R-FE-118',
        severity: 'warning',
        diagnosisCode: 'L20.9',
        feeCode: 'CONS02',
        message: 'احتُسب كشف المتابعة مرتين في اليوم نفسه.',
      ),
    ],
    crmFailures: <String, String>{
      'NIGHT_AD_NO_CONSENT': 'لا توجد موافقة على الإعلانات الليلية',
      'MARKETING_NO_CONSENT': 'لا توجد موافقة على الرسائل التسويقية',
      'OPTED_OUT': 'ألغى الاشتراك في الرسائل',
      'INVALID_NUMBER': 'رقم غير صالح',
    },
    // It ends the name of a compound package: `… + كريم مرمم للبشرة هدية`.
    packageBonus: 'كريم مرمم للبشرة هدية',
    staffNotices: <String, List<({String title, String body})>>{
      'training': <({String title, String body})>[
        (
          title: 'تدريب على جهاز الليزر الجديد',
          body:
              'يُعقد التدريب على جهاز الليزر الجديد يوم الأربعاء القادم الساعة 18:00 في غرفة الإجراءات 1.',
        ),
      ],
      'policy': <({String title, String body})>[
        (
          title: 'تدقيق الاطلاع على أرقام الهوية',
          body:
              'لا يُعرض رقم الهوية كاملًا إلا مع ذكر السبب، ويُدقَّق الاطلاع شهريًا.',
        ),
      ],
      'schedule': <({String title, String body})>[
        (
          title: 'جدول الدوام في أيام الإجازات',
          body:
              'تُغلق العيادة الساعة 17:00 في اليوم السابق للإجازة. يُرجى مراجعة الجدول المشترك.',
        ),
      ],
    },
    vitalsNotes: <String, String>{
      'normal':
          'العلامات الحيوية مستقرة (ضغط الدم {sys}/{dia} ملم زئبق، النبض {pulse}، تشبع الأكسجين {spo2}%، الحرارة {temp} °م).',
      'highBp':
          'ضغط الدم {sys}/{dia} ملم زئبق مرتفع؛ يُعاد القياس بعد 10 دقائق من الراحة.',
      'fever': 'حمى خفيفة {temp} °م؛ يقرر الطبيب ما إذا كان الإجراء سيُؤجَّل.',
      'lowSpo2':
          'تشبع الأكسجين {spo2}% منخفض؛ أُعيد القياس ولا يوجد ضيق في التنفس.',
      'highGlucose':
          'سكر الدم {glucose} ملجم/دسل مرتفع؛ تأكد أن القياس كان بعد الأكل.',
    },
    // A date reads `الأربعاء 25/11` and a range `من الأربعاء 25/11 إلى الخميس
    // 26/11`. The reason follows `السبب:`, and the name of a holiday stands in
    // parentheses.
    closure: <String, String>{
      'title': 'مغلق: {dates}',
      'holiday':
          '{clinic}: مغلقة {dates} ({name}). تُستأنف المواعيد اعتبارًا من '
          '{reopen}.',
      'other':
          '{clinic}: مغلقة {dates}. السبب: {reason}. تُستأنف المواعيد اعتبارًا '
          'من {reopen}.',
    },
    closureReasons: <String>['مؤتمر طبي', 'تجديد المرافق', 'صيانة الأجهزة'],
    dateFormat: '{weekday} {day}/{month}',
    weekdayNames: <String>[
      'الاثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد',
    ],
    dateRangeFormat: 'من {from} إلى {to}',
    // `توحيد لون البشرة بليزر البيكو ×3`: the same sign as a package.
    compoundItemFormat: '{name} ×{sessions}',
    labels: <String, String>{
      'requested': 'مطلوب',
      'waiting': 'في الانتظار',
      'priority': 'أولوية',
      'inProgress': 'قيد التنفيذ',
      'done': 'تم',
      'tablet': 'جهاز لوحي',
      'online': 'عبر الإنترنت',
      'app': 'التطبيق',
      'kiosk': 'جهاز الخدمة الذاتية',
      'desk': 'الاستقبال',
      'paper': 'نموذج ورقي',
      'privacyRequired': 'البيانات الشخصية (إلزامي)',
      'marketingOptional': 'التسويق (اختياري)',
      'sensitiveInfo': 'البيانات الحساسة',
      'photoUse': 'استخدام الصور',
      'thirdParty': 'المشاركة مع أطراف ثالثة',
      'aiRecording': 'تسجيل المحادثة للذكاء الاصطناعي',
      'nightAdvertising': 'الإعلانات الليلية',
      'agreed': 'تمت الموافقة',
      'withdrawn': 'سُحبت الموافقة',
      'chartHistory': 'سجل الملف الطبي',
      'procedureHistory': 'سجل الإجراءات',
      'priceRule': 'قاعدة التسعير',
      'contraindication': 'مانع استعمال',
      'guideline': 'إرشادات سريرية',
      'preference': 'تفضيل',
      'error': 'خطأ',
      'warning': 'تحذير',
      'discount': 'خصم',
      'coupon': 'قسيمة',
      'point': 'نقاط',
      'rounding': 'تقريب',
    },
  ),
  // The Saudi riyal: `1,234.00 ر.س`, with Western digits, a comma between
  // thousands, and a no-break space before the symbol.
  currency: CoCurrencyFormat(
    code: 'SAR',
    symbol: 'ر.س',
    pattern: '{amount} {symbol}',
    groupSeparator: ',',
    decimalSeparator: '.',
    fractionDigits: 2,
  ),
  // Riyals are about a quarter of a euro, so the units are about four times
  // those of the French data: a price tag rounds to 10 ر.س, a package to
  // 50 ر.س, and a prepaid balance is a multiple of 50 ر.س; a payment in
  // installments starts at 1 500 ر.س, a payment is split from 200 ر.س, and a
  // point is worth one riyal.
  priceScale: CoClinicPriceScale(
    priceRounding: 10,
    packageRounding: 50,
    prepaidStep: 50,
    installmentMinimum: 1500,
    splitMinimum: 200,
    splitRounding: 5,
    adjustmentUnit: 5,
    pointUnit: 1,
    quoteMin: 200,
    quoteMax: 1200,
  ),
  clinicNameFormat: '{suffix} «{prefix}»',
  koreanValues: CoKoreanValues.none,
  // The shape of a ten-digit Saudi national ID, masked but for the last
  // digits.
  maskedIdFormat: '******####',
  // A Saudi address goes from the street to the city, with the Arabic comma.
  addressLineFormat: '{line1}، {city}',
);

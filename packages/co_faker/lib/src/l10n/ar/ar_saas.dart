import '../../currency_format.dart';
import '../../korean_values.dart';
import '../../saas_data.dart';
import '../../saas_ops.dart';

/// Arabic (Saudi Arabia, `ar`) SaaS data for `faker.saas`.
///
/// The back office of a clinic software vendor in Saudi riyals that follows
/// `CoFakerSaasData.english`: every list has the length of the English one, in
/// the same order, and a map has its keys. `ar`, `ar_SA`, and
/// `CoFaker.forLanguage('ar')` read it.
///
/// What makes the data Arabic and not a translation only:
///
/// - the amounts are riyals written `1,234.00 ر.س`, the plans cost riyals, and
///   the VAT of an invoice is the 15% that Saudi Arabia applies;
/// - a notification template writes its variables in Arabic
///   (`#{الاسم}`, `#{العيادة}`) and addresses the patient in the plural of
///   respect; a variable follows `مرحبًا`, a colon, or stands in parentheses;
/// - a summary or a title that a name or a service fills (`{target}`,
///   `{service}`) puts the name first and a colon after it, and a count
///   follows its label (`المطالبات المرسلة: {n}`), so that no number agreement
///   has to fit it;
/// - no Korean-only value appears (`CoKoreanValues.none`): the business number
///   of a tenant is the ten digits of a Saudi commercial registration.
///
/// An AI draft that a native speaker reviews.
const CoFakerSaasData arSaas = CoFakerSaasData(
  // The prices are riyals a month, about four times the euros of the French
  // data.
  plans: <CoPlanSpec>[
    (
      code: 'starter',
      name: 'الأساسية',
      monthlyPrice: 279,
      seats: 3,
      messageCredits: 500,
    ),
    (
      code: 'standard',
      name: 'القياسية',
      monthlyPrice: 599,
      seats: 10,
      messageCredits: 2000,
    ),
    (
      code: 'pro',
      name: 'الاحترافية',
      monthlyPrice: 999,
      seats: 25,
      messageCredits: 5000,
    ),
    (
      code: 'enterprise',
      name: 'المؤسسات',
      monthlyPrice: 1999,
      seats: 100,
      messageCredits: 20000,
    ),
  ],
  // The variables are Arabic, because the template is not filled by the
  // generator: the application that sends it fills them.
  messageTemplates: <CoMessageTemplateSpec>[
    (
      code: 'RSV_CREATED',
      name: 'تأكيد الحجز',
      body: 'مرحبًا #{الاسم}، تم حجز موعدكم: #{العيادة}، #{التاريخ_والوقت}.',
    ),
    (
      code: 'RSV_CANCELLED',
      name: 'إلغاء الحجز',
      body: 'مرحبًا #{الاسم}، أُلغي موعدكم المحدد في #{التاريخ_والوقت}.',
    ),
    (
      code: 'RSV_REMIND_D1',
      name: 'تذكير بالموعد',
      body:
          'مرحبًا #{الاسم}، نذكّركم بموعدكم غدًا الساعة #{الوقت}: #{العيادة}.',
    ),
    (
      code: 'QUESTIONNAIRE',
      name: 'استبيان ما قبل الزيارة',
      body: 'مرحبًا #{الاسم}، يُرجى تعبئة الاستبيان قبل زيارتكم: #{الرابط}',
    ),
    (
      code: 'SURVEY',
      name: 'استطلاع الرضا',
      body: 'مرحبًا #{الاسم}، كيف كانت زيارتكم (#{العيادة})؟ #{الرابط}',
    ),
    (
      code: 'AD_EVENT',
      name: 'عرض (إعلان)',
      body:
          '[إعلان] #{العيادة}، عرض الشهر: 10 جلسات ليزر لتوحيد لون البشرة '
          'بسعر خاص. لإلغاء الاشتراك: #{الرابط}',
    ),
  ],
  notices: <CoNoticeSpec>[
    (
      category: 'maintenance',
      title: 'صيانة مجدولة',
      body:
          'ستكون الخدمة غير متاحة من الساعة 02:00 إلى 04:00 بسبب أعمال الصيانة.',
    ),
    (
      category: 'release',
      title: 'ميزات جديدة',
      body: 'أصبح بالإمكان الآن رؤية رقم الدور مباشرة على شاشة الحجز.',
    ),
    (
      category: 'notice',
      title: 'تغيير الأسعار',
      body: 'تسري الأسعار الجديدة اعتبارًا من تاريخ الفوترة التالي.',
    ),
    (
      category: 'notice',
      title: 'تأخر الإشعارات',
      body: 'تتأخر بعض الإشعارات، وسيُرسل جزء منها عبر الرسائل النصية.',
    ),
  ],
  failureReasons: <String, String>{
    'INVALID_NUMBER': 'رقم المستلم غير صالح',
    'NOT_FRIEND': 'المستلم لا يستخدم تطبيق المراسلة',
    'TEMPLATE_MISMATCH': 'عدم التطابق مع القالب',
    'NO_CREDIT': 'الرصيد غير كافٍ',
    'CARRIER_TIMEOUT': 'انتهت مهلة استجابة مشغل الاتصالات',
    'OPTED_OUT': 'ألغى المستلم الاشتراك',
  },
  // A status is an adjective in the masculine or a noun, so that the same label
  // serves a subscription, an invoice, and a message.
  labels: <String, String>{
    'trialing': 'فترة تجريبية',
    'active': 'نشط',
    'pastDue': 'متأخر السداد',
    'paused': 'موقوف مؤقتًا',
    'cancelled': 'ملغى',
    'draft': 'مسودة',
    'open': 'بانتظار الدفع',
    'paid': 'مدفوع',
    'overdue': 'متأخر',
    'void': 'باطل',
    'refunded': 'مُسترد',
    'alimtalk': 'إشعار عبر تطبيق المراسلة',
    'sms': 'رسالة نصية',
    'lms': 'رسالة نصية طويلة',
    'queued': 'في قائمة الانتظار',
    'sent': 'مُرسل',
    'failed': 'فشل الإرسال',
    'fallbackSent': 'أُرسل عبر القناة البديلة',
    'approved': 'مُعتمد',
    'reviewing': 'قيد المراجعة',
    'rejected': 'مرفوض',
    'pending': 'معلّق',
    'eligibility': 'التحقق من التغطية التأمينية',
    'dur': 'مراجعة الوصفات الدوائية',
    'ePrescription': 'الوصفة الإلكترونية',
    'insuranceClaim': 'المطالبة التأمينية',
    'identityQr': 'رمز QR للهوية',
    'alimtalkGateway': 'بوابة الرسائل',
    'payment': 'بوابة الدفع',
    'up': 'يعمل',
    'degraded': 'أداء منخفض',
    'down': 'متوقف',
    'login': 'تسجيل الدخول',
    'loginFailed': 'فشل تسجيل الدخول',
    'view': 'عرض',
    'revealRrn': 'كشف رقم الهوية',
    'create': 'إنشاء',
    'update': 'تعديل',
    'delete': 'حذف',
    'print': 'طباعة',
    'exportData': 'تصدير',
    'send': 'إرسال',
    'roleChange': 'تغيير الدور',
    'notice': 'إعلان',
    'maintenance': 'صيانة',
    'release': 'إصدار',
    'fee': 'جدول الرسوم',
    'drug': 'أسعار الأدوية',
    'material': 'المستلزمات',
    'diagnosis': 'التشخيصات',
    'current': 'الحالي',
    'scheduled': 'مجدول',
    'archived': 'مؤرشف',
    'purchase': 'شراء',
    'usage': 'استخدام',
    'refund': 'استرداد',
    'grant': 'منح',
  },
  ops: CoFakerSaasOps(
    // A summary starts with the name it is about, then a colon.
    operatorActions: <String, CoOperatorActionSpec>{
      'tenant.approve': (
        label: 'اعتماد العيادة',
        summary: '{target}: تم اعتماد التسجيل.',
      ),
      'tenant.suspend': (
        label: 'تعليق العيادة',
        summary: '{target}: عُلّق الوصول (السداد متأخر).',
      ),
      'tenant.resume': (
        label: 'استئناف العيادة',
        summary: '{target}: رُفع تعليق الوصول.',
      ),
      'plan.change': (
        label: 'تغيير الباقة',
        summary: '{target}: تغيّرت الباقة من «القياسية» إلى «الاحترافية».',
      ),
      'invoice.issue': (
        label: 'إصدار فاتورة',
        summary: '{target}: صدرت الفاتورة الشهرية.',
      ),
      'invoice.refund': (
        label: 'استرداد مبلغ الفاتورة',
        summary: '{target}: استرداد جزئي لمبلغ الفاتورة.',
      ),
      'credit.grant': (
        label: 'منح أرصدة',
        summary: '{target}: مُنح 1,000 رصيد للرسائل.',
      ),
      'template.approve': (
        label: 'اعتماد القالب',
        summary: '{target}: اعتُمد القالب.',
      ),
      'template.reject': (
        label: 'رفض القالب',
        summary: '{target}: رُفض القالب الإعلاني.',
      ),
      'senderNumber.approve': (
        label: 'اعتماد رقم المرسل',
        summary: '{target}: اعتُمد رقم المرسل.',
      ),
      'master.publish': (
        label: 'نشر البيانات المرجعية للمطالبات',
        summary: 'نُشرت نسخة جديدة من البيانات المرجعية للمطالبات ({target}).',
      ),
      'notice.publish': (
        label: 'نشر إعلان',
        summary: 'نُشر الإعلان «{target}».',
      ),
      'operator.invite': (
        label: 'دعوة مشغّل',
        summary: '{target}: أُرسلت دعوة للانضمام بصفة مشغّل.',
      ),
      'operator.roleChange': (
        label: 'تغيير دور المشغّل',
        summary: '{target}: تغيّر الدور إلى «مسؤول».',
      ),
      'impersonate.start': (
        label: 'الدخول باسم العيادة',
        summary: '{target}: الدخول باسم العيادة لتشخيص مشكلة.',
      ),
    },
    operatorRoles: <String, String>{
      'owner': 'المالك',
      'admin': 'مسؤول',
      'billing': 'الشؤون المالية',
      'support': 'الدعم',
      'viewer': 'عرض فقط',
    },
    autopayFailures: <String, String>{
      'LIMIT_EXCEEDED': 'تجاوز حد البطاقة',
      'CARD_EXPIRED': 'انتهت صلاحية البطاقة',
      'INSUFFICIENT_FUNDS': 'الرصيد غير كافٍ',
      'CARD_LOST': 'أُبلغ عن فقدان البطاقة أو سرقتها',
      'CARD_SUSPENDED': 'البطاقة موقوفة',
      'ISSUER_TIMEOUT': 'انتهت مهلة استجابة البنك المُصدر',
    },
    // Unit prices in riyals; a drug is named as the clinic data names it.
    masterRows: <String, List<CoMasterRowSpec>>{
      'fee': <CoMasterRowSpec>[
        (name: 'كشف مريض جديد', price: 240),
        (name: 'كشف متابعة', price: 180),
        (name: 'العلاج بالتبريد (منطقة واحدة)', price: 140),
      ],
      'drug': <CoMasterRowSpec>[
        (name: 'لوميسول أقراص 10 ملجم', price: 16),
        (name: 'كيرافين مرهم 15 جم', price: 36),
      ],
      'material': <CoMasterRowSpec>[
        (name: 'شاش معقم (10 قطع)', price: 20),
        (name: 'محقنة 1 مل', price: 4),
      ],
      'diagnosis': <CoMasterRowSpec>[
        (name: 'حب الشباب الشائع', price: null),
        (name: 'الثآليل الفيروسية', price: null),
      ],
    },
    masterChecks: <String, String>{
      'DUPLICATE_CODE': 'لا توجد رموز مكررة',
      'NEGATIVE_PRICE': 'لا توجد أسعار صفرية أو سالبة',
      'EFFECTIVE_DATE': 'تواريخ السريان متسلسلة',
      'REQUIRED_COLUMNS': 'لا توجد أعمدة إلزامية ناقصة',
      'ROW_DELTA': 'لا يختلف عدد الصفوف عن الإصدار السابق بأكثر من 5%',
      'REMOVED_IN_USE': 'الرموز المحذوفة غير مستخدمة في مطالبات مفتوحة',
    },
    // The service comes first, then a colon.
    incidentTitles: <String, String>{
      'outage': '{service}: انقطاع',
      'degraded': '{service}: بطء في الاستجابة',
      'maintenance': '{service}: صيانة مجدولة',
    },
    // A fixed number has the form of noun that it needs: `3 عيادات`,
    // `7 فواتير`, `100 رصيد`.
    alerts: <CoOpsAlertSpec>[
      (
        level: 'warning',
        code: 'SYNC_DELAY',
        message: 'تتأخر المزامنة دون اتصال أكثر من 15 دقيقة في 3 عيادات.',
      ),
      (
        level: 'critical',
        code: 'AUTOPAY_FAILED',
        message: 'فشل الدفع التلقائي هذا الشهر لـ7 فواتير.',
      ),
      (
        level: 'warning',
        code: 'LOW_CREDIT',
        message: 'لدى 5 عيادات أقل من 100 رصيد للرسائل.',
      ),
      (
        level: 'info',
        code: 'BACKUP_DONE',
        message: 'اكتمل النسخ الاحتياطي الليلي.',
      ),
    ],
    releaseItems: <String>[
      'أصبح رقم الدور ظاهرًا مباشرة على شاشة الحجز.',
      'الدفعات المجزأة والرصيد المدفوع مسبقًا في شاشة واحدة.',
      'تُرسل الإشعارات التي تعذر إرسالها تلقائيًا عبر الرسائل النصية.',
      'يمكن الإشارة إلى الزملاء بـ@ في ملاحظات الملف الطبي.',
    ],
    regulationItems: <String>[
      'طُبّق جدول الرسوم المعدّل.',
      'طُبّقت قائمة أسعار الأدوية المحدّثة.',
      'حُدّث ربط رموز التشخيص.',
    ],
    releaseTitle: 'ملاحظات إصدار السجل الطبي الإلكتروني {version}',
    // The month follows a colon: `التغييرات التنظيمية: 2026-10`.
    regulationTitle: 'التغييرات التنظيمية: {month}',
    // The count follows its label, so that one or many needs no agreement.
    tenantActivities: <String>[
      'المرضى الجدد المسجلون: {n}',
      'المطالبات المرسلة: {n}',
      'الإشعارات المرسلة: {n}',
      'المواعيد المحجوزة: {n}',
      'حسابات الموظفين المضافة: {n}',
    ],
    templateRejectReason: 'يتضمن محتوى إعلانيًا؛ يُرجى إرساله رسالةً إعلانية.',
    labels: <String, String>{
      'active': 'نشط',
      'invited': 'مدعو',
      'suspended': 'معلّق',
      'allTenants': 'جميع العيادات',
      'proAndAbove': 'باقة «الاحترافية» وما فوقها',
      'dermatology': 'عيادات الجلدية',
      'inApp': 'داخل التطبيق',
      'email': 'البريد الإلكتروني',
      'alimtalk': 'إشعار عبر تطبيق المراسلة',
      'outage': 'انقطاع',
      'degraded': 'أداء منخفض',
      'maintenance': 'صيانة',
      'info': 'معلومة',
      'warning': 'تحذير',
      'critical': 'حرج',
      'topUp': 'شحن الرصيد',
      'usage': 'استخدام',
      'refund': 'استرداد',
      'card': 'بطاقة',
      'transfer': 'تحويل بنكي',
      'virtualAccount': 'حساب بنكي افتراضي',
      'release': 'إصدار',
      'regulation': 'تغيير تنظيمي',
      'failed': 'فشل الدفع',
      'added': 'مُضاف',
      'updated': 'مُحدّث',
      'removed': 'محذوف',
    },
    senderLabels: <String>['الرقم الرئيسي', 'حجز المواعيد', 'الاستقبال'],
    healthMessages: <String, String>{
      'degraded': 'بطء في الاستجابة',
      'down': 'انتهت مهلة الاتصال',
    },
    auditTargets: <String, String>{
      'login': 'الحساب',
      'loginFailed': 'الحساب',
      'roleChange': 'دور الموظف',
      'send': 'الإشعار',
    },
    auditRecords: <String>['مريض', 'ملف طبي', 'فاتورة', 'موعد'],
    // The count follows its label: `عدد الصفوف: 3`.
    masterCheckDetail: 'عدد الصفوف: {n}',
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
  // Saudi Arabia applies a 15% VAT to a software service. The prepaid wallet of
  // message credits is topped up in riyals, from 200 to 10 000, and a top-up
  // from 500 ر.س earns a bonus of five to fifteen percent.
  priceScale: CoSaasPriceScale(
    vatRate: 0.15,
    prepaidTopUps: <int>[200, 500, 1000, 2000, 5000, 10000],
    prepaidBonusTiers: <(int, int)>[
      (500, 5),
      (1000, 8),
      (2000, 10),
      (5000, 15),
    ],
    prepaidLowBalance: 500,
    prepaidUsageMin: 20,
    prepaidUsageRounding: 10,
    prepaidRefundMin: 20,
    prepaidRefundRounding: 10,
  ),
  koreanValues: CoKoreanValues.none,
  // Ten digits, as a Saudi commercial registration number is written.
  businessNumberFormat: '##########',
);

import '../../clinic_data.dart';
import '../../clinic_ops.dart';
import '../../clinic_texts.dart';
import '../../currency_format.dart';
import '../../korean_values.dart';

/// Russian (`ru`) clinic data for `faker.clinic`.
///
/// A general dermatology and aesthetic clinic in rubles that follows
/// `CoFakerClinicData.english`: every list has the length of the English one,
/// in the same order, so that one seed picks the same record in both
/// languages. `ru`, `ru_RU`, and `CoFaker.forLanguage('ru')` read it.
///
/// What makes the data Russian and not a translation only:
///
/// - the amounts are rubles written `1 234,56 ₽`: a no-break space between
///   thousands and before the symbol, and a comma before the kopecks. The price
///   bands are what a private clinic charges in rubles, not the dollars of the
///   English data multiplied, and the price scale has the units of a ruble
///   price (a price rounded to 100 ₽, a package to 500 ₽, a point worth 10 ₽);
/// - a clinic name is the kind of place first and the name in guillemets after
///   it (`Детская клиника «Ясный Вид»`), and a date is `25.11 (ср)`;
/// - the patient is addressed with `вы`, a first-person line is written in the
///   present or the future, which have no gender, and a template that a value
///   fills never needs the value to agree with a noun: the patient and the
///   staff name stand after a colon, in parentheses, or alone, and a count
///   follows its label or is written as `×3`;
/// - no value of the Korean data appears (`CoKoreanValues.none`): the ID is
///   masked in the shape of a Russian insurance account number, the phones and
///   addresses are those of Russia, and a closure notice gives a reason.
const CoFakerClinicData ruClinic = CoFakerClinicData(
  specialties: <CoSpecialtySpec>[
    (name: 'Дерматология', clinicSuffix: 'Дерматологическая клиника'),
    (
      name: 'Пластическая хирургия',
      clinicSuffix: 'Клиника пластической хирургии',
    ),
    (name: 'Семейная медицина', clinicSuffix: 'Семейная клиника'),
    (name: 'Терапия', clinicSuffix: 'Терапевтическая клиника'),
    (name: 'Педиатрия', clinicSuffix: 'Детская клиника'),
  ],
  // They stand in guillemets after the kind of place: `Детская клиника
  // «Образец»`, or `Детская клиника «Демо»`.
  clinicNamePrefixes: <String>[
    'Ясный Вид',
    'Светлая Сторона',
    'Кленовая Заводь',
    'Береговая Тишь',
    'Вечная Хвоя',
    'Образец',
    'Демо',
    'Северный Створ',
  ],
  // A role is a generic title: where a title has a feminine and a masculine
  // form, both are written (`Медсестра / медбрат`), because the name that goes
  // with it is drawn without a sex.
  staffRoles: <String, String>{
    'director': 'Главный врач',
    'doctor': 'Врач',
    'counselor': 'Консультант по работе с пациентами',
    'coordinator': 'Координатор по уходу',
    'nurse': 'Медсестра / медбрат',
    'nurseAide': 'Помощник медсестры',
    'skincare': 'Косметолог',
    'desk': 'Администратор ресепшена',
  },
  visitPurposes: <CoVisitPurposeSpec>[
    (
      name: 'Консультация',
      details: <String>['Первичная консультация', 'Повторная консультация'],
    ),
    (name: 'Процедура', details: <String>['Инъекции', 'Лазер', 'Лифтинг']),
    (
      name: 'Лечение',
      details: <String>['Акне', 'Кожное заболевание', 'Бородавки'],
    ),
    (name: 'Уход', details: <String>['Уход за лицом', 'Успокаивающий уход']),
  ],
  // Prices are rubles, what a private clinic charges (a first visit 3 000 to
  // 8 000 ₽, a laser session 6 000 to 18 000 ₽), and not the dollars of the
  // English data multiplied.
  procedures: <CoProcedureSpec>[
    (
      code: 'CONS01',
      category: 'Приём/Стоимость',
      name: 'Первичный приём',
      unit: 'приём',
      minPrice: 3000,
      maxPrice: 8000,
      taxable: false,
    ),
    (
      code: 'BTX-F',
      category: 'Ботулотоксин/Морщины',
      name: 'Ботулотоксин, лоб',
      unit: 'зона',
      minPrice: 8000,
      maxPrice: 22000,
      taxable: true,
    ),
    (
      code: 'FIL-L',
      category: 'Филлеры/Зона',
      name: 'Гиалуроновый филлер, губы, 1\u00A0мл',
      unit: 'мл',
      minPrice: 20000,
      maxPrice: 45000,
      taxable: true,
    ),
    (
      code: 'LT-01',
      category: 'Лазер/Тонинг',
      name: 'Пикосекундный лазерный тонинг',
      unit: 'сеанс',
      minPrice: 6000,
      maxPrice: 18000,
      taxable: true,
    ),
    (
      code: 'HIFU-300',
      category: 'Лифтинг/HIFU',
      name: 'Лифтинг сфокусированным ультразвуком, 300 линий',
      unit: 'сеанс',
      minPrice: 30000,
      maxPrice: 110000,
      taxable: true,
    ),
    (
      code: 'ACN-01',
      category: 'Акне/Лечение',
      name: 'Экстракция комедонов',
      unit: 'сеанс',
      minPrice: 3000,
      maxPrice: 7000,
      taxable: false,
    ),
    (
      code: 'CARE-01',
      category: 'Уход/Успокаивающий',
      name: 'Успокаивающий уход за лицом с LED-терапией',
      unit: 'сеанс',
      minPrice: 2500,
      maxPrice: 6500,
      taxable: true,
    ),
    (
      code: 'DOC-01',
      category: 'Документы',
      name: 'Медицинская справка',
      unit: 'экз.',
      minPrice: 500,
      maxPrice: 2000,
      taxable: false,
    ),
  ],
  // The codes and the English names are the ones of the English data; the
  // Russian names are those of the Russian version of ICD-10.
  diagnoses: <CoDiagnosisSpec>[
    (code: 'L70.0', name: 'Акне вульгарное', nameEn: 'Acne vulgaris'),
    (code: 'L81.1', name: 'Хлоазма', nameEn: 'Chloasma'),
    (code: 'B07', name: 'Вирусные бородавки', nameEn: 'Viral warts'),
    (
      code: 'L20.9',
      name: 'Атопический дерматит неуточнённый',
      nameEn: 'Atopic dermatitis, unspecified',
    ),
    (
      code: 'L30.9',
      name: 'Дерматит неуточнённый',
      nameEn: 'Dermatitis, unspecified',
    ),
    (
      code: 'L71.9',
      name: 'Розацеа неуточнённая',
      nameEn: 'Rosacea, unspecified',
    ),
  ],
  // Invented names that no marketed product has, as in the English data.
  drugStems: <String>[
    'Адермекс',
    'Люмисол',
    'Кераплен',
    'Диоклин',
    'Навирокс',
    'Сератон',
    'Минобел',
    'Акрозин',
  ],
  // A drug reads `Адермекс, таблетки 10 мг`: the form has its comma and its
  // leading space, and the unit a no-break space.
  drugForms: <({String form, String unit, List<int> strengths})>[
    (form: ', таблетки', unit: '\u00A0мг', strengths: <int>[5, 10, 20, 50]),
    (form: ', капсулы', unit: '\u00A0мг', strengths: <int>[25, 50, 100]),
    (form: ', мазь', unit: '\u00A0г', strengths: <int>[15, 30]),
    (form: ', крем', unit: '\u00A0г', strengths: <int>[15, 30]),
  ],
  drugUsages: <String>[
    'Один раз в день перед сном',
    'Два раза в день после еды',
    'Наносить тонким слоем два раза в день',
    'Наносить один раз в день после очищения кожи',
  ],
  complaints: <String>[
    'Жалуется на более тёмные пятна на обеих щеках',
    'Повторяющиеся высыпания акне по линии челюсти',
    'Беспокоят морщины на лбу',
    'Хочет уменьшить дряблость кожи',
    'Покраснение сохраняется после процедуры',
  ],
  findings: <String>[
    'Нечётко очерченные коричневые пятна в обеих скуловых областях',
    'Множественные воспалительные папулы на подбородке',
    'Динамические морщины лба, степень 2',
    'Умеренная дряблость нижней части лица',
    'Лёгкая эритема, отёка нет',
  ],
  plans: <String>[
    'Лазерный тонинг каждые две недели',
    'Экстракция и наружная терапия',
    'Контрольный осмотр через две недели после инъекции',
    'Рекомендации по защите от солнца, повторный приём через четыре недели',
    'Наблюдение; при ухудшении обратиться повторно',
  ],
  memos: <String>[
    'Рекомендовано не пользоваться макияжем 24\u00A0часа.',
    'Местный анестетик нанесён за 30\u00A0минут до процедуры.',
    'Фото «до» сделаны.',
    'Условия курса объяснены; пациент примет решение позже.',
    'Следующий приём назначен через две недели.',
  ],
  questions: <CoQuestionSpec>[
    (
      question: 'Есть ли у вас аллергия на лекарства?',
      options: <String>[
        'Нет',
        'Лидокаин',
        'Пенициллин',
        'Затрудняюсь ответить',
      ],
    ),
    (
      question: 'Принимаете ли вы какие-либо лекарства?',
      options: <String>['Нет', 'Антикоагулянты', 'Препараты от акне', 'Другое'],
    ),
    (
      question: 'Вы беременны или кормите грудью?',
      options: <String>['Нет', 'Беременна', 'Кормлю грудью', 'Не применимо'],
    ),
    (
      question: 'Что вы хотели бы улучшить в первую очередь?',
      options: <String>['Пигментация', 'Акне', 'Морщины', 'Упругость кожи'],
    ),
  ],
  // Card networks, with the Russian domestic one in place of the fourth.
  cardIssuers: <String>['Visa', 'Mastercard', 'Amex', 'Мир'],
  // A status is written as a noun or in the neuter, so that it fits a visit, a
  // booking, and a payment whatever their gender: `Забронировано`, `Неявка`.
  labels: <String, String>{
    'nhis': 'Обязательное медицинское страхование',
    'medicalAid1': 'Льготное обслуживание (тип 1)',
    'medicalAid2': 'Льготное обслуживание (тип 2)',
    'uninsured': 'За свой счёт',
    'reception': 'Регистрация',
    'waiting': 'Ожидание',
    'consultation': 'Консультация',
    'counseling': 'Консультирование',
    'procedure': 'Процедура',
    'care': 'Уход',
    'payment': 'Оплата',
    'done': 'Готово',
    'requested': 'Запрошено',
    'reserved': 'Забронировано',
    'confirmed': 'Подтверждено',
    'checkedIn': 'Явка отмечена',
    'completed': 'Завершено',
    'cancelled': 'Отменено',
    'noShow': 'Неявка',
    'rejected': 'Отклонено',
    'card': 'Карта',
    'cash': 'Наличные',
    'transfer': 'Банковский перевод',
    'prepaid': 'Предоплаченный остаток',
    'package': 'Курс',
    'female': 'Женский',
    'male': 'Мужской',
  },
  // A package is `Пикосекундный лазерный тонинг ×5`: the count follows the
  // name with a sign, so that no noun has to agree with it.
  packageNameFormat: '{name} ×{sessions}',
  texts: CoFakerClinicTexts(
    consentForms: <CoConsentFormSpec>[
      (
        kind: 'procedure',
        title: 'Согласие на процедуру',
        clauses: <String>[
          'Мне объяснили цель, метод и ожидаемый эффект процедуры.',
          'Я понимаю, что после процедуры возможны покраснение, отёк или синяки.',
          'Я понимаю, что результаты у разных людей различаются и не гарантируются.',
          'Сведения о принимаемых лекарствах, аллергиях и беременности мной указаны.',
        ],
      ),
      (
        kind: 'privacy',
        title: 'Согласие на обработку персональных данных',
        clauses: <String>[
          'Собираются: ФИО, дата рождения, контактные данные, медицинские записи.',
          'Цель: лечение, напоминания о приёме, расчёты за услуги.',
          'Я вправе отказаться, но тогда онлайн-запись может быть недоступна.',
        ],
      ),
      (
        kind: 'photo',
        title: 'Согласие на фотосъёмку',
        clauses: <String>[
          'Фотографии «до» и «после» делаются, чтобы отслеживать динамику.',
          'Фотографии используются только для лечения и никогда не публикуются.',
        ],
      ),
    ],
    consentDisclaimer:
        'Пример текста только для демонстрации. Юридическую проверку не проходил; '
        'не используйте как настоящую форму согласия.',
    feedback: <String, List<String>>{
      'positive': <String>[
        'Врач всё внимательно объяснил.',
        'Недолгое ожидание и приветливая команда.',
        'После трёх сеансов цвет лица улучшился.',
      ],
      'neutral': <String>[
        'Хороший результат, но немного дороговато.',
        'Парковка была неудобной.',
      ],
      'negative': <String>[
        'Пришлось ждать больше 40\u00A0минут после назначенного времени.',
        'Итоговая сумма отличалась от озвученной стоимости.',
      ],
    },
    counselTopics: <CoCounselTopicSpec>[
      (
        topic: 'toning',
        procedureCode: 'LT-01',
        procedure: 'пикосекундный лазерный тонинг',
        concern: 'Тёмные пятна на щеках становятся заметнее.',
        recommend: 'При пигментации рекомендую пикосекундный лазерный тонинг.',
        pain:
            'Слегка пощипывает; большинству людей обезболивание не требуется.',
        interval: 'Около десяти сеансов с интервалом в две недели.',
        downtime:
            'Покраснение держится несколько часов; умываться можно в тот же день.',
        sessions: 10,
      ),
      (
        topic: 'lifting',
        procedureCode: 'HIFU-300',
        procedure: 'лифтинг сфокусированным ультразвуком',
        concern: 'Овал лица кажется обвисшим.',
        recommend:
            'Лифтинг сфокусированным ультразвуком подтягивает глубокие слои кожи.',
        pain:
            'Возле кости возможна ноющая боль, поэтому мы наносим обезболивающий крем.',
        interval: 'Раз в шесть–двенадцать месяцев.',
        downtime: 'Вернуться к работе можно сразу.',
        sessions: 3,
      ),
    ],
    counselScript: (
      greeting: 'Здравствуйте, что вас беспокоит сегодня?',
      questions: <String, String>{
        'pain': 'Это больно?',
        'interval': 'Как часто это нужно делать?',
        'downtime': 'Можно ли сразу после этого идти на работу?',
        'price': 'Сколько это стоит?',
      },
      // The number of sessions follows its label, so that no noun has to agree
      // with it.
      priceAnswer:
          'Один сеанс стоит {price}, курс — {packagePrice} (сеансов в курсе: '
          '{sessions}).',
      bookYes: 'Отлично, хочу записаться на этой неделе.',
      bookYesReply:
          'Конечно, запишу вас и отправлю SMS с рекомендациями после '
          'процедуры.',
      bookNo: 'Я подумаю и свяжусь с вами.',
      bookNoReply: 'Конечно, обращайтесь в любое время.',
      summary:
          'Рекомендация: {procedure}; за сеанс — {price}; курс (сеансов: '
          '{sessions}) — {packagePrice}. {outcome}',
      booked: 'Запись оформлена.',
      pending: 'Решение не принято, связаться позже.',
    ),
    integrationResults: <String, List<CoIntegrationResultSpec>>{
      'eligibility': <CoIntegrationResultSpec>[
        (code: 'OK', message: 'Страховое покрытие подтверждено', ok: true),
        (code: 'LOST', message: 'Страховое покрытие прекращено', ok: false),
        (
          code: 'NOT_FOUND',
          message: 'Застрахованное лицо не найдено',
          ok: false,
        ),
      ],
      'dur': <CoIntegrationResultSpec>[
        (code: 'OK', message: 'Взаимодействий не обнаружено', ok: true),
        (
          code: 'WARN_COMBINATION',
          message: 'Предупреждение о лекарственном взаимодействии',
          ok: false,
        ),
      ],
      'insuranceClaim': <CoIntegrationResultSpec>[
        (code: 'ACCEPTED', message: 'Заявка принята', ok: true),
        (
          code: 'ADJUSTED',
          message: 'Заявка скорректирована при проверке',
          ok: false,
        ),
        (
          code: 'RETURNED',
          message: 'Заявка возвращена: не заполнены обязательные поля',
          ok: false,
        ),
      ],
      'ePrescription': <CoIntegrationResultSpec>[
        (code: 'SENT', message: 'Электронный рецепт отправлен', ok: true),
        (code: 'FAILED', message: 'Аптека не получила рецепт', ok: false),
      ],
      'identityQr': <CoIntegrationResultSpec>[
        (code: 'OK', message: 'Личность подтверждена', ok: true),
        (code: 'EXPIRED', message: 'Срок действия QR-кода истёк', ok: false),
      ],
    },
    // Invented names of insurers.
    insurers: <String>[
      'СК «Северный Парус»',
      'СК «Бухта Жизни»',
      'СК «Горная Гряда»',
      'СК «Прозрачный Ручей»',
    ],
    // `{mention}` stands at the start of a sentence, and `{patient}` after a
    // colon or in parentheses: no template puts a case ending on a name.
    teamNotes: <String>[
      '{mention}, пожалуйста, снизьте мощность лазера на одну ступень. '
          'Пациент: {patient}.',
      'Передача: обезболивающий крем нанесён (пациент: {patient}). '
          '{mention}, можно начинать, когда будете готовы.',
      '{mention}, остался один сеанс курса (пациент: {patient}).',
      'Нужна подпись законного представителя. Пациент: {patient}. '
          '{mention}, пожалуйста, проверьте.',
    ],
    // `Пикосекундный лазер № 2`: the number sign and a no-break space.
    deviceNameFormat: '{kind} №\u00A0{number}',
    staffMentionFormat: '@{name} ({role})',
    nameMentionFormat: '@{name}',
    labels: <String, String>{
      'self': 'Сам пациент',
      'spouse': 'Супруг / супруга',
      'parent': 'Родитель',
      'child': 'Ребёнок',
      'sibling': 'Брат / сестра',
      'grandparent': 'Бабушка / дедушка',
      'grandchild': 'Внук / внучка',
      'legalGuardian': 'Законный представитель',
      'other': 'Другое',
      'picoLaser': 'Пикосекундный лазер',
      'hifu': 'HIFU',
      'rf': 'RF',
      'ipl': 'IPL',
      'ledTherapy': 'LED-терапия',
      'skinAnalyzer': 'Анализатор кожи',
      'photoCamera': 'Клиническая камера',
      'labelPrinter': 'Принтер этикеток',
      'cardTerminal': 'Платёжный терминал',
      'signaturePad': 'Планшет для подписи',
      'kiosk': 'Терминал регистрации',
      'bridgePc': 'Компьютер-шлюз',
      'positive': 'Положительный',
      'neutral': 'Нейтральный',
      'negative': 'Отрицательный',
      'counselor': 'Консультант',
      'patientSpeaker': 'Пациент',
      'life': 'Страхование жизни',
      'nonLife': 'Прочее страхование',
    },
  ),
  ops: CoFakerClinicOps(
    patientTags: <CoColoredLabelSpec>[
      (code: 'vip', label: 'VIP', color: '#F59E0B'),
      (code: 'lifting', label: 'Лифтинг', color: '#6366F1'),
      (code: 'referral', label: 'По рекомендации', color: '#10B981'),
      (code: 'caution', label: 'Особое внимание', color: '#EF4444'),
      (code: 'package', label: 'С курсом процедур', color: '#8B5CF6'),
    ],
    acquisitionChannels: <CoColoredLabelSpec>[
      (code: 'onlineBooking', label: 'Онлайн-запись', color: '#03C75A'),
      (code: 'referral', label: 'По рекомендации', color: '#10B981'),
      (code: 'instagramAd', label: 'Реклама в соцсетях', color: '#E1306C'),
      (code: 'search', label: 'Поиск в интернете', color: '#7C3AED'),
      (code: 'walkIn', label: 'Без записи', color: '#64748B'),
    ],
    specialNotes: <String>[
      'Аллергия на лидокаин',
      'Склонность к келоидным рубцам: снижать мощность лазера',
      'Принимает антикоагулянты: уточнять перед процедурами',
      'Аллергия на пенициллин',
    ],
    rooms: <CoRoomSpec>[
      (
        name: 'Кабинет консультирования 1',
        kind: 'counseling',
        staffRole: 'counselor',
      ),
      (name: 'Кабинет осмотра 1', kind: 'consultation', staffRole: 'director'),
      (name: 'Кабинет осмотра 2', kind: 'consultation', staffRole: 'doctor'),
      (name: 'Процедурный кабинет 1', kind: 'procedure', staffRole: 'nurse'),
      (name: 'Кабинет ухода 1', kind: 'care', staffRole: 'skincare'),
      (name: 'Касса', kind: 'payment', staffRole: 'coordinator'),
      (name: 'Регистрация на планшете', kind: 'reception', staffRole: null),
    ],
    termsChanges: <String>[
      'Уточнён срок хранения данных.',
      'Сеть электронных рецептов добавлена в число получателей.',
      'Указан срок хранения записей ИИ-консультирования — 90\u00A0дней.',
    ],
    consentDispatch: <String, String>{
      'sent': 'Запрос на подпись отправлен.',
      'opened': 'Пациент открыл запрос.',
      'signed': 'Подписано электронно.',
      'expired': 'Срок действия запроса истёк (24\u00A0часа).',
      'failed': 'Не удалось отправить запрос; проверьте номер.',
    },
    adjustments: <String, List<String>>{
      'discount': <String>[
        'Повторный пациент, 10\u00A0%',
        'Члены семей сотрудников, 20\u00A0%',
      ],
      'coupon': <String>[
        'Купон на первый визит, 20\u00A0%',
        'Купон ко дню рождения',
      ],
      'point': <String>['Использованы баллы'],
      'rounding': <String>['Округление'],
    },
    pointReasons: <String, String>{
      'earn': 'Начислено 3\u00A0% от суммы платежа',
      'use': 'Списано при оплате',
      'bonus': 'Бонус за отзыв',
      'expire': 'Срок действия истёк',
      'refund': 'Списано после возврата платежа',
      'adjust': 'Ручная корректировка',
    },
    paymentMessages: <String, String>{
      'approved': 'Платёж по карте одобрен.',
      'cashReceipt': 'Кассовый чек выдан.',
      'partialCancel': 'Частично отменено.',
      'prepaidUsed': 'Списано с предоплаченного остатка.',
      'declined': 'Платёж по карте отклонён: {reason}',
    },
    tasks: <String>[
      'Проверить запас насадок для лазера',
      'Заказать расходные материалы',
      'Закрытие дня',
      'Записать температуру в холодильнике',
    ],
    taskMemos: <String>[
      'Пожалуйста, завершите до 15:00.',
      'Если осталось меньше 5, закажите сразу.',
    ],
    kioskPurposes: <String, String>{
      'checkin': 'Регистрация',
      'reservation': 'Найти мою запись',
      'payment': 'Оплата',
      'document': 'Документы',
    },
    evidence: <CoEvidenceSpec>[
      (kind: 'chartHistory', rule: 'Такая же процедура за последние 3 месяца'),
      (
        kind: 'priceRule',
        rule: 'Сначала предлагать имеющиеся курсы, затем разовые сеансы',
      ),
      (
        kind: 'contraindication',
        rule: 'Не применять обезболивающий крем при аллергии на лидокаин',
      ),
    ],
    counselFailures: <String, String>{
      'CONSENT_MISSING':
          'Нет согласия на запись; ИИ-консультирование не может начаться.',
      'STT_FAILED': 'Не удалось распознать речь. Проверьте микрофон.',
      'TOO_SHORT': 'Запись слишком короткая для краткого изложения.',
      'MODEL_TIMEOUT':
          'Подготовка сводки задерживается. Повторите попытку чуть позже.',
    },
    claimRules: <CoClaimRuleSpec>[
      (
        ruleId: 'R-DX-001',
        severity: 'error',
        diagnosisCode: 'Z41.1',
        feeCode: 'CONS01',
        message:
            'По косметическим диагнозам нельзя выставлять страховой тариф приёма.',
      ),
      (
        ruleId: 'R-FE-118',
        severity: 'warning',
        diagnosisCode: 'L20.9',
        feeCode: 'CONS02',
        message: 'Повторный приём выставлен к оплате дважды в один день.',
      ),
    ],
    crmFailures: <String, String>{
      'NIGHT_AD_NO_CONSENT': 'Нет согласия на ночную рекламную рассылку',
      'MARKETING_NO_CONSENT': 'Нет согласия на рекламную рассылку',
      'OPTED_OUT': 'Отказ от рассылки',
      'INVALID_NUMBER': 'Неверный номер',
    },
    // It ends the name of a compound package: `… + восстанавливающий крем в
    // подарок`.
    packageBonus: 'восстанавливающий крем в подарок',
    staffNotices: <String, List<({String title, String body})>>{
      'training': <({String title, String body})>[
        (
          title: 'Обучение работе с новым лазером',
          body:
              'Обучение работе с новым лазером состоится в следующую среду в 18:00 в процедурном кабинете 1.',
        ),
      ],
      'policy': <({String title, String body})>[
        (
          title: 'Проверка доступа к идентификационным номерам',
          body:
              'Полные идентификационные номера можно открыть только с указанием причины; доступ проверяется ежемесячно.',
        ),
      ],
      'schedule': <({String title, String body})>[
        (
          title: 'График на праздничные дни',
          body:
              'В предпраздничный день клиника закрывается в 17:00. Проверьте общий график.',
        ),
      ],
    },
    vitalsNotes: <String, String>{
      'normal':
          'Витальные показатели стабильны (АД {sys}/{dia}\u00A0мм\u00A0рт.\u00A0ст., ЧСС {pulse}, SpO2 {spo2}\u00A0%, T {temp}\u00A0°C).',
      'highBp':
          'АД {sys}/{dia}\u00A0мм\u00A0рт.\u00A0ст. повышено; повторить измерение после 10\u00A0минут покоя.',
      'fever':
          'Субфебрильная температура {temp}\u00A0°C; врач решит, нужно ли отложить процедуру.',
      'lowSpo2': 'SpO2 {spo2}\u00A0% снижена; перепроверено, одышки нет.',
      'highGlucose':
          'Глюкоза {glucose}\u00A0мг/дл повышена; подтверждено, что измерение после еды.',
    },
    // A date reads `25.11 (ср)` and a range `с 25.11 (ср) по 26.11 (чт)`, so a
    // notice needs no preposition before it. The reason follows `Причина:`, and
    // the name of a holiday stands in parentheses, so that neither needs a case.
    closure: <String, String>{
      'title': 'Закрыто: {dates}',
      'holiday':
          '{clinic}: закрыто {dates} ({name}). Приём возобновится {reopen}.',
      'other':
          '{clinic}: закрыто {dates}. Причина: {reason}. Приём возобновится '
          '{reopen}.',
    },
    closureReasons: <String>[
      'медицинская конференция',
      'ремонт помещений',
      'техническое обслуживание оборудования',
    ],
    dateFormat: '{day}.{month} ({weekday})',
    weekdayNames: <String>['пн', 'вт', 'ср', 'чт', 'пт', 'сб', 'вс'],
    dateRangeFormat: 'с {from} по {to}',
    // `Пикосекундный лазерный тонинг ×3`: the same sign as a package.
    compoundItemFormat: '{name} ×{sessions}',
    labels: <String, String>{
      'requested': 'Запрошено',
      'waiting': 'Ожидание',
      'priority': 'Приоритет',
      'inProgress': 'В работе',
      'done': 'Готово',
      'tablet': 'Планшет',
      'online': 'Онлайн',
      'app': 'Приложение',
      'kiosk': 'Терминал',
      'desk': 'Ресепшен',
      'paper': 'Бумажная форма',
      'privacyRequired': 'Персональные данные (обязательно)',
      'marketingOptional': 'Реклама (по желанию)',
      'sensitiveInfo': 'Специальные категории данных',
      'photoUse': 'Использование фото',
      'thirdParty': 'Передача третьим лицам',
      'aiRecording': 'Запись разговора для ИИ',
      'nightAdvertising': 'Ночная реклама',
      'agreed': 'Согласие дано',
      'withdrawn': 'Согласие отозвано',
      'chartHistory': 'История карты',
      'procedureHistory': 'История процедур',
      'priceRule': 'Правило расчёта цены',
      'contraindication': 'Противопоказание',
      'guideline': 'Клиническая рекомендация',
      'preference': 'Предпочтение',
      'error': 'Ошибка',
      'warning': 'Предупреждение',
      'discount': 'Скидка',
      'coupon': 'Купон',
      'point': 'Баллы',
      'rounding': 'Округление',
    },
  ),
  // The ruble: `1 234,56 ₽`, with a no-break space between thousands and before
  // the symbol.
  currency: CoCurrencyFormat(
    code: 'RUB',
    symbol: '₽',
    pattern: '{amount}\u00A0{symbol}',
    groupSeparator: '\u00A0',
    decimalSeparator: ',',
    fractionDigits: 2,
  ),
  // Rubles are about a hundredth of the dollars of the English data, so the
  // units are those of a ruble price: a price tag rounds to 100 ₽ (`5 900 ₽`),
  // a package to 500 ₽, and a prepaid balance is a multiple of 1 000 ₽; a
  // payment in installments starts at 30 000 ₽, a payment is split from 3 000 ₽,
  // and a point is worth 10 ₽.
  priceScale: CoClinicPriceScale(
    priceRounding: 100,
    packageRounding: 500,
    prepaidStep: 1000,
    installmentMinimum: 30000,
    splitMinimum: 3000,
    splitRounding: 100,
    adjustmentUnit: 100,
    pointUnit: 10,
    quoteMin: 3000,
    quoteMax: 20000,
  ),
  clinicNameFormat: '{suffix} «{prefix}»',
  koreanValues: CoKoreanValues.none,
  // The shape of a Russian insurance account number (СНИЛС), masked but for the
  // last digits.
  maskedIdFormat: '***-***-### ##',
  // A Russian address goes from the city to the street.
  addressLineFormat: '{city}, {line1}',
);

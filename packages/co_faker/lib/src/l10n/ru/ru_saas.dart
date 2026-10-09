import '../../currency_format.dart';
import '../../korean_values.dart';
import '../../saas_data.dart';
import '../../saas_ops.dart';

/// Russian (`ru`) SaaS data for `faker.saas`.
///
/// The back office of a clinic software vendor in rubles that follows
/// `CoFakerSaasData.english`: every list has the length of the English one, in
/// the same order, and a map has its keys. `ru`, `ru_RU`, and
/// `CoFaker.forLanguage('ru')` read it.
///
/// What makes the data Russian and not a translation only:
///
/// - the amounts are rubles written `1 234,56 ₽`, the plans cost rubles, and the
///   VAT of an invoice is the 22% that Russia has applied since 1 January 2026
///   (Federal Law No. 425-FZ);
/// - a notification template writes its variables in Russian
///   (`#{имя}`, `#{клиника}`), and no variable stands where a case ending would
///   have to fit it: a name follows `Здравствуйте,`, and a clinic or a link
///   follows a colon or stands in parentheses;
/// - a summary or a title that a name or a service fills (`{target}`,
///   `{service}`) puts the name first and a colon after it, so that it needs no
///   case, and a count follows its label (`Заявок отправлено: {n}`), which needs
///   no number agreement;
/// - no Korean-only value appears (`CoKoreanValues.none`): the business number
///   of a tenant is ten digits, as the INN of a company is.
const CoFakerSaasData ruSaas = CoFakerSaasData(
  // The prices are rubles a month.
  plans: <CoPlanSpec>[
    (
      code: 'starter',
      name: 'Старт',
      monthlyPrice: 4900,
      seats: 3,
      messageCredits: 500,
    ),
    (
      code: 'standard',
      name: 'Стандарт',
      monthlyPrice: 9900,
      seats: 10,
      messageCredits: 2000,
    ),
    (
      code: 'pro',
      name: 'Профи',
      monthlyPrice: 17900,
      seats: 25,
      messageCredits: 5000,
    ),
    (
      code: 'enterprise',
      name: 'Корпоративный',
      monthlyPrice: 34900,
      seats: 100,
      messageCredits: 20000,
    ),
  ],
  // The variables are Russian and stand after `Здравствуйте,`, a colon, a
  // comma, or in parentheses, because the template is not filled by the
  // generator: the application that sends it fills them.
  messageTemplates: <CoMessageTemplateSpec>[
    (
      code: 'RSV_CREATED',
      name: 'Запись оформлена',
      body:
          'Здравствуйте, #{имя}! Вы записаны на приём: #{клиника}, '
          '#{дата_время}.',
    ),
    (
      code: 'RSV_CANCELLED',
      name: 'Запись отменена',
      body:
          'Здравствуйте, #{имя}! Ваш приём, назначенный на #{дата_время}, '
          'отменён.',
    ),
    (
      code: 'RSV_REMIND_D1',
      name: 'Напоминание',
      body: 'Здравствуйте, #{имя}! Ждём вас завтра в #{время}: #{клиника}.',
    ),
    (
      code: 'QUESTIONNAIRE',
      name: 'Анкета перед приёмом',
      body:
          'Здравствуйте, #{имя}! Пожалуйста, заполните анкету перед приёмом: '
          '#{ссылка}',
    ),
    (
      code: 'SURVEY',
      name: 'Опрос об удовлетворённости',
      body:
          'Здравствуйте, #{имя}! Как прошёл ваш приём (#{клиника})? #{ссылка}',
    ),
    (
      code: 'AD_EVENT',
      name: 'Акция (реклама)',
      body:
          'Реклама. #{клиника}, предложение месяца: 10 сеансов лазерного '
          'тонинга по специальной цене. Отказаться от рассылки: #{ссылка}',
    ),
  ],
  notices: <CoNoticeSpec>[
    (
      category: 'maintenance',
      title: 'Плановое техническое обслуживание',
      body:
          'Сервис будет недоступен с 02:00 до 04:00 из-за технического '
          'обслуживания.',
    ),
    (
      category: 'release',
      title: 'Новые возможности',
      body: 'Теперь номер в очереди можно увидеть прямо на экране записи.',
    ),
    (
      category: 'notice',
      title: 'Изменение тарифов',
      body:
          'Новые тарифы начнут действовать со следующей даты выставления '
          'счёта.',
    ),
    (
      category: 'notice',
      title: 'Задержка уведомлений',
      body: 'Часть уведомлений задерживается и будет отправлена по SMS.',
    ),
  ],
  failureReasons: <String, String>{
    'INVALID_NUMBER': 'Неверный номер получателя',
    'NOT_FRIEND': 'Получатель не пользуется мессенджером',
    'TEMPLATE_MISMATCH': 'Несоответствие шаблону',
    'NO_CREDIT': 'Недостаточно кредитов',
    'CARRIER_TIMEOUT': 'Оператор связи не ответил вовремя',
    'OPTED_OUT': 'Получатель отказался от рассылки',
  },
  // A status is written as a noun, in the neuter, or as a verb that has no
  // gender, because the same label serves a subscription, an invoice, and a
  // message: `Оплачено`, `Действует`, `Отправлено`.
  labels: <String, String>{
    'trialing': 'Пробный период',
    'active': 'Действует',
    'pastDue': 'Оплата просрочена',
    'paused': 'Приостановлено',
    'cancelled': 'Отменено',
    'draft': 'Черновик',
    'open': 'Ожидает оплаты',
    'paid': 'Оплачено',
    'overdue': 'Просрочено',
    'void': 'Аннулировано',
    'refunded': 'Возвращено',
    'alimtalk': 'Уведомление в мессенджере',
    'sms': 'SMS',
    'lms': 'Длинное SMS',
    'queued': 'В очереди',
    'sent': 'Отправлено',
    'failed': 'Не отправлено',
    'fallbackSent': 'Отправлено запасным каналом',
    'approved': 'Одобрено',
    'reviewing': 'На проверке',
    'rejected': 'Отклонено',
    'pending': 'В ожидании',
    'eligibility': 'Проверка страхового покрытия',
    'dur': 'Проверка лекарственных назначений',
    'ePrescription': 'Электронный рецепт',
    'insuranceClaim': 'Заявка на возмещение',
    'identityQr': 'QR-код личности',
    'alimtalkGateway': 'Шлюз сообщений',
    'payment': 'Платёжный шлюз',
    'up': 'Работает',
    'degraded': 'Замедление',
    'down': 'Сбой',
    'login': 'Вход',
    'loginFailed': 'Неудачный вход',
    'view': 'Просмотр',
    'revealRrn': 'Показ идентификационного номера',
    'create': 'Создание',
    'update': 'Изменение',
    'delete': 'Удаление',
    'print': 'Печать',
    'exportData': 'Экспорт',
    'send': 'Отправка',
    'roleChange': 'Смена роли',
    'notice': 'Объявление',
    'maintenance': 'Техобслуживание',
    'release': 'Релиз',
    'fee': 'Прейскурант',
    'drug': 'Цены на лекарства',
    'material': 'Материалы',
    'diagnosis': 'Диагнозы',
    'current': 'Действующий',
    'scheduled': 'Запланированный',
    'archived': 'Архивный',
    'purchase': 'Покупка',
    'usage': 'Использование',
    'refund': 'Возврат',
    'grant': 'Начисление',
  },
  ops: CoFakerSaasOps(
    // A summary starts with the name it is about, then a colon: no case ending
    // has to fit `{target}`.
    operatorActions: <String, CoOperatorActionSpec>{
      'tenant.approve': (
        label: 'Одобрить клинику',
        summary: '{target}: регистрация одобрена.',
      ),
      'tenant.suspend': (
        label: 'Приостановить клинику',
        summary: '{target}: доступ приостановлен (оплата просрочена).',
      ),
      'tenant.resume': (
        label: 'Возобновить клинику',
        summary: '{target}: приостановка доступа снята.',
      ),
      'plan.change': (
        label: 'Сменить тариф',
        summary: '{target}: тариф изменён со «Стандарт» на «Профи».',
      ),
      'invoice.issue': (
        label: 'Выставить счёт',
        summary: '{target}: выставлен ежемесячный счёт.',
      ),
      'invoice.refund': (
        label: 'Вернуть оплату по счёту',
        summary: '{target}: частичный возврат по счёту.',
      ),
      'credit.grant': (
        label: 'Начислить кредиты',
        summary: '{target}: начислено 1 000 кредитов на сообщения.',
      ),
      'template.approve': (
        label: 'Одобрить шаблон',
        summary: '{target}: шаблон одобрен.',
      ),
      'template.reject': (
        label: 'Отклонить шаблон',
        summary: '{target}: рекламный шаблон отклонён.',
      ),
      'senderNumber.approve': (
        label: 'Одобрить номер отправителя',
        summary: '{target}: номер отправителя одобрен.',
      ),
      'master.publish': (
        label: 'Опубликовать справочник заявок',
        summary: 'Опубликован новый справочник заявок ({target}).',
      ),
      'notice.publish': (
        label: 'Опубликовать объявление',
        summary: 'Опубликовано объявление «{target}».',
      ),
      'operator.invite': (
        label: 'Пригласить оператора',
        summary: '{target}: отправлено приглашение стать оператором.',
      ),
      'operator.roleChange': (
        label: 'Изменить роль оператора',
        summary: '{target}: роль изменена на «Администратор».',
      ),
      'impersonate.start': (
        label: 'Войти от имени клиники',
        summary: '{target}: вход от имени клиники для разбора проблемы.',
      ),
    },
    operatorRoles: <String, String>{
      'owner': 'Владелец',
      'admin': 'Администратор',
      'billing': 'Финансы',
      'support': 'Поддержка',
      'viewer': 'Только просмотр',
    },
    autopayFailures: <String, String>{
      'LIMIT_EXCEEDED': 'Превышен лимит по карте',
      'CARD_EXPIRED': 'Срок действия карты истёк',
      'INSUFFICIENT_FUNDS': 'Недостаточно средств',
      'CARD_LOST': 'Карта заявлена как утерянная или украденная',
      'CARD_SUSPENDED': 'Карта заблокирована',
      'ISSUER_TIMEOUT': 'Банк-эмитент не ответил вовремя',
    },
    // Unit prices in rubles; a drug is named as the clinic data names it.
    masterRows: <String, List<CoMasterRowSpec>>{
      'fee': <CoMasterRowSpec>[
        (name: 'Первичный приём', price: 3200),
        (name: 'Повторный приём', price: 2400),
        (name: 'Криотерапия (одна зона)', price: 1800),
      ],
      'drug': <CoMasterRowSpec>[
        (name: 'Люмисол, таблетки 10 мг', price: 45),
        (name: 'Кераплен, мазь 15 г', price: 380),
      ],
      'material': <CoMasterRowSpec>[
        (name: 'Стерильные салфетки (10 шт.)', price: 90),
        (name: 'Шприц 1 мл', price: 12),
      ],
      'diagnosis': <CoMasterRowSpec>[
        (name: 'Акне вульгарное', price: null),
        (name: 'Вирусные бородавки', price: null),
      ],
    },
    masterChecks: <String, String>{
      'DUPLICATE_CODE': 'Нет повторяющихся кодов',
      'NEGATIVE_PRICE': 'Нет нулевых или отрицательных цен',
      'EFFECTIVE_DATE': 'Даты вступления в силу идут по порядку',
      'REQUIRED_COLUMNS': 'Нет пропущенных обязательных столбцов',
      'ROW_DELTA':
          'Число строк отличается от предыдущей версии не более чем на 5 %',
      'REMOVED_IN_USE': 'Удалённые коды не используются в открытых заявках',
    },
    // The service comes first, then a colon, so that no case ending has to fit
    // it.
    incidentTitles: <String, String>{
      'outage': '{service}: сбой',
      'degraded': '{service}: медленные ответы',
      'maintenance': '{service}: плановое обслуживание',
    },
    // A fixed number has the form that it needs: `у 3 клиник`, `по 7 счетам`,
    // `у 5 клиник`.
    alerts: <CoOpsAlertSpec>[
      (
        level: 'warning',
        code: 'SYNC_DELAY',
        message:
            'Офлайн-синхронизация задерживается более чем на 15 минут у 3 клиник.',
      ),
      (
        level: 'critical',
        code: 'AUTOPAY_FAILED',
        message: 'В этом месяце автоплатёж не прошёл по 7 счетам.',
      ),
      (
        level: 'warning',
        code: 'LOW_CREDIT',
        message: 'У 5 клиник осталось меньше 100 кредитов на сообщения.',
      ),
      (
        level: 'info',
        code: 'BACKUP_DONE',
        message: 'Ночное резервное копирование завершено.',
      ),
    ],
    releaseItems: <String>[
      'Номер в очереди теперь виден прямо на экране записи.',
      'Раздельные платежи и предоплаченный остаток — на одном экране.',
      'Неотправленные уведомления автоматически уходят по SMS.',
      'В заметках к карте можно упоминать коллег через @.',
    ],
    regulationItems: <String>[
      'Применён пересмотренный прейскурант.',
      'Применён обновлённый прайс-лист на лекарства.',
      'Обновлено сопоставление кодов диагнозов.',
    ],
    releaseTitle: 'Заметки о релизе ЭМК {version}',
    // The month follows a colon: `Изменения в регулировании: 2026-10`.
    regulationTitle: 'Изменения в регулировании: {month}',
    // The count follows its label, so that one or many needs no agreement.
    tenantActivities: <String>[
      'Новых пациентов зарегистрировано: {n}',
      'Заявок отправлено: {n}',
      'Уведомлений отправлено: {n}',
      'Записей на приём создано: {n}',
      'Учётных записей сотрудников добавлено: {n}',
    ],
    templateRejectReason:
        'Содержит рекламу; отправьте его как рекламное сообщение.',
    labels: <String, String>{
      'active': 'Активен',
      'invited': 'Приглашён',
      'suspended': 'Приостановлен',
      'allTenants': 'Все клиники',
      'proAndAbove': 'Тарифы «Профи» и выше',
      'dermatology': 'Дерматологические клиники',
      'inApp': 'В приложении',
      'email': 'Электронная почта',
      'alimtalk': 'Уведомление в мессенджере',
      'outage': 'Сбой',
      'degraded': 'Замедление',
      'maintenance': 'Техобслуживание',
      'info': 'Информация',
      'warning': 'Предупреждение',
      'critical': 'Критично',
      'topUp': 'Пополнение',
      'usage': 'Использование',
      'refund': 'Возврат',
      'card': 'Карта',
      'transfer': 'Банковский перевод',
      'virtualAccount': 'Виртуальный счёт',
      'release': 'Релиз',
      'regulation': 'Изменение регулирования',
      'failed': 'Платёж не прошёл',
      'added': 'Добавлено',
      'updated': 'Обновлено',
      'removed': 'Удалено',
    },
    senderLabels: <String>['Основной номер', 'Запись на приём', 'Ресепшен'],
    healthMessages: <String, String>{
      'degraded': 'Медленные ответы',
      'down': 'Время ожидания соединения истекло',
    },
    auditTargets: <String, String>{
      'login': 'учётная запись',
      'loginFailed': 'учётная запись',
      'roleChange': 'роль сотрудника',
      'send': 'уведомление',
    },
    auditRecords: <String>['пациент', 'карта', 'счёт', 'запись'],
    // The count follows its label: `Строк: 3`.
    masterCheckDetail: 'Строк: {n}',
  ),
  // The ruble: `1 234,56 ₽`, with a no-break space between thousands and before
  // the symbol.
  currency: CoCurrencyFormat(
    code: 'RUB',
    symbol: '₽',
    pattern: '{amount} {symbol}',
    groupSeparator: ' ',
    decimalSeparator: ',',
    fractionDigits: 2,
  ),
  // Russia has applied a 22% VAT to a software service since 1 January 2026.
  // The prepaid wallet of message credits is topped up in rubles, from 1 000 to
  // 50 000, and a top-up from 3 000 ₽ earns a bonus of five to fifteen percent.
  priceScale: CoSaasPriceScale(
    vatRate: 0.22,
    prepaidTopUps: <int>[1000, 3000, 5000, 10000, 25000, 50000],
    prepaidBonusTiers: <(int, int)>[
      (3000, 5),
      (5000, 8),
      (10000, 10),
      (25000, 15),
    ],
    prepaidLowBalance: 1000,
    prepaidUsageMin: 100,
    prepaidUsageRounding: 50,
    prepaidRefundMin: 100,
    prepaidRefundRounding: 50,
  ),
  koreanValues: CoKoreanValues.none,
  // Ten digits, as the INN of a company is written.
  businessNumberFormat: '##########',
);

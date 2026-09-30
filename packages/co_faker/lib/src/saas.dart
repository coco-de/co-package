import 'co_faker.dart';
import 'korea.dart';
import 'saas_data.dart';

/// A clinic tenant of a SaaS back office.
typedef CoFakeTenant = ({
  String code,
  String name,
  String specialty,
  String businessNumber,
  String ownerName,
  String phone,
  String address,
  String planCode,
  String status,
  DateTime createdAt,
});

/// A subscription of a tenant to a plan.
typedef CoFakeSubscription = ({
  String planCode,
  String planName,
  String status,
  String statusLabel,
  int seats,
  DateTime startedAt,
  DateTime currentPeriodStart,
  DateTime currentPeriodEnd,
  DateTime? trialEndsAt,
  DateTime? cancelledAt,
});

/// A monthly invoice. [supplyAmount] + [vat] = [total].
typedef CoFakeInvoice = ({
  String number,
  DateTime periodStart,
  DateTime periodEnd,
  DateTime issuedAt,
  DateTime dueAt,
  int supplyAmount,
  int vat,
  int total,
  String status,
  String statusLabel,
  DateTime? paidAt,
});

/// A message credit ledger entry. Positive [delta] adds credits.
typedef CoFakeCreditTransaction = ({
  String reason,
  String reasonLabel,
  int delta,
  int balanceAfter,
  DateTime at,
});

/// A registered sender (caller ID) number.
typedef CoFakeSenderNumber = ({
  String number,
  String label,
  String status,
  String statusLabel,
  DateTime registeredAt,
});

/// A notification template with its review status.
typedef CoFakeMessageTemplate = ({
  String code,
  String name,
  String body,
  String channel,
  String status,
  String statusLabel,
});

/// A message delivery log row. [recipient] is masked.
typedef CoFakeMessageLog = ({
  String id,
  String channel,
  String? templateCode,
  String recipient,
  String status,
  String statusLabel,
  int credits,
  DateTime requestedAt,
  DateTime? sentAt,
  String? failureCode,
  String? failureReason,
});

/// A published version of a claim master table (fee, drug, material, or
/// diagnosis codes).
typedef CoFakeMasterVersion = ({
  String kind,
  String kindLabel,
  String version,
  DateTime effectiveFrom,
  DateTime publishedAt,
  int rowCount,
  String status,
  String statusLabel,
});

/// A health check result of an external integration.
typedef CoFakeHealthCheck = ({
  String service,
  String serviceLabel,
  String status,
  String statusLabel,
  int latencyMs,
  DateTime checkedAt,
  String? message,
});

/// An audit log event. [ip] is always a documentation address
/// (RFC 5737 TEST-NET).
typedef CoFakeAuditEvent = ({
  String id,
  String action,
  String actionLabel,
  String actorName,
  String actorRole,
  String target,
  String ip,
  String userAgent,
  DateTime at,
});

/// A service notice.
typedef CoFakeNotice = ({
  String title,
  String body,
  String category,
  String categoryLabel,
  bool pinned,
  DateTime publishedAt,
});

/// One point of a time series.
typedef CoFakePoint = ({DateTime date, num value});

/// Generates SaaS back-office values for a clinic software vendor: tenants,
/// plans, subscriptions, invoices, message credits, sender numbers,
/// notification templates, delivery logs, claim master versions,
/// integration health, audit events, notices, and KPI time series.
///
/// Status and action codes are locale independent (`pastDue`, `revealRrn`,
/// `fallbackSent`, ...); `label(code)` localizes them. Times are relative to
/// `faker.now`, so a fixed clock gives repeatable dates.
class CoFakerSaas {
  /// Creates a SaaS generator backed by [faker].
  CoFakerSaas(this.faker);

  /// The faker instance used by this module.
  final CoFaker faker;

  /// The SaaS data of the current locale.
  CoFakerSaasData get data => faker.localeData.saas!;

  bool get _korean => faker.locale.startsWith('ko');

  /// Returns the localized label of a code, or the code itself.
  String label(String code) => data.labels[code] ?? code;

  /// Generates a tenant: a clinic with its business details and plan.
  CoFakeTenant tenant() {
    final specialty = faker.clinic.specialty();
    final String phone;
    final String address;
    if (_korean) {
      final road = faker.korea.roadAddress();
      phone = faker.korea.landlinePhone(
        areaCode: CoFakerKorea.areaCodeOf(road.sido),
      );
      address = '${road.line1} ${road.line2}';
    } else {
      phone = faker.internet.phoneNumber();
      address = faker.address.streetAddress();
    }
    return (
      code: 'CLN-${faker.random.string(6, alphabet: _codeAlphabet)}',
      name: faker.clinic.clinicName(specialty: specialty),
      specialty: specialty,
      businessNumber: faker.korea.businessNumber(),
      ownerName: faker.person.fullName(),
      phone: phone,
      address: address,
      planCode: plan().code,
      status: subscriptionStatus(),
      createdAt: _past(730),
    );
  }

  /// Generates a plan from the catalog.
  CoPlanSpec plan() => faker.random.pick(data.plans);

  /// Generates a subscription status: `active` (70%), `trialing`, `pastDue`,
  /// `paused`, or `cancelled`.
  String subscriptionStatus() {
    return _weighted(const <(String, int)>[
      ('active', 70),
      ('trialing', 10),
      ('pastDue', 8),
      ('paused', 4),
      ('cancelled', 8),
    ]);
  }

  /// Generates a subscription whose period contains `faker.now`.
  CoFakeSubscription subscription({String? planCode, String? status}) {
    final selected = planCode == null
        ? plan()
        : data.plans.firstWhere(
            (p) => p.code == planCode,
            orElse: () => throw ArgumentError.value(planCode, 'planCode'),
          );
    final resolved = status ?? subscriptionStatus();
    final startedAt = _past(540);
    final periodStart = _monthStart(faker.now);
    final periodEnd = _addMonths(periodStart, 1);
    return (
      planCode: selected.code,
      planName: selected.name,
      status: resolved,
      statusLabel: label(resolved),
      seats: faker.random.int(min: 1, max: selected.seats),
      startedAt: startedAt,
      currentPeriodStart: periodStart,
      currentPeriodEnd: periodEnd,
      trialEndsAt: resolved == 'trialing'
          ? _day(faker.now).add(Duration(days: faker.random.int(max: 14)))
          : null,
      cancelledAt: resolved == 'cancelled' ? _past(60) : null,
    );
  }

  /// Generates a monthly invoice for the month [monthsAgo] months before
  /// `faker.now` (0 is the current month). [supplyAmount] defaults to a plan
  /// price; VAT is 10%.
  CoFakeInvoice invoice({int monthsAgo = 1, int? supplyAmount}) {
    final periodStart = _addMonths(_monthStart(faker.now), -monthsAgo);
    final periodEnd = _addMonths(periodStart, 1);
    final supply = supplyAmount ?? plan().monthlyPrice;
    final vat = (supply * 0.1).round();
    final issuedAt = periodEnd;
    final dueAt = issuedAt.add(const Duration(days: 10));
    final String status;
    if (monthsAgo <= 0) {
      status = 'draft';
    } else if (dueAt.isAfter(faker.now)) {
      status = faker.random.double() < 0.5 ? 'paid' : 'open';
    } else {
      status = _weighted(const <(String, int)>[
        ('paid', 88),
        ('overdue', 8),
        ('void', 2),
        ('refunded', 2),
      ]);
    }
    return (
      number:
          'INV-${periodStart.year}${_two(periodStart.month)}-'
          '${faker.random.digits('######')}',
      periodStart: periodStart,
      periodEnd: periodEnd,
      issuedAt: issuedAt,
      dueAt: dueAt,
      supplyAmount: supply,
      vat: vat,
      total: supply + vat,
      status: status,
      statusLabel: label(status),
      paidAt: status == 'paid' || status == 'refunded'
          ? issuedAt.add(Duration(days: faker.random.int(max: 9)))
          : null,
    );
  }

  /// Generates a message credit ledger of [count] entries, oldest first,
  /// starting from [openingBalance]. Balances never go negative.
  List<CoFakeCreditTransaction> creditLedger({
    int count = 10,
    int openingBalance = 0,
  }) {
    var balance = openingBalance;
    final start = faker.now.subtract(Duration(days: count * 3));
    final result = <CoFakeCreditTransaction>[];
    for (var i = 0; i < count; i++) {
      final at = start.add(
        Duration(days: i * 3, minutes: faker.random.int(max: 1439)),
      );
      String reason;
      int delta;
      if (balance < 200 || (i == 0 && balance == 0)) {
        reason = faker.random.double() < 0.9 ? 'purchase' : 'grant';
        delta = faker.random.pick(const <int>[1000, 2000, 5000]);
      } else {
        reason = faker.random.double() < 0.95 ? 'usage' : 'refund';
        final amount = faker.random.int(min: 20, max: balance ~/ 2);
        delta = reason == 'usage' ? -amount : faker.random.int(min: 1, max: 20);
      }
      balance += delta;
      result.add((
        reason: reason,
        reasonLabel: label(reason),
        delta: delta,
        balanceAfter: balance,
        at: at,
      ));
    }
    return result;
  }

  /// Generates a registered sender number (a fake landline).
  CoFakeSenderNumber senderNumber() {
    final status = _weighted(const <(String, int)>[
      ('approved', 80),
      ('pending', 15),
      ('rejected', 5),
    ]);
    return (
      number: _korean
          ? faker.korea.landlinePhone()
          : faker.internet.phoneNumber(),
      label: faker.random.pick(
        _korean
            ? const <String>['대표번호', '예약 문의', '상담실', '데스크']
            : const <String>['Main line', 'Bookings', 'Front desk'],
      ),
      status: status,
      statusLabel: label(status),
      registeredAt: _past(365),
    );
  }

  /// Generates a notification template with its review status.
  CoFakeMessageTemplate messageTemplate() {
    final spec = faker.random.pick(data.messageTemplates);
    final status = _weighted(const <(String, int)>[
      ('approved', 80),
      ('reviewing', 15),
      ('rejected', 5),
    ]);
    return (
      code: spec.code,
      name: spec.name,
      body: spec.body,
      channel: 'alimtalk',
      status: status,
      statusLabel: label(status),
    );
  }

  /// Generates a message delivery log row requested within the last [days]
  /// days.
  CoFakeMessageLog messageLog({int days = 7}) {
    final channel = _weighted(const <(String, int)>[
      ('alimtalk', 75),
      ('sms', 15),
      ('lms', 10),
    ]);
    final status = _weighted(const <(String, int)>[
      ('sent', 86),
      ('fallbackSent', 6),
      ('failed', 5),
      ('queued', 3),
    ]);
    final requestedAt = faker.date.between(
      faker.now.subtract(Duration(days: days)),
      faker.now,
      utc: faker.now.isUtc,
    );
    final failed = status == 'failed' || status == 'fallbackSent';
    final failureCode = failed
        ? faker.random.pick(data.failureReasons.keys.toList())
        : null;
    final recipient = _korean
        ? CoFakerKorea.maskPhone(faker.korea.mobilePhone())
        : faker.internet.phoneNumber();
    return (
      id: faker.id.uuid(),
      channel: channel,
      templateCode: channel == 'alimtalk'
          ? faker.random.pick(data.messageTemplates).code
          : null,
      recipient: recipient,
      status: status,
      statusLabel: label(status),
      credits: switch (channel) {
        'alimtalk' => 1,
        'sms' => 2,
        _ => 5,
      },
      requestedAt: requestedAt,
      sentAt: status == 'queued' || status == 'failed'
          ? null
          : requestedAt.add(
              Duration(seconds: faker.random.int(min: 1, max: 90)),
            ),
      failureCode: failureCode,
      failureReason: failureCode == null
          ? null
          : data.failureReasons[failureCode],
    );
  }

  /// Generates a claim master version. [kind] is `fee`, `drug`,
  /// `material`, or `diagnosis`; versions are named `YYYY.MM.rN`.
  CoFakeMasterVersion masterVersion({String? kind, int monthsAgo = 0}) {
    final resolvedKind =
        kind ??
        faker.random.pick<String>(const <String>[
          'fee',
          'drug',
          'material',
          'diagnosis',
        ]);
    final effective = _addMonths(_monthStart(faker.now), -monthsAgo);
    final status = monthsAgo < 0
        ? 'scheduled'
        : (monthsAgo == 0 ? 'current' : 'archived');
    return (
      kind: resolvedKind,
      kindLabel: label(resolvedKind),
      version:
          '${effective.year}.${_two(effective.month)}.'
          'r${faker.random.int(min: 1, max: 3)}',
      effectiveFrom: effective,
      publishedAt: effective.subtract(
        Duration(days: faker.random.int(min: 3, max: 20)),
      ),
      rowCount: switch (resolvedKind) {
        'drug' => faker.random.int(min: 20000, max: 26000),
        'material' => faker.random.int(min: 15000, max: 19000),
        'diagnosis' => faker.random.int(min: 50000, max: 54000),
        _ => faker.random.int(min: 8000, max: 11000),
      },
      status: status,
      statusLabel: label(status),
    );
  }

  /// Integration service codes checked by [healthCheck].
  static const List<String> services = <String>[
    'eligibility',
    'dur',
    'ePrescription',
    'insuranceClaim',
    'identityQr',
    'alimtalkGateway',
    'payment',
  ];

  /// Generates a health check result checked within the last 5 minutes.
  CoFakeHealthCheck healthCheck({String? service}) {
    final resolved = service ?? faker.random.pick<String>(services);
    final status = _weighted(const <(String, int)>[
      ('up', 90),
      ('degraded', 7),
      ('down', 3),
    ]);
    return (
      service: resolved,
      serviceLabel: label(resolved),
      status: status,
      statusLabel: label(status),
      latencyMs: switch (status) {
        'up' => faker.random.int(min: 40, max: 400),
        'degraded' => faker.random.int(min: 1200, max: 4000),
        _ => 0,
      },
      checkedAt: faker.now.subtract(
        Duration(seconds: faker.random.int(max: 300)),
      ),
      message: switch (status) {
        'degraded' => _korean ? '응답 지연' : 'Slow responses',
        'down' => _korean ? '연결 시간 초과' : 'Connection timed out',
        _ => null,
      },
    );
  }

  /// Audit action codes generated by [auditEvent].
  static const List<String> auditActions = <String>[
    'login',
    'loginFailed',
    'view',
    'revealRrn',
    'create',
    'update',
    'delete',
    'print',
    'exportData',
    'send',
    'roleChange',
  ];

  /// Generates an audit event within the last [days] days.
  CoFakeAuditEvent auditEvent({int days = 30}) {
    final action = _weighted(const <(String, int)>[
      ('view', 40),
      ('login', 15),
      ('update', 12),
      ('create', 10),
      ('print', 5),
      ('send', 5),
      ('revealRrn', 4),
      ('loginFailed', 3),
      ('exportData', 2),
      ('delete', 2),
      ('roleChange', 2),
    ]);
    final role = faker.clinic.staffRole();
    final target = switch (action) {
      'login' || 'loginFailed' => _korean ? '계정' : 'account',
      'roleChange' => _korean ? '직원 권한' : 'staff role',
      'send' => _korean ? '알림톡' : 'notification',
      _ =>
        '${faker.random.pick(_korean ? const <String>['환자', '차트', '수납', '예약'] : const <String>['patient', 'chart', 'invoice', 'reservation'])}'
            ' #${faker.random.int(min: 1, max: 9999)}',
    };
    return (
      id: faker.id.uuid(),
      action: action,
      actionLabel: label(action),
      actorName: faker.person.fullName(),
      actorRole: role.label,
      target: target,
      ip:
          '${faker.random.pick(const <String>['192.0.2', '198.51.100', '203.0.113'])}'
          '.${faker.random.int(min: 1, max: 254)}',
      userAgent: faker.random.pick(_userAgents),
      at: faker.date.between(
        faker.now.subtract(Duration(days: days)),
        faker.now,
        utc: faker.now.isUtc,
      ),
    );
  }

  /// Generates a service notice published within the last 90 days.
  CoFakeNotice notice() {
    final spec = faker.random.pick(data.notices);
    return (
      title: spec.title,
      body: spec.body,
      category: spec.category,
      categoryLabel: label(spec.category),
      pinned: faker.random.double() < 0.15,
      publishedAt: _past(90),
    );
  }

  /// Generates a daily KPI series of [days] points ending on the day of
  /// `faker.now` (inclusive).
  ///
  /// Values start around [base], move by [trend] per day, swing with a
  /// weekly pattern of relative amplitude [weekly] (weekends lower), and get
  /// relative noise up to [noise]. [integer] rounds values; negatives are
  /// clamped to zero.
  List<CoFakePoint> timeSeries({
    int days = 30,
    num base = 100,
    num trend = 0,
    double weekly = 0.2,
    double noise = 0.1,
    bool integer = true,
  }) {
    if (days < 0) {
      throw ArgumentError.value(days, 'days', 'must not be negative');
    }
    final end = _day(faker.now);
    return <CoFakePoint>[
      for (var i = 0; i < days; i++)
        _point(
          end.subtract(Duration(days: days - 1 - i)),
          i,
          base,
          trend,
          weekly,
          noise,
          integer,
        ),
    ];
  }

  CoFakePoint _point(
    DateTime date,
    int i,
    num base,
    num trend,
    double weekly,
    double noise,
    bool integer,
  ) {
    final level = base + trend * i;
    final weekday = date.weekday;
    final season = weekday == DateTime.sunday
        ? -weekly
        : (weekday == DateTime.saturday ? -weekly / 2 : weekly / 5);
    final jitter = faker.random.double(min: -noise, max: noise);
    final value = level * (1 + season + jitter);
    final clamped = value < 0 ? 0 : value;
    return (
      date: date,
      value: integer
          ? clamped.round()
          : double.parse(clamped.toStringAsFixed(2)),
    );
  }

  DateTime _past(int days) =>
      _day(faker.date.past(days: days, utc: faker.now.isUtc));

  T _weighted<T>(List<(T, int)> items) {
    var total = 0;
    for (final item in items) {
      total += item.$2;
    }
    var roll = faker.random.int(max: total - 1);
    for (final item in items) {
      if (roll < item.$2) return item.$1;
      roll -= item.$2;
    }
    return items.last.$1;
  }

  static DateTime _day(DateTime value) => value.isUtc
      ? DateTime.utc(value.year, value.month, value.day)
      : DateTime(value.year, value.month, value.day);

  static DateTime _monthStart(DateTime value) => value.isUtc
      ? DateTime.utc(value.year, value.month)
      : DateTime(value.year, value.month);

  static DateTime _addMonths(DateTime value, int months) => value.isUtc
      ? DateTime.utc(value.year, value.month + months, value.day)
      : DateTime(value.year, value.month + months, value.day);

  static String _two(int value) => value.toString().padLeft(2, '0');

  static const String _codeAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  static const List<String> _userAgents = <String>[
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/140.0 Safari/537.36',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 15_6) Safari/605.1.15',
    'Mozilla/5.0 (iPad; CPU OS 18_6 like Mac OS X) Mobile/15E148',
    'EMR-Desktop/1.8.2 (Windows 11)',
  ];
}

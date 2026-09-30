import 'co_faker.dart';
import 'korea.dart';
import 'saas_data.dart';
import 'saas_ops.dart';

/// How [CoFakerSaas.invoice] formats invoice numbers.
enum CoInvoiceNumberFormat {
  /// `INV-YYYYMM-NNNNNN` with six random digits (the default).
  compact,

  /// `INV-YYYY-MM-NNNN` with a four-digit sequence.
  monthly,
}

/// The bucket size of [CoFakerSaas.timeSeries].
enum CoTimeGranularity {
  /// One point per hour, shaped by clinic opening hours.
  hour,

  /// One point per day, shaped by the weekday (the default).
  day,

  /// One point per month, shaped by a mild yearly season.
  month,
}

/// A prepaid (won) ledger entry of a tenant wallet. [kind] is `topUp`,
/// `usage`, or `refund`; top-ups carry the [bonus] earned by
/// [CoFakerSaas.prepaidBonusTiers] and the payment [method].
typedef CoFakePrepaidEntry = ({
  String kind,
  String kindLabel,
  int amount,
  int bonus,
  int balanceAfter,
  String? method,
  String? methodLabel,
  DateTime at,
});

/// A vendor operator of the back office.
typedef CoFakeOperator = ({
  String name,
  String email,
  String role,
  String roleLabel,
  String status,
  String statusLabel,
  bool twoFactor,
  List<String> allowedIps,
  DateTime? lastLoginAt,
});

/// An audit event of a vendor operator in the back office. [action] is a
/// console action key such as `tenant.approve`.
typedef CoFakeOperatorEvent = ({
  String id,
  String action,
  String actionLabel,
  String operatorName,
  String operatorRole,
  String target,
  String summary,
  String ip,
  DateTime at,
});

/// A changed row between two claim master versions. [change] is `added`,
/// `updated`, or `removed`; prices are `null` for unpriced kinds.
typedef CoFakeMasterChange = ({
  String kind,
  String code,
  String name,
  String change,
  String changeLabel,
  int? oldPrice,
  int? newPrice,
});

/// A claim master validation check result.
typedef CoFakeMasterCheck = ({
  String code,
  String label,
  bool passed,
  String? detail,
});

/// A point-in-time health snapshot of one integration service.
typedef CoFakeIntegrationSnapshot = ({
  String service,
  String serviceLabel,
  String status,
  String statusLabel,
  double successRate,
  int calls24h,
  int avgLatencyMs,
  DateTime? lastIncidentAt,
});

/// An incident or maintenance window of an integration service.
typedef CoFakeIncident = ({
  String service,
  String kind,
  String kindLabel,
  String title,
  DateTime startedAt,
  DateTime? endedAt,
  bool resolved,
});

/// An operations alert.
typedef CoFakeOpsAlert = ({
  String level,
  String levelLabel,
  String code,
  String message,
  DateTime at,
});

/// A release note or regulatory update announcement with its audience,
/// channels, and read rate.
typedef CoFakeAnnouncement = ({
  String kind,
  String kindLabel,
  String title,
  List<String> items,
  String audience,
  String audienceLabel,
  List<String> channels,
  double readRate,
  DateTime publishedAt,
});

/// A recent activity line of a tenant.
typedef CoFakeTenantActivity = ({String tenant, String text, DateTime at});

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
  String? failureCode,
  String? failureReason,
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
  bool advertising,
  String? rejectReason,
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

  /// The operations console texts of the current locale.
  CoFakerSaasOps get ops => data.ops ?? CoFakerSaasOps.english;

  /// Returns the localized label of a code, falling back to the operations
  /// labels, English, and then the code itself.
  String label(String code) =>
      data.labels[code] ??
      ops.labels[code] ??
      CoFakerSaasData.english.labels[code] ??
      CoFakerSaasOps.english.labels[code] ??
      code;

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
  ///
  /// [status] fixes the status and [statusWeights] replaces the default
  /// distribution of past-due invoices (for example
  /// `{'paid': 80, 'failed': 15, 'overdue': 5}`). A `failed` invoice is a
  /// failed card autopay and carries [CoFakeInvoice.failureCode] and
  /// [CoFakeInvoice.failureReason]. [numberFormat] and [sequence] shape the
  /// invoice number.
  CoFakeInvoice invoice({
    int monthsAgo = 1,
    int? supplyAmount,
    String? status,
    Map<String, int>? statusWeights,
    CoInvoiceNumberFormat numberFormat = CoInvoiceNumberFormat.compact,
    int? sequence,
  }) {
    final periodStart = _addMonths(_monthStart(faker.now), -monthsAgo);
    final periodEnd = _addMonths(periodStart, 1);
    final supply = supplyAmount ?? plan().monthlyPrice;
    final vat = (supply * 0.1).round();
    final issuedAt = periodEnd;
    final dueAt = issuedAt.add(const Duration(days: 10));
    final String resolved;
    if (status != null) {
      resolved = status;
    } else if (statusWeights != null) {
      resolved = _weighted<String>([
        for (final entry in statusWeights.entries) (entry.key, entry.value),
      ]);
    } else if (monthsAgo <= 0) {
      resolved = 'draft';
    } else if (dueAt.isAfter(faker.now)) {
      resolved = faker.random.double() < 0.5 ? 'paid' : 'open';
    } else {
      resolved = _weighted(const <(String, int)>[
        ('paid', 88),
        ('overdue', 8),
        ('void', 2),
        ('refunded', 2),
      ]);
    }
    final number = switch (numberFormat) {
      CoInvoiceNumberFormat.compact =>
        'INV-${periodStart.year}${_two(periodStart.month)}-'
            '${sequence?.toString().padLeft(6, '0') ?? faker.random.digits('######')}',
      CoInvoiceNumberFormat.monthly =>
        'INV-${periodStart.year}-${_two(periodStart.month)}-'
            '${sequence?.toString().padLeft(4, '0') ?? faker.random.digits('####')}',
    };
    final failure = resolved == 'failed' ? autopayFailure() : null;
    return (
      number: number,
      periodStart: periodStart,
      periodEnd: periodEnd,
      issuedAt: issuedAt,
      dueAt: dueAt,
      supplyAmount: supply,
      vat: vat,
      total: supply + vat,
      status: resolved,
      statusLabel: resolved == 'failed'
          ? (ops.labels['failed'] ?? 'failed')
          : label(resolved),
      paidAt: resolved == 'paid' || resolved == 'refunded'
          ? issuedAt.add(Duration(days: faker.random.int(max: 9)))
          : null,
      failureCode: failure?.code,
      failureReason: failure?.reason,
    );
  }

  /// Generates [count] consecutive monthly invoices, newest first, starting
  /// with last month and numbered with a running [CoInvoiceNumberFormat]
  /// sequence from [firstSequence].
  List<CoFakeInvoice> invoices(
    int count, {
    int? supplyAmount,
    Map<String, int>? statusWeights,
    CoInvoiceNumberFormat numberFormat = CoInvoiceNumberFormat.monthly,
    int firstSequence = 1,
  }) {
    final supply = supplyAmount ?? plan().monthlyPrice;
    return <CoFakeInvoice>[
      for (var i = 0; i < count; i++)
        invoice(
          monthsAgo: i + 1,
          supplyAmount: supply,
          statusWeights: statusWeights,
          numberFormat: numberFormat,
          sequence: firstSequence + count - 1 - i,
        ),
    ];
  }

  /// Autopay failure codes: `LIMIT_EXCEEDED`, `CARD_EXPIRED`,
  /// `INSUFFICIENT_FUNDS`, `CARD_LOST`, `CARD_SUSPENDED`, `ISSUER_TIMEOUT`.
  List<String> get autopayFailureCodes => ops.autopayFailures.keys.toList();

  /// Generates a card autopay (or card approval) failure reason.
  ({String code, String reason}) autopayFailure() {
    final code = _weighted<String>(const <(String, int)>[
      ('LIMIT_EXCEEDED', 35),
      ('INSUFFICIENT_FUNDS', 25),
      ('CARD_EXPIRED', 20),
      ('CARD_SUSPENDED', 8),
      ('CARD_LOST', 7),
      ('ISSUER_TIMEOUT', 5),
    ]);
    return (code: code, reason: ops.autopayFailures[code] ?? code);
  }

  /// Prepaid top-up bonus tiers `(minimum amount, bonus percent)` in won,
  /// lowest first: 100,000 won earns 10% up to 60% from 15,000,000 won.
  static const List<(int, int)> prepaidBonusTiers = <(int, int)>[
    (100000, 10),
    (300000, 15),
    (500000, 20),
    (1000000, 25),
    (3000000, 35),
    (5000000, 45),
    (10000000, 55),
    (15000000, 60),
  ];

  /// Returns the bonus earned by a top-up of [amount] won.
  static int prepaidBonus(int amount) {
    var percent = 0;
    for (final tier in prepaidBonusTiers) {
      if (amount >= tier.$1) percent = tier.$2;
    }
    return amount * percent ~/ 100;
  }

  /// Generates a prepaid (won) wallet ledger of [count] entries, oldest
  /// first, from [openingBalance]. Top-ups pick a tier amount and earn the
  /// tier bonus; usage never drives the balance negative.
  List<CoFakePrepaidEntry> prepaidLedger({
    int count = 10,
    int openingBalance = 0,
  }) {
    var balance = openingBalance;
    final start = faker.now.subtract(Duration(days: count * 5));
    final result = <CoFakePrepaidEntry>[];
    for (var i = 0; i < count; i++) {
      final at = start.add(
        Duration(days: i * 5, minutes: faker.random.int(max: 1439)),
      );
      final String kind;
      var amount = 0;
      var bonus = 0;
      String? method;
      if (balance < 50000 || faker.random.double() < 0.25) {
        kind = 'topUp';
        amount = faker.random.pick(const <int>[
          100000,
          300000,
          500000,
          1000000,
          3000000,
          5000000,
        ]);
        bonus = prepaidBonus(amount);
        method = _weighted<String>(const <(String, int)>[
          ('card', 55),
          ('transfer', 30),
          ('virtualAccount', 15),
        ]);
      } else if (faker.random.double() < 0.95) {
        kind = 'usage';
        amount = -_roundTo(
          faker.random.int(min: 10000, max: balance ~/ 2),
          1000,
        );
      } else {
        kind = 'refund';
        amount = -_roundTo(
          faker.random.int(min: 1000, max: balance ~/ 4),
          1000,
        );
      }
      balance += amount + bonus;
      result.add((
        kind: kind,
        kindLabel: label(kind),
        amount: amount,
        bonus: bonus,
        balanceAfter: balance,
        method: method,
        methodLabel: method == null ? null : label(method),
        at: at,
      ));
    }
    return result;
  }

  /// Operator role codes: `owner`, `admin`, `billing`, `support`, `viewer`.
  List<String> get operatorRoles => ops.operatorRoles.keys.toList();

  /// Generates a vendor operator with a role, status, two-factor flag, and
  /// allowed IP ranges (RFC 5737 documentation ranges only).
  CoFakeOperator operator({String? role}) {
    final resolvedRole =
        role ??
        _weighted<String>(const <(String, int)>[
          ('owner', 5),
          ('admin', 20),
          ('billing', 15),
          ('support', 45),
          ('viewer', 15),
        ]);
    final status = _weighted<String>(const <(String, int)>[
      ('active', 82),
      ('invited', 10),
      ('suspended', 8),
    ]);
    final sex = faker.person.sex();
    final first = faker.person.firstName(sex: sex);
    final last = faker.person.lastName();
    final restricted = resolvedRole == 'owner' || faker.random.double() < 0.5;
    return (
      name: faker.person.fullName(firstName: first, lastName: last),
      email: faker.internet.email(
        firstName: first,
        lastName: last,
        domain: 'ops.example.com',
      ),
      role: resolvedRole,
      roleLabel: ops.operatorRoles[resolvedRole] ?? resolvedRole,
      status: status,
      statusLabel: label(status),
      twoFactor:
          resolvedRole == 'owner' ||
          resolvedRole == 'admin' ||
          faker.random.double() < 0.6,
      allowedIps: restricted
          ? <String>[
              for (var i = 0; i < 1 + faker.random.int(max: 1); i++)
                '${faker.random.pick(_testNets)}.${faker.random.int(max: 7) * 32}/27',
            ]
          : const <String>[],
      lastLoginAt: status == 'invited'
          ? null
          : faker.date.between(
              faker.now.subtract(const Duration(days: 14)),
              faker.now,
              utc: faker.now.isUtc,
            ),
    );
  }

  /// Console action keys generated by [operatorEvent].
  List<String> get operatorActions => ops.operatorActions.keys.toList();

  /// Generates a vendor operator audit event within the last [days] days.
  /// [action] is a console action key such as `tenant.approve`.
  CoFakeOperatorEvent operatorEvent({String? action, int days = 30}) {
    final key = action ?? faker.random.pick<String>(operatorActions);
    final spec = ops.operatorActions[key];
    if (spec == null) throw ArgumentError.value(action, 'action');
    final operator = this.operator();
    final target = switch (key) {
      'master.publish' => masterVersion().version,
      'notice.publish' => notice().title,
      'operator.invite' || 'operator.roleChange' => faker.person.fullName(),
      _ => faker.clinic.clinicName(),
    };
    return (
      id: faker.id.uuid(),
      action: key,
      actionLabel: spec.label,
      operatorName: operator.name,
      operatorRole: operator.roleLabel,
      target: target,
      summary: spec.summary.replaceAll('{target}', target),
      ip: '${faker.random.pick(_testNets)}.${faker.random.int(min: 1, max: 254)}',
      at: faker.date.between(
        faker.now.subtract(Duration(days: days)),
        faker.now,
        utc: faker.now.isUtc,
      ),
    );
  }

  /// Generates [count] changed rows of a claim master of [kind] (`fee`,
  /// `drug`, `material`, `diagnosis`). Codes use an `EX-` prefix to mark
  /// them as examples; updated prices move by -5% to +8%.
  List<CoFakeMasterChange> masterChanges({String kind = 'fee', int count = 5}) {
    final rows = ops.masterRows[kind];
    if (rows == null || rows.isEmpty) throw ArgumentError.value(kind, 'kind');
    final prefix = switch (kind) {
      'drug' => 'D',
      'material' => 'M',
      'diagnosis' => 'X',
      _ => 'F',
    };
    return <CoFakeMasterChange>[
      for (var i = 0; i < count; i++)
        _masterChange(kind, prefix, rows[i % rows.length], i),
    ];
  }

  CoFakeMasterChange _masterChange(
    String kind,
    String prefix,
    CoMasterRowSpec row,
    int index,
  ) {
    final change = _weighted<String>(const <(String, int)>[
      ('updated', 70),
      ('added', 20),
      ('removed', 10),
    ]);
    final base = row.price;
    final moved = base == null
        ? null
        : (base * (1 + faker.random.int(min: -5, max: 8) / 100)).round();
    return (
      kind: kind,
      code: 'EX-$prefix${faker.random.digits('####')}',
      name: row.name,
      change: change,
      changeLabel: label(change),
      oldPrice: change == 'added' ? null : base,
      newPrice: change == 'removed' ? null : (change == 'added' ? base : moved),
    );
  }

  /// Generates the validation checks of a claim master upload. About one
  /// check in eight fails with a detail message unless [allPass].
  List<CoFakeMasterCheck> masterChecks({bool allPass = false}) {
    return <CoFakeMasterCheck>[
      for (final entry in ops.masterChecks.entries)
        _masterCheck(entry.key, entry.value, allPass),
    ];
  }

  CoFakeMasterCheck _masterCheck(String code, String label, bool allPass) {
    final passed = allPass || faker.random.double() >= 0.125;
    return (
      code: code,
      label: label,
      passed: passed,
      detail: passed ? null : '${faker.random.int(min: 1, max: 12)} rows',
    );
  }

  /// Generates a health snapshot per integration service.
  ///
  /// Each service's status is fixed by the seed and the service code (a
  /// derived stream), so the same service stays down or up across calls and
  /// regardless of other generated values; [at] defaults to `faker.now`.
  List<CoFakeIntegrationSnapshot> integrationSnapshot({DateTime? at}) {
    final time = at ?? faker.now;
    return <CoFakeIntegrationSnapshot>[
      for (final service in services) _snapshot(service, time),
    ];
  }

  CoFakeIntegrationSnapshot _snapshot(String service, DateTime at) {
    final f = faker.derive('saas/health/$service');
    final roll = f.random.int(max: 99);
    final status = roll < 80 ? 'up' : (roll < 93 ? 'degraded' : 'down');
    final rate = switch (status) {
      'up' => f.random.double(min: 99, max: 100),
      'degraded' => f.random.double(min: 92, max: 99),
      _ => f.random.double(min: 40, max: 85),
    };
    return (
      service: service,
      serviceLabel: label(service),
      status: status,
      statusLabel: label(status),
      successRate: double.parse(rate.toStringAsFixed(2)),
      calls24h: f.random.int(min: 800, max: 60000),
      avgLatencyMs: switch (status) {
        'up' => f.random.int(min: 60, max: 400),
        'degraded' => f.random.int(min: 1200, max: 4000),
        _ => f.random.int(min: 5000, max: 30000),
      },
      lastIncidentAt: status == 'up' && f.random.bool()
          ? null
          : at.subtract(Duration(minutes: f.random.int(min: 5, max: 20000))),
    );
  }

  /// Generates [count] incidents and maintenance windows within the last
  /// [days] days, newest first. Only the newest may still be open.
  List<CoFakeIncident> incidents({int count = 5, int days = 30}) {
    final items = <CoFakeIncident>[];
    for (var i = 0; i < count; i++) {
      final service = faker.random.pick(services);
      final kind = _weighted<String>(const <(String, int)>[
        ('degraded', 45),
        ('maintenance', 35),
        ('outage', 20),
      ]);
      final startedAt = faker.date.between(
        faker.now.subtract(Duration(days: days)),
        faker.now.subtract(const Duration(hours: 1)),
        utc: faker.now.isUtc,
      );
      items.add((
        service: service,
        kind: kind,
        kindLabel: label(kind),
        title: (ops.incidentTitles[kind] ?? '{service}').replaceAll(
          '{service}',
          label(service),
        ),
        startedAt: startedAt,
        endedAt: startedAt.add(
          Duration(minutes: faker.random.int(min: 5, max: 240)),
        ),
        resolved: true,
      ));
    }
    items.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    if (items.isNotEmpty && faker.random.double() < 0.3) {
      final open = items.first;
      items[0] = (
        service: open.service,
        kind: open.kind,
        kindLabel: open.kindLabel,
        title: open.title,
        startedAt: open.startedAt,
        endedAt: null,
        resolved: false,
      );
    }
    return items;
  }

  /// Generates an operations alert raised within the last day.
  CoFakeOpsAlert opsAlert({String? level}) {
    final pool = level == null
        ? ops.alerts
        : ops.alerts.where((a) => a.level == level).toList();
    if (pool.isEmpty) throw ArgumentError.value(level, 'level');
    final spec = faker.random.pick(pool);
    return (
      level: spec.level,
      levelLabel: label(spec.level),
      code: spec.code,
      message: spec.message,
      at: faker.now.subtract(Duration(minutes: faker.random.int(max: 1439))),
    );
  }

  /// Generates an announcement: an EMR release note (`release`) or a
  /// regulatory update (`regulation`), with its audience, delivery
  /// channels, and read rate.
  CoFakeAnnouncement announcement({String? kind}) {
    final resolved =
        kind ?? (faker.random.double() < 0.6 ? 'release' : 'regulation');
    final publishedAt = _past(60);
    final pool = resolved == 'regulation'
        ? ops.regulationItems
        : ops.releaseItems;
    final items = [...pool];
    final picked = <String>[
      for (var i = 0; i < 2 + faker.random.int(max: 1) && items.isNotEmpty; i++)
        items.removeAt(faker.random.int(max: items.length - 1)),
    ];
    final title = resolved == 'regulation'
        ? ops.regulationTitle.replaceAll(
            '{month}',
            '${publishedAt.year}-${_two(publishedAt.month)}',
          )
        : ops.releaseTitle.replaceAll(
            '{version}',
            'v${publishedAt.year}.${_two(publishedAt.month)}.'
                '${faker.random.int(min: 1, max: 4)}',
          );
    final audience = _weighted<String>(const <(String, int)>[
      ('allTenants', 70),
      ('proAndAbove', 15),
      ('dermatology', 15),
    ]);
    return (
      kind: resolved,
      kindLabel: label(resolved),
      title: title,
      items: picked,
      audience: audience,
      audienceLabel: label(audience),
      channels: <String>[
        'inApp',
        if (faker.random.double() < 0.6) 'email',
        if (resolved == 'regulation' || faker.random.double() < 0.3) 'alimtalk',
      ],
      readRate: double.parse(
        faker.random.double(min: 0.2, max: 0.95).toStringAsFixed(2),
      ),
      publishedAt: publishedAt,
    );
  }

  /// Generates a recent activity line of a tenant within the last day.
  CoFakeTenantActivity tenantActivity({String? tenant}) {
    return (
      tenant: tenant ?? faker.clinic.clinicName(),
      text: faker.random
          .pick(ops.tenantActivities)
          .replaceAll('{n}', '${faker.random.int(min: 1, max: 240)}'),
      at: faker.now.subtract(Duration(minutes: faker.random.int(max: 1439))),
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

  /// Generates a notification template with its review status. [code]
  /// picks a specific template (`QUESTIONNAIRE`, `SURVEY`, `AD_EVENT`, ...).
  ///
  /// Advertising templates (codes starting with `AD_`) are always rejected
  /// with [CoFakeMessageTemplate.rejectReason], as notification channels do
  /// not allow advertising.
  CoFakeMessageTemplate messageTemplate({String? code}) {
    final pool = code == null
        ? data.messageTemplates
        : data.messageTemplates.where((t) => t.code == code).toList();
    if (pool.isEmpty) throw ArgumentError.value(code, 'code');
    final spec = faker.random.pick(pool);
    final status = _weighted(const <(String, int)>[
      ('approved', 80),
      ('reviewing', 15),
      ('rejected', 5),
    ]);
    final advertising = spec.code.startsWith('AD_');
    final resolved = advertising ? 'rejected' : status;
    return (
      code: spec.code,
      name: spec.name,
      body: spec.body,
      channel: 'alimtalk',
      status: resolved,
      statusLabel: label(resolved),
      advertising: advertising,
      rejectReason: resolved == 'rejected' ? ops.templateRejectReason : null,
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

  /// Generates a KPI series ending at `faker.now` (inclusive).
  ///
  /// With the default [granularity] of [CoTimeGranularity.day] there are
  /// [days] daily points and a weekly pattern of relative amplitude [weekly]
  /// (weekends lower). [CoTimeGranularity.hour] gives [count] (default 24)
  /// hourly points shaped by clinic hours (near zero at night, peaks late
  /// morning and afternoon); [CoTimeGranularity.month] gives [count]
  /// (default 12) monthly points with a mild winter peak. Values start
  /// around [base], move by [trend] per point, and get relative noise up to
  /// [noise]. [integer] rounds values; negatives are clamped to zero.
  List<CoFakePoint> timeSeries({
    int days = 30,
    num base = 100,
    num trend = 0,
    double weekly = 0.2,
    double noise = 0.1,
    bool integer = true,
    CoTimeGranularity granularity = CoTimeGranularity.day,
    int? count,
  }) {
    final total =
        count ??
        switch (granularity) {
          CoTimeGranularity.hour => 24,
          CoTimeGranularity.day => days,
          CoTimeGranularity.month => 12,
        };
    if (total < 0) {
      throw ArgumentError.value(total, 'count', 'must not be negative');
    }
    return <CoFakePoint>[
      for (var i = 0; i < total; i++)
        _point(
          _bucket(granularity, total - 1 - i),
          i,
          base,
          trend,
          weekly,
          noise,
          integer,
          granularity,
        ),
    ];
  }

  DateTime _bucket(CoTimeGranularity granularity, int back) {
    final now = faker.now;
    return switch (granularity) {
      CoTimeGranularity.hour =>
        (now.isUtc
                ? DateTime.utc(now.year, now.month, now.day, now.hour)
                : DateTime(now.year, now.month, now.day, now.hour))
            .subtract(Duration(hours: back)),
      CoTimeGranularity.day => _day(now).subtract(Duration(days: back)),
      CoTimeGranularity.month => _addMonths(_monthStart(now), -back),
    };
  }

  CoFakePoint _point(
    DateTime date,
    int i,
    num base,
    num trend,
    double weekly,
    double noise,
    bool integer,
    CoTimeGranularity granularity,
  ) {
    final level = base + trend * i;
    final double season;
    switch (granularity) {
      case CoTimeGranularity.day:
        final weekday = date.weekday;
        season = weekday == DateTime.sunday
            ? -weekly
            : (weekday == DateTime.saturday ? -weekly / 2 : weekly / 5);
      case CoTimeGranularity.hour:
        season = _hourShape[date.hour] - 1;
      case CoTimeGranularity.month:
        season = const <double>[
          0.15, 0.1, 0, -0.05, -0.1, -0.15, //
          -0.15, -0.1, -0.05, 0, 0.1, 0.15,
        ][date.month - 1];
    }
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

  /// Relative load per hour of day for a clinic open 10:00-19:00.
  static const List<double> _hourShape = <double>[
    0.02, 0.02, 0.02, 0.02, 0.02, 0.02, 0.03, 0.05, 0.2, 0.6, //
    1.3, 1.6, 1.4, 0.7, 1.4, 1.7, 1.8, 1.5, 1.2, 0.4, //
    0.15, 0.08, 0.04, 0.03,
  ];

  static const List<String> _testNets = <String>[
    '192.0.2',
    '198.51.100',
    '203.0.113',
  ];

  static int _roundTo(int value, int unit) => (value / unit).round() * unit;

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

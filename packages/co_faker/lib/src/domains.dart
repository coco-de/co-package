import 'clinic.dart';
import 'domain.dart';
import 'domain_packs/co_fx_domain.dart';
import 'domain_packs/co_remit_domain.dart';
import 'domain_packs/co_vet_domain.dart';
import 'domain_packs/co_commerce_domain.dart';
import 'domain_packs/co_grocery_domain.dart';
import 'domain_packs/co_booking_domain.dart';
import 'domain_packs/co_dental_domain.dart';
import 'domain_packs/co_homecare_domain.dart';
import 'domain_packs/co_travel_wallet_domain.dart';
import 'domain_packs/co_b2b_trade_domain.dart';
import 'domain_packs/co_group_deal_domain.dart';
import 'domain_packs/co_fitness_domain.dart';
import 'domain_packs/co_space_rental_domain.dart';
import 'domain_packs/co_dining_domain.dart';
import 'domain_packs/co_daycare_domain.dart';
import 'domain_packs/co_exam_prep_domain.dart';
import 'domain_packs/co_hrd_domain.dart';
import 'domain_packs/co_neighborhood_domain.dart';
import 'domain_packs/co_meetup_domain.dart';
import 'domain_packs/co_fandom_domain.dart';
import 'domain_packs/co_content_domain.dart';
import 'domain_packs/co_helpdesk_domain.dart';
import 'domain_packs/co_campaign_domain.dart';
import 'domain_packs/co_workplace_domain.dart';
import 'domain_packs/co_brokerage_domain.dart';
import 'domain_packs/co_logistics_domain.dart';
import 'domain_packs/co_hospitality_domain.dart';
import 'korea.dart';
import 'saas.dart';

/// Built-in domain packs. Register them with
/// `CoFaker(domains: CoFakerDomains.all)` or pick the ones you need.
abstract final class CoFakerDomains {
  /// Korean identity: phones, resident and business numbers, road
  /// addresses, birth dates.
  static const CoFakerDomain korea = CoKoreaDomain();

  /// Clinic and EMR: patients, staff, reservations, visits, fee items,
  /// diagnoses, payments, rooms.
  static const CoFakerDomain clinic = CoClinicDomain();

  /// SaaS back office: tenants, subscriptions, invoices, message logs, audit
  /// events, operators.
  static const CoFakerDomain saas = CoSaasDomain();

  /// Fictional currency quotes and pickup labels.
  static const CoFakerDomain fx = CoFxDomain();

  /// Masked recipients and remittance corridors.
  static const CoFakerDomain remit = CoRemitDomain();

  /// Veterinary profiles and unbranded example medicine labels.
  static const CoFakerDomain vet = CoVetDomain();

  /// Brand-free common catalog/order values.
  static const CoFakerDomain commerce = CoCommerceDomain();

  /// Fresh grocery catalog and picker labels.
  static const CoFakerDomain grocery = CoGroceryDomain();

  /// UTC booking blocks and common booking labels.
  static const CoFakerDomain booking = CoBookingDomain();

  /// Dental procedure and valid FDI-tooth examples.
  static const CoFakerDomain dental = CoDentalDomain();

  /// Masked home-care recipients and illustrative vitals.
  static const CoFakerDomain homecare = CoHomecareDomain();

  /// Fictional merchants, budgets and masked travel cards.
  static const CoFakerDomain travelWallet = CoTravelWalletDomain();

  /// Fictional wholesale buyers and package specifications.
  static const CoFakerDomain b2bTrade = CoB2bTradeDomain();

  /// Generic group deals and example benefits.
  static const CoFakerDomain groupDeal = CoGroupDealDomain();

  /// Fitness classes and pass labels.
  static const CoFakerDomain fitness = CoFitnessDomain();

  /// Fictional rental spaces and host messages.
  static const CoFakerDomain spaceRental = CoSpaceRentalDomain();

  /// Fictional restaurant and queue labels.
  static const CoFakerDomain dining = CoDiningDomain();

  /// Daycare given names and unbranded fictional drug labels.
  static const CoFakerDomain daycare = CoDaycareDomain();

  /// Authored IT questions and coherent answer adapters.
  static const CoFakerDomain examPrep = CoExamPrepDomain();

  /// Fictional corporate training and certificate labels.
  static const CoFakerDomain hrd = CoHrdDomain();

  /// Fictional neighborhood text and place labels.
  static const CoFakerDomain neighborhood = CoNeighborhoodDomain();

  /// Fictional clubs, gatherings and dues.
  static const CoFakerDomain meetup = CoMeetupDomain();

  /// The two approved fictional creators and fan text.
  static const CoFakerDomain fandom = CoFandomDomain();

  /// Original fictional works and prose.
  static const CoFakerDomain content = CoContentDomain();

  /// Authored support tickets and simulated AI drafts.
  static const CoFakerDomain helpdesk = CoHelpdeskDomain();

  /// Fictional campaign copy and recipe-aligned delivery codes.
  static const CoFakerDomain campaign = CoCampaignDomain();

  /// Shared HR, project and expense labels.
  static const CoFakerDomain workplace = CoWorkplaceDomain();

  /// Fictional providers and general-information-only consultations.
  static const CoFakerDomain brokerage = CoBrokerageDomain();

  /// Last-mile, freight and WMS labels.
  static const CoFakerDomain logistics = CoLogisticsDomain();

  /// Stay, housekeeping and concierge labels.
  static const CoFakerDomain hospitality = CoHospitalityDomain();

  /// All packs, preserving the original clinic, saas, korea precedence.
  static const List<CoFakerDomain> all = <CoFakerDomain>[
    clinic,
    saas,
    korea,
    fx,
    remit,
    vet,
    commerce,
    grocery,
    booking,
    dental,
    homecare,
    travelWallet,
    b2bTrade,
    groupDeal,
    fitness,
    spaceRental,
    dining,
    daycare,
    examPrep,
    hrd,
    neighborhood,
    meetup,
    fandom,
    content,
    helpdesk,
    campaign,
    workplace,
    brokerage,
    logistics,
    hospitality,
  ];

  /// Resolves a registered built-in pack by its snake_case name.
  static CoFakerDomain byName(String name) => all.firstWhere(
    (pack) => pack.name == name,
    orElse: () =>
        throw ArgumentError.value(name, 'name', 'unknown domain pack'),
  );
}

String _dateString(DateTime value) => value.toIso8601String().substring(0, 10);

/// Korean identity domain pack (`korea.*` roles).
class CoKoreaDomain extends CoFakerDomain {
  /// Creates the pack.
  const CoKoreaDomain();

  @override
  String get name => 'korea';

  @override
  Map<String, CoDomainRole> get roles => <String, CoDomainRole>{
    'landline': CoDomainRole(
      (f, _) => f.korea.landlinePhone(),
      description: 'Unassignable landline (02-0##-####)',
      fieldPatterns: const [
        'landline',
        'clinicphone',
        'officephone',
        'tenantphone',
        'telno',
        'faxnumber',
      ],
    ),
    'mobilePhone': CoDomainRole(
      (f, _) => f.korea.mobilePhone(),
      description: 'Unassignable mobile (010-0###-####)',
      fieldPatterns: const ['phone', 'mobile', 'cellphone', '=tel'],
    ),
    'rrn': CoDomainRole(
      (f, _) => f.korea.rrn(),
      description: 'Masked fake resident number (YYMMDD-G******)',
      fieldPatterns: const ['rrn', 'rrnmasked', 'residentnumber'],
    ),
    'businessNumber': CoDomainRole(
      (f, _) => f.korea.businessNumber(),
      description: 'Checksum-failing business number (###-##-#####)',
      fieldPatterns: const ['businessnumber', 'bizno', 'brn'],
    ),
    'address1': CoDomainRole(
      (f, _) => f.korea.roadAddress().line1,
      description: 'Road-name address line',
      fieldPatterns: const ['=address', 'address1', 'roadaddress'],
    ),
    'address2': CoDomainRole(
      (f, _) => f.korea.roadAddress().detail,
      description: 'Address detail (동·호, 층)',
      fieldPatterns: const ['address2', 'addressdetail', 'detailaddress'],
    ),
    'postalCode': CoDomainRole(
      (f, _) => f.korea.roadAddress().postalCode,
      description: 'Five-digit postal code in a real province range',
      fieldPatterns: const ['zipcode', 'postalcode', '=zip'],
    ),
    'birthDate': CoDomainRole(
      (f, c) {
        final date = f.korea.birthDate();
        return c.type.startsWith('String') ? _dateString(date) : date;
      },
      description: 'Birth date (YYYY-MM-DD for String fields)',
      fieldPatterns: const ['birthdate', 'dateofbirth', 'dob', 'birthday'],
    ),
  };
}

/// Clinic and EMR domain pack (`clinic.*` roles).
class CoClinicDomain extends CoFakerDomain {
  /// Creates the pack.
  const CoClinicDomain();

  @override
  String get name => 'clinic';

  @override
  Map<String, CoDomainRole> get roles => <String, CoDomainRole>{
    'chartNo': CoDomainRole(
      (f, c) => c.type.startsWith('int')
          ? c.index + 1
          : f.clinic.chartNumber(c.index + 1),
      description: 'Chart number (index + 1)',
      fieldPatterns: const ['chartno', 'chartnumber'],
    ),
    'clinicName': CoDomainRole(
      (f, _) => f.clinic.clinicName(),
      description: 'Clinic name (맑은피부과의원)',
      fieldPatterns: const ['clinicname', 'hospitalname', 'clinic.name'],
    ),
    'patientName': CoDomainRole(
      (f, _) => f.person.fullName(),
      description: 'Person name',
      fieldPatterns: const [
        'patientname',
        'guestname',
        'bookername',
        'guardianname',
        'patient.name',
      ],
    ),
    'staffRole': CoDomainRole(
      (f, _) => f.clinic.staffRole().code,
      description: 'Staff role code (director, nurse, ...)',
      fieldPatterns: const ['staffrole', 'staff.role'],
    ),
    'visitPurpose': CoDomainRole(
      (f, _) => f.clinic.visitPurpose().purpose,
      description: 'Visit purpose (상담·시술·진료·관리)',
      fieldPatterns: const ['visitpurpose', 'purpose'],
    ),
    'procedureCode': CoDomainRole(
      (f, _) => f.clinic.procedure().code,
      description: 'Fee item code from the catalog',
      fieldPatterns: const [
        'procedurecode',
        'feecode',
        'feeitemcode',
        'procedure.code',
        'feeitem.code',
      ],
    ),
    'procedureName': CoDomainRole(
      (f, _) => f.clinic.procedure().name,
      description: 'Procedure or product name',
      fieldPatterns: const [
        'procedurename',
        'feeitemname',
        'treatmentname',
        'procedure.name',
        'feeitem.name',
      ],
    ),
    'procedurePrice': CoDomainRole(
      (f, _) => f.clinic.procedure().price,
      description: 'Price within a catalog band',
      fieldPatterns: const ['unitprice', 'procedure.price', 'feeitem.price'],
    ),
    'diagnosisCode': CoDomainRole(
      (f, _) => f.clinic.diagnosis().code,
      description: 'Illustrative ICD-10/KCD code',
      fieldPatterns: const [
        'diagnosiscode',
        'kcdcode',
        'dxcode',
        '=kcd',
        'diagnosis.code',
      ],
    ),
    'diagnosisName': CoDomainRole(
      (f, _) => f.clinic.diagnosis().name,
      description: 'Diagnosis name',
      fieldPatterns: const ['diagnosisname', 'diagnosis.name'],
    ),
    'drugName': CoDomainRole(
      (f, _) => f.clinic.drugName(),
      description: 'Fictional drug name',
      fieldPatterns: const ['drugname', 'medicationname', 'medicine'],
    ),
    'insurance': CoDomainRole(
      (f, _) => f.clinic.insuranceType().code,
      description: 'Insurance code (nhis, medicalAid1, ...)',
      fieldPatterns: const ['insurance', 'insurancetype'],
    ),
    'chartMemo': CoDomainRole(
      (f, _) => f.clinic.chartMemo(),
      description: 'Chart memo sentence',
      fieldPatterns: const ['chartmemo', 'clinicalnote', 'chartnote'],
    ),
    'specialNote': CoDomainRole(
      (f, _) => f.clinic.specialNote(),
      description: 'Allergy or caution note',
      fieldPatterns: const ['specialnote', 'allergy', 'caution'],
    ),
    'reservationStatus': CoDomainRole(
      (f, _) => f.clinic.reservationStatus(),
      description: 'Reservation status code',
      fieldPatterns: const ['reservationstatus', 'reservation.status'],
    ),
    'visitStage': CoDomainRole(
      (f, _) => f.clinic.visitStage(),
      description: 'Visit stage code (waiting, procedure, ...)',
      fieldPatterns: const ['visitstage', 'queuestage'],
    ),
    'payMethod': CoDomainRole(
      (f, _) => f.clinic.payment(amount: 10000).method,
      description: 'Payment method code (card, cash, ...)',
      fieldPatterns: const ['paymethod', 'paymentmethod', 'payment.method'],
    ),
    'cardIssuer': CoDomainRole(
      (f, _) => f.random.pick(f.clinic.data.cardIssuers),
      description: 'Card issuer name',
      fieldPatterns: const ['cardissuer'],
    ),
    'approvalNo': CoDomainRole(
      (f, _) => f.korea.cardApprovalNumber(),
      description: 'Card approval number (8 digits)',
      fieldPatterns: const ['approvalno', 'approvalnumber'],
    ),
    'roomName': CoDomainRole(
      (f, _) => f.random.pick(f.clinic.ops.rooms).name,
      description: 'Room name',
      fieldPatterns: const ['roomname', 'room.name'],
    ),
    'roomKind': CoDomainRole(
      (f, _) => f.random.pick(f.clinic.ops.rooms).kind,
      description: 'Room kind code',
      fieldPatterns: const ['roomkind', 'room.kind'],
    ),
    'tagName': CoDomainRole(
      (f, _) => f.clinic.patientTag().label,
      description: 'Patient tag label',
      fieldPatterns: const ['tagname', 'patienttag', 'tag.name'],
    ),
    'channelName': CoDomainRole(
      (f, _) => f.clinic.acquisitionChannel().label,
      description: 'Acquisition channel label',
      fieldPatterns: const ['acquisitionchannel', 'channel.name'],
    ),
    'consentKind': CoDomainRole(
      (f, _) => f.random.pick(CoFakerClinic.consentHistoryKinds),
      description: 'Consent kind code',
      fieldPatterns: const ['consentkind', 'consent.kind'],
    ),
  };

  @override
  Map<String, Map<String, String>> get entities =>
      const <String, Map<String, String>>{
        'patient': <String, String>{
          'id': 'int',
          'chartNo': 'String',
          'name': 'String',
          'sex': 'String',
          'birthDate': 'String',
          'rrnMasked': 'String',
          'phone': 'String',
          'email': 'String?',
          'zipCode': 'String',
          'address1': 'String',
          'address2': 'String',
          'insurance': 'String',
          'specialNote': 'String?',
          'createdAt': 'DateTime',
        },
        'staff': <String, String>{
          'id': 'int',
          'name': 'String',
          'staffRole': 'String',
          'email': 'String',
          'phone': 'String',
          'color': 'String',
        },
        'reservation': <String, String>{
          'id': 'int',
          'patientId': 'int',
          'startsAt': 'DateTime',
          'status': 'String',
          'visitPurpose': 'String',
          'memo': 'String?',
        },
        'visit': <String, String>{
          'id': 'int',
          'patientId': 'int',
          'status': 'String',
          'visitStage': 'String',
          'checkedInAt': 'DateTime',
        },
        'feeItem': <String, String>{
          'code': 'String',
          'name': 'String',
          'price': 'int',
          'taxable': 'bool',
        },
        'diagnosis': <String, String>{'code': 'String', 'name': 'String'},
        'payment': <String, String>{
          'id': 'int',
          'invoiceId': 'int',
          'method': 'String',
          'amount': 'int',
          'cardIssuer': 'String?',
          'approvalNo': 'String?',
        },
        'room': <String, String>{
          'id': 'int',
          'name': 'String',
          'kind': 'String',
        },
      };

  @override
  Map<String, Map<String, String>> get entityRoles =>
      const <String, Map<String, String>>{
        'patient': <String, String>{'name': 'patientName'},
        'feeItem': <String, String>{
          'code': 'procedureCode',
          'name': 'procedureName',
          'price': 'procedurePrice',
        },
        'diagnosis': <String, String>{
          'code': 'diagnosisCode',
          'name': 'diagnosisName',
        },
        'payment': <String, String>{'method': 'payMethod'},
        'room': <String, String>{'name': 'roomName', 'kind': 'roomKind'},
        'reservation': <String, String>{'status': 'reservationStatus'},
      };

  @override
  Map<String, Map<String, List<String>>> get enums =>
      const <String, Map<String, List<String>>>{
        'patient': <String, List<String>>{
          'sex': <String>['female', 'male'],
        },
        'visit': <String, List<String>>{
          'status': <String>['active', 'completed', 'cancelled'],
        },
      };
}

/// SaaS back-office domain pack (`saas.*` roles).
class CoSaasDomain extends CoFakerDomain {
  /// Creates the pack.
  const CoSaasDomain();

  @override
  String get name => 'saas';

  @override
  Map<String, CoDomainRole> get roles => <String, CoDomainRole>{
    'tenantCode': CoDomainRole(
      (f, _) => f.saas.tenant().code,
      description: 'Tenant code (CLN-XXXXXX)',
      fieldPatterns: const ['tenantcode', 'tenant.code'],
    ),
    'tenantName': CoDomainRole(
      (f, _) => f.clinic.clinicName(),
      description: 'Tenant (clinic) name',
      fieldPatterns: const ['tenantname', 'tenant.name'],
    ),
    'planCode': CoDomainRole(
      (f, _) => f.saas.plan().code,
      description: 'Plan code (starter, pro, ...)',
      fieldPatterns: const ['plancode', 'plan.code'],
    ),
    'planName': CoDomainRole(
      (f, _) => f.saas.plan().name,
      description: 'Plan name',
      fieldPatterns: const ['planname', 'plan.name'],
    ),
    'subscriptionStatus': CoDomainRole(
      (f, _) => f.saas.subscriptionStatus(),
      description: 'Subscription status code',
      fieldPatterns: const [
        'subscriptionstatus',
        'subscription.status',
        'tenant.status',
      ],
    ),
    'invoiceNumber': CoDomainRole(
      (f, c) => f.saas
          .invoice(
            numberFormat: CoInvoiceNumberFormat.monthly,
            sequence: c.index + 1,
          )
          .number,
      description: 'Invoice number (INV-YYYY-MM-NNNN)',
      fieldPatterns: const ['invoicenumber', 'invoiceno', 'invoice.number'],
    ),
    'invoiceStatus': CoDomainRole(
      (f, _) => f.saas.invoice().status,
      description: 'Invoice status code',
      fieldPatterns: const ['invoicestatus', 'invoice.status'],
    ),
    'messageChannel': CoDomainRole(
      (f, _) => f.saas.messageLog().channel,
      description: 'Message channel (alimtalk, sms, lms)',
      fieldPatterns: const ['messagechannel', 'messagelog.channel'],
    ),
    'messageStatus': CoDomainRole(
      (f, _) => f.saas.messageLog().status,
      description: 'Delivery status code',
      fieldPatterns: const ['messagestatus', 'messagelog.status'],
    ),
    'recipient': CoDomainRole(
      (f, _) => CoFakerKorea.maskPhone(f.korea.mobilePhone()),
      description: 'Masked recipient phone',
      fieldPatterns: const ['recipient', 'recipientphone'],
    ),
    'templateCode': CoDomainRole(
      (f, _) => f.saas.messageTemplate().code,
      description: 'Notification template code',
      fieldPatterns: const ['templatecode'],
    ),
    'auditAction': CoDomainRole(
      (f, _) => f.saas.auditEvent().action,
      description: 'Audit action code',
      fieldPatterns: const ['auditaction', 'auditevent.action'],
    ),
    'operatorAction': CoDomainRole(
      (f, _) => f.random.pick(f.saas.operatorActions),
      description: 'Console action key (tenant.approve, ...)',
      fieldPatterns: const ['operatorevent.action', 'operatoraction'],
    ),
    'operatorRole': CoDomainRole(
      (f, _) => f.random.pick(f.saas.operatorRoles),
      description: 'Operator role code',
      fieldPatterns: const ['operatorrole', 'operator.role'],
    ),
    'serviceCode': CoDomainRole(
      (f, _) => f.random.pick(CoFakerSaas.services),
      description: 'Integration service code',
      fieldPatterns: const ['servicecode', 'healthcheck.service'],
    ),
    'healthStatus': CoDomainRole(
      (f, _) => f.saas.healthCheck().status,
      description: 'Health status (up, degraded, down)',
      fieldPatterns: const ['healthstatus', 'healthcheck.status'],
    ),
    'ipAddress': CoDomainRole(
      (f, _) =>
          '${f.random.pick(const ['192.0.2', '198.51.100', '203.0.113'])}'
          '.${f.random.int(min: 1, max: 254)}',
      description: 'RFC 5737 documentation IP',
      fieldPatterns: const ['ipaddress', '=ip'],
    ),
  };

  @override
  Map<String, Map<String, String>> get entities =>
      const <String, Map<String, String>>{
        'tenant': <String, String>{
          'code': 'String',
          'name': 'String',
          'businessNumber': 'String',
          'clinicPhone': 'String',
          'planCode': 'String',
          'status': 'String',
          'createdAt': 'DateTime',
        },
        'subscription': <String, String>{
          'id': 'int',
          'tenantCode': 'String',
          'planCode': 'String',
          'status': 'String',
          'currentPeriodEnd': 'DateTime',
        },
        'invoice': <String, String>{
          'number': 'String',
          'tenantCode': 'String',
          'total': 'int',
          'status': 'String',
          'dueAt': 'DateTime',
        },
        'messageLog': <String, String>{
          'id': 'String',
          'channel': 'String',
          'status': 'String',
          'recipient': 'String',
          'templateCode': 'String?',
          'sentAt': 'DateTime?',
        },
        'auditEvent': <String, String>{
          'id': 'String',
          'action': 'String',
          'actorName': 'String',
          'ipAddress': 'String',
          'createdAt': 'DateTime',
        },
        'operator': <String, String>{
          'name': 'String',
          'email': 'String',
          'role': 'String',
          'status': 'String',
        },
      };

  @override
  Map<String, Map<String, String>> get entityRoles =>
      const <String, Map<String, String>>{
        'tenant': <String, String>{'code': 'tenantCode', 'name': 'tenantName'},
        'invoice': <String, String>{'number': 'invoiceNumber'},
      };

  @override
  Map<String, Map<String, List<String>>> get enums =>
      const <String, Map<String, List<String>>>{
        'operator': <String, List<String>>{
          'status': <String>['active', 'invited', 'suspended'],
        },
      };
}

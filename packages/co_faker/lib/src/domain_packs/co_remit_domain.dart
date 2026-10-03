import '../co_faker.dart';
import '../domain.dart';
import 'authored_roles.dart';
import 'co_fake_remit_recipient.dart';
import 'co_fake_remittance.dart';
import 'co_faker_remit.dart';

/// Fictional remittance corridors, recipients, purposes and document labels.
class CoRemitDomain extends CoFakerDomain {
  /// Creates this pack; register fx for the shared reference role.
  const CoRemitDomain();
  @override
  String get name => 'remit';

  static CoFakeRemitRecipient _recipient(CoFaker f, CoDomainRoleContext c) =>
      CoFakerRemit(f.derive('remit/recipient')).recipient(
        index: c.index,
        countryCode: CoFakerRemit
            .countryCodes[c.index % CoFakerRemit.countryCodes.length],
        payoutMethod: CoFakerRemit.payoutMethods[c.index % 3],
      );

  static CoFakeRemittance _transfer(CoFaker f, CoDomainRoleContext c) =>
      CoFakerRemit(
        f.derive('remit/transfer'),
      ).transfer(index: c.index, recipient: _recipient(f, c));

  @override
  Map<String, CoDomainRole> get roles => {
    'corridorCountry': authoredRole(
      (f, c) => _recipient(f, c).countryName,
      coherent: true,
    ),
    'payoutMethod': authoredRole(
      (f, c) => _recipient(f, c).payoutMethod,
      coherent: true,
    ),
    'bankNameFictional': authoredRole(
      (f, c) => _recipient(f, c).bankName,
      coherent: true,
    ),
    'romanizedNameMasked': authoredRole(
      (f, c) => _recipient(f, c).name,
      coherent: true,
    ),
    'transferPurpose': enumRole(CoFakerRemit.purposes),
    'fundSource': enumRole(CoFakerRemit.fundSources),
    'docKind': enumRole([
      'tuition_invoice',
      'family_relation',
      'employment_proof',
      'medical_bill',
      'other',
    ]),
    'flagRule': textRole(
      ['1건 고액(데모 기준)', '추가 서류 확인(데모 기준)', '반복 요청 확인(데모 기준)'],
      [
        'Large transfer (demo rule)',
        'Additional document check (demo rule)',
        'Repeated request check (demo rule)',
      ],
    ),
    'accountMasked': authoredRole(
      (f, c) => _recipient(f, c).accountMasked,
      coherent: true,
    ),
    'receiveCurrency': authoredRole(
      (f, c) => _recipient(f, c).currencyCode,
      coherent: true,
    ),
    'sendAmount': authoredRole(
      (f, c) => _transfer(f, c).sendAmount,
      type: 'int',
      coherent: true,
    ),
    'feeAmount': authoredRole(
      (f, c) => _transfer(f, c).feeAmount,
      type: 'int',
      coherent: true,
    ),
    'appliedRate': authoredRole(
      (f, c) => _transfer(f, c).appliedRate,
      type: 'double',
      coherent: true,
    ),
    'receiveAmount': authoredRole(
      (f, c) => _transfer(f, c).receiveAmount,
      type: 'double',
      coherent: true,
    ),
    'requestedAt': authoredRole(
      (f, c) => _transfer(f, c).requestedAt,
      type: 'DateTime',
      coherent: true,
    ),
    'expectedArrivalAt': authoredRole(
      (f, c) => _transfer(f, c).expectedArrivalAt,
      type: 'DateTime',
      coherent: true,
    ),
  };

  @override
  Map<String, Map<String, String>> get entities => const {
    'recipient': {
      'id': 'int',
      'name': 'String',
      'country': 'String',
      'payoutMethod': 'String',
      'bankName': 'String',
      'accountMasked': 'String',
      'receiveCurrency': 'String',
      'relationship': 'String',
    },
    'remittance': {
      'id': 'int',
      'recipientId': 'int',
      'recipientName': 'String',
      'referenceNo': 'String',
      'receiveCountry': 'String',
      'sendAmount': 'int',
      'feeAmount': 'int',
      'appliedRate': 'double',
      'receiveAmount': 'double',
      'receiveCurrency': 'String',
      'purpose': 'String',
      'fundSource': 'String',
      'requestedAt': 'DateTime',
      'expectedArrivalAt': 'DateTime',
      'status': 'String',
    },
    'supporting_document': {
      'id': 'int',
      'remittanceId': 'int',
      'docKind': 'String',
      'confirmed': 'bool',
    },
  };

  @override
  Map<String, Map<String, String>> get entityRoles => const {
    'recipient': {
      'name': 'romanizedNameMasked',
      'country': 'corridorCountry',
      'payoutMethod': 'payoutMethod',
      'bankName': 'bankNameFictional',
      'accountMasked': 'accountMasked',
      'receiveCurrency': 'receiveCurrency',
    },
    'remittance': {
      'recipientName': 'romanizedNameMasked',
      'referenceNo': 'fx.referenceNo',
      'receiveCountry': 'corridorCountry',
      'sendAmount': 'sendAmount',
      'feeAmount': 'feeAmount',
      'appliedRate': 'appliedRate',
      'receiveAmount': 'receiveAmount',
      'receiveCurrency': 'receiveCurrency',
      'purpose': 'transferPurpose',
      'fundSource': 'fundSource',
      'requestedAt': 'requestedAt',
      'expectedArrivalAt': 'expectedArrivalAt',
    },
    'supporting_document': {'docKind': 'docKind'},
  };

  @override
  Map<String, Map<String, List<String>>> get enums => const {
    'recipient': {
      'relationship': ['parent', 'spouse', 'child', 'sibling', 'self', 'other'],
    },
    'remittance': {
      'status': CoFakerRemit.statuses,
      'purpose': CoFakerRemit.purposes,
      'fundSource': CoFakerRemit.fundSources,
    },
  };
}

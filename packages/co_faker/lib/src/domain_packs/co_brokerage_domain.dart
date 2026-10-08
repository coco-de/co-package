import '../domain.dart';
import 'authored_roles.dart';

/// Fictional service providers and general-information-only consultation text.
class CoBrokerageDomain extends CoFakerDomain {
  /// Creates the three-recipe brokerage pack.
  const CoBrokerageDomain();
  @override
  String get name => 'brokerage';

  /// The roots of the service-type taxonomy: `serviceParent` points at them
  /// and `brokerage.serviceTypeName` names them.
  static const _serviceRoots = 4;
  @override
  Map<String, CoDomainRole> get roles => {
    'projectTitle': textRole('brokerage.projectTitle'),
    'serviceCategory': textRole('brokerage.serviceCategory'),
    'providerName': textRole('brokerage.providerName'),
    'providerHeadline': textRole('brokerage.providerHeadline'),
    'skillTag': textRole('brokerage.skillTag'),
    'proposalMessage': textRole('brokerage.proposalMessage'),
    'portfolioTitle': textRole('brokerage.portfolioTitle'),
    'milestoneLabel': textRole('brokerage.milestoneLabel'),
    'disputeReason': enumRole([
      'scope_change',
      'delay',
      'payment',
      'quality',
      'other',
    ]),
    'quoteAmount': intRole(50000, 60000000, step: 10000),
    'responseTime': intRole(5, 360, step: 5),
    'workMode': enumRole(['remote', 'onsite', 'hybrid']),
    'homeServiceName': textRole('brokerage.homeServiceName'),
    'requestAnswer': textRole('brokerage.requestAnswer'),
    'regionDong': textRole('brokerage.regionDong'),
    'reviewText': textRole('brokerage.reviewText'),
    'creditLabel': textRole('brokerage.creditLabel'),
    'abuseReason': enumRole([
      'overcharge',
      'no_show',
      'rude',
      'fake_profile',
      'other',
    ]),
    'advisorTitle': textRole('brokerage.advisorTitle'),
    'adviceField': enumRole([
      'vat',
      'income_tax',
      'transfer_tax',
      'inheritance',
      'lease',
      'labor',
      'family',
      'consumer',
    ]),
    'consultTopic': textRole('brokerage.consultTopic'),
    'qnaQuestion': textRole('brokerage.qnaQuestion'),
    'qnaAnswerGeneric': textRole('brokerage.qnaAnswerGeneric'),
    'consultNoteGeneric': textRole('brokerage.consultNoteGeneric'),
    'officeName': textRole('brokerage.officeName'),
    'serviceParent': parentRole(_serviceRoots),
    'serviceTypeName': taxonomyRole(
      'brokerage.serviceTypeName',
      roots: _serviceRoots,
    ),
  };
  @override
  Map<String, Map<String, String>> get entities => const {
    'service_request': {
      'id': 'int',
      'title': 'String',
      'categoryName': 'String',
      'workMode': 'String',
      'status': 'String',
    },
    'provider_profile': {
      'id': 'int',
      'name': 'String',
      'headline': 'String',
      'status': 'String',
    },
    'home_service_type': {'id': 'int', 'name': 'String', 'parentId': 'int'},
    'qna_post': {
      'id': 'int',
      'question': 'String',
      'answer': 'String',
      'fieldName': 'String',
    },
    'consult_note': {'id': 'int', 'consultationId': 'int', 'summary': 'String'},
    'consultation': {
      'id': 'int',
      'advisorId': 'int',
      'topic': 'String',
      'status': 'String',
    },
  };
  @override
  Map<String, Map<String, String>> get entityRoles => const {
    'service_request': {
      'title': 'projectTitle',
      'categoryName': 'serviceCategory',
      'workMode': 'workMode',
    },
    'provider_profile': {
      'name': 'providerName',
      'headline': 'providerHeadline',
    },
    'home_service_type': {
      'name': 'serviceTypeName',
      'parentId': 'serviceParent',
    },
    'qna_post': {
      'question': 'qnaQuestion',
      'answer': 'qnaAnswerGeneric',
      'fieldName': 'adviceField',
    },
    'consult_note': {'summary': 'consultNoteGeneric'},
    'consultation': {'topic': 'consultTopic'},
  };
  @override
  Map<String, Map<String, List<String>>> get enums => const {
    'service_request': {
      'status': ['draft', 'open', 'offered', 'matched', 'closed', 'canceled'],
    },
    'provider_profile': {
      'status': ['draft', 'published', 'hidden'],
    },
    'consultation': {
      'status': ['requested', 'confirmed', 'completed', 'canceled', 'no_show'],
    },
  };
}

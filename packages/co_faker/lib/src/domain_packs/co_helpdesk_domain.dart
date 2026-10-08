import '../domain.dart';
import 'authored_roles.dart';
import 'co_faker_helpdesk.dart';

/// Authored support ticket text for a fictional SaaS, not generic lorem.
class CoHelpdeskDomain extends CoFakerDomain {
  /// Creates this pack.
  const CoHelpdeskDomain();
  @override
  String get name => 'helpdesk';

  /// The category of each ticket; its subject and description are
  /// `helpdesk.ticketSubject` and `helpdesk.ticketDescription` in the same
  /// order.
  static const _ticketCategories = <String>[
    'account',
    'billing',
    'data_export',
    'integration',
    'bug',
    'other',
  ];
  @override
  Map<String, CoDomainRole> get roles => {
    'ticketSubject': indexedTextRole(
      'helpdesk.ticketSubject',
      rows: _ticketCategories.length,
    ),
    'ticketDescription': indexedTextRole(
      'helpdesk.ticketDescription',
      rows: _ticketCategories.length,
    ),
    'ticketCategory': authoredRole(
      (f, c) => _ticketCategories[c.index % _ticketCategories.length],
      coherent: true,
    ),
    'agentName': firstNameRole(),
    'macroName': textRole('helpdesk.macroName'),
    'helpArticleTitle': textRole('helpdesk.helpArticleTitle'),
    'csatComment': textRole('helpdesk.csatComment'),
    'aiDraftText': authoredRole(
      (f, c) => CoFakerHelpdesk(f).drafts()[c.index % 8]['templateBody'],
    ),
    'topicParent': parentRole(4),
    'topicName': taxonomyRole('helpdesk.topicName'),
  };
  @override
  Map<String, Map<String, String>> get entities => const {
    'ticket': {
      'id': 'int',
      'subject': 'String',
      'description': 'String',
      'category': 'String',
      'assigneeName': 'String',
      'priority': 'String',
      'status': 'String',
    },
    'help_topic': {'id': 'int', 'name': 'String', 'parentId': 'int'},
  };
  @override
  Map<String, Map<String, String>> get entityRoles => const {
    'ticket': {
      'subject': 'ticketSubject',
      'description': 'ticketDescription',
      'category': 'ticketCategory',
      'assigneeName': 'agentName',
    },
    'help_topic': {'name': 'topicName', 'parentId': 'topicParent'},
  };
  @override
  Map<String, Map<String, List<String>>> get enums => const {
    'ticket': {
      'priority': ['urgent', 'high', 'normal', 'low'],
      'status': ['new', 'open', 'pending', 'solved', 'closed'],
    },
  };
}

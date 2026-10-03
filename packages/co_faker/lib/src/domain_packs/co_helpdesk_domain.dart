import '../domain.dart';
import 'authored_roles.dart';
import 'co_faker_helpdesk.dart';

/// Authored support ticket text for a fictional SaaS, not generic lorem.
class CoHelpdeskDomain extends CoFakerDomain {
  /// Creates this pack.
  const CoHelpdeskDomain();
  @override
  String get name => 'helpdesk';
  static const _tickets = <(String, String, String, String, String)>[
    (
      'account',
      '팀 초대 상태를 확인하고 싶어요',
      'Please check the team invitation status',
      '응답데스크 예시 계정의 초대 상태가 대기 중으로 보여요.',
      'The fictional support account shows a pending invitation.',
    ),
    (
      'billing',
      '예시 청구서 항목 문의',
      'Question about example invoice lines',
      '가상 청구서의 항목과 기간을 확인하고 싶어요.',
      'I would like to check the lines and period of the fictional invoice.',
    ),
    (
      'data_export',
      'CSV 내보내기 예시 오류',
      'Example CSV export error',
      '예시 데이터를 CSV로 내보낼 때 오류 상태가 보여요.',
      'An error state appears when exporting the example data to CSV.',
    ),
    (
      'integration',
      '연동 상태 표시 문의',
      'Question about integration status',
      '가상 연동 상태 화면의 문구를 확인하고 싶어요.',
      'I would like to check the wording on the fictional integration status page.',
    ),
    (
      'bug',
      '예시 화면 버튼 동작 문의',
      'Question about an example screen button',
      '예시 화면에서 버튼을 누른 뒤 같은 화면이 보여요.',
      'The example screen remains the same after pressing a button.',
    ),
    (
      'other',
      '도움말 위치 문의',
      'Question about finding help',
      '응답데스크 예시 도움말을 어디서 볼 수 있나요?',
      'Where can I find the fictional support help page?',
    ),
  ];
  @override
  Map<String, CoDomainRole> get roles => {
    'ticketSubject': authoredRole(
      (f, c) =>
          localized(f, _tickets[c.index % 6].$2, _tickets[c.index % 6].$3),
      coherent: true,
    ),
    'ticketDescription': authoredRole(
      (f, c) =>
          localized(f, _tickets[c.index % 6].$4, _tickets[c.index % 6].$5),
      coherent: true,
    ),
    'ticketCategory': authoredRole(
      (f, c) => _tickets[c.index % 6].$1,
      coherent: true,
    ),
    'agentName': firstNameRole(),
    'macroName': textRole(
      ['예시 접수 확인', '추가 정보 확인', '처리 상태 안내'],
      [
        'Example receipt acknowledgement',
        'Additional information check',
        'Processing status notice',
      ],
    ),
    'helpArticleTitle': textRole(
      ['예시 계정 초대 안내', '가상 청구서 읽기', '예시 CSV 내보내기'],
      [
        'Example invitation guide',
        'Reading a fictional invoice',
        'Exporting example CSV data',
      ],
    ),
    'csatComment': textRole(
      ['설명 내용을 확인했습니다.', '예시 안내가 이해하기 쉬웠어요.', '추가로 확인할 내용이 있어요.'],
      [
        'I reviewed the explanation.',
        'The example instructions were easy to follow.',
        'I have additional details to check.',
      ],
    ),
    'aiDraftText': authoredRole(
      (f, c) => CoFakerHelpdesk(f).drafts()[c.index % 8]['templateBody'],
    ),
    'topicParent': parentRole(4),
    'topicName': taxonomyRole(
      ['계정', '청구', '데이터', '연동'],
      ['Account', 'Billing', 'Data', 'Integration'],
    ),
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

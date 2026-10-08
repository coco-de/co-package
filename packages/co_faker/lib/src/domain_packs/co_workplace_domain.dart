import '../domain.dart';
import 'authored_roles.dart';

/// Shared workplace/HR/project/expense labels, with first-name-only people.
class CoWorkplaceDomain extends CoFakerDomain {
  /// Creates this pack.
  const CoWorkplaceDomain();
  @override
  String get name => 'workplace';
  @override
  Map<String, CoDomainRole> get roles => {
    'employeeName': firstNameRole(),
    'department': textRole('workplace.department'),
    'position': textRole('workplace.position'),
    'workPlace': textRole('workplace.workPlace'),
    'shiftName': textRole('workplace.shiftName'),
    'leaveType': enumRole([
      'annual',
      'half_am',
      'half_pm',
      'sick',
      'family_event',
      'compensatory',
    ]),
    'attendanceStatus': enumRole([
      'scheduled',
      'working',
      'finished',
      'missing',
      'corrected',
    ]),
    'approvalDecision': enumRole(['pending', 'approved', 'rejected']),
    'approvalComment': textRole('workplace.approvalComment'),
    'expenseCategory': enumRole([
      'meal',
      'transport',
      'meeting',
      'supplies',
      'travel',
      'etc',
    ]),
    'projectName': textRole('workplace.projectName'),
    'workItemTitle': textRole('workplace.workItemTitle'),
    'labelName': textRole('workplace.labelName'),
    'milestoneTitle': textRole('workplace.milestoneTitle'),
    'sprintName': authoredRole(
      (f, c) => f.l10n.format('workplace.sprintName', {'n': c.index + 1}),
    ),
    'commentBody': textRole('workplace.commentBody'),
    'merchantName': textRole('workplace.merchantName'),
    'accountCode': authoredRole(
      (f, c) => [
        'DEMO-601',
        'DEMO-602',
        'DEMO-603',
        'DEMO-604',
        'DEMO-605',
        'DEMO-606',
      ][c.index % 6],
      coherent: true,
    ),
    'accountName': indexedTextRole('workplace.accountName'),
    'rejectReasonText': textRole('workplace.rejectReasonText'),
  };
  @override
  Map<String, Map<String, String>> get entities => const {
    'employee': {
      'id': 'int',
      'name': 'String',
      'department': 'String',
      'position': 'String',
    },
    'work_item': {
      'id': 'int',
      'projectId': 'int',
      'title': 'String',
      'status': 'String',
    },
    'expense_line': {
      'id': 'int',
      'reportId': 'int',
      'merchantName': 'String',
      'accountCode': 'String',
      'accountName': 'String',
    },
    'work_day': {'id': 'int', 'employeeId': 'int', 'status': 'String'},
  };
  @override
  Map<String, Map<String, String>> get entityRoles => const {
    'employee': {
      'name': 'employeeName',
      'department': 'department',
      'position': 'position',
    },
    'work_item': {'title': 'workItemTitle'},
    'expense_line': {
      'merchantName': 'merchantName',
      'accountCode': 'accountCode',
      'accountName': 'accountName',
    },
    'work_day': {'status': 'attendanceStatus'},
  };
  @override
  Map<String, Map<String, List<String>>> get enums => const {
    'work_item': {
      'status': ['todo', 'in_progress', 'in_review', 'done', 'blocked'],
    },
  };
}

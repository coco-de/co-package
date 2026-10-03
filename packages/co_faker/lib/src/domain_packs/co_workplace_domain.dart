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
    'department': textRole(
      ['프런트엔드팀', '백엔드팀', '디자인팀', '고객지원팀', '인사팀'],
      [
        'Frontend team',
        'Backend team',
        'Design team',
        'Customer support',
        'HR team',
      ],
    ),
    'position': textRole(
      ['사원', '매니저', '팀장'],
      ['Associate', 'Manager', 'Team lead'],
    ),
    'workPlace': textRole(
      ['솔빛 사무실(가상)', '가람 업무센터(가상)', '재택'],
      ['Solbit office (fictional)', 'Garam work center (fictional)', 'Remote'],
    ),
    'shiftName': textRole(
      ['주간 근무', '오전 근무', '주말 당직'],
      ['Day shift', 'Morning shift', 'Weekend duty'],
    ),
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
    'approvalComment': textRole(
      ['첨부한 예시 기록을 확인했습니다.', '예시 사유에 추가 확인이 필요합니다.'],
      [
        'Reviewed the attached example record.',
        'The example reason needs further clarification.',
      ],
    ),
    'expenseCategory': enumRole([
      'meal',
      'transport',
      'meeting',
      'supplies',
      'travel',
      'etc',
    ]),
    'projectName': textRole(
      ['고객 포털 정비(가상)', '사내 위키 정리(가상)', '접근성 개선 예시'],
      [
        'Customer portal refresh (fictional)',
        'Internal wiki cleanup (fictional)',
        'Example accessibility improvement',
      ],
    ),
    'workItemTitle': textRole(
      ['로그인 오류 문구 개선', '예시 표 정렬 확인', '알림 상태 표시 정리'],
      [
        'Improve login error wording',
        'Check example table sorting',
        'Organize notification state display',
      ],
    ),
    'labelName': textRole(
      ['문구', '접근성', '백로그', '확인 필요'],
      ['Copy', 'Accessibility', 'Backlog', 'Needs checking'],
    ),
    'milestoneTitle': textRole(
      ['첫 검토 마일스톤', '예시 화면 완료', '회귀 확인'],
      ['First review milestone', 'Example screen complete', 'Regression check'],
    ),
    'sprintName': authoredRole(
      (f, c) => localized(f, '스프린트 ${c.index + 1}', 'Sprint ${c.index + 1}'),
    ),
    'commentBody': textRole(
      ['예시 화면을 확인한 뒤 의견을 남깁니다.', '다음 작업 전에 문구를 함께 확인해 주세요.'],
      [
        'Leaving feedback after checking the example screen.',
        'Please review the wording before the next task.',
      ],
    ),
    'merchantName': textRole(
      ['한식당 들꽃(가상)', '골목 다과점(가상)', '솔빛 사무용품점(가상)'],
      [
        'Wildflower dining (fictional)',
        'Lane snack shop (fictional)',
        'Solbit office supplies (fictional)',
      ],
    ),
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
    'accountName': authoredRole(
      (f, c) => (f.locale.startsWith('ko')
          ? ['식대(예시)', '교통비(예시)', '회의비(예시)', '소모품비(예시)', '출장비(예시)', '기타비(예시)']
          : [
              'Meals (example)',
              'Transport (example)',
              'Meeting (example)',
              'Supplies (example)',
              'Travel (example)',
              'Other (example)',
            ])[c.index % 6],
      coherent: true,
    ),
    'rejectReasonText': textRole(
      ['예시 영수증 누락', '항목 분류 확인 필요', '예시 정책 한도 확인 필요'],
      [
        'Missing example receipt',
        'Item classification needs checking',
        'Example policy limit needs checking',
      ],
    ),
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

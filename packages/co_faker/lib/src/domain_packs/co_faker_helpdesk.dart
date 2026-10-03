import '../co_faker.dart';
import 'authored_roles.dart';

/// Human-authored simulated AI drafts; no model/runtime/network dependency.
class CoFakerHelpdesk {
  /// Uses the supplied locale.
  const CoFakerHelpdesk(this.faker);

  /// Locale and supplied random source.
  final CoFaker faker;
  static const _drafts = <(String, String, String)>[
    (
      'account',
      '계정 설정 화면에서 초대 상태를 확인해 주세요. 이 문장은 모의 AI 초안이며 상담원 검토가 필요합니다.',
      'Check the invitation status in account settings. This simulated AI draft needs agent review.',
    ),
    (
      'account',
      '로그인 방법과 표시된 예시 오류를 함께 기록해 주세요. 모의 AI 초안이므로 실제 계정 변경은 하지 않습니다.',
      'Record the login method and example error together. This simulated AI draft makes no account changes.',
    ),
    (
      'billing',
      '예시 청구서의 기간과 항목을 확인해 주세요. 금액은 가상 요금표를 설명하는 모의 AI 초안입니다.',
      'Check the period and lines on the example invoice. This simulated AI draft describes fictional prices.',
    ),
    (
      'billing',
      '청구 알림의 예시 번호를 상담 기록에 남겨 주세요. 실제 결제 안내가 아닌 모의 AI 초안입니다.',
      'Record the example invoice number in the support note. This simulated AI draft is not a real payment notice.',
    ),
    (
      'data_export',
      '내보내기 화면에서 선택한 기간과 형식을 확인해 주세요. 개인정보를 제외한 예시 오류 내용을 남기는 모의 AI 초안입니다.',
      'Check the date range and format selected for export. This simulated AI draft records an example error without personal information.',
    ),
    (
      'data_export',
      '예시 CSV의 열 이름과 파일 상태를 확인해 주세요. 상담원이 내용을 검토하는 모의 AI 초안입니다.',
      'Check column names and file status in the example CSV. This simulated AI draft requires agent review.',
    ),
    (
      'integration',
      '연동 설정에 표시된 예시 상태와 확인 시각을 기록해 주세요. 외부 호출을 하지 않는 모의 AI 초안입니다.',
      'Record the example integration status and check time. This simulated AI draft makes no external calls.',
    ),
    (
      'bug',
      '문제가 보인 화면과 재현 순서를 기록해 주세요. 결과를 약속하지 않는 모의 AI 초안입니다.',
      'Record the screen and reproduction steps. This simulated AI draft promises no outcome.',
    ),
  ];

  /// Eight primitive seed records covering the five required draft categories.
  List<Map<String, Object?>> drafts() => List.generate(
    _drafts.length,
    (i) => {
      'code': 'AD-${_drafts[i].$1}-${i + 1}',
      'category': _drafts[i].$1,
      'templateBody': localized(faker, _drafts[i].$2, _drafts[i].$3),
      'sourceArticleCode': 'HA-${(i + 1).toString().padLeft(4, '0')}',
      'isSimulated': true,
    },
    growable: false,
  );
}

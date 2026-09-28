/// 범용 BDD 공유 step 라이브러리.
///
/// `.feature` 문장을 Key·텍스트 파라미터로 받는 **도메인 무관** step 만 둔다.
/// 생성기는 문장에서 파일명(`I tap the {'save_button'} widget` →
/// `i_tap_the_widget`)을 유도하고, 그 이름이 `sharedStepNames` 에 있으면 이
/// 라이브러리에서 가져온다.
///
/// ```yaml
/// co_bdd|dual_test_gen:
///   options:
///     sharedSteps: true
///     sharedStepsImport: "package:co_bdd/shared_steps.dart"
///     sharedStepNames:
///       - i_tap_the_widget
///       - the_widget_should_be_displayed
///       # ...
/// ```
///
/// 프로젝트 전용 step(디자인 시스템 판정 등)을 함께 쓰려면 자체 배럴에서
/// 이 라이브러리를 `show` 로 다시 내보내고 `sharedStepsImport` 를 그 배럴로
/// 둔다 — 채택 목록이 한 파일에 드러난다.
///
/// ## 여기에 두지 않는 것 (도메인 step)
///
/// - `Given` 페이지 마운트 · Mock 상태 조성
/// - 액션 2개 이상을 묶은 복합 동작
/// - 이름이 본문보다 큰 상태를 주장하는 step (예: "the review should be
///   deleted" 가 성공 메시지만 본다) — 공유 문장으로 바꾸면 주장이 약해진다
/// - 특정 화면 전용 Key·헬퍼에 기대는 판정
///
/// ## 규칙
///
/// - 파일명 = `/// Usage:` 문장에서 생성기가 유도한 이름 = 함수명의 snake_case.
///   `test/shared_steps_contract_test.dart` 가 생성기 코드로 이를 검사한다.
/// - `/// Usage:` 는 한 줄 — 줄바꿈하면 잘린 이름을 유도한다.
/// - 상태를 주장하는 step 은 그 상태를 검사한다. 존재 확인으로 대신하지 않는다.
library;

export 'src/shared_step/i_clear_the_widget.dart';
export 'src/shared_step/i_confirm_deletion.dart';
export 'src/shared_step/i_enter_in_the_widget.dart';
export 'src/shared_step/i_long_press_the_widget.dart';
export 'src/shared_step/i_scroll_until_the_widget_is_visible.dart';
export 'src/shared_step/i_should_see_widgets.dart';
export 'src/shared_step/i_tap_the_next_page_button.dart';
export 'src/shared_step/i_tap_the_text.dart';
export 'src/shared_step/i_tap_the_widget.dart';
export 'src/shared_step/i_tap_the_widget_at_index.dart';
export 'src/shared_step/i_wait_for_seconds.dart';
export 'src/shared_step/the_current_page_should_be.dart';
export 'src/shared_step/the_error_message_should_be_displayed.dart';
export 'src/shared_step/the_loading_indicator_should_be_displayed.dart';
export 'src/shared_step/the_success_message_should_be_displayed.dart';
export 'src/shared_step/the_text_should_be_displayed.dart';
export 'src/shared_step/the_total_count_should_be_displayed.dart';
export 'src/shared_step/the_widget_should_be_anchored_to.dart';
export 'src/shared_step/the_widget_should_be_displayed.dart';
export 'src/shared_step/the_widget_should_be_selected.dart';
export 'src/shared_step/the_widget_should_contain_text.dart';
export 'src/shared_step/the_widget_should_not_be_displayed.dart';
export 'src/shared_step/the_widget_should_not_be_selected.dart';

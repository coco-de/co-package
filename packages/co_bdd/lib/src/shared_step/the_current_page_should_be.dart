import 'package:co_bdd/src/driver/test_driver.dart';
import 'package:co_bdd/src/driver/widget_test_driver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the current page should be {'1'}
/// # 현재 페이지가 N 이어야 합니다
///
/// 페이지네이션 위젯이 **선택된 페이지 버튼 하나**에만
/// `current_page_indicator` Key 를 부여한다. 이 step 은 그 버튼의 라벨을
/// **정확히** 비교한다.
///
/// ⚠️ `the {'current_page_indicator'} widget should contain {'1'} text` 로
/// 대신하지 말 것 — `expectContainsText` 는 **부분 일치**라 `'1'` 이
/// `10`·`11`·`21` 페이지에도 통과한다. 페이지 리셋 계약은 "1페이지로
/// 돌아갔는가"가 핵심인데, 부분 일치로는 11페이지에 머물러 있어도 green 이 된다.
///
/// 정렬·필터·검색을 바꾸면 1페이지로 돌아가야 한다
/// (목록 화면의 페이지 리셋 계약).
// step 함수 시그니처 통일 (generated 호출부가 await)
Future<void> theCurrentPageShouldBe(TestDriver driver, String page) async {
  // Patrol 은 위젯 트리에 직접 접근할 수 없다 — 위젯 테스트에서만 검증한다.
  if (driver is! WidgetTestDriver) return;

  final indicator = find.byKey(const Key('current_page_indicator'));

  expect(
    indicator,
    findsOneWidget,
    reason:
        '현재 페이지 표시를 찾지 못했다. 페이지네이션이 렌더되지 않았거나 '
        '(`totalPages > 1` 이어야 표시된다) 선택된 페이지 버튼에 이 Key 를 주지 않는 '
        '화면이다',
  );

  // `find.text` 는 `Text.data` 를 **완전 일치**로 비교한다 — coui 체인
  // (`Text('5').bodyMedium...`)이 래퍼를 덧씌워도 안쪽 `Text` 를 찾는다.
  expect(
    find.descendant(of: indicator, matching: find.text(page)),
    findsOneWidget,
    reason: '현재 페이지가 $page 이 아니다',
  );
}

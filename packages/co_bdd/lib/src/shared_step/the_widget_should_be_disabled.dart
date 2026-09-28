import 'package:co_bdd/src/driver/test_driver.dart';
import 'package:co_bdd/src/driver/widget_tester_of.dart';
import 'package:co_bdd/src/helper/declared_semantics.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the {'settlement_approve_button'} widget should be disabled
/// # 해당 컨트롤이 비활성이어야 합니다
///
/// "보인다" 만으로는 버튼이 눌리는지 알 수 없다. 중복 제출·이중 트리거처럼
/// 비활성 여부 자체가 계약인 자리에서는 존재 단언이 아무것도 보증하지 못한다.
///
/// 판정은 Key 하위 트리의 **`Semantics(enabled:)` 선언**이다. 컨트롤이 비활성이
/// 되는 경로가 여럿이어도(CoUI `Button` 의 `onPressed: null` · `enabled: false`)
/// 컨트롤이 계산한 최종값 하나를 본다 — 경로 하나만 보던 로컬 구현들은 반대
/// 방식으로 비활성화된 버튼을 조용히 통과시켰다 (coco-de/unibook#9504).
// step 함수 시그니처 통일 (generated 호출부가 await)
Future<void> theWidgetShouldBeDisabled(
  TestDriver driver,
  String keyName,
) async {
  final enabled = declaredSemanticsFlag(
    widgetTesterOf(driver),
    keyName,
    flag: 'enabled',
    read: (properties) => properties.enabled,
  );

  expect(enabled, isFalse, reason: '$keyName 이 활성 상태다');
}

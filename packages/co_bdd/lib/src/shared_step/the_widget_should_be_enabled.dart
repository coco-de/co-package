import 'package:co_bdd/src/driver/test_driver.dart';
import 'package:co_bdd/src/driver/widget_tester_of.dart';
import 'package:co_bdd/src/helper/declared_semantics.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the {'login_button'} widget should be enabled
/// # 해당 컨트롤이 활성이어야 합니다
///
/// 판정은 Key 하위 트리의 **`Semantics(enabled:)` 선언**이다 — 스크린리더가
/// "사용 불가" 로 읽는지와 같은 값이다. CoUI `Button` 은 이 값에
/// `enabled ?? (onPressed != null)` 를 싣는다([declaredSemanticsFlag] 참조).
///
/// ⚠️ **`expectVisible` 로 대신하지 말 것.** 존재만 확인하는 step 은 비활성
/// 버튼도 그대로 통과한다 — 폼 검증 시나리오("필수 입력을 채우면 제출이
/// 활성화된다")에서는 그 단언이 검증 대상 자체를 비껴간다 (coco-de/unibook#9504).
// step 함수 시그니처 통일 (generated 호출부가 await)
Future<void> theWidgetShouldBeEnabled(TestDriver driver, String keyName) async {
  final enabled = declaredSemanticsFlag(
    widgetTesterOf(driver),
    keyName,
    flag: 'enabled',
    read: (properties) => properties.enabled,
  );

  expect(enabled, isTrue, reason: '$keyName 이 비활성 상태다');
}

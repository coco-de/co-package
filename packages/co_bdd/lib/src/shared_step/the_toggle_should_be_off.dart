import 'package:co_bdd/src/driver/test_driver.dart';
import 'package:co_bdd/src/driver/widget_tester_of.dart';
import 'package:co_bdd/src/helper/declared_semantics.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the {'push_notification_toggle'} toggle should be off
/// # 해당 토글이 꺼져 있어야 합니다
///
/// `the {'key'} toggle should be on` 의 짝. 판정은 Key 하위 트리의
/// **`Semantics(toggled:)` 선언**이다.
///
/// **`the {'key'} widget should be disabled` 로 대신할 수 없다** — 그 step 은
/// 누를 수 있는지를 보고, 이 step 은 토글의 값을 본다. 꺼져 있는 토글도 대개
/// **활성** 이다(눌러서 켤 수 있어야 하므로).
// step 함수 시그니처 통일 (generated 호출부가 await)
Future<void> theToggleShouldBeOff(TestDriver driver, String keyName) async {
  final toggled = declaredSemanticsFlag(
    widgetTesterOf(driver),
    keyName,
    flag: 'toggled',
    read: (properties) => properties.toggled,
  );

  expect(toggled, isFalse, reason: '$keyName 이 켜져 있다');
}

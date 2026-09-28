import 'package:co_bdd/src/driver/test_driver.dart';
import 'package:co_bdd/src/driver/widget_tester_of.dart';
import 'package:co_bdd/src/helper/declared_semantics.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the {'push_notification_toggle'} toggle should be on
/// # 해당 토글이 켜져 있어야 합니다
///
/// 판정은 Key 하위 트리의 **`Semantics(toggled:)` 선언**이다 — CoUI `Toggle` 은
/// `Semantics(toggled: value)` 를 선언한다.
///
/// **`the {'key'} widget should be enabled` 로 대신할 수 없다.** 그 step 은
/// 누를 수 있는지를 보고, 토글은 활성인 채로 **꺼져 있을 수** 있다.
///
/// | 컨트롤 | 관심사 | step |
/// |---|---|---|
/// | 버튼 | 누를 수 있는가 | `the {'key'} widget should be enabled` |
/// | 토글 | 켜져 있는가 | **이 step** |
///
/// `expectVisible` 로 대신하지도 말 것 — 존재 확인만 하면 꺼진 토글도 그대로
/// 통과한다 (coco-de/unibook#9538).
// step 함수 시그니처 통일 (generated 호출부가 await)
Future<void> theToggleShouldBeOn(TestDriver driver, String keyName) async {
  final toggled = declaredSemanticsFlag(
    widgetTesterOf(driver),
    keyName,
    flag: 'toggled',
    read: (properties) => properties.toggled,
  );

  expect(toggled, isTrue, reason: '$keyName 이 꺼져 있다');
}

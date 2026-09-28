// `Tristate` 는 `dart:ui` 원형 — semantics 플래그 3상(참/거짓/미지정)이라
// `isFalse` 와 `false` 는 다른 타입이다.
import 'dart:ui' show Tristate;

import 'package:co_bdd/src/driver/test_driver.dart';
import 'package:co_bdd/src/driver/widget_tester_of.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the {'filter_chip_blue'} widget should not be selected
/// # 위젯이 선택 상태가 아니어야 합니다
///
/// Semantics `isSelected` 가 **명시적으로 거짓**이어야 통과한다. 선택 상태
/// 자체가 없는 위젯(`Tristate.none`)은 실패한다 — 선택할 수 없는 위젯을 "선택
/// 안 됨" 으로 통과시키면 선택 계약이 빠진 화면이 조용히 green 이 된다.
///
/// 켜진 쪽만 단언하면 `selected: isSelected` 를 상수 `true` 로 바꿔도 통과한다 —
/// 선택 계약은 **양방향**이라 꺼진 쪽도 함께 고정한다.
// step 함수 시그니처 통일 (generated 호출부가 await)
Future<void> theWidgetShouldNotBeSelected(
  TestDriver driver,
  String keyName,
) async {
  final semantics = widgetTesterOf(
    driver,
  ).getSemantics(find.byKey(Key(keyName)));

  expect(
    semantics.flagsCollection.isSelected,
    Tristate.isFalse,
    reason: "'$keyName' 가 선택 상태이거나 선택 상태를 갖지 않는다",
  );
}

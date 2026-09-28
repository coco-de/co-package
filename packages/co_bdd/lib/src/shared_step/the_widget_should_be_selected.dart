// `Tristate` 는 `dart:ui` 원형 — semantics 플래그 3상(참/거짓/미지정)이라
// `isTrue` 와 `true` 는 다른 타입이다.
import 'dart:ui' show Tristate;

import 'package:co_bdd/src/driver/test_driver.dart';
import 'package:co_bdd/src/driver/widget_tester_of.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the {'filter_chip_yellow'} widget should be selected
/// # 위젯이 선택 상태여야 합니다
///
/// 판정은 **Semantics `isSelected` 플래그**다 — 스크린리더가 "선택됨" 으로 읽는
/// 값이고, `Semantics(selected:)` · `ChoiceChip` · `ListTile(selected:)` 같은
/// 프레임워크 위젯이 채우는 신호다.
///
/// 화면마다 다른 표식(체크 아이콘 등)으로 선택을 판정해야 하면 이 문장을 쓰지
/// 말고 **도메인 문장**으로 가른다. 같은 문장이 패키지마다 다른 판정을 가지면
/// `.feature` 를 읽는 사람이 무엇이 검증되는지 알 수 없다
/// (coco-de/unibook#14433 — 한쪽은 Semantics, 한쪽은 아이콘 Key 로 판정하고 있었다).
///
/// "표시된다" 로 대신하지 않는다 — 선택 칩은 켜져 있든 꺼져 있든 항상
/// 표시되고, 계약의 핵심은 선택 **상태**다.
// step 함수 시그니처 통일 (generated 호출부가 await)
Future<void> theWidgetShouldBeSelected(
  TestDriver driver,
  String keyName,
) async {
  final semantics = widgetTesterOf(
    driver,
  ).getSemantics(find.byKey(Key(keyName)));

  expect(
    semantics.flagsCollection.isSelected,
    Tristate.isTrue,
    reason: "'$keyName' 의 Semantics selected 가 참이 아니다",
  );
}

import 'package:flutter/semantics.dart' show SemanticsProperties;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// [keyName] 위젯(자신 포함) 아래에서 [read] 가 값을 돌려주는 `Semantics` 선언을
/// **정확히 하나** 찾아 그 값을 돌려준다.
///
/// 컨트롤의 상태(활성 · 켜짐 등)를 디자인 시스템 타입 없이 판정하려고 쓴다 —
/// 컨트롤은 스크린리더에 상태를 알리려고 `Semantics(enabled:)` ·
/// `Semantics(toggled:)` 를 선언하고, 그 값이 곧 화면이 주장하는 상태다.
/// 예를 들어 CoUI `Button` 은 `enabled ?? (onPressed != null)` 를 계산해
/// `Clickable` 의 `Semantics(enabled:)` 에 그대로 싣고, `Toggle` 은
/// `Semantics(toggled: value)` 를 선언한다. Material 버튼도 같은 신호를 낸다.
///
/// 컴파일된 Semantics **트리**가 아니라 위젯 트리의 **선언**을 읽는다. 트리는
/// `container` 가 아닌 선언을 조상 노드로 병합하므로, Key 가 붙은 위젯에서
/// 거슬러 올라가 읽으면 형제 컨트롤의 상태를 읽을 수 있다. 선언은 Key 의 하위
/// 트리로 범위가 한정된다.
///
/// Key 는 컨트롤 자신에도, 식별용 래퍼(`Semantics(container: true, identifier:)`
/// 등)에도 붙을 수 있다 — `matchRoot: true` 로 양쪽을 함께 받는다.
///
/// ⚠️ 여러 개면 **실패**한다. 트리 순서상 첫 것을 조용히 고르면 엉뚱한 컨트롤의
/// 상태를 판정한다 — 대상이 여럿인 화면은 대상을 좁힐 Key 를 따로 부여한다.
bool declaredSemanticsFlag(
  WidgetTester tester,
  String keyName, {
  required String flag,
  required bool? Function(SemanticsProperties properties) read,
}) {
  final keyed = find.byKey(Key(keyName));
  expect(keyed, findsOneWidget, reason: "Key '$keyName' 을 가진 위젯이 없다");

  final declared = find.descendant(
    of: keyed,
    matching: find.byWidgetPredicate(
      (widget) => widget is Semantics && read(widget.properties) != null,
    ),
    matchRoot: true,
  );
  expect(
    declared,
    findsOneWidget,
    reason:
        "Key '$keyName' 아래에서 $flag 를 선언한 Semantics 를 정확히 1개 찾지 "
        '못했다 — 상태를 스크린리더에 알리지 않는 컨트롤이거나, 같은 상태를 '
        '가진 컨트롤이 여럿이다. 대상을 좁힐 Key 를 따로 부여할 것',
  );

  return read(tester.widget<Semantics>(declared).properties)!;
}

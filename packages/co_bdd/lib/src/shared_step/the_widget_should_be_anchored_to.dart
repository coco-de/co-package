import 'package:co_bdd/src/driver/test_driver.dart';
import 'package:co_bdd/src/driver/widget_test_driver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// 앵커 정렬 허용 오차(논리 픽셀).
///
/// 팝오버 엔진은 배치 좌표를 소수로 계산하므로 정확히 같은 값이 나오지 않는다.
const double _kAlignmentEpsilon = 1;

/// 앵커가 화면 최상단에 붙어 있다고 볼 임계값(논리 픽셀).
///
/// 이보다 위면 "버튼에 앵커됨"과 "화면 상단 고정"이 구분되지 않아 단언이
/// 공허해진다 — 아래 [theWidgetShouldBeAnchoredTo] 의 공허성 가드 참조.
const double _kTopEdgeThreshold = 8;

/// Usage: the {'filter_dialog'} widget should be anchored to {'filter_button'}
/// # 팝오버가 앵커 위젯에 붙어서 열려야 합니다
///
/// ⚠️ `Usage:` 는 **한 줄**이어야 한다 — 생성기가 이 문구에서 step 이름을
/// 유도하므로, 줄바꿈하면 잘린 이름(`..._anchored_to_the`)을 찾다가 컴파일
/// 에러가 난다. `test/shared_steps_contract_test.dart` 가 이 불일치를 막는다.
///
/// 팝오버의 `bottomEnd` 배치 계약 — 패널 **우측**을 앵커 우측에 맞추고
/// 앵커 **아래**로 펼친다. 화면 아래 공간이 부족하면 엔진이 상하로
/// 반전시키므로 위로 펼쳐지는 것도 계약 위반이 아니다.
///
/// ## 무엇을 잡는가
///
/// 팝오버가 `anchorKey` 를 받아 놓고 쓰지 않아 **화면 우상단 고정** 위치에
/// 뜨는 회귀(coco-de/unibook#9745 — 팝오버 API 교체 중 `showDialog(alignment:
/// topRight)` 로 대체됐다)를 잡는다.
///
/// ## ⚠️ 공허성 가드
///
/// 앵커가 화면 최상단에 있으면 "앵커에 붙음"과 "화면 우상단 고정"의 결과가
/// 겹쳐 회귀를 **구분할 수 없다**. 그런 배치에서는 이 step 이 통과해도 아무것도
/// 보증하지 못하므로, 앵커가 `y < $_kTopEdgeThreshold` 면 **실패시킨다**.
/// 실제 목록 화면은 필터 버튼이 헤더(y≈100 이상)에 있어 문제되지 않는다.
///
/// 가로축은 앵커가 우상단에 있어도 무방하다 — 세로 인접 단언이 회귀를 잡는다.
// step 함수 시그니처 통일 (generated 호출부가 await)
Future<void> theWidgetShouldBeAnchoredTo(
  TestDriver driver,
  String panelKeyName,
  String anchorKeyName,
) async {
  // Patrol 은 위젯 좌표를 직접 잴 수 없다 — 위젯 테스트에서만 검증한다.
  if (driver is! WidgetTestDriver) return;

  final tester = driver.tester;

  final anchorFinder = find.byKey(Key(anchorKeyName));
  expect(anchorFinder, findsOneWidget, reason: "앵커 '$anchorKeyName' 을 찾지 못했다");

  final panelFinder = find.byKey(Key(panelKeyName));
  expect(
    panelFinder,
    findsOneWidget,
    reason: "팝오버 '$panelKeyName' 이 열려 있지 않다 — 앵커를 먼저 탭했는지 확인할 것",
  );

  final anchor = tester.getRect(anchorFinder);
  final panel = tester.getRect(panelFinder);

  expect(
    anchor.top,
    greaterThanOrEqualTo(_kTopEdgeThreshold),
    reason:
        "앵커 '$anchorKeyName' 이 화면 최상단(y=${anchor.top})에 있어 이 단언이 "
        '공허하다 — 화면 우상단 고정 회귀와 결과가 겹쳐 구분되지 않는다. '
        '테스트 하네스에서 앵커를 아래로 내릴 것',
  );

  // 우측 정렬 (bottomEnd) — 패널 우측 끝이 앵커 우측 끝에 맞는다.
  expect(
    panel.right,
    moreOrLessEquals(anchor.right, epsilon: _kAlignmentEpsilon),
    reason:
        'bottomEnd 배치는 패널 우측을 앵커 우측에 정렬한다 '
        '(패널 right=${panel.right}, 앵커 right=${anchor.right})',
  );

  // 세로 인접 — 아래로 펼치거나(정상), 공간 부족 시 위로 반전(허용).
  final opensBelow = panel.top >= anchor.bottom;
  final opensAbove = panel.bottom <= anchor.top;

  expect(
    opensBelow || opensAbove,
    isTrue,
    reason:
        '팝오버가 앵커 위아래 어느 쪽으로도 붙지 않고 겹쳐 있다 '
        '(패널 ${panel.top}~${panel.bottom}, 앵커 ${anchor.top}~${anchor.bottom}) '
        '— 앵커를 무시하고 화면 좌표에 고정된 회귀일 수 있다',
  );
}

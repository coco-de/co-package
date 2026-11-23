import 'package:co_bdd/src/driver/test_driver.dart';

/// Usage: I press the back button # 뒤로 가기를 누릅니다
///
/// 시스템 뒤로 가기를 누른다. 위젯 테스트는 안드로이드 뒤로 가기와 같은
/// `popRoute` 를 보내 앱의 `Navigator`·`Router`·`PopScope` 처리를 실제로 일으키고,
/// Patrol 은 `$.native.pressBack()` 이다(Android 만 — iOS 는 뒤로 가기 버튼이 없어
/// 예외가 난다. iOS 를 거치는 시나리오는 화면의 뒤로 가기 컨트롤을 Key 로 탭한다).
///
/// 결과는 이 step 이 아니라 뒤따르는 `Then` 이 단언한다. 처리할 것이 없는 루트에서도
/// 예외 없이 끝난다.
Future<void> iPressTheBackButton(TestDriver driver) async {
  await driver.pressBack();
  await driver.settle();
}

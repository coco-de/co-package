import 'package:co_bdd/src/driver/test_driver.dart';

/// Usage: the {'로그인 성공'} text should be displayed
/// # 지정된 텍스트가 화면에 표시되어야 합니다
Future<void> theTextShouldBeDisplayed(TestDriver driver, String text) async {
  await driver.expectTextVisible(text);
}

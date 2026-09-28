import 'package:co_bdd/src/driver/test_driver.dart';

/// Usage: I tap the {'로그인'} text # 텍스트를 포함한 위젯을 탭합니다
Future<void> iTapTheText(TestDriver driver, String text) async {
  await driver.tapText(text);
  await driver.settle();
}

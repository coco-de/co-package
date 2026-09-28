import 'package:co_bdd/src/driver/test_driver.dart';
import 'package:flutter/foundation.dart';

/// Usage: the {'error_banner'} widget should not be displayed
/// # 위젯이 화면에 표시되지 않아야 합니다
Future<void> theWidgetShouldNotBeDisplayed(
  TestDriver driver,
  String keyName,
) async {
  await driver.expectNotVisible(Key(keyName));
}

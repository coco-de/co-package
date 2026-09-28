import 'package:co_bdd/src/driver/test_driver.dart';
import 'package:flutter/foundation.dart';

/// Usage: the {'error_message'} widget should be displayed
/// # 위젯이 화면에 표시되어야 합니다
Future<void> theWidgetShouldBeDisplayed(
  TestDriver driver,
  String keyName,
) async {
  await driver.expectVisible(Key(keyName));
}

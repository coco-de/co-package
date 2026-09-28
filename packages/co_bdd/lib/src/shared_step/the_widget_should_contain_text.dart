import 'package:co_bdd/src/driver/test_driver.dart';
import 'package:flutter/foundation.dart';

/// Usage: the {'total_count'} widget should contain {'42'} text
/// # 위젯 서브트리에 해당 텍스트가 포함되어야 합니다
Future<void> theWidgetShouldContainText(
  TestDriver driver,
  String keyName,
  String text,
) async {
  await driver.expectContainsText(Key(keyName), text);
}

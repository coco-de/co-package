import 'package:co_bdd/src/driver/test_driver.dart';
import 'package:flutter/foundation.dart';

/// Usage: I long press the {'book_list_item'} widget
/// # 위젯을 길게 눌러 컨텍스트 액션을 트리거합니다
Future<void> iLongPressTheWidget(TestDriver driver, String keyName) async {
  await driver.longPress(Key(keyName));
  await driver.settle();
}

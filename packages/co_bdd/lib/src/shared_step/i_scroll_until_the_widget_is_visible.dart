import 'package:co_bdd/src/driver/test_driver.dart';
import 'package:flutter/foundation.dart';

/// Usage: I scroll until the {'save_button'} widget is visible
/// # 스크롤해서 위젯이 화면에 보일 때까지 이동합니다
Future<void> iScrollUntilTheWidgetIsVisible(
  TestDriver driver,
  String keyName,
) async {
  await driver.scrollUntilVisible(Key(keyName));
}

import 'package:co_bdd/src/driver/test_driver.dart';
import 'package:flutter/foundation.dart';

/// Usage: I enter {'test@example.com'} in the {'email_field'} widget
/// # 텍스트 필드에 값을 입력합니다
Future<void> iEnterInTheWidget(
  TestDriver driver,
  String value,
  String keyName,
) async {
  await driver.enterText(Key(keyName), value);
  await driver.settle();
}

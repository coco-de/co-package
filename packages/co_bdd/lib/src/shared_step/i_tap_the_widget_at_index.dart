import 'package:co_bdd/src/driver/test_driver.dart';
import 'package:flutter/foundation.dart';

/// Usage: I tap the {'book_list_item'} widget at index {'2'}
/// # 같은 Key를 가진 N번째 위젯을 탭합니다 (0-based)
Future<void> iTapTheWidgetAtIndex(
  TestDriver driver,
  String keyName,
  String index,
) async {
  final parsed = int.parse(index);
  await driver.tapAtIndex(Key(keyName), parsed);
  await driver.settle();
}

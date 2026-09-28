import 'package:co_bdd/src/driver/test_driver.dart';
import 'package:flutter/foundation.dart';

/// Usage: I should see {'3'} {'book_list_item'} widgets
/// # 해당 Key를 가진 위젯이 N개 보여야 합니다
Future<void> iShouldSeeWidgets(
  TestDriver driver,
  String count,
  String keyName,
) async {
  final parsed = int.parse(count);
  await driver.expectCount(Key(keyName), parsed);
}

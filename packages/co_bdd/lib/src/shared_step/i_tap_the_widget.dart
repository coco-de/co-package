import 'package:co_bdd/src/driver/test_driver.dart';
import 'package:flutter/foundation.dart';

/// Usage: I tap the {'search_icon'} widget # 검색 아이콘을 탭합니다
Future<void> iTapTheWidget(TestDriver driver, String keyName) async {
  await driver.tap(Key(keyName));
  await driver.settle();
}

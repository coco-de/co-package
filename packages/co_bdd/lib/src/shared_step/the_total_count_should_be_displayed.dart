import 'package:co_bdd/src/driver/test_driver.dart';
import 'package:co_bdd/src/key/common_keys.dart';

/// Usage: the total count should be displayed
/// # 총 개수 표시 위젯이 화면에 표시되어야 합니다
///
/// 총 개수 표시 위젯에 [CommonKeys.totalCount] Key 가 할당되어 있어야 한다.
Future<void> theTotalCountShouldBeDisplayed(TestDriver driver) async {
  await driver.expectVisible(CommonKeys.totalCount);
}

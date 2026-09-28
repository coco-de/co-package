import 'package:co_bdd/src/driver/test_driver.dart';
import 'package:co_bdd/src/key/common_keys.dart';

/// Usage: I tap the next page button # 다음 페이지 버튼을 탭합니다
///
/// 페이지네이션 위젯에 [CommonKeys.nextPageButton] Key 가 할당되어 있어야 한다.
Future<void> iTapTheNextPageButton(TestDriver driver) async {
  await driver.tap(CommonKeys.nextPageButton);
  await driver.settle();
}

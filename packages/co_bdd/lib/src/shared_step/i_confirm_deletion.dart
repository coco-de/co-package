import 'package:co_bdd/src/driver/test_driver.dart';
import 'package:co_bdd/src/key/common_keys.dart';

/// Usage: I confirm deletion # 삭제 확인 다이얼로그의 확인 버튼을 탭합니다
///
/// 삭제 확인 다이얼로그에 [CommonKeys.confirmButton] Key 가 할당되어 있어야 한다.
Future<void> iConfirmDeletion(TestDriver driver) async {
  await driver.tap(CommonKeys.confirmButton);
  await driver.settle();
}

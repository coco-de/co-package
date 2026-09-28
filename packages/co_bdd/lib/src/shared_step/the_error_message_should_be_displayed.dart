import 'package:co_bdd/src/driver/test_driver.dart';
import 'package:co_bdd/src/key/common_keys.dart';

/// Usage: the error message should be displayed # 에러 메시지가 표시되어야 합니다
///
/// Toast/Overlay 는 비동기로 렌더링되므로 `expectVisible` 직전 [TestDriver.settle]
/// 을 호출하여 위젯 트리에 mount 될 시간을 확보한다 (coco-de/unibook#5694).
Future<void> theErrorMessageShouldBeDisplayed(TestDriver driver) async {
  await driver.settle();
  await driver.expectVisible(CommonKeys.errorMessage);
}

import 'package:co_bdd/src/driver/test_driver.dart';
import 'package:co_bdd/src/key/common_keys.dart';

/// Usage: the loading indicator should be displayed
/// # 로딩 인디케이터가 표시되어야 합니다
///
/// 비동기 BLoC 상태 전이가 끝난 후 즉시 호출되는 케이스에 대비해 `expectVisible`
/// 직전 [TestDriver.settle] 을 호출한다 (coco-de/unibook#5694).
Future<void> theLoadingIndicatorShouldBeDisplayed(TestDriver driver) async {
  await driver.settle();
  await driver.expectVisible(CommonKeys.loadingIndicator);
}

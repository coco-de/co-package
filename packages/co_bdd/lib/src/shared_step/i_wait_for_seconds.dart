import 'package:co_bdd/src/driver/test_driver.dart';

/// Usage: I wait for {'2'} seconds # 지정된 초만큼 대기합니다
///
/// [seconds] 파라미터가 숫자로 파싱되지 않으면 0 초로 간주한다.
Future<void> iWaitForSeconds(TestDriver driver, String seconds) async {
  final parsed = int.tryParse(seconds) ?? 0;
  await driver.wait(Duration(seconds: parsed));
}

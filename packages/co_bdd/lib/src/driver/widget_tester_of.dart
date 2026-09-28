import 'package:co_bdd/src/driver/patrol_test_driver.dart';
import 'package:co_bdd/src/driver/test_driver.dart';
import 'package:co_bdd/src/driver/widget_test_driver.dart';
import 'package:flutter_test/flutter_test.dart';

/// [driver] 가 감싼 [WidgetTester] — 위젯 테스트와 Patrol E2E 양쪽에서 얻는다.
///
/// Semantics 플래그처럼 위젯 트리를 직접 읽어야 하는 step 이 드라이버 종류마다
/// 분기하지 않게 한다. 알 수 없는 드라이버면 조용히 건너뛰지 않고
/// [UnsupportedError] 로 알린다 — 검증을 건너뛴 step 이 통과로 보이면 안 된다.
WidgetTester widgetTesterOf(TestDriver driver) => switch (driver) {
  WidgetTestDriver(:final tester) => tester,
  PatrolTestDriver(:final $) => $.tester,
  _ => throw UnsupportedError(
    '${driver.runtimeType} 는 WidgetTester 를 노출하지 않는다',
  ),
};

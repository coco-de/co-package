// Story: S8.1 (E8 follow-up) — EpubViewController 페이지 내비게이션

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_epub/src/api/epub_reader_controller.dart';
import 'package:open_epub_engine/src/api/epub_source.dart';
import 'package:open_epub/src/presentation/widgets/epub_reader.dart';

import 'package:open_epub_engine/testing.dart';

void main() {
  testWidgets('controller가 페이지를 프로그램적으로 이동하고 상태를 갱신한다', (tester) async {
    final controller = EpubViewController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EpubReader(
            source: EpubSource.bytes(searchableEpub3()),
            controller: controller,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 초기 상태(3 spine, 0번)
    expect(controller.spineCount, 3);
    expect(controller.currentSpineIndex, 0);
    expect(controller.hasPrevious, isFalse);
    expect(controller.hasNext, isTrue);

    // nextPage → 1
    // animateToPage는 pump가 애니메이션을 구동해야 완료되므로, future를 먼저
    // 잡고 pumpAndSettle로 애니메이션을 끝낸 뒤 await한다(미펌프 await는 데드락).
    final next = controller.nextPage();
    await tester.pumpAndSettle();
    await next;
    expect(controller.currentSpineIndex, 1);

    // goToSpine(2) → 끝
    final toLast = controller.goToSpine(2);
    await tester.pumpAndSettle();
    await toLast;
    expect(controller.currentSpineIndex, 2);
    expect(controller.hasNext, isFalse);

    // previousPage → 1
    final prev = controller.previousPage();
    await tester.pumpAndSettle();
    await prev;
    expect(controller.currentSpineIndex, 1);
  });

  test('syncState는 변경 시에만 listener에 통지한다', () {
    final controller = EpubViewController();
    addTearDown(controller.dispose);
    var notifications = 0;
    controller.addListener(() => notifications++);

    controller.syncState(currentSpineIndex: 1, spineCount: 3);
    expect(notifications, 1);
    expect(controller.currentSpineIndex, 1);
    expect(controller.spineCount, 3);

    // 같은 값 → 통지 없음
    controller.syncState(currentSpineIndex: 1, spineCount: 3);
    expect(notifications, 1);
  });

  test('미부착 controller의 nextPage는 무시된다(크래시 없음)', () async {
    final controller = EpubViewController();
    addTearDown(controller.dispose);
    await controller.nextPage();
    expect(controller.currentSpineIndex, 0);
  });

  // open-epub#221 — controller가 있어도 paged:false(스크롤모드)가 무시되고
  // 강제로 paged 모드로 바뀌던 버그의 회귀 테스트. 이제 스크롤모드에서도
  // ReflowableEngine이 controller 내비게이션을 지원한다.
  testWidgets('스크롤모드(paged:false)에서도 controller가 동작한다(open-epub#221)',
      (tester) async {
    final controller = EpubViewController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EpubReader(
            source: EpubSource.bytes(searchableEpub3()),
            controller: controller,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 스크롤모드 유지 확인 — PageView(paged 모드 전용)가 아닌
    // ScrollablePositionedList 기반 ReflowableEngine이어야 한다.
    expect(find.byType(PageView), findsNothing);

    expect(controller.spineCount, 3);
    expect(controller.currentSpineIndex, 0);

    final next = controller.nextPage();
    await tester.pumpAndSettle();
    await next;
    expect(controller.currentSpineIndex, 1);

    final toLast = controller.goToSpine(2);
    await tester.pumpAndSettle();
    await toLast;
    expect(controller.currentSpineIndex, 2);
  });
}

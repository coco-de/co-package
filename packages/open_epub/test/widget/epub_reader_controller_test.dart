// Story: S8.1 (E8 follow-up) — EpubViewController 페이지 내비게이션

import 'dart:typed_data';

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

  // open-epub#221 후속 — 페이지 버튼(nextPage/previousPage)이 spine 전체를
  // 건너뛰지 않고, 엔진이 attachPageStepper로 등록한 세분화된(윈도우 등)
  // 이동을 우선 사용해야 한다.
  group('attachPageStepper — 페이지 단위 이동 우선순위', () {
    test('attachPageStepper가 있으면 goToSpine 대신 stepper를 쓴다', () async {
      final controller = EpubViewController();
      addTearDown(controller.dispose);
      controller.syncState(currentSpineIndex: 0, spineCount: 3);

      final steps = <int>[];
      controller.attachPageStepper((direction) async {
        steps.add(direction);
      });
      // attachNavigator(goToSpine)는 등록하지 않음 — stepper가 있으면
      // goToSpine 없이도 nextPage/previousPage가 동작해야 한다.

      await controller.nextPage();
      await controller.previousPage();

      expect(steps, [1, -1]);
      // stepper만으로는 currentSpineIndex가 안 바뀐다(엔진이 syncState로
      // 직접 갱신하는 책임) — goToSpine 경로를 타지 않았다는 방증.
      expect(controller.currentSpineIndex, 0);
    });

    test('attachPageStepper가 없으면 goToSpine으로 폴백한다(회귀)', () async {
      final controller = EpubViewController();
      addTearDown(controller.dispose);
      controller.syncState(currentSpineIndex: 0, spineCount: 3);

      final jumps = <int>[];
      controller.attachNavigator((index) async {
        jumps.add(index);
        controller.syncState(currentSpineIndex: index, spineCount: 3);
      });

      await controller.nextPage();
      expect(jumps, [1]);
      expect(controller.currentSpineIndex, 1);
    });

    test('detachNavigator는 stepper도 함께 해제한다', () async {
      final controller = EpubViewController();
      addTearDown(controller.dispose);
      controller.syncState(currentSpineIndex: 0, spineCount: 3);

      var stepperCalls = 0;
      controller.attachPageStepper((direction) async => stepperCalls++);
      controller.detachNavigator();

      // stepper 해제됨 → goToSpine 폴백. navigate도 해제됐으니 무시(크래시 없음).
      await controller.nextPage();
      expect(stepperCalls, 0);
      expect(controller.currentSpineIndex, 0);
    });
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

  // open-epub#228 — 코드 리뷰에서 확인된 갭: 윈도우 단위 이동(stepper)만으로는
  // currentSpineIndex/hasNext/hasPrevious가 갱신되지 않아, 마지막 spine이
  // 여러 윈도우로 나뉜 경우 hasNext가 false로 고정돼 "다음" 버튼을 잘못
  // 비활성화할 수 있었다. syncState에 windowIndex/windowCount를 추가해 해결.
  group('syncState — 윈도우 정보 (open-epub#228)', () {
    test('windowIndex/windowCount를 반영하고 변경 시에만 통지한다', () {
      final controller = EpubViewController();
      addTearDown(controller.dispose);
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.syncState(
        currentSpineIndex: 0,
        spineCount: 1,
        windowIndex: 0,
        windowCount: 3,
      );
      expect(notifications, 1);
      expect(controller.windowIndex, 0);
      expect(controller.windowCount, 3);

      // 같은 값 → 통지 없음
      controller.syncState(
        currentSpineIndex: 0,
        spineCount: 1,
        windowIndex: 0,
        windowCount: 3,
      );
      expect(notifications, 1);

      // 윈도우 인덱스만 변경 → 통지
      controller.syncState(
        currentSpineIndex: 0,
        spineCount: 1,
        windowIndex: 1,
        windowCount: 3,
      );
      expect(notifications, 2);
      expect(controller.windowIndex, 1);
    });

    test('windowIndex/windowCount 생략 시 기본값(0/1) — 기존 spine 전용 동작과 동일 (회귀)', () {
      final controller = EpubViewController();
      addTearDown(controller.dispose);
      controller.syncState(currentSpineIndex: 1, spineCount: 3);
      expect(controller.windowIndex, 0);
      expect(controller.windowCount, 1);
    });

    test('hasNext — 마지막 spine이어도 남은 윈도우가 있으면 true', () {
      final controller = EpubViewController();
      addTearDown(controller.dispose);
      // 마지막 spine(2/3)이지만 3개 윈도우 중 첫 번째 — spine 관점으론
      // "마지막"이지만 아직 윈도우 2개가 남아있다.
      controller.syncState(
        currentSpineIndex: 2,
        spineCount: 3,
        windowIndex: 0,
        windowCount: 3,
      );
      expect(controller.hasNext, isTrue);

      controller.syncState(
        currentSpineIndex: 2,
        spineCount: 3,
        windowIndex: 2,
        windowCount: 3,
      );
      expect(controller.hasNext, isFalse); // 진짜 마지막 윈도우
    });

    test('hasPrevious — 첫 spine이어도 윈도우가 0보다 크면 true(대칭)', () {
      final controller = EpubViewController();
      addTearDown(controller.dispose);
      controller.syncState(
        currentSpineIndex: 0,
        spineCount: 3,
        windowIndex: 1,
        windowCount: 3,
      );
      expect(controller.hasPrevious, isTrue);

      controller.syncState(
        currentSpineIndex: 0,
        spineCount: 3,
        windowIndex: 0,
        windowCount: 3,
      );
      expect(controller.hasPrevious, isFalse);
    });
  });

  // 목차(TOC) 항목 탭 → 페이지 이동 안 되는 문제 수정 — EpubOutlineItem의
  // spineHref를 controller.goToHref로 넘기면 실제 화면이 해당 spine으로
  // 이동해야 한다(기존에는 매칭 API가 없어 host가 연결할 방법이 없었다).
  group('goToHref — 목차(TOC) 탭 시 spineHref로 이동', () {
    testWidgets('등록된 spine href로 해당 spine으로 이동한다', (tester) async {
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

      expect(controller.currentSpineIndex, 0);

      final jump = controller.goToHref('ch3.xhtml');
      await tester.pumpAndSettle();
      await jump;
      expect(controller.currentSpineIndex, 2);
    });

    test('매칭되는 href가 없으면 무시된다(크래시 없음)', () async {
      final controller = EpubViewController();
      addTearDown(controller.dispose);
      controller.syncState(currentSpineIndex: 0, spineCount: 3);
      await controller.goToHref('does-not-exist.xhtml');
      expect(controller.currentSpineIndex, 0);
    });

    test('detachNavigator 이후에는 href 목록도 초기화된다', () async {
      final controller = EpubViewController();
      addTearDown(controller.dispose);
      controller.attachSpineHrefs(['ch1.xhtml', 'ch2.xhtml']);
      controller.attachNavigator((index) async {});
      controller.syncState(currentSpineIndex: 0, spineCount: 2);
      controller.detachNavigator();

      await controller.goToHref('ch2.xhtml');
      expect(controller.currentSpineIndex, 0);
    });
  });

  // open-epub#228 — 코드 리뷰에서 확인된 갭: paged:true + 실제 EpubReader +
  // 실제 EpubViewController 조합으로 controller.nextPage()를 눌렀을 때 화면
  // 단위로만 이동하는지(챕터 전체를 건너뛰지 않는지)를 검증하는 end-to-end
  // 테스트가 없었다 — 이 테스트가 그 실제 신고 재현 경로를 검증한다.
  group(
      'EpubReader(paged:true) + controller — end-to-end 윈도우 이동 (open-epub#228)',
      () {
    testWidgets('nextPage()가 긴 챕터를 건너뛰지 않고 화면 단위로 이동한다', (tester) async {
      final controller = EpubViewController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 600,
              child: EpubReader(
                source: EpubSource.bytes(_longChapterEpub()),
                controller: controller,
                paged: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 2번째 spine(긴 챕터)으로 이동.
      final toChapter2 = controller.goToSpine(1);
      await tester.pumpAndSettle();
      await toChapter2;
      expect(controller.currentSpineIndex, 1);
      expect(controller.windowCount, greaterThan(1)); // 화면보다 긴 챕터
      final chapterWindowCount = controller.windowCount;

      // nextPage() — 같은 spine 안에서 윈도우만 이동해야 한다(챕터 전체를
      // 건너뛰지 않음). 이게 바로 실기기 QA에서 신고된 버그의 재현 경로다.
      final next = controller.nextPage();
      await tester.pumpAndSettle();
      await next;
      expect(controller.currentSpineIndex, 1); // 같은 spine 유지
      expect(controller.windowIndex, 1); // 다음 윈도우로
      expect(controller.windowCount, chapterWindowCount);
      expect(controller.hasNext, isTrue); // 아직 윈도우가 더 남아있음
    });
  });
}

Uint8List _longChapterEpub() => zipEpub({
      'mimetype': 'application/epub+zip',
      'META-INF/container.xml': '''
<?xml version="1.0"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>
''',
      'OEBPS/content.opf': '''
<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0" unique-identifier="bookid">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>긴 챕터 테스트북</dc:title>
    <dc:language>ko</dc:language>
    <dc:identifier id="bookid">urn:uuid:test-longchapter</dc:identifier>
  </metadata>
  <manifest>
    <item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav"/>
    <item id="c1" href="ch1.xhtml" media-type="application/xhtml+xml"/>
    <item id="c2" href="ch2.xhtml" media-type="application/xhtml+xml"/>
    <item id="c3" href="ch3.xhtml" media-type="application/xhtml+xml"/>
  </manifest>
  <spine>
    <itemref idref="c1"/>
    <itemref idref="c2"/>
    <itemref idref="c3"/>
  </spine>
</package>
''',
      'OEBPS/nav.xhtml': '''
<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
  <body>
    <nav epub:type="toc">
      <ol>
        <li><a href="ch1.xhtml">1장</a></li>
        <li><a href="ch2.xhtml">2장</a></li>
        <li><a href="ch3.xhtml">3장</a></li>
      </ol>
    </nav>
  </body>
</html>
''',
      'OEBPS/ch1.xhtml':
          '<html xmlns="http://www.w3.org/1999/xhtml"><body><p>짧은 1장</p></body></html>',
      'OEBPS/ch2.xhtml':
          '<html xmlns="http://www.w3.org/1999/xhtml"><body>${List.generate(60, (i) => '<p>2장 문단 $i — 화면 크기 윈도잉 테스트용 채움 텍스트</p>').join()}</body></html>',
      'OEBPS/ch3.xhtml':
          '<html xmlns="http://www.w3.org/1999/xhtml"><body><p>짧은 3장</p></body></html>',
    });

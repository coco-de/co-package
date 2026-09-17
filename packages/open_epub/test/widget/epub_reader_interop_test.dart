// Story: S8.1/S8.2 (E8) — EpubReader 페이지·위치·viewport 콜백 (open-board 연동)

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_epub_engine/src/api/epub_position.dart';
import 'package:open_epub_engine/src/api/epub_source.dart';
import 'package:open_epub/src/presentation/engine/reflowable/reflowable_engine.dart';
import 'package:open_epub/src/presentation/engine/reflowable/reflowable_page_view.dart';
import 'package:open_epub/src/presentation/widgets/epub_reader.dart';

import 'package:open_epub_engine/testing.dart';

void main() {
  testWidgets('paged EpubReader가 초기 페이지·위치·viewport를 보고한다', (tester) async {
    final pages = <List<int>>[];
    final positions = <EpubPosition>[];
    Size? viewport;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EpubReader(
            source: EpubSource.bytes(searchableEpub3()),
            paged: true,
            onPageChanged: (index, count) => pages.add([index, count]),
            onPositionChanged: positions.add,
            onViewportChanged: (size) => viewport = size,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(pages, isNotEmpty);
    expect(pages.first, [0, 3]); // 첫 spine, 총 3개
    expect(positions, isNotEmpty);
    expect(positions.first.spineHref, 'ch1.xhtml');
    expect(viewport, isNotNull);
    expect(viewport!.width, greaterThan(0));
  });

  testWidgets('스와이프 시 페이지 전환이 보고된다', (tester) async {
    final pages = <int>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EpubReader(
            source: EpubSource.bytes(searchableEpub3()),
            paged: true,
            onPageChanged: (index, _) => pages.add(index),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.fling(find.byType(PageView), const Offset(-500, 0), 1500);
    await tester.pumpAndSettle();

    expect(pages.last, 1); // 2번째 spine으로 전환
  });

  // open-epub 위치 복원 정확도 개선 — 재진입 시 위치 복원이 챕터(spine)
  // 단위로만 동작하던 문제. fixedPageSize 없이도 같은 챕터 내 윈도우 이동이
  // 위치로 저장·복원되는지 검증한다.
  testWidgets(
      'paged 모드(fixedPageSize 없음)에서도 같은 챕터 내 윈도우 이동이 저장·복원된다',
      (tester) async {
    final source = largeEpub3(chapters: 2, paragraphsPerChapter: 60);
    final positions = <EpubPosition>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EpubReader(
            source: EpubSource.bytes(source),
            paged: true,
            onPositionChanged: positions.add,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.fling(
      find.byType(ReflowablePageView),
      const Offset(-500, 0),
      1500,
    );
    await tester.pumpAndSettle();

    final pageState = tester.state<ReflowablePageViewState>(
      find.byType(ReflowablePageView),
    );
    // 같은 챕터(첫 spine) 안에서 윈도우만 이동했는지 먼저 확인 — spine
    // 전환이면 이 테스트가 의도한 시나리오(챕터 내부 이동)가 아니다.
    expect(pageState.windowIndex, greaterThan(0));

    final saved = positions.last as EpubReflowablePosition;
    expect(saved.spineHref, 'ch1.xhtml');
    expect(saved.pageIndex, pageState.windowIndex);

    // 재진입 — 저장된 위치로 새 EpubReader를 마운트.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EpubReader(
            source: EpubSource.bytes(source),
            paged: true,
            initialPosition: saved,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final restoredState = tester.state<ReflowablePageViewState>(
      find.byType(ReflowablePageView),
    );
    expect(restoredState.windowIndex, saved.pageIndex);
  });

  testWidgets('스크롤(기본) 모드에서도 같은 챕터 내부 스크롤 위치가 저장·복원된다',
      (tester) async {
    final source = largeEpub3(chapters: 2, paragraphsPerChapter: 60);
    final positions = <EpubPosition>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EpubReader(
            source: EpubSource.bytes(source),
            onPositionChanged: positions.add,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 화면 여러 장 분량을 위로 드래그해 첫 챕터 내부 깊숙이 스크롤한다
    // (챕터 경계는 넘지 않을 만큼).
    await tester.drag(
      find.byType(ReflowableEngine),
      const Offset(0, -1500),
      touchSlopY: 0,
    );
    await tester.pumpAndSettle();

    final engineState = tester.state<ReflowableEngineState>(
      find.byType(ReflowableEngine),
    );
    expect(engineState.spineIndex, 0); // 아직 첫 챕터 — 챕터 경계는 안 넘음
    expect(engineState.currentAlignment, lessThan(0)); // 챕터 안쪽으로 스크롤됨

    final saved = positions.last as EpubReflowablePosition;
    expect(saved.spineHref, 'ch1.xhtml');
    expect(saved.scrollAlignment, isNotNull);
    expect(saved.scrollAlignment, closeTo(engineState.currentAlignment, 0.01));

    // 재진입 — 저장된 위치로 새 EpubReader를 마운트하면 챕터 시작이 아니라
    // 저장했던 스크롤 위치 근처에서 시작해야 한다.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EpubReader(
            source: EpubSource.bytes(source),
            initialPosition: saved,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final restoredState = tester.state<ReflowableEngineState>(
      find.byType(ReflowableEngine),
    );
    expect(restoredState.spineIndex, 0);
    expect(
      restoredState.currentAlignment,
      closeTo(saved.scrollAlignment!, 0.01),
    );
  });
}

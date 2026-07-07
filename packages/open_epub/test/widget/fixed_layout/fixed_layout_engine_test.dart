// Story: S1.7 (#13) — FixedLayoutEngine + FixedLayoutPage widget tests
// BDD: F3.1 (viewport fit)

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_epub_engine/src/api/epub_book.dart';
import 'package:open_epub_engine/src/domain/entity/epub_metadata.dart';
import 'package:open_epub_engine/src/domain/entity/epub_outline.dart';
import 'package:open_epub_engine/src/domain/entity/epub_spine_item.dart';
import 'package:open_epub/src/presentation/engine/fixed_layout/fixed_layout_engine.dart';
import 'package:open_epub/src/presentation/engine/fixed_layout/fixed_layout_page.dart';

void main() {
  group('FixedLayoutPage — viewport fit (BDD F3.1)', () {
    testWidgets('logical 1024×768 → viewport 400×300 contain fit',
        (tester) async {
      const contentKey = Key('content');
      await tester.pumpWidget(
        _wrap(
          width: 400,
          height: 300,
          child: const FixedLayoutPage(
            logicalSize: Size(1024, 768),
            content: SizedBox(
              key: contentKey,
              width: 1024,
              height: 768,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // content가 트리에 존재
      expect(find.byKey(contentKey), findsOneWidget);
      // FittedBox로 contain fit: 400/1024 ≈ 0.39, 300/768 ≈ 0.39
      // logical content의 실제 화면 크기는 logical * scale ≈ 1024*0.39 ≈ 400 / 768*0.39 ≈ 300
      // (FittedBox 안 SizedBox가 child render에 fit되므로 logical 그대로 측정)
      final renderedSize = tester.getSize(find.byKey(contentKey));
      // logical 그대로 유지 (FittedBox가 외부에서 scale 적용)
      expect(renderedSize.width, 1024);
      expect(renderedSize.height, 768);
    });

    testWidgets('content widget이 트리에 존재', (tester) async {
      await tester.pumpWidget(
        _wrap(
          width: 400,
          height: 400,
          child: const FixedLayoutPage(
            logicalSize: Size(100, 100),
            content: Text('Page Content'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Page Content'), findsOneWidget);
    });

    testWidgets('logicalSize 0 → safe default scale 적용', (tester) async {
      await tester.pumpWidget(
        _wrap(
          width: 400,
          height: 400,
          child: const FixedLayoutPage(
            logicalSize: Size(0, 0),
            content: Text('zero'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // 에러 없이 빌드되어야 함
      expect(find.text('zero'), findsOneWidget);
    });
  });

  group('FixedLayoutEngine — spine 표시 + 이동', () {
    testWidgets('initialSpineIndex의 페이지 표시', (tester) async {
      final book = _fakeBook(['p1.xhtml', 'p2.xhtml', 'p3.xhtml']);
      await tester.pumpWidget(
        _wrap(
          width: 400,
          height: 600,
          child: FixedLayoutEngine(
            book: book,
            initialSpineIndex: 1,
            pageBuilder: (item) async => FixedLayoutPageData(
              logicalSize: const Size(800, 600),
              content: Text(item.href),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('p2.xhtml'), findsOneWidget);
    });

    testWidgets('nextSpine() / previousSpine() 으로 이동', (tester) async {
      final book = _fakeBook(['a.xhtml', 'b.xhtml', 'c.xhtml']);
      await tester.pumpWidget(
        _wrap(
          width: 400,
          height: 600,
          child: FixedLayoutEngine(
            book: book,
            pageBuilder: (item) async => FixedLayoutPageData(
              logicalSize: const Size(800, 600),
              content: Text(item.href),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final state = tester.state<FixedLayoutEngineState>(
        find.byType(FixedLayoutEngine),
      );

      expect(state.spineIndex, 0);
      expect(state.spineCount, 3);
      expect(find.text('a.xhtml'), findsOneWidget);

      expect(state.nextSpine(), isTrue);
      await tester.pumpAndSettle();
      expect(state.spineIndex, 1);
      expect(find.text('b.xhtml'), findsOneWidget);

      expect(state.nextSpine(), isTrue);
      await tester.pumpAndSettle();
      expect(state.spineIndex, 2);

      // 끝
      expect(state.nextSpine(), isFalse);

      expect(state.previousSpine(), isTrue);
      await tester.pumpAndSettle();
      expect(state.spineIndex, 1);

      expect(state.previousSpine(), isTrue);
      await tester.pumpAndSettle();
      expect(state.spineIndex, 0);

      // 시작
      expect(state.previousSpine(), isFalse);
    });

    testWidgets('initialSpineIndex 범위 초과 시 clamp', (tester) async {
      final book = _fakeBook(['a.xhtml', 'b.xhtml']);
      await tester.pumpWidget(
        _wrap(
          width: 400,
          height: 600,
          child: FixedLayoutEngine(
            book: book,
            initialSpineIndex: 99,
            pageBuilder: (item) async => FixedLayoutPageData(
              logicalSize: const Size(800, 600),
              content: Text(item.href),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final state = tester.state<FixedLayoutEngineState>(
        find.byType(FixedLayoutEngine),
      );
      expect(state.spineIndex, 1);
    });

    testWidgets('spine이 비어 있으면 empty state', (tester) async {
      final book = _fakeBook([]);
      await tester.pumpWidget(
        _wrap(
          width: 400,
          height: 600,
          child: FixedLayoutEngine(
            book: book,
            pageBuilder: (_) async => const FixedLayoutPageData(
              logicalSize: Size(1, 1),
              content: SizedBox(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('표시할 내용이 없습니다'), findsOneWidget);
    });

    testWidgets('pageBuilder가 throw 시 에러 메시지', (tester) async {
      final book = _fakeBook(['p.xhtml']);
      await tester.pumpWidget(
        _wrap(
          width: 400,
          height: 600,
          child: FixedLayoutEngine(
            book: book,
            pageBuilder: (_) async => throw Exception('decode fail'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('페이지를 불러올 수 없습니다'), findsOneWidget);
      expect(find.textContaining('decode fail'), findsOneWidget);
    });

    testWidgets('로딩 중 CircularProgressIndicator', (tester) async {
      final book = _fakeBook(['p.xhtml']);
      final completer = Completer<FixedLayoutPageData>();
      await tester.pumpWidget(
        _wrap(
          width: 400,
          height: 600,
          child: FixedLayoutEngine(
            book: book,
            pageBuilder: (_) => completer.future,
          ),
        ),
      );
      // settle 전 frame
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      completer.complete(
        const FixedLayoutPageData(
          logicalSize: Size(100, 100),
          content: Text('done'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('done'), findsOneWidget);
    });
  });

  // open-epub#221 후속 — EpubViewController.nextPage()/previousPage()가
  // FixedLayoutEngine에서도 spine 전체가 아니라 "표시 단위"(nextPage/
  // previousPage와 동일 — spread 렌더 중이면 row 단위)로 이동하는지 검증한다.
  group('FixedLayoutEngine — onPageStepReady (open-epub#221 후속)', () {
    testWidgets('step(+1)/step(-1)이 nextPage()/previousPage()와 동일하게 이동한다',
        (tester) async {
      final book = _fakeBook(['a.xhtml', 'b.xhtml', 'c.xhtml']);
      Future<void> Function(int direction)? step;
      await tester.pumpWidget(
        _wrap(
          width: 400,
          height: 600,
          child: FixedLayoutEngine(
            book: book,
            pageBuilder: (item) async => FixedLayoutPageData(
              logicalSize: const Size(800, 600),
              content: Text(item.href),
            ),
            onPageStepReady: (s) => step = s,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(step, isNotNull);

      final state = tester.state<FixedLayoutEngineState>(
        find.byType(FixedLayoutEngine),
      );
      expect(state.spineIndex, 0);

      await step!(1);
      await tester.pumpAndSettle();
      expect(state.spineIndex, 1);
      expect(find.text('b.xhtml'), findsOneWidget);

      await step!(-1);
      await tester.pumpAndSettle();
      expect(state.spineIndex, 0);
      expect(find.text('a.xhtml'), findsOneWidget);
    });
  });

  group('FixedLayoutEngine — breakpoint 재마운트 방지 (S9.2 #66)', () {
    testWidgets('single↔spread 리사이즈 시 로드된 페이지의 pageBuilder 재호출/줌 초기화 없음',
        (tester) async {
      // breakpoint(1024px)를 실제로 넘나들려면 SizedBox가 아니라 뷰 크기 자체를
      // 바꿔야 한다(SizedBox는 화면 폭에 클램프됨).
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final calls = <String, int>{};
      final book = _fakeBook(['p1.xhtml', 'p2.xhtml', 'p3.xhtml', 'p4.xhtml']);
      final engine = FixedLayoutEngine(
        book: book,
        spreadOverride: EpubSpread.auto,
        pageBuilder: (item) async {
          calls[item.href] = (calls[item.href] ?? 0) + 1;
          return FixedLayoutPageData(
            logicalSize: const Size(800, 600),
            content: Text(item.href),
          );
        },
      );
      final app = MaterialApp(home: Scaffold(body: engine));

      Future<void> resizeTo(double width) async {
        tester.view.physicalSize = Size(width, 800);
        await tester.pumpWidget(app);
        await tester.pumpAndSettle();
      }

      // 좁은 화면(<1024px) → 단일 페이지. p1만 로드.
      await resizeTo(800);
      expect(find.text('p1.xhtml'), findsOneWidget);
      expect(find.text('p2.xhtml'), findsNothing);
      expect(calls['p1.xhtml'], 1);

      // p1을 2.0x로 줌.
      final p1State1 = _pageStateFor(tester, 'p1.xhtml');
      p1State1.controller.value = Matrix4.identity()..scaleByDouble(2, 2, 2, 1);
      await tester.pump();
      expect(p1State1.currentScale, closeTo(2, 0.001));

      // 넓은 화면(≥1024px) → 2-page spread(p1,p2). p1 재로딩 없음, p2 신규 로드.
      await resizeTo(1200);
      expect(find.text('p1.xhtml'), findsOneWidget);
      expect(find.text('p2.xhtml'), findsOneWidget);
      expect(calls['p1.xhtml'], 1, reason: 'p1은 재마운트/재로딩되지 않아야 한다');
      expect(calls['p2.xhtml'], 1);

      // 같은 State가 이전(reparent)되어 줌 상태가 보존된다.
      final p1State2 = _pageStateFor(tester, 'p1.xhtml');
      expect(identical(p1State1, p1State2), isTrue,
          reason: 'GlobalKey로 element State가 이전(remount 아님)되어야 한다');
      expect(p1State2.currentScale, closeTo(2, 0.001),
          reason: 'TransformationController(줌/팬) 상태가 유지되어야 한다');

      // 다시 좁은 화면 → 단일. 여전히 p1 재로딩/줌 초기화 없음.
      await resizeTo(800);
      expect(calls['p1.xhtml'], 1);
      final p1State3 = _pageStateFor(tester, 'p1.xhtml');
      expect(identical(p1State1, p1State3), isTrue);
      expect(p1State3.currentScale, closeTo(2, 0.001));
    });
  });
}

// -------- helpers --------

/// [href] 콘텐츠를 렌더 중인 FixedLayoutPage의 State를 찾는다.
FixedLayoutPageState _pageStateFor(WidgetTester tester, String href) =>
    tester.state<FixedLayoutPageState>(
      find.ancestor(
        of: find.text(href),
        matching: find.byType(FixedLayoutPage),
      ),
    );

Widget _wrap({
  required double width,
  required double height,
  required Widget child,
}) =>
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(width: width, height: height, child: child),
        ),
      ),
    );

EpubBook _fakeBook(List<String> hrefs) => _FakeEpubBook(
      spine: hrefs
          .map((h) => EpubSpineItem(
              idref: h, href: h, mediaType: 'application/xhtml+xml'))
          .toList(growable: false),
    );

class _FakeEpubBook implements EpubBook {
  _FakeEpubBook({required this.spine});
  @override
  final List<EpubSpineItem> spine;
  @override
  EpubMetadata get metadata => const EpubMetadata(
        title: 'fake',
        epubVersion: '3.0',
        layout: EpubLayout.fixedLayout,
      );
  @override
  EpubOutline get outline => EpubOutline.empty;
  @override
  EpubLayout get layout => EpubLayout.fixedLayout;
}

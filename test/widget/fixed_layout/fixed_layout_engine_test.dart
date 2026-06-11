// Story: S1.7 (#13) — FixedLayoutEngine + FixedLayoutPage widget tests
// BDD: F3.1 (viewport fit)

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_epub/src/api/epub_book.dart';
import 'package:open_epub/src/domain/entity/epub_metadata.dart';
import 'package:open_epub/src/domain/entity/epub_outline.dart';
import 'package:open_epub/src/domain/entity/epub_spine_item.dart';
import 'package:open_epub/src/presentation/engine/fixed_layout/fixed_layout_engine.dart';
import 'package:open_epub/src/presentation/engine/fixed_layout/fixed_layout_page.dart';

void main() {
  group('FixedLayoutPage — viewport fit (BDD F3.1)', () {
    testWidgets('logical 1024×768 → viewport 400×300 contain fit', (tester) async {
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
}

// -------- helpers --------

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
          .map((h) => EpubSpineItem(idref: h, href: h, mediaType: 'application/xhtml+xml'))
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

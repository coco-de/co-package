// Story: S1.9 (#15) — FixedLayoutEngine spread mode widget tests
// BDD: F3.3 (auto spread 1024px breakpoint), F3.5 (L/R 슬롯 존중)

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_epub/src/api/epub_book.dart';
import 'package:open_epub/src/domain/entity/epub_metadata.dart';
import 'package:open_epub/src/domain/entity/epub_outline.dart';
import 'package:open_epub/src/domain/entity/epub_spine_item.dart';
import 'package:open_epub/src/presentation/engine/fixed_layout/fixed_layout_engine.dart';

void main() {
  group('FixedLayoutEngine — auto spread breakpoint (BDD F3.3)', () {
    testWidgets('screenWidth < 1024 + spread:auto → 1-page (Row 없음)', (tester) async {
      final book = _fakeBook(
        spread: EpubSpread.auto,
        spine: const [('a', []), ('b', [])],
      );
      await tester.pumpWidget(_wrap(
        width: 800,
        height: 600,
        child: FixedLayoutEngine(
          book: book,
          pageBuilder: (item) async => FixedLayoutPageData(
            logicalSize: const Size(400, 600),
            content: Text(item.href),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('a.xhtml'), findsOneWidget);
      expect(find.text('b.xhtml'), findsNothing);
    });

    testWidgets('screenWidth ≥ 1024 + spread:auto → 2-page (Row + L/R)', (tester) async {
      await _setViewSize(tester, 1200, 800);
      final book = _fakeBook(
        spread: EpubSpread.auto,
        spine: const [('a', []), ('b', [])],
      );
      await tester.pumpWidget(_wrap(
        width: 1200,
        height: 800,
        child: FixedLayoutEngine(
          book: book,
          pageBuilder: (item) async => FixedLayoutPageData(
            logicalSize: const Size(400, 600),
            content: Text(item.href),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('a.xhtml'), findsOneWidget);
      expect(find.text('b.xhtml'), findsOneWidget);
    });

    testWidgets('spread:none → 항상 1-page (큰 화면에서도)', (tester) async {
      await _setViewSize(tester, 1400, 900);
      final book = _fakeBook(
        spread: EpubSpread.none,
        spine: const [('a', []), ('b', [])],
      );
      await tester.pumpWidget(_wrap(
        width: 1400,
        height: 900,
        child: FixedLayoutEngine(
          book: book,
          pageBuilder: (item) async => FixedLayoutPageData(
            logicalSize: const Size(400, 600),
            content: Text(item.href),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('a.xhtml'), findsOneWidget);
      expect(find.text('b.xhtml'), findsNothing);
    });

    testWidgets('spread:both → 항상 2-page (작은 화면에서도)', (tester) async {
      final book = _fakeBook(
        spread: EpubSpread.both,
        spine: const [('a', []), ('b', [])],
      );
      await tester.pumpWidget(_wrap(
        width: 400,
        height: 600,
        child: FixedLayoutEngine(
          book: book,
          pageBuilder: (item) async => FixedLayoutPageData(
            logicalSize: const Size(400, 600),
            content: Text(item.href),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('a.xhtml'), findsOneWidget);
      expect(find.text('b.xhtml'), findsOneWidget);
    });

    testWidgets('spreadOverride가 metadata.spread를 우선', (tester) async {
      await _setViewSize(tester, 1200, 800);
      final book = _fakeBook(
        spread: EpubSpread.auto, // metadata는 auto이지만
        spine: const [('a', []), ('b', [])],
      );
      await tester.pumpWidget(_wrap(
        width: 1200, // auto면 2-page지만 override:none이면 1-page
        height: 800,
        child: FixedLayoutEngine(
          book: book,
          spreadOverride: EpubSpread.none,
          pageBuilder: (item) async => FixedLayoutPageData(
            logicalSize: const Size(400, 600),
            content: Text(item.href),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('a.xhtml'), findsOneWidget);
      expect(find.text('b.xhtml'), findsNothing);
    });
  });

  group('FixedLayoutEngine — L/R 슬롯 존중 (BDD F3.5)', () {
    testWidgets('page-spread-left 명시된 첫 항목 → row의 left slot', (tester) async {
      await _setViewSize(tester, 1200, 800);
      final book = _fakeBook(
        spread: EpubSpread.both,
        spine: const [
          ('a', ['page-spread-left']),
          ('b', ['page-spread-right']),
        ],
      );
      await tester.pumpWidget(_wrap(
        width: 1200,
        height: 800,
        child: FixedLayoutEngine(
          book: book,
          pageBuilder: (item) async => FixedLayoutPageData(
            logicalSize: const Size(400, 600),
            content: Text(item.href),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      // a가 row의 첫 Expanded(=left), b가 두번째(=right)에 위치
      final aPos = tester.getTopLeft(find.text('a.xhtml'));
      final bPos = tester.getTopLeft(find.text('b.xhtml'));
      expect(aPos.dx, lessThan(bPos.dx));
    });

    testWidgets('첫 항목이 page-spread-right → left가 빈 슬롯 (cover 시작)',
        (tester) async {
      await _setViewSize(tester, 1200, 800);
      final book = _fakeBook(
        spread: EpubSpread.both,
        spine: const [
          ('cover', ['page-spread-right']),
          ('p1', []),
          ('p2', []),
        ],
      );
      await tester.pumpWidget(_wrap(
        width: 1200,
        height: 800,
        child: FixedLayoutEngine(
          book: book,
          pageBuilder: (item) async => FixedLayoutPageData(
            logicalSize: const Size(400, 600),
            content: Text(item.href),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      // 첫 row: left=빈, right=cover → cover만 보인다
      expect(find.text('cover.xhtml'), findsOneWidget);
      expect(find.text('p1.xhtml'), findsNothing);
    });

    testWidgets('rendition:page-spread-center → 단독 row (다른 페이지 없음)', (tester) async {
      await _setViewSize(tester, 1200, 800);
      final book = _fakeBook(
        spread: EpubSpread.both,
        spine: const [
          ('cover', ['rendition:page-spread-center']),
          ('p1', []),
          ('p2', []),
        ],
      );
      await tester.pumpWidget(_wrap(
        width: 1200,
        height: 800,
        child: FixedLayoutEngine(
          book: book,
          pageBuilder: (item) async => FixedLayoutPageData(
            logicalSize: const Size(400, 600),
            content: Text(item.href),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      // cover만 보임 (center row)
      expect(find.text('cover.xhtml'), findsOneWidget);
      expect(find.text('p1.xhtml'), findsNothing);
      expect(find.text('p2.xhtml'), findsNothing);

      // 다음 row로 이동하면 p1+p2
      final state = tester.state<FixedLayoutEngineState>(
        find.byType(FixedLayoutEngine),
      );
      expect(state.nextSpine(), isTrue); // cover → p1
      await tester.pumpAndSettle();
      expect(find.text('p1.xhtml'), findsOneWidget);
      expect(find.text('p2.xhtml'), findsOneWidget);
      expect(find.text('cover.xhtml'), findsNothing);
    });
  });

  group('FixedLayoutEngine — rowIndex 관리', () {
    testWidgets('초기 rowIndex가 spineIndex 0의 row를 가리킴', (tester) async {
      await _setViewSize(tester, 1200, 800);
      final book = _fakeBook(
        spread: EpubSpread.both,
        spine: const [('a', []), ('b', []), ('c', []), ('d', [])],
      );
      await tester.pumpWidget(_wrap(
        width: 1200,
        height: 800,
        child: FixedLayoutEngine(
          book: book,
          pageBuilder: (item) async => FixedLayoutPageData(
            logicalSize: const Size(400, 600),
            content: Text(item.href),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      final state = tester.state<FixedLayoutEngineState>(
        find.byType(FixedLayoutEngine),
      );
      expect(state.rowIndex, 0);
      expect(state.rowCount, 2); // [a,b][c,d]
    });

    testWidgets('nextSpine 진행 시 rowIndex 갱신 (a→b 같은 row 유지)', (tester) async {
      await _setViewSize(tester, 1200, 800);
      final book = _fakeBook(
        spread: EpubSpread.both,
        spine: const [('a', []), ('b', []), ('c', []), ('d', [])],
      );
      await tester.pumpWidget(_wrap(
        width: 1200,
        height: 800,
        child: FixedLayoutEngine(
          book: book,
          pageBuilder: (item) async => FixedLayoutPageData(
            logicalSize: const Size(400, 600),
            content: Text(item.href),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      final state = tester.state<FixedLayoutEngineState>(
        find.byType(FixedLayoutEngine),
      );

      // a→b: 같은 row 0
      expect(state.nextSpine(), isTrue);
      await tester.pumpAndSettle();
      expect(state.spineIndex, 1);
      expect(state.rowIndex, 0);

      // b→c: row 1로 이동
      expect(state.nextSpine(), isTrue);
      await tester.pumpAndSettle();
      expect(state.spineIndex, 2);
      expect(state.rowIndex, 1);
    });
  });
}

// -------- helpers --------

/// tester 화면 view를 [width] × [height]로 강제. 호출 후 끝에서 자동 reset.
Future<void> _setViewSize(WidgetTester tester, double width, double height) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

Widget _wrap({
  required double width,
  required double height,
  required Widget child,
}) =>
    MaterialApp(
      home: Scaffold(
        body: SizedBox(width: width, height: height, child: child),
      ),
    );

EpubBook _fakeBook({
  required EpubSpread spread,
  required List<(String, List<String>)> spine,
}) =>
    _FakeEpubBook(
      spread: spread,
      spine: [
        for (final (id, props) in spine)
          EpubSpineItem(
            idref: id,
            href: '$id.xhtml',
            mediaType: 'application/xhtml+xml',
            properties: props,
          ),
      ],
    );

class _FakeEpubBook implements EpubBook {
  _FakeEpubBook({required this.spine, required EpubSpread spread})
      : metadata = EpubMetadata(
          title: 'fake',
          epubVersion: '3.0',
          layout: EpubLayout.fixedLayout,
          spread: spread,
        );
  @override
  final List<EpubSpineItem> spine;
  @override
  final EpubMetadata metadata;
  @override
  EpubOutline get outline => EpubOutline.empty;
  @override
  EpubLayout get layout => EpubLayout.fixedLayout;
}

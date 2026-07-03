// kobic#7576 — FixedLayoutEngine 페이지 내비게이션 widget tests
// - jumpToSpine / onSpineChanged / onNavigatorReady 배선
// - nextPage/previousPage의 spread row 단위 이동
// - 줌 1.0x 수평 fling 스와이프 페이지 넘김 (InteractiveViewer onInteractionEnd)

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_epub_engine/src/api/epub_book.dart';
import 'package:open_epub_engine/src/domain/entity/epub_metadata.dart';
import 'package:open_epub_engine/src/domain/entity/epub_outline.dart';
import 'package:open_epub_engine/src/domain/entity/epub_spine_item.dart';
import 'package:open_epub/src/presentation/engine/fixed_layout/fixed_layout_engine.dart';

void main() {
  group('FixedLayoutEngine — jumpToSpine / onSpineChanged (kobic#7576)', () {
    testWidgets('jumpToSpine이 spineIndex·rowIndex를 갱신하고 통지한다', (tester) async {
      final changed = <int>[];
      final book = _fakeBook(
        spread: EpubSpread.none,
        spine: const [('a', []), ('b', []), ('c', [])],
      );
      await tester.pumpWidget(_wrap(
        width: 400,
        height: 600,
        child: FixedLayoutEngine(
          book: book,
          pageBuilder: _textPageBuilder,
          onSpineChanged: changed.add,
        ),
      ));
      await tester.pumpAndSettle();

      final state = tester.state<FixedLayoutEngineState>(
        find.byType(FixedLayoutEngine),
      );
      state.jumpToSpine(2);
      await tester.pumpAndSettle();

      expect(state.spineIndex, 2);
      expect(find.text('c.xhtml'), findsOneWidget);
      expect(changed, [2]);
    });

    testWidgets('jumpToSpine은 범위 밖 인덱스를 클램프하고 동일 인덱스는 no-op', (tester) async {
      final changed = <int>[];
      final book = _fakeBook(
        spread: EpubSpread.none,
        spine: const [('a', []), ('b', [])],
      );
      await tester.pumpWidget(_wrap(
        width: 400,
        height: 600,
        child: FixedLayoutEngine(
          book: book,
          pageBuilder: _textPageBuilder,
          onSpineChanged: changed.add,
        ),
      ));
      await tester.pumpAndSettle();

      final state = tester.state<FixedLayoutEngineState>(
        find.byType(FixedLayoutEngine),
      );
      state.jumpToSpine(99); // → 1로 클램프
      await tester.pumpAndSettle();
      expect(state.spineIndex, 1);

      state.jumpToSpine(1); // 동일 인덱스 → 통지 없음
      await tester.pumpAndSettle();
      expect(changed, [1]);
    });

    testWidgets('onNavigatorReady로 받은 navigate가 spine을 이동시킨다', (tester) async {
      Future<void> Function(int index)? navigate;
      final book = _fakeBook(
        spread: EpubSpread.none,
        spine: const [('a', []), ('b', [])],
      );
      await tester.pumpWidget(_wrap(
        width: 400,
        height: 600,
        child: FixedLayoutEngine(
          book: book,
          pageBuilder: _textPageBuilder,
          onNavigatorReady: (fn) => navigate = fn,
        ),
      ));
      await tester.pumpAndSettle();

      expect(navigate, isNotNull);
      await navigate!(1);
      await tester.pumpAndSettle();
      expect(find.text('b.xhtml'), findsOneWidget);
      expect(find.text('a.xhtml'), findsNothing);
    });
  });

  group('FixedLayoutEngine — nextPage/previousPage row 단위 이동', () {
    testWidgets('spread 렌더 중 nextPage는 다음 row로 이동 (2 spine 건너뜀)',
        (tester) async {
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
          pageBuilder: _textPageBuilder,
        ),
      ));
      await tester.pumpAndSettle();

      final state = tester.state<FixedLayoutEngineState>(
        find.byType(FixedLayoutEngine),
      );
      expect(state.rowIndex, 0); // [a,b]

      expect(state.nextPage(), isTrue);
      await tester.pumpAndSettle();
      expect(state.rowIndex, 1); // [c,d]
      expect(find.text('c.xhtml'), findsOneWidget);
      expect(find.text('d.xhtml'), findsOneWidget);
      expect(find.text('a.xhtml'), findsNothing);

      expect(state.nextPage(), isFalse); // 마지막 row

      expect(state.previousPage(), isTrue);
      await tester.pumpAndSettle();
      expect(state.rowIndex, 0);
      expect(find.text('a.xhtml'), findsOneWidget);
    });

    testWidgets('단면 렌더(spread:none) 중 nextPage는 spine 단위 이동', (tester) async {
      final book = _fakeBook(
        spread: EpubSpread.none,
        spine: const [('a', []), ('b', [])],
      );
      await tester.pumpWidget(_wrap(
        width: 400,
        height: 600,
        child: FixedLayoutEngine(
          book: book,
          pageBuilder: _textPageBuilder,
        ),
      ));
      await tester.pumpAndSettle();

      final state = tester.state<FixedLayoutEngineState>(
        find.byType(FixedLayoutEngine),
      );
      expect(state.nextPage(), isTrue);
      await tester.pumpAndSettle();
      expect(state.spineIndex, 1);
      expect(find.text('b.xhtml'), findsOneWidget);
    });
  });

  group('FixedLayoutEngine — 수평 fling 스와이프 페이지 넘김', () {
    testWidgets('줌 1.0x에서 좌측 fling → 다음 페이지', (tester) async {
      final book = _fakeBook(
        spread: EpubSpread.none,
        spine: const [('a', []), ('b', [])],
      );
      await tester.pumpWidget(_wrap(
        width: 400,
        height: 600,
        child: FixedLayoutEngine(
          book: book,
          pageBuilder: _textPageBuilder,
        ),
      ));
      await tester.pumpAndSettle();

      await tester.fling(
        find.text('a.xhtml'),
        const Offset(-200, 0),
        1000,
      );
      await tester.pumpAndSettle();

      expect(find.text('b.xhtml'), findsOneWidget);
      expect(find.text('a.xhtml'), findsNothing);

      // 우측 fling → 이전 페이지 복귀
      await tester.fling(
        find.text('b.xhtml'),
        const Offset(200, 0),
        1000,
      );
      await tester.pumpAndSettle();
      expect(find.text('a.xhtml'), findsOneWidget);
    });

    testWidgets('enableZoom=false면 스와이프 미동작 (드로잉 제스처 보호)', (tester) async {
      final book = _fakeBook(
        spread: EpubSpread.none,
        spine: const [('a', []), ('b', [])],
      );
      await tester.pumpWidget(_wrap(
        width: 400,
        height: 600,
        child: FixedLayoutEngine(
          book: book,
          pageBuilder: _textPageBuilder,
          enableZoom: false,
        ),
      ));
      await tester.pumpAndSettle();

      await tester.fling(
        find.text('a.xhtml'),
        const Offset(-200, 0),
        1000,
      );
      await tester.pumpAndSettle();
      expect(find.text('a.xhtml'), findsOneWidget);
      expect(find.text('b.xhtml'), findsNothing);
    });
  });
}

// -------- helpers --------

Future<FixedLayoutPageData> _textPageBuilder(EpubSpineItem item) async =>
    FixedLayoutPageData(
      logicalSize: const Size(400, 600),
      content: Text(item.href),
    );

Future<void> _setViewSize(
    WidgetTester tester, double width, double height) async {
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

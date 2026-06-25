// Story: S8.6 (E8) — fixed-layout 전경 오버레이 builder seam
// open-board 절대좌표 필기 캔버스를 페이지 논리 좌표 공간에 합성하기 위한
// FixedLayoutPage / FixedLayoutEngine / EpubReader 의 foregroundBuilder.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_epub/src/api/epub_book.dart';
import 'package:open_epub/src/domain/entity/epub_metadata.dart';
import 'package:open_epub/src/domain/entity/epub_outline.dart';
import 'package:open_epub/src/domain/entity/epub_spine_item.dart';
import 'package:open_epub/src/presentation/engine/fixed_layout/fixed_layout_engine.dart';
import 'package:open_epub/src/presentation/engine/fixed_layout/fixed_layout_page.dart';

void main() {
  group('FixedLayoutPage.foregroundBuilder (S8.6)', () {
    testWidgets('전경 오버레이를 content 위에 같은 논리 크기로 합성한다', (tester) async {
      const overlayKey = Key('overlay');
      Size? capturedSize;

      await tester.pumpWidget(
        _wrap(
          width: 400,
          height: 300,
          child: FixedLayoutPage(
            logicalSize: const Size(600, 800),
            content: const SizedBox(width: 600, height: 800),
            foregroundBuilder: (context, logicalSize) {
              capturedSize = logicalSize;
              return const SizedBox.expand(
                key: overlayKey,
                child: ColoredBox(color: Color(0x11000000)),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 오버레이가 트리에 존재하고 페이지 논리 크기를 전달받는다.
      expect(find.byKey(overlayKey), findsOneWidget);
      expect(capturedSize, const Size(600, 800));

      // 오버레이는 content와 같은 논리 좌표(600×800)로 배치된다.
      expect(tester.getSize(find.byKey(overlayKey)), const Size(600, 800));
    });

    testWidgets('foregroundBuilder가 null이면 오버레이가 없다', (tester) async {
      const overlayKey = Key('overlay');
      await tester.pumpWidget(
        _wrap(
          width: 400,
          height: 300,
          child: const FixedLayoutPage(
            logicalSize: Size(600, 800),
            content: SizedBox(width: 600, height: 800),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(overlayKey), findsNothing);
    });

    testWidgets('enableZoom: false면 InteractiveViewer를 비활성화한다(드로잉 잠금)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          width: 400,
          height: 300,
          child: FixedLayoutPage(
            logicalSize: const Size(600, 800),
            content: const SizedBox(width: 600, height: 800),
            enableZoom: false,
            foregroundBuilder: (context, logicalSize) =>
                const SizedBox.expand(key: Key('overlay')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(InteractiveViewer), findsNothing);
      expect(find.byKey(const Key('overlay')), findsOneWidget);
    });
  });

  group('FixedLayoutEngine.foregroundBuilder (S8.6)', () {
    testWidgets('현재 spine item과 논리 크기를 받아 각 페이지 위에 합성한다', (tester) async {
      final book = _fakeBook(['a.xhtml', 'b.xhtml']);
      EpubSpineItem? capturedItem;
      Size? capturedSize;

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
            foregroundBuilder: (context, item, logicalSize) {
              capturedItem = item;
              capturedSize = logicalSize;
              return const SizedBox.expand(key: Key('fg'));
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('fg')), findsOneWidget);
      expect(capturedItem?.href, 'a.xhtml');
      expect(capturedSize, const Size(800, 600));

      // 페이지 전환 시 오버레이 빌더가 새 spine으로 다시 호출된다.
      final state = tester.state<FixedLayoutEngineState>(
        find.byType(FixedLayoutEngine),
      );
      expect(state.nextSpine(), isTrue);
      await tester.pumpAndSettle();
      expect(capturedItem?.href, 'b.xhtml');
    });

    testWidgets('enableZoom: false가 페이지까지 전달된다', (tester) async {
      final book = _fakeBook(['a.xhtml']);
      await tester.pumpWidget(
        _wrap(
          width: 400,
          height: 600,
          child: FixedLayoutEngine(
            book: book,
            enableZoom: false,
            pageBuilder: (item) async => FixedLayoutPageData(
              logicalSize: const Size(800, 600),
              content: Text(item.href),
            ),
            foregroundBuilder: (context, item, logicalSize) =>
                const SizedBox.expand(key: Key('fg')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(InteractiveViewer), findsNothing);
      expect(find.byKey(const Key('fg')), findsOneWidget);
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
          .map(
            (h) => EpubSpineItem(
              idref: h,
              href: h,
              mediaType: 'application/xhtml+xml',
            ),
          )
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

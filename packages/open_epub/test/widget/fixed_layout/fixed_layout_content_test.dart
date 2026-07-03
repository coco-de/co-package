// Story: S8.6 (E8) — fixed-layout 콘텐츠 wrapper builder seam
// open-board 절대좌표 필기 캔버스가 페이지 content를 child로 받아 논리 좌표
// 공간에 필기를 얹기 위한 FixedLayoutPage / FixedLayoutEngine / EpubReader 의
// contentBuilder.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_epub/src/api/epub_book.dart';
import 'package:open_epub/src/domain/entity/epub_metadata.dart';
import 'package:open_epub/src/domain/entity/epub_outline.dart';
import 'package:open_epub/src/domain/entity/epub_spine_item.dart';
import 'package:open_epub/src/presentation/engine/fixed_layout/fixed_layout_engine.dart';
import 'package:open_epub/src/presentation/engine/fixed_layout/fixed_layout_page.dart';

void main() {
  group('FixedLayoutPage.contentBuilder (S8.6)', () {
    testWidgets('content를 같은 논리 크기로 감싸 치환한다', (tester) async {
      const contentKey = Key('content');
      const wrapKey = Key('wrap');
      Size? capturedSize;
      Widget? capturedContent;

      await tester.pumpWidget(
        _wrap(
          width: 400,
          height: 300,
          child: FixedLayoutPage(
            logicalSize: const Size(600, 800),
            content: const SizedBox(key: contentKey, width: 600, height: 800),
            contentBuilder: (context, logicalSize, content) {
              capturedSize = logicalSize;
              capturedContent = content;
              return ColoredBox(
                key: wrapKey,
                color: const Color(0x11000000),
                child: content,
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // wrapper가 트리에 존재하고 원본 content를 child로 받는다.
      expect(find.byKey(wrapKey), findsOneWidget);
      expect(find.byKey(contentKey), findsOneWidget);
      expect(capturedSize, const Size(600, 800));
      expect(capturedContent, isNotNull);

      // wrapper는 content와 같은 논리 좌표(600×800)로 배치된다.
      expect(tester.getSize(find.byKey(wrapKey)), const Size(600, 800));
    });

    testWidgets('contentBuilder가 null이면 content를 그대로 렌더', (tester) async {
      const wrapKey = Key('wrap');
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
      expect(find.byKey(wrapKey), findsNothing);
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
            contentBuilder: (context, logicalSize, content) =>
                ColoredBox(key: const Key('wrap'), color: const Color(0x00000000), child: content),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(InteractiveViewer), findsNothing);
      expect(find.byKey(const Key('wrap')), findsOneWidget);
    });
  });

  group('FixedLayoutEngine.contentBuilder (S8.6)', () {
    testWidgets('현재 spine item·논리 크기·content를 받아 각 페이지를 감싼다', (tester) async {
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
            contentBuilder: (context, item, logicalSize, content) {
              capturedItem = item;
              capturedSize = logicalSize;
              return ColoredBox(
                key: const Key('wrap'),
                color: const Color(0x00000000),
                child: content,
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('wrap')), findsOneWidget);
      expect(find.text('a.xhtml'), findsOneWidget);
      expect(capturedItem?.href, 'a.xhtml');
      expect(capturedSize, const Size(800, 600));

      // 페이지 전환 시 wrapper가 새 spine·content로 다시 호출된다.
      final state = tester.state<FixedLayoutEngineState>(
        find.byType(FixedLayoutEngine),
      );
      expect(state.nextSpine(), isTrue);
      await tester.pumpAndSettle();
      expect(capturedItem?.href, 'b.xhtml');
      expect(find.text('b.xhtml'), findsOneWidget);
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
            contentBuilder: (context, item, logicalSize, content) => content,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(InteractiveViewer), findsNothing);
      expect(find.text('a.xhtml'), findsOneWidget);
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

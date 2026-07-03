// Story: S1.6 (#12) — ReflowablePageView widget tests
// BDD: F2.2 (글자 크기), F2.3 (줄간격), F2.4 (페이지 전환)

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_epub_engine/src/api/epub_book.dart';
import 'package:open_epub_engine/src/domain/entity/epub_metadata.dart';
import 'package:open_epub_engine/src/domain/entity/epub_outline.dart';
import 'package:open_epub_engine/src/domain/entity/epub_spine_item.dart';
import 'package:open_epub/src/presentation/engine/reflowable/reflowable_engine.dart';
import 'package:open_epub/src/presentation/engine/reflowable/reflowable_page_view.dart';

void main() {
  group('ReflowablePageView — 페이지 모드 (BDD F2.4)', () {
    testWidgets('spine N개 → PageView로 표시, initialSpineIndex 적용',
        (tester) async {
      final book = _fakeBook(['ch01.xhtml', 'ch02.xhtml', 'ch03.xhtml']);
      await tester.pumpWidget(
        _wrap(
          ReflowablePageView(
            book: book,
            initialSpineIndex: 1,
            xhtmlLoader: (href) async => _wrapXhtml('<p>$href</p>'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final state = tester.state<ReflowablePageViewState>(
        find.byType(ReflowablePageView),
      );
      expect(state.pageIndex, 1);
      expect(state.pageCount, 3);
      expect(find.textContaining('ch02.xhtml'), findsOneWidget);
    });

    testWidgets('jumpToPage()로 페이지 이동 (animation 없음)', (tester) async {
      final book = _fakeBook(['a.xhtml', 'b.xhtml', 'c.xhtml']);
      await tester.pumpWidget(
        _wrap(
          ReflowablePageView(
            book: book,
            xhtmlLoader: (href) async => _wrapXhtml('<p>$href</p>'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final state = tester.state<ReflowablePageViewState>(
        find.byType(ReflowablePageView),
      );
      expect(state.pageIndex, 0);

      state.jumpToPage(1);
      await tester.pumpAndSettle();
      expect(state.pageIndex, 1);

      state.jumpToPage(2);
      await tester.pumpAndSettle();
      expect(state.pageIndex, 2);

      state.jumpToPage(0);
      await tester.pumpAndSettle();
      expect(state.pageIndex, 0);
    });

    testWidgets('nextPage() animation을 pump로 진행', (tester) async {
      final book = _fakeBook(['a.xhtml', 'b.xhtml']);
      await tester.pumpWidget(
        _wrap(
          ReflowablePageView(
            book: book,
            xhtmlLoader: (href) async => _wrapXhtml('<p>$href</p>'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final state = tester.state<ReflowablePageViewState>(
        find.byType(ReflowablePageView),
      );

      // fire-and-forget — Future를 await하지 않고 ticker를 직접 pump
      unawaited(state.nextPage());
      await tester.pumpAndSettle();
      expect(state.pageIndex, 1);
    });

    testWidgets('범위 밖 jumpToPage / goToPage는 무시', (tester) async {
      final book = _fakeBook(['a.xhtml', 'b.xhtml']);
      await tester.pumpWidget(
        _wrap(
          ReflowablePageView(
            book: book,
            xhtmlLoader: (href) async => _wrapXhtml('<p>$href</p>'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final state = tester.state<ReflowablePageViewState>(
        find.byType(ReflowablePageView),
      );
      state.jumpToPage(-1);
      await tester.pumpAndSettle();
      expect(state.pageIndex, 0);
      state.jumpToPage(99);
      await tester.pumpAndSettle();
      expect(state.pageIndex, 0);
    });

    testWidgets('spine이 비어 있으면 empty state', (tester) async {
      final book = _fakeBook([]);
      await tester.pumpWidget(
        _wrap(
          ReflowablePageView(
            book: book,
            xhtmlLoader: (_) async => '',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('표시할 내용이 없습니다'), findsOneWidget);
    });

    testWidgets('xhtmlLoader가 throw 시 에러 메시지 표시', (tester) async {
      final book = _fakeBook(['ch.xhtml']);
      await tester.pumpWidget(
        _wrap(
          ReflowablePageView(
            book: book,
            xhtmlLoader: (_) async => throw Exception('disk fail'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('본문을 불러올 수 없습니다'), findsOneWidget);
      expect(find.textContaining('disk fail'), findsOneWidget);
    });

    testWidgets('onPageChanged 콜백 호출', (tester) async {
      final book = _fakeBook(['a.xhtml', 'b.xhtml']);
      final pages = <int>[];
      await tester.pumpWidget(
        _wrap(
          ReflowablePageView(
            book: book,
            xhtmlLoader: (href) async => _wrapXhtml('<p>$href</p>'),
            onPageChanged: pages.add,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final state = tester.state<ReflowablePageViewState>(
        find.byType(ReflowablePageView),
      );
      state.jumpToPage(1);
      await tester.pumpAndSettle();
      expect(pages, contains(1));
    });
  });

  group('ReflowableEngine + ReflowablePageView — 글자 크기·줄간격 적용', () {
    testWidgets('fontSize property가 Html style에 반영 (ReflowableEngine)',
        (tester) async {
      final book = _fakeBook(['ch.xhtml']);
      await tester.pumpWidget(
        _wrap(
          ReflowableEngine(
            book: book,
            xhtmlLoader: (_) async => _wrapXhtml('<p>안녕</p>'),
            fontSize: 24,
            lineHeight: 2.0,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final html = tester.widget<Html>(find.byType(Html));
      final bodyStyle = html.style['body'];
      expect(bodyStyle?.fontSize?.value, 24);
      expect(bodyStyle?.lineHeight?.size, 2.0);
    });

    testWidgets('fontSize 변경 시 spineIndex 보존 (BDD F2.2)', (tester) async {
      final book = _fakeBook(['a.xhtml', 'b.xhtml', 'c.xhtml']);
      // initialSpineIndex=1로 시작
      Widget buildAt(double fontSize) => _wrap(
            ReflowablePageView(
              book: book,
              initialSpineIndex: 1,
              fontSize: fontSize,
              xhtmlLoader: (href) async => _wrapXhtml('<p>$href</p>'),
            ),
          );
      await tester.pumpWidget(buildAt(16));
      await tester.pumpAndSettle();
      var state = tester.state<ReflowablePageViewState>(
        find.byType(ReflowablePageView),
      );
      expect(state.pageIndex, 1);

      // 사용자가 페이지 이동 (page 2로) — jumpToPage 사용
      state.jumpToPage(2);
      await tester.pumpAndSettle();
      expect(state.pageIndex, 2);

      // 글자 크기 변경 → 같은 widget 트리, fontSize만 변경
      await tester.pumpWidget(_wrap(
        ReflowablePageView(
          book: book,
          initialSpineIndex: 1, // 무시되어야 함 (이미 controller 있음)
          fontSize: 24, // 변경
          xhtmlLoader: (href) async => _wrapXhtml('<p>$href</p>'),
        ),
      ));
      await tester.pumpAndSettle();
      state = tester.state<ReflowablePageViewState>(
        find.byType(ReflowablePageView),
      );
      // 현재 페이지가 보존되어야 함 (didUpdateWidget에서 book 동일이라 controller 유지)
      expect(state.pageIndex, 2);
    });

    testWidgets('book이 바뀌면 initialSpineIndex가 재적용 (PageController 재생성)',
        (tester) async {
      final bookA = _fakeBook(['a1.xhtml', 'a2.xhtml']);
      final bookB = _fakeBook(['b1.xhtml', 'b2.xhtml', 'b3.xhtml']);

      await tester.pumpWidget(_wrap(
        ReflowablePageView(
          book: bookA,
          xhtmlLoader: (href) async => _wrapXhtml('<p>$href</p>'),
        ),
      ));
      await tester.pumpAndSettle();
      var state = tester.state<ReflowablePageViewState>(
        find.byType(ReflowablePageView),
      );
      state.jumpToPage(1);
      await tester.pumpAndSettle();
      expect(state.pageIndex, 1);

      // 책 교체
      await tester.pumpWidget(_wrap(
        ReflowablePageView(
          book: bookB,
          initialSpineIndex: 2,
          xhtmlLoader: (href) async => _wrapXhtml('<p>$href</p>'),
        ),
      ));
      await tester.pumpAndSettle();
      state = tester.state<ReflowablePageViewState>(
        find.byType(ReflowablePageView),
      );
      expect(state.pageCount, 3);
      expect(state.pageIndex, 2);
    });
  });

  group('ReflowablePageView — contentRevision 캐시 무효화 (open-epub#62)', () {
    testWidgets('같은 revision rebuild는 loader 재호출 없음(캐시)', (tester) async {
      final book = _fakeBook(['ch.xhtml']);
      var loadCount = 0;
      Future<String> loader(String href) async {
        loadCount++;
        return _wrapXhtml('<p>body</p>');
      }

      final rev0 = <String>['r0'];
      Widget build(Object revision, double fontSize) => _wrap(
            ReflowablePageView(
              book: book,
              xhtmlLoader: loader,
              fontSize: fontSize,
              contentRevision: revision,
            ),
          );

      await tester.pumpWidget(build(rev0, 16));
      await tester.pumpAndSettle();
      final loadsAfterFirst = loadCount;

      // fontSize만 변경(같은 revision) → 캐시 유지.
      await tester.pumpWidget(build(rev0, 24));
      await tester.pumpAndSettle();
      expect(loadCount, loadsAfterFirst);
    });

    testWidgets('revision identity 변경 시 재로드 + 새 콘텐츠 렌더', (tester) async {
      final book = _fakeBook(['ch.xhtml']);
      var version = 0;
      Future<String> loader(String href) async =>
          _wrapXhtml('<p>revision v$version</p>');

      Widget build(Object revision) => _wrap(
            ReflowablePageView(
              book: book,
              xhtmlLoader: loader,
              contentRevision: revision,
            ),
          );

      await tester.pumpWidget(build(<String>['r0']));
      await tester.pumpAndSettle();
      expect(find.textContaining('revision v0'), findsOneWidget);

      version = 1;
      await tester.pumpWidget(build(<String>['r1']));
      await tester.pumpAndSettle();
      expect(find.textContaining('revision v1'), findsOneWidget);
    });

    testWidgets('재로드 동안 직전 콘텐츠 유지(스피너 flash 없음)', (tester) async {
      final book = _fakeBook(['ch.xhtml']);
      var delayed = false;
      final gate = Completer<void>();
      Future<String> loader(String href) async {
        if (delayed) await gate.future;
        return _wrapXhtml('<p>${delayed ? 'after' : 'before'} reload</p>');
      }

      Widget build(Object revision) => _wrap(
            ReflowablePageView(
              book: book,
              xhtmlLoader: loader,
              contentRevision: revision,
            ),
          );

      await tester.pumpWidget(build(const ['r0']));
      await tester.pumpAndSettle();
      expect(find.textContaining('before reload'), findsOneWidget);

      delayed = true;
      await tester.pumpWidget(build(const ['r1']));
      await tester.pump();
      expect(find.textContaining('before reload'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      gate.complete();
      await tester.pumpAndSettle();
      expect(find.textContaining('after reload'), findsOneWidget);
    });
  });
}

// -------- helpers --------

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(body: SizedBox(width: 400, height: 600, child: child)),
    );

String _wrapXhtml(String body) => '''
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml"><body>$body</body></html>
''';

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
  EpubMetadata get metadata =>
      const EpubMetadata(title: 'fake', epubVersion: '3.0');
  @override
  EpubOutline get outline => EpubOutline.empty;
  @override
  EpubLayout get layout => EpubLayout.reflowable;
}

// Story: S1.6 (#12) — ReflowablePageView widget tests
// BDD: F2.2 (글자 크기), F2.3 (줄간격), F2.4 (페이지 전환)

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
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
      expect(find.textContaining('ch02.xhtml', findRichText: true),
          findsOneWidget);
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
    testWidgets(
        'fontSize property가 HtmlWidget textStyle에 반영 (ReflowableEngine)',
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
      final html = tester.widget<HtmlWidget>(find.byType(HtmlWidget));
      expect(html.textStyle?.fontSize, 24);
      expect(html.textStyle?.height, 2.0);
    });

    // kobic Epic #7964 S3 — 가로 페이지 넘김 A4 고정 페이지네이션에서 고정
    // 서체가 적용되는지 회귀 방지.
    testWidgets(
        'fontFamily property가 HtmlWidget textStyle에 반영 (ReflowableEngine)',
        (tester) async {
      final book = _fakeBook(['ch.xhtml']);
      await tester.pumpWidget(
        _wrap(
          ReflowableEngine(
            book: book,
            xhtmlLoader: (_) async => _wrapXhtml('<p>안녕</p>'),
            fontFamily: 'Pretendard',
          ),
        ),
      );
      await tester.pumpAndSettle();
      final html = tester.widget<HtmlWidget>(find.byType(HtmlWidget));
      expect(html.textStyle?.fontFamily, 'Pretendard');
    });

    testWidgets(
        'fontFamily property가 HtmlWidget textStyle에 반영 (ReflowablePageView)',
        (tester) async {
      final book = _fakeBook(['ch.xhtml']);
      await tester.pumpWidget(
        _wrap(
          ReflowablePageView(
            book: book,
            xhtmlLoader: (_) async => _wrapXhtml('<p>안녕</p>'),
            fontFamily: 'Pretendard',
          ),
        ),
      );
      await tester.pumpAndSettle();
      final html = tester.widget<HtmlWidget>(find.byType(HtmlWidget));
      expect(html.textStyle?.fontFamily, 'Pretendard');
    });

    testWidgets('fontFamily 미지정(null) 시 기본 서체 유지(회귀 방지)', (tester) async {
      final book = _fakeBook(['ch.xhtml']);
      await tester.pumpWidget(
        _wrap(
          ReflowablePageView(
            book: book,
            xhtmlLoader: (_) async => _wrapXhtml('<p>안녕</p>'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final html = tester.widget<HtmlWidget>(find.byType(HtmlWidget));
      expect(html.textStyle?.fontFamily, isNull);
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
      expect(find.textContaining('revision v0', findRichText: true),
          findsOneWidget);

      version = 1;
      await tester.pumpWidget(build(<String>['r1']));
      await tester.pumpAndSettle();
      expect(find.textContaining('revision v1', findRichText: true),
          findsOneWidget);
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
      expect(find.textContaining('before reload', findRichText: true),
          findsOneWidget);

      delayed = true;
      await tester.pumpWidget(build(const ['r1']));
      await tester.pump();
      expect(find.textContaining('before reload', findRichText: true),
          findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      gate.complete();
      await tester.pumpAndSettle();
      expect(find.textContaining('after reload', findRichText: true),
          findsOneWidget);
    });
  });

  // S14.1 (#105) — RTL page-progression: paged 모드에서 넘김 방향 반전.
  group('ReflowablePageView — RTL 넘김 방향 (S14.1, F2)', () {
    testWidgets('reverse=true → PageView.reverse 반영(다음=좌향)', (tester) async {
      final book = _fakeBook(['a.xhtml', 'b.xhtml', 'c.xhtml']);
      await tester.pumpWidget(
        _wrap(
          ReflowablePageView(
            book: book,
            reverse: true,
            xhtmlLoader: (href) async => _wrapXhtml('<p>$href</p>'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final pageView = tester.widget<PageView>(find.byType(PageView));
      expect(pageView.reverse, isTrue);
    });

    testWidgets('reverse 기본값 false(LTR 회귀)', (tester) async {
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
      final pageView = tester.widget<PageView>(find.byType(PageView));
      expect(pageView.reverse, isFalse);
    });

    testWidgets('RTL이어도 페이지 인덱스 계약(다음=+1)은 불변', (tester) async {
      final book = _fakeBook(['a.xhtml', 'b.xhtml', 'c.xhtml']);
      await tester.pumpWidget(
        _wrap(
          ReflowablePageView(
            book: book,
            reverse: true,
            xhtmlLoader: (href) async => _wrapXhtml('<p>$href</p>'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final state = tester.state<ReflowablePageViewState>(
        find.byType(ReflowablePageView),
      );
      expect(state.pageIndex, 0);
      unawaited(state.nextPage());
      await tester.pumpAndSettle();
      expect(state.pageIndex, 1);
    });
  });

  // F2-Edge1 (flow-permutation): Reflowable 모드에서 글자 크기 변경 직후 페이지
  // 전환 → 새 페이지네이션(새 글자 크기)으로 다음 페이지가 렌더된다. 렌더러
  // fwfh 교체(S11.3) 후 페이지네이션 회귀 방지.
  group('ReflowablePageView — 페이지네이션 회귀 (F2-Edge1, S11.6)', () {
    testWidgets('글자 크기 변경 직후 페이지 전환 → 새 글자 크기로 다음 페이지 렌더', (tester) async {
      final book = _fakeBook(['a.xhtml', 'b.xhtml', 'c.xhtml']);
      Widget at(double fontSize) => _wrap(
            ReflowablePageView(
              book: book,
              fontSize: fontSize,
              xhtmlLoader: (href) async => _wrapXhtml('<p>$href 본문</p>'),
            ),
          );

      // 16px, page 0
      await tester.pumpWidget(at(16));
      await tester.pumpAndSettle();
      var state = tester.state<ReflowablePageViewState>(
        find.byType(ReflowablePageView),
      );
      expect(state.pageIndex, 0);

      // 글자 크기 변경 (본문 재배치)
      await tester.pumpWidget(at(24));
      await tester.pumpAndSettle();

      // 변경 직후 다음 페이지로 전환
      state = tester.state<ReflowablePageViewState>(
        find.byType(ReflowablePageView),
      );
      unawaited(state.nextPage());
      await tester.pumpAndSettle();
      expect(state.pageIndex, 1);

      // 새 페이지가 새 글자 크기(24px)로 렌더 + b.xhtml 본문 표시
      final htmls = tester.widgetList<HtmlWidget>(find.byType(HtmlWidget));
      expect(htmls, isNotEmpty);
      expect(htmls.every((h) => h.textStyle?.fontSize == 24), isTrue);
      expect(
          find.textContaining('b.xhtml', findRichText: true), findsOneWidget);
    });
  });

  // 화면 단위 윈도잉(open-epub#221) — spine 콘텐츠를 한 번 렌더링해 실제 높이를
  // 측정하고, 화면 높이만큼의 창을 좌우 스와이프로 이동한다.
  group('ReflowablePageView — 화면 단위 윈도잉 (open-epub#221)', () {
    testWidgets('spine 콘텐츠가 화면보다 길면 여러 윈도우로 측정된다', (tester) async {
      final book = _fakeBook(['a.xhtml']);
      await tester.pumpWidget(
        _wrap(
          ReflowablePageView(
            book: book,
            xhtmlLoader: (href) async => _tallXhtml(href),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final state = tester.state<ReflowablePageViewState>(
        find.byType(ReflowablePageView),
      );
      expect(state.windowCount, greaterThan(1));
      expect(state.windowIndex, 0);
    });

    // open-epub#221 후속 — EpubViewController.nextPage()/previousPage()가
    // paged 모드에서 spine 전체를 건너뛰지 않고 화면 단위 윈도우로 이동하도록,
    // onPageStepReady로 노출한 step 함수가 실제로 윈도우 단위 이동(_advance와
    // 동일 동작)을 수행하는지 검증한다 — EpubViewController를 거치지 않고
    // ReflowablePageView 자체의 배선만 확인.
    testWidgets('onPageStepReady로 노출된 step 함수는 윈도우 단위로 이동한다', (tester) async {
      final book = _fakeBook(['a.xhtml', 'b.xhtml']);
      Future<void> Function(int direction)? step;
      await tester.pumpWidget(
        _wrap(
          ReflowablePageView(
            book: book,
            xhtmlLoader: (href) async => href == 'a.xhtml'
                ? _tallXhtml(href)
                : _wrapXhtml('<p>짧은 본문</p>'),
            onPageStepReady: (s) => step = s,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final state = tester.state<ReflowablePageViewState>(
        find.byType(ReflowablePageView),
      );
      expect(state.windowCount, greaterThan(1));
      expect(step, isNotNull);

      // step(+1) — 같은 spine 안에서 다음 윈도우로 (spine 점프 아님).
      await step!(1);
      await tester.pumpAndSettle();
      expect(state.pageIndex, 0);
      expect(state.windowIndex, 1);
    });

    testWidgets('짧은 spine은 윈도우가 1개다(회귀)', (tester) async {
      final book = _fakeBook(['a.xhtml']);
      await tester.pumpWidget(
        _wrap(
          ReflowablePageView(
            book: book,
            xhtmlLoader: (href) async => _wrapXhtml('<p>짧은 본문</p>'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final state = tester.state<ReflowablePageViewState>(
        find.byType(ReflowablePageView),
      );
      expect(state.windowCount, 1);
    });

    testWidgets('스와이프로 윈도우 이동 — spine은 유지된다', (tester) async {
      final book = _fakeBook(['a.xhtml']);
      await tester.pumpWidget(
        _wrap(
          ReflowablePageView(
            book: book,
            xhtmlLoader: (href) async => _tallXhtml(href),
          ),
        ),
      );
      await tester.pumpAndSettle();
      var state = tester.state<ReflowablePageViewState>(
        find.byType(ReflowablePageView),
      );
      expect(state.windowCount, greaterThan(1));

      await tester.fling(
        find.byType(ReflowablePageView),
        const Offset(-500, 0),
        1500,
      );
      await tester.pumpAndSettle();
      state = tester.state<ReflowablePageViewState>(
        find.byType(ReflowablePageView),
      );
      expect(state.pageIndex, 0); // 같은 spine 유지
      expect(state.windowIndex, 1); // 다음 윈도우로 이동
    });

    testWidgets('마지막 윈도우에서 스와이프하면 다음 spine으로 전환된다(windowIndex=0 착지)',
        (tester) async {
      final book = _fakeBook(['a.xhtml', 'b.xhtml']);
      await tester.pumpWidget(
        _wrap(
          ReflowablePageView(
            book: book,
            xhtmlLoader: (href) async => href == 'a.xhtml'
                ? _wrapXhtml('<p>짧은 본문</p>')
                : _tallXhtml(href),
          ),
        ),
      );
      await tester.pumpAndSettle();
      var state = tester.state<ReflowablePageViewState>(
        find.byType(ReflowablePageView),
      );
      expect(state.windowCount, 1); // a.xhtml은 화면보다 짧음

      await tester.fling(
        find.byType(ReflowablePageView),
        const Offset(-500, 0),
        1500,
      );
      await tester.pumpAndSettle();
      state = tester.state<ReflowablePageViewState>(
        find.byType(ReflowablePageView),
      );
      expect(state.pageIndex, 1); // 다음 spine으로 전환
      expect(state.windowIndex, 0);
    });

    testWidgets('이전 spine으로 스와이프해서 넘어가면 그 spine의 마지막(캐시된) 윈도우에 착지',
        (tester) async {
      final book = _fakeBook(['a.xhtml', 'b.xhtml']);
      await tester.pumpWidget(
        _wrap(
          ReflowablePageView(
            book: book,
            xhtmlLoader: (href) async => href == 'a.xhtml'
                ? _tallXhtml(href)
                : _wrapXhtml('<p>짧은 본문</p>'),
          ),
        ),
      );
      // spine 0(a.xhtml, 긴 콘텐츠)이 현재 페이지로 측정됨.
      await tester.pumpAndSettle();
      var state = tester.state<ReflowablePageViewState>(
        find.byType(ReflowablePageView),
      );
      expect(state.windowCount, greaterThan(1));

      state.jumpToPage(1);
      await tester.pumpAndSettle();
      state = tester.state<ReflowablePageViewState>(
        find.byType(ReflowablePageView),
      );
      expect(state.pageIndex, 1);

      // 오른쪽으로 스와이프(이전) — spine 0으로 되돌아가며 마지막 윈도우 착지.
      await tester.fling(
        find.byType(ReflowablePageView),
        const Offset(500, 0),
        1500,
      );
      await tester.pumpAndSettle();
      state = tester.state<ReflowablePageViewState>(
        find.byType(ReflowablePageView),
      );
      expect(state.pageIndex, 0);
      expect(state.windowIndex, greaterThan(0));
    });

    testWidgets('글자 크기를 키우면 윈도우 수가 줄어들지 않는다(재측정)', (tester) async {
      final book = _fakeBook(['a.xhtml']);
      Widget build(double fontSize) => _wrap(
            ReflowablePageView(
              book: book,
              fontSize: fontSize,
              xhtmlLoader: (href) async => _tallXhtml(href, lines: 20),
            ),
          );
      await tester.pumpWidget(build(12));
      await tester.pumpAndSettle();
      var state = tester.state<ReflowablePageViewState>(
        find.byType(ReflowablePageView),
      );
      final smallCount = state.windowCount;

      await tester.pumpWidget(build(32));
      await tester.pumpAndSettle();
      state = tester.state<ReflowablePageViewState>(
        find.byType(ReflowablePageView),
      );
      expect(state.windowCount, greaterThanOrEqualTo(smallCount));
    });

    // open-epub#228 후속 — 화면 높이가 본문 줄 높이(fontSize*lineHeight)의
    // 정확한 배수가 아니면, 남는 자투리만큼 페이지 아래쪽에 여백을 두어
    // 어떤 텍스트 줄도 위아래로 잘리지 않아야 한다(다음 윈도우로 넘어감).
    testWidgets('화면 높이가 줄 높이의 배수가 아니면 자투리는 여백으로 남고 줄 단위로 정렬된다', (tester) async {
      final book = _fakeBook(['a.xhtml']);
      // fontSize 16 * lineHeight 1.5 = 24px 줄 높이.
      // 화면 610px → floor(610/24)*24 = 600px(10px는 잘리지 않도록 남긴 여백).
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 610,
              child: ReflowablePageView(
                book: book,
                xhtmlLoader: (href) async => _tallXhtml(href),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 화면(뷰포트) 크기 자체는 610 그대로 유지되고,
      expect(
        find.byWidgetPredicate(
          (w) => w is SizedBox && w.height == 610 && w.width == 400,
        ),
        findsWidgets,
      );
      // 실제 콘텐츠를 자르는 창 높이는 줄 높이 배수로 내림한 600이어야 한다.
      expect(
        find.byWidgetPredicate(
          (w) => w is SizedBox && w.height == 600 && w.width == 400,
        ),
        findsWidgets,
      );
    });

    // 이미지가 비동기로 로드되는 동안엔 작은 placeholder(32x32)만 측정되고,
    // 로드가 끝나 실제(또는 실패) 크기로 바뀌어도 _SpinePageView 자체는
    // rebuild되지 않는다(하위 _RemoteImage만 rebuild) — SizeChangedLayoutNotifier
    // 없이는 이 높이 변화를 놓쳐 윈도우 수가 과소 측정된다.
    testWidgets('비동기 이미지 로드로 콘텐츠가 커지면 윈도우 수가 재측정된다', (tester) async {
      final book = _fakeBook(['a.xhtml']);
      final gate = Completer<Uint8List?>();
      final xhtml =
          _wrapXhtml(List.generate(6, (_) => '<img src="x.png"/>').join());

      await tester.pumpWidget(
        _wrap(
          ReflowablePageView(
            book: book,
            xhtmlLoader: (_) async => xhtml,
            imageLoader: (_) => gate.future,
          ),
        ),
      );
      // 이미지가 아직 로딩 중이면 CircularProgressIndicator(무한 애니메이션)가
      // 떠 있어 pumpAndSettle이 수렴하지 않는다 — 명시적으로 몇 프레임만 pump.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));
      var state = tester.state<ReflowablePageViewState>(
        find.byType(ReflowablePageView),
      );
      // 로딩 중 placeholder(32px)×6 — 화면(600px)보다 훨씬 작다.
      expect(state.windowCount, 1);

      // 로드 실패 → 각 이미지가 더 큰 placeholder(minHeight 120px)로 전환.
      gate.complete(null);
      await tester.pumpAndSettle();

      state = tester.state<ReflowablePageViewState>(
        find.byType(ReflowablePageView),
      );
      expect(state.windowCount, greaterThan(1));
    });

    // open-epub#228 — 코드 리뷰에서 확인된 갭: 윈도우 이동/측정이 부모(그리고
    // 결국 EpubViewController)에 전혀 보고되지 않아 hasNext/hasPrevious 등이
    // stale해지는 문제. onWindowChanged로 (spine, 윈도우 인덱스, 윈도우 수)를
    // 보고하도록 수정.
    testWidgets('onWindowChanged — 측정 완료와 같은 spine 내 윈도우 이동을 보고한다',
        (tester) async {
      final book = _fakeBook(['a.xhtml']);
      final reports = <List<int>>[];
      await tester.pumpWidget(
        _wrap(
          ReflowablePageView(
            book: book,
            xhtmlLoader: (href) async => _tallXhtml(href),
            onWindowChanged: (spineIndex, windowIndex, windowCount) =>
                reports.add([spineIndex, windowIndex, windowCount]),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final state = tester.state<ReflowablePageViewState>(
        find.byType(ReflowablePageView),
      );
      expect(state.windowCount, greaterThan(1));
      // 측정 완료 후 마지막 보고는 (spine 0, window 0, 측정된 windowCount).
      expect(reports.last, [0, 0, state.windowCount]);

      await tester.fling(
        find.byType(ReflowablePageView),
        const Offset(-500, 0),
        1500,
      );
      await tester.pumpAndSettle();

      // 같은 spine 안에서 윈도우만 이동 — spine은 그대로, windowCount도 그대로.
      expect(reports.last, [0, 1, state.windowCount]);
    });

    testWidgets(
        'onWindowChanged — spine 경계를 넘으면 (새 spine, 0, 새 windowCount)로 보고한다',
        (tester) async {
      final book = _fakeBook(['a.xhtml', 'b.xhtml']);
      final reports = <List<int>>[];
      await tester.pumpWidget(
        _wrap(
          ReflowablePageView(
            book: book,
            xhtmlLoader: (href) async => href == 'a.xhtml'
                ? _wrapXhtml('<p>짧은 본문</p>')
                : _tallXhtml(href),
            onWindowChanged: (spineIndex, windowIndex, windowCount) =>
                reports.add([spineIndex, windowIndex, windowCount]),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(reports.last[0], 0);

      await tester.fling(
        find.byType(ReflowablePageView),
        const Offset(-500, 0),
        1500,
      );
      await tester.pumpAndSettle();

      final state = tester.state<ReflowablePageViewState>(
        find.byType(ReflowablePageView),
      );
      expect(state.pageIndex, 1);
      expect(reports.last[0], 1); // 새 spine
      expect(reports.last[1], 0); // 첫 윈도우
      expect(reports.last[2], state.windowCount); // 새 spine의 측정된 windowCount
    });

    // open-epub#228 — 코드 리뷰에서 확인된 갭: spine 경계를 넘는 애니메이션
    // (150ms) 도중 두 번째 이동 요청이 오면, 둘 다 같은(stale) 상태를 읽어
    // 같은 목표로 중복 이동을 시도할 수 있었다. _crossingSpine 가드로 두
    // 번째 요청을 무시해 안전하게 수렴하도록 수정.
    testWidgets('spine 경계를 넘는 이동 중 중복 요청이 와도 안전하게 수렴한다(경합 방지)', (tester) async {
      final book = _fakeBook(['a.xhtml', 'b.xhtml', 'c.xhtml']);
      Future<void> Function(int direction)? step;
      await tester.pumpWidget(
        _wrap(
          ReflowablePageView(
            book: book,
            xhtmlLoader: (href) async => _wrapXhtml('<p>$href</p>'),
            onPageStepReady: (s) => step = s,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(step, isNotNull);

      // 애니메이션(150ms) 완료 전에 연속 호출 — 두 번째 호출은 무시되어야
      // 한다.
      final first = step!(1);
      final second = step!(1);
      await tester.pumpAndSettle();
      await first;
      await second;

      final state = tester.state<ReflowablePageViewState>(
        find.byType(ReflowablePageView),
      );
      expect(state.pageIndex, 1); // 정확히 한 칸만 이동, 범위 밖으로 안 나감
    });
  });

  // 논리 고정 페이지 크기(A4 등)로 윈도잉을 강제하는 모드 — kobic Epic #7964
  // S1. 실제 화면 크기가 아니라 [ReflowablePageView.fixedPageSize] 기준으로
  // 리플로우·윈도잉이 이루어지고, contentBuilder가 fixed-layout과 동일 계약
  // (합성 EpubSpineItem)으로 호출된다.
  group('ReflowablePageView — 고정 페이지 크기 (fixedPageSize, kobic Epic #7964 S1)',
      () {
    testWidgets('fixedPageSize가 있으면 실제 화면이 아닌 고정 크기로 윈도잉된다', (tester) async {
      final book = _fakeBook(['a.xhtml']);
      Widget build(Size? fixedPageSize) => _wrap(
            ReflowablePageView(
              book: book,
              xhtmlLoader: (href) async => _tallXhtml(href),
              fixedPageSize: fixedPageSize,
            ),
          );

      // 기준: 실제 화면(400x600, _wrap) 기준 윈도우 수.
      await tester.pumpWidget(build(null));
      await tester.pumpAndSettle();
      final baselineCount = tester
          .state<ReflowablePageViewState>(find.byType(ReflowablePageView))
          .windowCount;

      // 고정 페이지 높이를 훨씬 작게(100) 주면 같은 콘텐츠가 더 많은 윈도우로
      // 나뉘어야 한다 — 실제 화면(600) 크기가 무시되고 고정 크기가 쓰인다는
      // 증거.
      await tester.pumpWidget(build(const Size(400, 100)));
      await tester.pumpAndSettle();
      final fixedCount = tester
          .state<ReflowablePageViewState>(find.byType(ReflowablePageView))
          .windowCount;

      expect(fixedCount, greaterThan(baselineCount));
    });

    testWidgets('contentBuilder가 윈도우별 고유 href를 가진 합성 EpubSpineItem으로 호출된다',
        (tester) async {
      final book = _fakeBook(['a.xhtml']);
      final seenHrefs = <String>[];
      await tester.pumpWidget(
        _wrap(
          ReflowablePageView(
            book: book,
            xhtmlLoader: (href) async => _tallXhtml(href),
            fixedPageSize: const Size(400, 100),
            contentBuilder: (context, item, logicalSize, content) {
              seenHrefs.add(item.href);
              expect(logicalSize, const Size(400, 100));
              return content;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(seenHrefs, contains('a.xhtml#p0'));

      await tester.fling(
        find.byType(ReflowablePageView),
        const Offset(-500, 0),
        1500,
      );
      await tester.pumpAndSettle();

      expect(seenHrefs, contains('a.xhtml#p1'));
    });

    testWidgets('initialWindowIndex 힌트로 복원된 윈도우에서 시작한다', (tester) async {
      final book = _fakeBook(['a.xhtml']);
      await tester.pumpWidget(
        _wrap(
          ReflowablePageView(
            book: book,
            xhtmlLoader: (href) async => _tallXhtml(href),
            fixedPageSize: const Size(400, 100),
            initialWindowIndex: 2,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final state = tester.state<ReflowablePageViewState>(
        find.byType(ReflowablePageView),
      );
      expect(state.windowCount, greaterThan(2));
      expect(state.windowIndex, 2);
    });

    testWidgets('fixedPageSize가 null이면 contentBuilder는 무시된다(기존 동작 불변)',
        (tester) async {
      final book = _fakeBook(['a.xhtml']);
      var called = false;
      await tester.pumpWidget(
        _wrap(
          ReflowablePageView(
            book: book,
            xhtmlLoader: (href) async => _wrapXhtml('<p>본문</p>'),
            contentBuilder: (context, item, logicalSize, content) {
              called = true;
              return content;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(called, isFalse);
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

/// 화면(600px)보다 훨씬 긴 콘텐츠 — 윈도잉 회귀 테스트용.
String _tallXhtml(String label, {int lines = 60}) => _wrapXhtml(
      List.generate(lines, (i) => '<p>$label line $i</p>').join(),
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
  EpubMetadata get metadata =>
      const EpubMetadata(title: 'fake', epubVersion: '3.0');
  @override
  EpubOutline get outline => EpubOutline.empty;
  @override
  EpubLayout get layout => EpubLayout.reflowable;
}

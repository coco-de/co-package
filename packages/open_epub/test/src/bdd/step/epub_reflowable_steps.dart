// BDD Steps for epub_reflowable.feature
// Story: S1.5 (#11), S1.6 (#12) — Reflowable 본문 렌더링 / 글자 크기·줄간격 /
// 페이지 전환 / 이미지 인라인 + placeholder
//
// 세션은 [BddWorld]가 열고, 위젯 단언은 [ReflowablePageView] /
// [ReflowableEngine]을 직접 pump하여 수행한다.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:open_epub/open_epub.dart';
import 'package:open_epub/src/presentation/engine/reflowable/reflowable_page_view.dart';

import 'package:open_epub_engine/testing.dart';
import '_common_steps.dart';

/// 100% 기준 본문 글자 크기 (px).
const double _baseFontSize = 16.0;

/// 시나리오별 위젯 설정 상태 ([BddWorld]에 연결).
class _ReflowableUi {
  double fontSize = _baseFontSize;
  double lineHeight = 1.5;
  int savedPageIndex = 0;
}

final Expando<_ReflowableUi> _uiState = Expando<_ReflowableUi>();

_ReflowableUi _ui(BddWorld world) => _uiState[world] ??= _ReflowableUi();

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(body: SizedBox(width: 400, height: 600, child: child)),
    );

XhtmlLoader _xhtmlLoaderOf(BddWorld world) {
  final session = world.requireSession;
  return (href) async => session.readSpineXhtml(href) ?? '';
}

ImageLoader _imageLoaderOf(BddWorld world) {
  final session = world.requireSession;
  return (src) async => session.resources.readBytes(src);
}

/// 현재 [BddWorld] 세션의 책을 [ReflowablePageView] (페이지 모드)로 pump.
/// 같은 book 인스턴스로 재-pump하면 PageController(현재 페이지)가 보존된다.
Future<void> _pumpPageView(BddWorld world, WidgetTester tester) async {
  final ui = _ui(world);
  await tester.pumpWidget(
    _wrap(
      ReflowablePageView(
        book: world.requireSession.book,
        xhtmlLoader: _xhtmlLoaderOf(world),
        imageLoader: _imageLoaderOf(world),
        fontSize: ui.fontSize,
        lineHeight: ui.lineHeight,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

ReflowablePageViewState _pageViewState(WidgetTester tester) =>
    tester.state<ReflowablePageViewState>(find.byType(ReflowablePageView));

/// 화면에 있는 모든 [HtmlWidget]의 base text style (fwfh, S11.3).
List<TextStyle?> _bodyStyles(WidgetTester tester) => tester
    .widgetList<HtmlWidget>(find.byType(HtmlWidget))
    .map((h) => h.textStyle)
    .toList(growable: false);

/// Usage: Given 현재 글자 크기는 "`<size>`"(`<percent>`%)이다
Future<void> currentFontSizeIs(
    BddWorld world, WidgetTester tester, String size, int percent) async {
  final ui = _ui(world);
  ui.fontSize = _baseFontSize * percent / 100;
  await _pumpPageView(world, tester);

  // BookPosition 보존 검증이 의미를 갖도록 2번째 챕터로 이동해 둔다.
  final state = _pageViewState(tester);
  state.jumpToPage(1);
  await tester.pumpAndSettle();
  ui.savedPageIndex = state.pageIndex;
  expect(ui.savedPageIndex, 1);

  final styles = _bodyStyles(tester);
  expect(styles, isNotEmpty);
  expect(
    styles.map((s) => s?.fontSize),
    everyElement(closeTo(ui.fontSize, 1e-9)),
  );
}

/// Usage: When 사용자가 글자 크기를 "`<size>`"(`<percent>`%)로 변경한다
Future<void> userChangesFontSizeTo(
    BddWorld world, WidgetTester tester, String size, int percent) async {
  _ui(world).fontSize = _baseFontSize * percent / 100;
  await _pumpPageView(world, tester);
}

/// Usage: Then 본문 텍스트가 재배치되어 모두 `<percent>`% 크기로 표시된다
Future<void> bodyTextReflowsAtPercent(
    BddWorld world, WidgetTester tester, int percent) async {
  final expected = _baseFontSize * percent / 100;
  final styles = _bodyStyles(tester);
  expect(styles, isNotEmpty);
  expect(
    styles.map((s) => s?.fontSize),
    everyElement(closeTo(expected, 1e-9)),
  );
  // 재배치된 본문이 실제로 표시되는지 (현재 페이지 = 2번째 챕터).
  final chapter = _ui(world).savedPageIndex + 1;
  expect(find.textContaining('$chapter장', findRichText: true), findsWidgets);
}

/// Usage: Then 현재 BookPosition은 보존된다
Future<void> currentBookPositionPreserved(
    BddWorld world, WidgetTester tester) async {
  expect(_pageViewState(tester).pageIndex, _ui(world).savedPageIndex);
}

/// Usage: Given 현재 줄간격은 `<value>`이다
Future<void> currentLineHeightIs(
    BddWorld world, WidgetTester tester, double value) async {
  _ui(world).lineHeight = value;
  await _pumpPageView(world, tester);
  final styles = _bodyStyles(tester);
  expect(styles, isNotEmpty);
  expect(
    styles.map((s) => s?.height),
    everyElement(closeTo(value, 1e-9)),
  );
}

/// Usage: When 사용자가 줄간격을 `<value>`로 변경한다
Future<void> userChangesLineHeightTo(
    BddWorld world, WidgetTester tester, double value) async {
  _ui(world).lineHeight = value;
  await _pumpPageView(world, tester);
}

/// Usage: Then 본문이 새 줄간격으로 재배치된다
Future<void> bodyReflowsWithNewLineHeight(
    BddWorld world, WidgetTester tester) async {
  final styles = _bodyStyles(tester);
  expect(styles, isNotEmpty);
  expect(
    styles.map((s) => s?.height),
    everyElement(closeTo(_ui(world).lineHeight, 1e-9)),
  );
  expect(find.textContaining('1장', findRichText: true), findsWidgets);
}

/// Usage: Then 페이지 전환 시 깨짐이 없다
Future<void> pageTransitionsAreCrisp(
    BddWorld world, WidgetTester tester) async {
  final state = _pageViewState(tester);

  unawaited(state.nextPage());
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
  expect(state.pageIndex, 1);
  expect(find.textContaining('2장', findRichText: true), findsWidgets);

  unawaited(state.previousPage());
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
  expect(state.pageIndex, 0);
  expect(find.textContaining('1장', findRichText: true), findsWidgets);
}

/// Usage: Given Reflowable EPUB이 페이지 모드로 열려 있다
Future<void> reflowableEpubInPageMode(
    BddWorld world, WidgetTester tester) async {
  await _pumpPageView(world, tester);
  expect(find.byType(PageView), findsOneWidget);
  expect(_pageViewState(tester).pageIndex, 0);
}

/// Usage: When 사용자가 다음 페이지로 스와이프한다
Future<void> userSwipesToNextPage(BddWorld world, WidgetTester tester) async {
  await tester.fling(find.byType(PageView), const Offset(-300, 0), 1200);
}

/// Usage: Then 다음 페이지가 `<ms>`ms 안에 화면에 그려진다
Future<void> nextPageRenderedWithinMs(
    BddWorld world, WidgetTester tester, int ms) async {
  const frame = Duration(milliseconds: 15);
  final budget = Duration(milliseconds: ms);
  var elapsed = Duration.zero;
  while (elapsed < budget &&
      find.textContaining('2장', findRichText: true).evaluate().isEmpty) {
    await tester.pump(frame);
    elapsed += frame;
  }
  expect(
    find.textContaining('2장', findRichText: true),
    findsWidgets,
    reason: '다음 페이지가 ${ms}ms 안에 화면에 그려져야 합니다',
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
  expect(_pageViewState(tester).pageIndex, 1);
}

/// Usage: Given 본문에 이미지가 포함된 페이지가 있다
Future<void> pageContainsImage(BddWorld world, WidgetTester tester) async {
  // Background의 텍스트 책을 이미지 포함 책으로 갈아끼운다.
  // (fake async 안에서 dispose하면 pump가 멈출 수 있어 reopenWith 사용)
  await world.reopenWith(epubWithImages());
  expect(world.lastError, isNull);

  final session = world.requireSession;
  final xhtml = session.readSpineXhtml(session.book.spine.first.href);
  expect(xhtml, contains('<img'));
}

/// Usage: When 페이지가 표시된다
Future<void> pageIsDisplayed(BddWorld world, WidgetTester tester) async {
  await tester.pumpWidget(
    _wrap(
      ReflowableEngine(
        key: const ValueKey('reflowable-image-ok'),
        book: world.requireSession.book,
        xhtmlLoader: _xhtmlLoaderOf(world),
        imageLoader: _imageLoaderOf(world),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Usage: Then 이미지가 본문과 함께 렌더된다
Future<void> imageRendersWithBody(BddWorld world, WidgetTester tester) async {
  expect(find.textContaining('그림', findRichText: true), findsOneWidget);
  expect(find.byType(Image), findsOneWidget);
  expect(find.byIcon(Icons.image_not_supported_outlined), findsNothing);
}

/// Usage: Then 이미지 로딩 실패 시 placeholder가 보인다
Future<void> placeholderShownOnImageFail(
    BddWorld world, WidgetTester tester) async {
  // 로딩 실패를 시뮬레이션 — key를 바꿔 fresh 트리로 다시 pump.
  await tester.pumpWidget(
    _wrap(
      ReflowableEngine(
        key: const ValueKey('reflowable-image-fail'),
        book: world.requireSession.book,
        xhtmlLoader: _xhtmlLoaderOf(world),
        imageLoader: (_) async => throw Exception('이미지 로딩 실패 시뮬레이션'),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(find.byIcon(Icons.image_not_supported_outlined), findsOneWidget);
  // 본문 텍스트는 그대로 표시된다.
  expect(find.textContaining('그림', findRichText: true), findsOneWidget);
}

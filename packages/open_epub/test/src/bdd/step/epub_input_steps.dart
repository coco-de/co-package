// BDD Steps for epub_input.feature
// Story: S1.21 (#37) — BDD widget 통합 / F8 입력 (S3.18 wiring 동반)
//
// DesktopInput/TouchInput(lib/src/presentation/input/)은 S3.18
// UnimplementedError 스텁 — 키보드 단축키·마우스 휠·우클릭 step은 핸들러
// 구현 후 활성화한다 (해당 시나리오는 widget_test에서 skip).
// 모바일 좌/우 스와이프는 ReflowablePageView(PageView)가 제스처를 직접
// 처리하므로 엔진 레벨에서 실제 fling 제스처로 검증한다.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_epub/open_epub.dart';
import 'package:open_epub/src/presentation/engine/reflowable/reflowable_page_view.dart'
    show ReflowablePageViewState;

import '_common_steps.dart';

/// 세션을 열고 spine XHTML을 로드하는 [ReflowablePageView](페이지 모드)를
/// pump한다. 데스크톱/모바일 Given이 공유하는 하니스 — 입력 wrapper
/// (DesktopInput/TouchInput)는 S3.18 구현 후 감싼다.
Future<void> _pumpPageModeViewer(BddWorld world, WidgetTester tester) async {
  await world.openSession();
  expect(world.lastError, isNull);
  final session = world.requireSession;
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ReflowablePageView(
          book: session.book,
          xhtmlLoader: (href) async => session.readSpineXhtml(href) ?? '',
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

ReflowablePageViewState _pageViewState(WidgetTester tester) =>
    tester.state<ReflowablePageViewState>(find.byType(ReflowablePageView));

/// Usage: Given 모바일에서 책이 열려 있다
Future<void> bookOpenOnMobile(BddWorld world, WidgetTester tester) async {
  await _pumpPageModeViewer(world, tester);
  expect(_pageViewState(tester).pageIndex, 0);
  expect(find.textContaining('1장', findRichText: true), findsOneWidget);
}

/// Usage: When 사용자가 좌로 스와이프한다
Future<void> userSwipesLeft(BddWorld world, WidgetTester tester) async {
  await tester.fling(find.byType(PageView), const Offset(-300, 0), 1200);
  await tester.pumpAndSettle();
}

/// Usage: Then 다음 페이지가 표시된다
Future<void> nextPageShown(BddWorld world, WidgetTester tester) async {
  expect(_pageViewState(tester).pageIndex, 1);
  expect(find.textContaining('2장', findRichText: true), findsOneWidget);
}

/// Usage: Given 데스크톱 `<platform>`에서 책이 열려 있다
/// macOS/Windows 플랫폼 분기는 DesktopInput(S3.18) 책임 — 하니스에서는
/// 동일하게 세션 + 페이지 모드 엔진까지 준비한다.
Future<void> bookOpenOnDesktop(
    BddWorld world, WidgetTester tester, String platform) async {
  await _pumpPageModeViewer(world, tester);
}

/// Usage: When 사용자가 키 "`<key>`"를 누른다
/// 키 → 액션 매핑은 DesktopInput(S3.18 스텁) 책임 — 구현 후 활성화.
Future<void> userPressesKey(
    BddWorld world, WidgetTester tester, String key) async {
  throw UnimplementedError('DesktopInput 키보드 핸들러 미구현 — S3.18 범위');
}

/// Usage: Then "`<action>`"이 수행된다
Future<void> actionPerformed(
    BddWorld world, WidgetTester tester, String action) async {
  throw UnimplementedError('DesktopInput 키보드 핸들러 미구현 — S3.18 범위');
}

/// Usage: Given 데스크톱에서 책이 페이지 모드로 열려 있다
Future<void> bookOpenOnDesktopPageMode(
    BddWorld world, WidgetTester tester) async {
  await _pumpPageModeViewer(world, tester);
}

/// Usage: When 사용자가 마우스 휠을 아래로 굴린다
/// 휠 → 페이지 전환 변환은 DesktopInput(S3.18 스텁) 책임 — 구현 후 활성화.
Future<void> userScrollsMouseWheelDown(
    BddWorld world, WidgetTester tester) async {
  throw UnimplementedError('DesktopInput 마우스 휠 핸들러 미구현 — S3.18 범위');
}

/// Usage: Given 데스크톱에서 텍스트를 선택했다
Future<void> userSelectedTextOnDesktop(
    BddWorld world, WidgetTester tester) async {
  throw UnimplementedError('텍스트 선택 미구현 — S1.13 범위');
}

/// Usage: When 사용자가 우클릭한다
Future<void> userRightClicks(BddWorld world, WidgetTester tester) async {
  throw UnimplementedError('DesktopInput 우클릭(onContextMenu) 미구현 — S3.18 범위');
}

/// Usage: Then 컨텍스트 메뉴(Highlight/Copy/Note)가 표시된다
Future<void> highlightCopyNoteContextMenuShown(
    BddWorld world, WidgetTester tester) async {
  throw UnimplementedError('컨텍스트 메뉴 미구현 — S1.13/S3.18 범위');
}

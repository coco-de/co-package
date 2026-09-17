// BDD Steps for epub_fixed_layout.feature
// Story: S1.7 (#13), S1.8 (#14), S1.9 (#15) — viewport fit / 핀치 줌 / spread
//
// FixedLayoutEngine을 session.book + session.resources 기반 pageBuilder로
// pump한다 (페이지 XHTML의 viewport meta에서 논리 크기를 읽는다).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_epub/open_epub.dart';
import 'package:open_epub/src/presentation/engine/fixed_layout/fixed_layout_page.dart';
import 'package:open_epub/src/presentation/engine/fixed_layout/fixed_layout_spread.dart';

import '_common_steps.dart';

/// 페이지 XHTML의 `<meta name="viewport" content="width=…, height=…"/>`에서
/// 논리 크기를 읽는다. 없으면 기본 600×800 (fixedLayoutEpub3 기준).
Size _logicalSizeOf(EpubBookSession session, EpubSpineItem item) {
  final xhtml = session.resources.readString(item.href) ?? '';
  final w = RegExp(r'width\s*=\s*(\d+)').firstMatch(xhtml);
  final h = RegExp(r'height\s*=\s*(\d+)').firstMatch(xhtml);
  if (w == null || h == null) return const Size(600, 800);
  return Size(double.parse(w.group(1)!), double.parse(h.group(1)!));
}

/// 세션 book으로 [FixedLayoutEngine]을 전체 화면에 pump한다.
/// 각 페이지 콘텐츠는 `Text(item.href)`로 표시해 finder로 검증한다.
Future<void> _pumpEngine(
  BddWorld world,
  WidgetTester tester, {
  int initialSpineIndex = 0,
}) async {
  final session = world.requireSession;
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: FixedLayoutEngine(
          book: session.book,
          initialSpineIndex: initialSpineIndex,
          pageBuilder: (item) async => FixedLayoutPageData(
            logicalSize: _logicalSizeOf(session, item),
            content: Text(item.href),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// tester 화면 view를 강제 변경하고 테스트 종료 시 자동 reset한다.
void _setViewSize(WidgetTester tester, double width, double height) {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

/// Usage: Given rendition:layout은 "`<value>`"이다
Future<void> renditionLayoutIs(BddWorld world, String value) async {
  // 'pre-paginated' → EpubLayout.fixedLayout 매핑 보증.
  expect(value, 'pre-paginated');
  final book = world.requireSession.book;
  expect(book.layout, EpubLayout.fixedLayout);
  expect(book.metadata.layout, EpubLayout.fixedLayout);
}

/// Usage: When 페이지가 표시된다
Future<void> pageIsDisplayed(BddWorld world, WidgetTester tester) async {
  await _pumpEngine(world, tester);
  expect(find.byType(FixedLayoutPage), findsWidgets);
}

/// Usage: Then 페이지가 화면 viewport 비율에 fit된다
Future<void> pageFitsViewportRatio(BddWorld world, WidgetTester tester) async {
  final pageFinder = find.byType(FixedLayoutPage);
  expect(pageFinder, findsOneWidget);
  final page = tester.widget<FixedLayoutPage>(pageFinder);
  final viewportSize = tester.getSize(pageFinder);
  final fittedSize = tester.getSize(
    find.descendant(of: pageFinder, matching: find.byType(FittedBox)),
  );
  // contain fit: 페이지 전체가 viewport 안에 들어간다.
  expect(fittedSize.width, lessThanOrEqualTo(viewportSize.width + 0.01));
  expect(fittedSize.height, lessThanOrEqualTo(viewportSize.height + 0.01));
  // 한 축은 viewport에 정확히 닿는다 (최대 fit).
  final fitsWidth = (fittedSize.width - viewportSize.width).abs() < 0.01;
  final fitsHeight = (fittedSize.height - viewportSize.height).abs() < 0.01;
  expect(fitsWidth || fitsHeight, isTrue,
      reason: 'contain fit은 한 축이 viewport에 닿아야 합니다');
  // 논리 크기(600×800)의 가로세로 비율이 유지된다.
  final logicalRatio = page.logicalSize.width / page.logicalSize.height;
  expect(fittedSize.width / fittedSize.height, closeTo(logicalRatio, 0.01));
}

/// Usage: Then 디자인이 깨지지 않는다
Future<void> designIsNotBroken(BddWorld world, WidgetTester tester) async {
  // 레이아웃/렌더 예외 없이 콘텐츠가 표시된다.
  expect(tester.takeException(), isNull);
  final firstHref = world.requireSession.book.spine.first.href;
  expect(find.text(firstHref), findsOneWidget);
}

/// Usage: Given Fixed Layout 페이지가 표시되어 있다
Future<void> fixedLayoutPageDisplayed(
    BddWorld world, WidgetTester tester) async {
  await _pumpEngine(world, tester);
  expect(find.byType(FixedLayoutPage), findsOneWidget);
  expect(find.byType(InteractiveViewer), findsOneWidget);
}

/// Usage: When 사용자가 두 손가락으로 핀치 줌 인 한다
Future<void> userPinchZoomsIn(BddWorld world, WidgetTester tester) async {
  final center = tester.getCenter(find.byType(InteractiveViewer));
  // 두 손가락을 80px 간격으로 내려 160px 간격으로 벌린다 (≈2.0x).
  final finger1 = await tester.startGesture(center - const Offset(40, 0));
  final finger2 = await tester.startGesture(center + const Offset(40, 0));
  await tester.pump();
  await finger1.moveBy(const Offset(-40, 0));
  await finger2.moveBy(const Offset(40, 0));
  await tester.pump();
  await finger1.up();
  await finger2.up();
  await tester.pumpAndSettle();
}

/// Usage: Then 페이지가 줌 인된다
Future<void> pageZoomsIn(BddWorld world, WidgetTester tester) async {
  final state =
      tester.state<FixedLayoutPageState>(find.byType(FixedLayoutPage));
  expect(state.isZoomedIn, isTrue);
  expect(state.currentScale, greaterThan(1.0));
}

/// Usage: Then 줌 배율은 최대 `<value>`까지 가능하다
Future<void> zoomMaxIs(
    BddWorld world, WidgetTester tester, double value) async {
  final viewer =
      tester.widget<InteractiveViewer>(find.byType(InteractiveViewer));
  expect(viewer.maxScale, value);
  final state =
      tester.state<FixedLayoutPageState>(find.byType(FixedLayoutPage));
  expect(state.currentScale, lessThanOrEqualTo(value + 0.0001));
}

/// Usage: Then 더블 탭으로 줌이 원복된다
Future<void> doubleTapResetsZoom(BddWorld world, WidgetTester tester) async {
  final state =
      tester.state<FixedLayoutPageState>(find.byType(FixedLayoutPage));
  expect(state.isZoomedIn, isTrue, reason: '줌 인 상태에서 원복을 검증합니다');
  final center = tester.getCenter(find.byType(InteractiveViewer));
  await tester.tapAt(center);
  await tester.pump(const Duration(milliseconds: 50));
  await tester.tapAt(center);
  await tester.pumpAndSettle();
  expect(state.currentScale, closeTo(1.0, 0.001));
  expect(state.isZoomedIn, isFalse);
}

/// Usage: Given EPUB 메타 rendition:spread가 "`<value>`"이다
Future<void> renditionSpreadIs(BddWorld world, String value) async {
  final expected =
      EpubSpread.values.firstWhere((spread) => spread.name == value);
  expect(world.requireSession.book.metadata.spread, expected);
}

/// Usage: Given 화면 폭이 `<value>`이다
Future<void> screenWidthIs(
    BddWorld world, WidgetTester tester, int value) async {
  _setViewSize(tester, value.toDouble(), 800);
}

/// Usage: Then spread 모드는 `<mode>`이다 (1-page | 2-page)
Future<void> spreadModeIs(
    BddWorld world, WidgetTester tester, String mode) async {
  final spreadRow = find.byType(FixedLayoutSpreadRow);
  switch (mode) {
    case '2-page':
      expect(spreadRow, findsOneWidget);
    case '1-page':
      expect(spreadRow, findsNothing);
      expect(find.byType(FixedLayoutPage), findsOneWidget);
    default:
      fail('알 수 없는 spread 모드: $mode');
  }
}

/// Usage: Given spine item에 page-spread-left가 명시되어 있다
Future<void> spineItemHasPageSpreadLeft(BddWorld world) async {
  final spine = world.requireSession.book.spine;
  expect(
    spine.any((item) => item.properties.contains('page-spread-left')),
    isTrue,
    reason: 'fixedLayoutEpub3의 p2가 page-spread-left를 갖습니다',
  );
}

/// Usage: When 2-page spread 모드에서 표시된다
Future<void> displayedInTwoPageSpread(
    BddWorld world, WidgetTester tester) async {
  _setViewSize(tester, 1200, 800); // ≥1024 → spread:auto에서 2-page
  final spine = world.requireSession.book.spine;
  final leftIndex =
      spine.indexWhere((item) => item.properties.contains('page-spread-left'));
  expect(leftIndex, isNonNegative);
  await _pumpEngine(world, tester, initialSpineIndex: leftIndex);
  expect(find.byType(FixedLayoutSpreadRow), findsOneWidget);
}

/// Usage: Then 해당 페이지는 좌측 슬롯에 표시된다
Future<void> pageRendersInLeftSlot(BddWorld world, WidgetTester tester) async {
  final spine = world.requireSession.book.spine;
  final left = spine
      .firstWhere((item) => item.properties.contains('page-spread-left'));
  final right = spine
      .firstWhere((item) => item.properties.contains('page-spread-right'));
  final engineWidth = tester.getSize(find.byType(FixedLayoutEngine)).width;
  final leftCenter = tester.getCenter(find.text(left.href));
  final rightCenter = tester.getCenter(find.text(right.href));
  // page-spread-left 페이지는 화면 좌측 절반, right는 우측 절반.
  expect(leftCenter.dx, lessThan(engineWidth / 2));
  expect(rightCenter.dx, greaterThan(engineWidth / 2));
  expect(leftCenter.dx, lessThan(rightCenter.dx));
}

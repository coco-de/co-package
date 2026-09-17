// BDD widget tests — epub_fixed_layout.feature
// Story: S1.7 (#13), S1.8 (#14), S1.9 (#15) — Fixed Layout 렌더링
//
// Source: test/src/bdd/epub_fixed_layout.feature
// Steps:  test/src/bdd/step/epub_fixed_layout_steps.dart + _common_steps.dart
//
// '두 손가락 핀치 줌'은 WidgetTester 멀티터치 제스처로 시뮬레이션한다
// (실기기 제스처 매트릭스는 patrol E2E — E4 범위).

import 'package:flutter_test/flutter_test.dart';

import 'step/_common_steps.dart';
import 'step/epub_fixed_layout_steps.dart';

void main() {
  group('F3: Fixed Layout EPUB 본문 렌더링', () {
    late BddWorld world;

    setUp(() => world = BddWorld());
    tearDown(() => world.dispose());

    Future<void> background() async {
      await fixedLayoutEpubIsOpen(world, 'picture_book.epub');
      await renditionLayoutIs(world, 'pre-paginated');
    }

    testWidgets('SVG 단일 페이지 viewport fit (@P0)', (tester) async {
      await background();
      await pageIsDisplayed(world, tester);
      await pageFitsViewportRatio(world, tester);
      await designIsNotBroken(world, tester);
    });

    testWidgets('핀치 줌 (@P0)', (tester) async {
      await background();
      await fixedLayoutPageDisplayed(world, tester);
      await userPinchZoomsIn(world, tester);
      await pageZoomsIn(world, tester);
      await zoomMaxIs(world, tester, 4.0);
      await doubleTapResetsZoom(world, tester);
    });

    // Scenario Outline: 화면 폭에 따른 자동 spread (Examples 4행)
    for (final (width, mode) in [
      (480, '1-page'),
      (768, '1-page'),
      (1024, '2-page'),
      (1440, '2-page'),
    ]) {
      testWidgets('화면 폭에 따른 자동 spread — $width → $mode (@P0)',
          (tester) async {
        await background();
        await renditionSpreadIs(world, 'auto');
        await screenWidthIs(world, tester, width);
        await pageIsDisplayed(world, tester);
        await spreadModeIs(world, tester, mode);
      });
    }

    testWidgets('page-spread-left/right 표기 존중 (@P0)', (tester) async {
      await background();
      await spineItemHasPageSpreadLeft(world);
      await displayedInTwoPageSpread(world, tester);
      await pageRendersInLeftSlot(world, tester);
    });
  });
}

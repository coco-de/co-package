// BDD widget tests — epub_input.feature
// Story: S1.21 (#37) — BDD widget 통합 / F8 데스크톱·모바일 입력 (S3.18)
//
// Source: test/src/bdd/epub_input.feature
// Steps:  test/src/bdd/step/epub_input_steps.dart + _common_steps.dart
//
// DesktopInput/TouchInput(lib/src/presentation/input/)은 S3.18
// UnimplementedError 스텁 — 키보드 단축키·마우스 휠·우클릭 시나리오는
// 핸들러 구현 후 활성화한다. 모바일 좌 스와이프는 ReflowablePageView
// (PageView)가 제스처를 직접 처리하므로 실제 fling 제스처로 검증한다.

import 'package:flutter_test/flutter_test.dart';

import 'step/_common_steps.dart';
import 'step/epub_input_steps.dart';

void main() {
  group('F8: 데스크톱·모바일 통합 입력', () {
    late BddWorld world;

    setUp(() => world = BddWorld());
    tearDown(() => world.dispose());

    testWidgets('모바일 터치 스와이프 (@P0 @mobile)', (tester) async {
      await bookOpenOnMobile(world, tester);
      await userSwipesLeft(world, tester);
      await nextPageShown(world, tester);
    });

    group('데스크톱 키보드 단축키 (@P0 @desktop) — Scenario Outline', () {
      const examples = <(String, String, String)>[
        ('macOS', 'RightArrow', 'next page'),
        ('macOS', 'LeftArrow', 'prev page'),
        ('macOS', 'Home', 'go to start'),
        ('macOS', 'End', 'go to end'),
        ('macOS', 'Cmd+F', 'open search'),
        ('macOS', 'Cmd+B', 'toggle bookmark'),
        ('Windows', 'RightArrow', 'next page'),
        ('Windows', 'PageDown', 'next page'),
        ('Windows', 'Ctrl+F', 'open search'),
        ('Windows', 'F11', 'fullscreen'),
      ];
      for (final (platform, key, action) in examples) {
        testWidgets('$platform — "$key" → "$action"', (tester) async {
          await bookOpenOnDesktop(world, tester, platform);
          await userPressesKey(world, tester, key);
          await actionPerformed(world, tester, action);
        });
      }
    }, skip: 'DesktopInput 키보드 핸들러 미구현 — S3.18 범위');

    group('마우스 휠 페이지 전환 (@P0 @desktop)', () {
      testWidgets('휠 다운 → 다음 페이지', (tester) async {
        await bookOpenOnDesktopPageMode(world, tester);
        await userScrollsMouseWheelDown(world, tester);
        await nextPageShown(world, tester);
      });
    }, skip: 'DesktopInput 마우스 휠 핸들러 미구현 — S3.18 범위');

    group('우클릭 컨텍스트 메뉴 (@P0 @desktop)', () {
      testWidgets('우클릭 → Highlight/Copy/Note 메뉴', (tester) async {
        await userSelectedTextOnDesktop(world, tester);
        await userRightClicks(world, tester);
        await highlightCopyNoteContextMenuShown(world, tester);
      });
    }, skip: '텍스트 선택(S1.13) + DesktopInput 우클릭(S3.18) 미구현');
  });
}

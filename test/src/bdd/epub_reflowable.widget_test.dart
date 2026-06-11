// BDD widget tests — epub_reflowable.feature
// Story: S1.5 (#11), S1.6 (#12) — Reflowable 본문 렌더링
//
// Source: test/src/bdd/epub_reflowable.feature
// Steps:  test/src/bdd/step/epub_reflowable_steps.dart + _common_steps.dart
//
// '150ms 안에 그려진다'는 widget test에서 pump된 프레임 시간 예산(150ms) 안에
// 다음 페이지 콘텐츠가 트리에 그려짐을 검증한다 (실기기 wall-clock은 E4 범위).

import 'package:flutter_test/flutter_test.dart';

import 'step/_common_steps.dart';
import 'step/epub_reflowable_steps.dart';

void main() {
  group('F2: Reflowable EPUB 본문 렌더링', () {
    late BddWorld world;

    setUp(() => world = BddWorld());
    tearDown(() => world.dispose());

    Future<void> background() async {
      await reflowableEpubIsOpen(world, 'novel.epub');
    }

    testWidgets('글자 크기 변경 (@P0)', (tester) async {
      await background();
      await currentFontSizeIs(world, tester, '보통', 100);
      await userChangesFontSizeTo(world, tester, '크게', 140);
      await bodyTextReflowsAtPercent(world, tester, 140);
      await currentBookPositionPreserved(world, tester);
    });

    testWidgets('줄간격 변경 (@P0)', (tester) async {
      await background();
      await currentLineHeightIs(world, tester, 1.5);
      await userChangesLineHeightTo(world, tester, 2.0);
      await bodyReflowsWithNewLineHeight(world, tester);
      await pageTransitionsAreCrisp(world, tester);
    });

    testWidgets('페이지 전환 응답 시간 (@P0)', (tester) async {
      await background();
      await reflowableEpubInPageMode(world, tester);
      await userSwipesToNextPage(world, tester);
      await nextPageRenderedWithinMs(world, tester, 150);
    });

    testWidgets('이미지 인라인 렌더 (@P0)', (tester) async {
      await background();
      await pageContainsImage(world, tester);
      await pageIsDisplayed(world, tester);
      await imageRendersWithBody(world, tester);
      await placeholderShownOnImageFail(world, tester);
    });
  });
}

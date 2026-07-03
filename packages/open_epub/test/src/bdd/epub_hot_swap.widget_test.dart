// BDD widget tests — epub_hot_swap.feature
// Story: S1.22 (#38) — swapSource() 위치 보존 hot-swap
//
// Source: test/src/bdd/epub_hot_swap.feature
// Steps:  test/src/bdd/step/epub_hot_swap_steps.dart + _common_steps.dart
//
// Author(P2) 미리보기 hot-swap은 session API 레벨에서 end-to-end 검증한다
// (에디터 호스트 UI는 E3 범위 — swapSource 계약이 패키지 책임).

import 'package:flutter_test/flutter_test.dart';

import 'step/_common_steps.dart';
import 'step/epub_hot_swap_steps.dart';

void main() {
  group('F10: 에디터 EpubSourceBytes hot-swap', () {
    late BddWorld world;

    setUp(() => world = BddWorld());
    tearDown(() => world.dispose());

    test('같은 EPUB의 hot-swap (@P0)', () async {
      await authorOpenedPreview(world, 'draft.epub');
      await currentBookPositionIs(world, 'ch03.xhtml', 512);
      await authorSendsNewBytes(world);
      await spineStructureUnchanged(world);
      await viewerImmediatelyRefreshes(world);
      await bookPositionRestored(world);
    });

    test('spine 구조가 변경된 hot-swap (@P1)', () async {
      await authorPreviewingBook(world);
      await authorSendsEpubWithReorderedSpine(world);
      await viewerRefreshes(world);
      await fallbackToFirstSpinePageOnFailure(world);
      await notificationShown(world, '마지막 위치를 찾을 수 없어 처음부터 표시합니다');
    });

    test('Fixed Layout hot-swap (@P0)', () async {
      await fixedLayoutEpubInPreview(world);
      await authorAddsPageAndUpdatesBytes(world);
      await newPageReflectedInSpine(world);
    });
  });
}

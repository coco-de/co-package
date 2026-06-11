// BDD widget tests — epub_outline.feature
// Story: S1.2, S1.3, S1.15 — NCX/nav 목차 + sparse-ncx/empty-toc 보정
//
// Source: test/src/bdd/epub_outline.feature
// Steps:  test/src/bdd/step/epub_outline_steps.dart + _common_steps.dart
//
// '목차 패널' UI는 kobic 호스트 책임 — 패키지 레벨에서는 session.book.outline
// 트리와 jumpTo(목차 항목 탭→이동)로 치환 검증한다 (호스트 UI 통합은 E3 범위).

import 'package:flutter_test/flutter_test.dart';

import 'step/_common_steps.dart';
import 'step/epub_outline_steps.dart';

void main() {
  group('F4: 목차 표시 및 점프', () {
    late BddWorld world;

    setUp(() => world = BddWorld());
    tearDown(() => world.dispose());

    test('EPUB 3 nav 목차 표시 (@P0)', () async {
      await navHasChapters(world, 5);
      await userOpensOutlinePanel(world);
      await outlineTreeShowsChapters(world, 5);
    });

    test('목차 항목 클릭 시 이동 (@P0)', () async {
      await outlinePanelIsOpen(world);
      await userTapsOutlineItem(world, '3장. 시작하기');
      await viewerJumpsToBookPosition(world);
      await bodyShowsFirstPortion(world);
    });

    test('sparse-NCX 자동 보정 (@P0)', () async {
      await ncxHasSparseSpineEntries(world, 30);
      await bookIsOpened(world);
      await missingSpineAutoAddedToNcx(world);
      await diagnosticsRecordsPatch(world, 'sparse-ncx');
    });

    test('빈 목차 fallback (@P0)', () async {
      await ncxAndNavAreEmpty(world);
      await bookIsOpened(world);
      await spineBasedOutlineGenerated(world);
      await diagnosticsRecordsPatch(world, 'empty-toc');
    });
  });
}

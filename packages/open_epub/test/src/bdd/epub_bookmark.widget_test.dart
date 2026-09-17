// BDD widget tests — epub_bookmark.feature
// Story: S1.10, S1.11, S1.12 — 북마크 추가·목록·이동·삭제
//
// Source: test/src/bdd/epub_bookmark.feature
// Steps:  test/src/bdd/step/epub_bookmark_steps.dart + _common_steps.dart
//
// 북마크 영속 저장소·패널 UI(아이콘 상태, 스와이프 Delete)는 kobic 호스트
// 책임 — 하니스 치환(BookmarkWorld store/panel)으로 검증한다. 패키지는
// recordBookmark → EpubBookmarkToolUse(position) 발사, BookPosition v1 토큰
// round-trip, jumpTo 이동을 보증한다.

import 'package:flutter_test/flutter_test.dart';

import 'step/epub_bookmark_steps.dart';

void main() {
  group('F6: 북마크 추가·삭제·이동', () {
    late BookmarkWorld world;

    setUp(() => world = BookmarkWorld());
    tearDown(() => world.dispose());

    test('북마크 추가 (@P0)', () async {
      await userIsAtProgress(world, 0.6);
      await userTapsBookmarkButton(world);
      await bookPositionStoredAsBookmark(world);
      await bookmarkIconBecomesAdded(world);
    });

    test('북마크 목록 표시 (@P0)', () async {
      await userHasNBookmarks(world, 3);
      await userOpensBookmarkPanel(world);
      await nBookmarksShownInReverseChronological(world, 3);
      await eachItemShowsPageOrProgress(world);
    });

    test('북마크 이동 (@P0)', () async {
      await bookmarkPanelHasBookmarkAtProgress(world, 0.6);
      await userTapsBookmark(world);
      await viewerMovesToBookmarkPosition(world);
    });

    test('북마크 삭제 (스와이프) (@P0)', () async {
      await bookmarkPanelShowsBookmarks(world);
      await userSwipesLeftAndTapsDelete(world);
      await bookmarkRemovedFromList(world);
      await bookmarkDeletedFromStore(world);
    });
  });
}

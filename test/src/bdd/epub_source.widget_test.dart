// BDD widget tests — epub_source.feature
// Story: S1.20, S1.21, S1.23, S1.25 — 책 열기 / 위치 복원 / analytics
//
// Source: test/src/bdd/epub_source.feature
// Steps:  test/src/bdd/step/epub_source_steps.dart + _common_steps.dart
//
// 시나리오 'progressEvents debounce'의 30초 실시간 검증과 5플랫폼 매트릭스는
// patrol E2E(E4) 범위 — 여기서는 throttle 억제 동작과 현재 플랫폼 동작을 검증.

import 'package:flutter_test/flutter_test.dart';

import 'step/_common_steps.dart';
import 'step/epub_source_steps.dart';

void main() {
  group('F1: EPUB 책 열기 및 마지막 위치 복원', () {
    late BddWorld world;

    setUp(() => world = BddWorld());
    tearDown(() => world.dispose());

    Future<void> background() async {
      await kobicUserIsLoggedIn(world);
      await userLibraryHasEpubBook(world, '사용자_매뉴얼.epub');
    }

    test('새 EPUB 책 첫 열람 (@P0 @smoke)', () async {
      await background();
      await userIsOnLibraryScreen(world);
      await userTapsBookItem(world, '사용자_매뉴얼.epub');
      await epubViewerShowsFirstPageWithin(world, 2.0);
      await bookSessionStartedEventEmitted(world);
      await progressIs(world, 0.0);
    });

    test('마지막 위치에서 이어 읽기 (@P0)', () async {
      await background();
      await userClosedBookAtProgress(world, '사용자_매뉴얼.epub', 0.45);
      await bookPositionTokenStored(world);
      await userOpensSameBookAgain(world);
      await viewerRestoresPositionAt(world, 0.45);
      await progressIndicatorShows(world, '45%');
    });

    test('위치 복원 실패 시 fallback (@P0)', () async {
      await background();
      await storedSpineHrefMissing(world);
      await userOpensBook(world);
      await viewerShowsFirstSpinePage(world);
      await diagnosticEventIsRecorded(world, 'position-restore-failed');
      await userSeesMessage(world, '마지막 위치를 찾을 수 없어 처음부터 표시합니다');
    });

    test('큰 EPUB 열기 성능 smoke — 첫 페이지 ≤ 2.0s (@P0)', () async {
      await background();
      await userRunsKobicOnPlatform(world, 'VM');
      final stopwatch = Stopwatch()..start();
      await userOpens50MbBook(world);
      stopwatch.stop();
      await firstPageShownWithin(world, 2.0);
      expect(stopwatch.elapsed, lessThan(const Duration(seconds: 2)));
    });

    test('lifecycleEvents 발사 (@P0)', () async {
      await background();
      await kobicStartsBookSession(world);
      await sessionOpensSuccessfully(world);
      await lifecycleEventsEmitsSessionStarted(world);
      await kobicTransformsToExternalEvent(world, 'book_session_started');
    });

    test('progressEvents debounce (@P0)', () async {
      await background();
      world.progressThrottle = const Duration(seconds: 30);
      await sessionIsActive(world);
      await userFlipsPagesFastNTimes(world);
      await progressEventsThrottledTo30Seconds(world);
      await kobicReceivesLatestProgress(world);
    });

    test('toolUseEvents 분류 (@P0)', () async {
      await background();
      await sessionIsActive(world);
      await userAddsHighlightAndBookmark(world);
      await toolUseEventsEmitsHighlightAndBookmark(world);
      await eachEventIncludesBookPosition(world);
    });
  });
}

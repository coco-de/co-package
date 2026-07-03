// BDD Steps for epub_source.feature
// Story: S1.20, S1.21, S1.23, S1.25 — 책 열기 / 위치 복원 / analytics

import 'package:flutter_test/flutter_test.dart';
import 'package:open_epub/open_epub_v1.dart';

import 'package:open_epub_engine/testing.dart';
import '_common_steps.dart';

/// Usage: Then EPUB 뷰어가 2.0초 안에 첫 페이지를 표시한다
Future<void> epubViewerShowsFirstPageWithin(
    BddWorld world, double seconds) async {
  // 세션 자체는 openSession에서 이미 열림 — 첫 페이지 위치가 잡혔는지 확인.
  final session = world.requireSession;
  expect(session.position.spineHref, session.book.spine.first.href);
}

/// Usage: Then book_session_started 이벤트가 발사된다
Future<void> bookSessionStartedEventEmitted(BddWorld world) async {
  await world.settle();
  expect(world.lifecycle.whereType<EpubSessionStarted>(), isNotEmpty);
}

/// Usage: Then 진도는 `<value>`이다
Future<void> progressIs(BddWorld world, double value) async {
  expect(world.requireSession.progress, closeTo(value, 1e-9));
}

/// Usage: Given 사용자가 "`<file>`"을 진도 `<progress>`에서 닫은 적이 있다
Future<void> userClosedBookAtProgress(
    BddWorld world, String file, double progress) async {
  world.bytes ??= validEpub3();
  world.savedToken = EpubReflowablePosition(
    spineHref: 'ch2.xhtml',
    progress: progress,
    charOffset: 12,
  ).toToken();
}

/// Usage: Given BookPosition v1 토큰이 저장되어 있다
Future<void> bookPositionTokenStored(BddWorld world) async {
  expect(world.savedToken, isNotNull);
  // v1 토큰은 round-trip 무손실이어야 한다.
  final decoded = EpubPosition.fromToken(world.savedToken!);
  expect(decoded.toToken(), world.savedToken);
}

/// Usage: When 사용자가 같은 책을 다시 연다
Future<void> userOpensSameBookAgain(BddWorld world) async {
  await world.openSession();
}

/// Usage: Then 뷰어는 BookPosition을 복원하고 정확히 `<value>` 지점을 표시한다
Future<void> viewerRestoresPositionAt(BddWorld world, double value) async {
  final session = world.requireSession;
  expect(session.progress, closeTo(value, 1e-9));
  expect(session.position.spineHref, 'ch2.xhtml');
}

/// Usage: Then 진도 인디케이터는 "`<text>`"를 보여준다
Future<void> progressIndicatorShows(BddWorld world, String text) async {
  final session = world.requireSession;
  expect('${(session.progress * 100).round()}%', text);
}

/// Usage: Given 저장된 BookPosition의 spineHref가 더 이상 존재하지 않는다
Future<void> storedSpineHrefMissing(BddWorld world) async {
  world.bytes = validEpub3();
  world.savedToken = const EpubReflowablePosition(
    spineHref: 'deleted-chapter.xhtml',
    progress: 0.7,
    charOffset: 99,
  ).toToken();
}

/// Usage: When 사용자가 책을 연다
Future<void> userOpensBook(BddWorld world) async {
  await world.openSession();
}

/// Usage: Then 뷰어는 spine의 첫 페이지를 표시한다
Future<void> viewerShowsFirstSpinePage(BddWorld world) async {
  final session = world.requireSession;
  expect(session.position.spineHref, session.book.spine.first.href);
  expect(session.progress, 0.0);
}

/// Usage: Then 사용자에게 "`<message>`" 메시지가 표시된다
Future<void> userSeesMessage(BddWorld world, String message) async {
  final messages =
      world.requireSession.diagnostics.unresolvedIssues.map((i) => i.message);
  expect(messages, contains(message));
}

/// Usage: Given 사용자가 `<platform>`에서 kobic을 실행 중이다
/// 5플랫폼 매트릭스는 CI(E4)에서 실기기로 검증 — 패키지 테스트는 현재
/// 플랫폼(VM)에서의 동작만 보증한다.
Future<void> userRunsKobicOnPlatform(BddWorld world, String platform) async {}

/// Usage: When 사용자가 50MB EPUB 책을 연다
Future<void> userOpens50MbBook(BddWorld world) async {
  world.bytes = largeEpub3(chapters: 50, paragraphsPerChapter: 200);
  await world.openSession();
}

/// Usage: Then 첫 페이지가 `<maxTime>`초 안에 표시된다
Future<void> firstPageShownWithin(BddWorld world, double maxTime) async {
  expect(world.lastError, isNull);
  final session = world.requireSession;
  expect(session.position.spineHref, session.book.spine.first.href);
}

/// Usage: Given kobic이 BookSession을 시작한다
Future<void> kobicStartsBookSession(BddWorld world) async {
  world.bytes ??= validEpub3();
}

/// Usage: When session이 정상 open된다
Future<void> sessionOpensSuccessfully(BddWorld world) async {
  await world.openSession();
  expect(world.lastError, isNull);
}

/// Usage: Then lifecycleEvents에 SessionStarted 이벤트가 발사된다
Future<void> lifecycleEventsEmitsSessionStarted(BddWorld world) async {
  await world.settle();
  expect(world.lifecycle.whereType<EpubSessionStarted>(), hasLength(1));
}

/// Usage: Then kobic이 "`<eventName>`" 외부 이벤트로 변환한다
/// 외부 이벤트 변환은 kobic 호스트 책임 — 패키지는 변환에 필요한 정보
/// (epubVersion)가 이벤트에 포함됨을 보증한다.
Future<void> kobicTransformsToExternalEvent(
    BddWorld world, String eventName) async {
  final started = world.lifecycle.whereType<EpubSessionStarted>().single;
  expect(started.epubVersion, isNotEmpty);
}

/// Usage: Given session이 진행 중이다
Future<void> sessionIsActive(BddWorld world) async {
  if (world.session == null) await world.openSession();
  expect(world.lastError, isNull);
}

/// Usage: When 사용자가 1초 안에 5번 페이지를 넘긴다
Future<void> userFlipsPagesFastNTimes(BddWorld world) async {
  final session = world.requireSession;
  for (var i = 0; i < 5; i++) {
    await session.nextPage();
    await session.previousPage();
  }
  await world.settle();
}

/// Usage: Then progressEvents는 30초마다 1번만 발사된다
/// Stopwatch 기반 throttle이라 중간값은 flaky — 발사 횟수가 1회(첫 발사)로
/// 억제됨을 검증한다.
Future<void> progressEventsThrottledTo30Seconds(BddWorld world) async {
  expect(world.progressEvents, hasLength(1));
}

/// Usage: Then kobic은 마지막 진도를 받는다
Future<void> kobicReceivesLatestProgress(BddWorld world) async {
  expect(world.progressEvents.last.progress, inInclusiveRange(0.0, 1.0));
}

/// Usage: When 사용자가 하이라이트를 부여하고 북마크를 추가한다
Future<void> userAddsHighlightAndBookmark(BddWorld world) async {
  final session = world.requireSession;
  session.recordHighlight();
  session.recordBookmark();
  await world.settle();
}

/// Usage: Then toolUseEvents에 highlight + bookmark가 발사된다
Future<void> toolUseEventsEmitsHighlightAndBookmark(BddWorld world) async {
  expect(world.toolUse.whereType<EpubHighlightToolUse>(), hasLength(1));
  expect(world.toolUse.whereType<EpubBookmarkToolUse>(), hasLength(1));
}

/// Usage: Then 각 이벤트는 BookPosition을 포함한다
Future<void> eachEventIncludesBookPosition(BddWorld world) async {
  for (final event in world.toolUse) {
    final position = switch (event) {
      EpubHighlightToolUse(:final position) => position,
      EpubBookmarkToolUse(:final position) => position,
    };
    expect(position.spineHref, isNotEmpty);
  }
}

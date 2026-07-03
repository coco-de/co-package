// BDD Steps for epub_bookmark.feature
// Story: S1.10, S1.11, S1.12 — 북마크 추가·목록·이동·삭제
//
// 북마크 영속 저장소와 패널 UI(아이콘 상태, 스와이프 Delete)는 kobic 호스트
// 책임 — 패키지는 recordBookmark()가 발사하는 EpubBookmarkToolUse(position
// 포함)와 BookPosition v1 토큰 round-trip, jumpTo 이동을 보증한다.
// 호스트 저장소/패널은 [BookmarkWorld]의 하니스 치환으로 검증한다.

import 'package:flutter_test/flutter_test.dart';
import 'package:open_epub/open_epub.dart';

import '_common_steps.dart';

/// 호스트(kobic) 데이터 저장소에 영속된 북마크 1건의 치환물.
class BookmarkEntry {
  BookmarkEntry({required this.seq, required this.token});

  /// 저장 순번 (클수록 최근 — 시간 역순 정렬 기준).
  final int seq;

  /// BookPosition v1 토큰 (호스트는 토큰 문자열만 저장한다).
  final String token;

  EpubPosition get position => EpubPosition.fromToken(token);

  /// 패널 항목에 표시할 페이지 번호 또는 진도 라벨.
  String get displayLabel {
    final p = position;
    if (p is EpubFixedPosition) return '${p.pageIndex + 1}쪽';
    if (p is EpubReflowablePosition && p.pageIndex != null) {
      return '${p.pageIndex! + 1}쪽';
    }
    return '${(p.progress * 100).round()}%';
  }
}

/// 북마크 시나리오 상태: [BddWorld] + 호스트 저장소/패널 치환.
class BookmarkWorld extends BddWorld {
  /// 호스트 데이터 저장소 치환 (toolUse 이벤트 → 토큰 영속).
  final List<BookmarkEntry> store = [];

  /// 열려 있는 북마크 패널(시간 역순 목록). 닫혀 있으면 null.
  List<BookmarkEntry>? panel;

  BookmarkEntry? tappedBookmark;
  BookmarkEntry? deletedBookmark;

  int _seq = 0;

  /// 호스트가 [EpubBookmarkToolUse]를 받아 토큰으로 영속하는 동작의 치환.
  void persistBookmark(EpubPosition position) {
    store.add(BookmarkEntry(seq: _seq++, token: position.toToken()));
  }

  /// 북마크 아이콘 상태의 파생값 — 현재 위치에 저장된 북마크가 있는가.
  bool get hasBookmarkAtCurrentPosition {
    final current = requireSession.position.toToken();
    return store.any((e) => e.token == current);
  }
}

/// Usage: Given 사용자가 책의 진도 `<progress>` 지점에 있다
Future<void> userIsAtProgress(BookmarkWorld world, double progress) async {
  await world.openSession();
  expect(world.lastError, isNull);
  await world.requireSession.jumpTo(EpubReflowablePosition(
    spineHref: 'ch2.xhtml',
    progress: progress,
    charOffset: 24,
  ));
  expect(world.requireSession.progress, closeTo(progress, 1e-9));
}

/// Usage: When 사용자가 북마크 버튼을 탭한다
Future<void> userTapsBookmarkButton(BookmarkWorld world) async {
  world.requireSession.recordBookmark();
  await world.settle();
  // 호스트는 toolUseEvents의 EpubBookmarkToolUse를 받아 영속한다.
  final event = world.toolUse.whereType<EpubBookmarkToolUse>().last;
  world.persistBookmark(event.position);
}

/// Usage: Then 현재 BookPosition이 북마크로 저장된다
Future<void> bookPositionStoredAsBookmark(BookmarkWorld world) async {
  expect(world.toolUse.whereType<EpubBookmarkToolUse>(), hasLength(1));
  expect(world.store, hasLength(1));
  final entry = world.store.single;
  // v1 토큰 round-trip 무손실 + 현재 위치와 일치.
  final decoded = EpubPosition.fromToken(entry.token);
  expect(decoded.toToken(), entry.token);
  expect(decoded, world.requireSession.position);
}

/// Usage: Then 북마크 아이콘이 "추가됨" 상태로 변한다
/// 아이콘 위젯은 kobic 패널 UI — 하니스에서는 "현재 위치에 북마크가
/// 존재한다" 파생 상태로 치환한다.
Future<void> bookmarkIconBecomesAdded(BookmarkWorld world) async {
  expect(world.hasBookmarkAtCurrentPosition, isTrue);
}

/// Usage: Given 사용자가 책에 `<n>`개의 북마크를 저장했다
Future<void> userHasNBookmarks(BookmarkWorld world, int n) async {
  await world.openSession();
  expect(world.lastError, isNull);
  final session = world.requireSession;
  final hrefs = session.book.spine.map((s) => s.href).toList();
  for (var i = 0; i < n; i++) {
    await session.jumpTo(EpubReflowablePosition(
      spineHref: hrefs[i % hrefs.length],
      progress: (i + 1) / (n + 1),
      charOffset: i * 10,
    ));
    session.recordBookmark();
  }
  await world.settle();
  for (final event in world.toolUse.whereType<EpubBookmarkToolUse>()) {
    world.persistBookmark(event.position);
  }
  expect(world.store, hasLength(n));
}

/// Usage: When 사용자가 북마크 패널을 연다
/// 패널 UI는 kobic 호스트 — 저장소의 시간 역순 목록 구성으로 치환.
Future<void> userOpensBookmarkPanel(BookmarkWorld world) async {
  world.panel = [...world.store]..sort((a, b) => b.seq.compareTo(a.seq));
}

/// Usage: Then `<n>`개의 북마크가 시간 역순으로 표시된다
Future<void> nBookmarksShownInReverseChronological(
    BookmarkWorld world, int n) async {
  final panel = world.panel;
  expect(panel, isNotNull, reason: '북마크 패널이 열려 있어야 합니다');
  expect(panel, hasLength(n));
  for (var i = 0; i + 1 < panel!.length; i++) {
    expect(panel[i].seq, greaterThan(panel[i + 1].seq),
        reason: '패널은 최근 북마크가 먼저 보여야 합니다');
  }
}

/// Usage: Then 각 항목에 페이지 번호 또는 진도가 보인다
Future<void> eachItemShowsPageOrProgress(BookmarkWorld world) async {
  final panel = world.panel;
  expect(panel, isNotNull);
  for (final entry in panel!) {
    expect(entry.displayLabel, matches(RegExp(r'^\d+(쪽|%)$')));
  }
}

/// Usage: Given 북마크 패널에 진도 `<progress>` 북마크가 있다
Future<void> bookmarkPanelHasBookmarkAtProgress(
    BookmarkWorld world, double progress) async {
  await world.openSession();
  expect(world.lastError, isNull);
  // 이전 세션에서 저장된 진도 [progress] 북마크가 저장소에 있다.
  world.persistBookmark(EpubReflowablePosition(
    spineHref: 'ch2.xhtml',
    progress: progress,
    charOffset: 24,
  ));
  await userOpensBookmarkPanel(world);
  expect(
    world.panel!.map((e) => e.position.progress),
    contains(closeTo(progress, 1e-9)),
  );
}

/// Usage: When 사용자가 해당 북마크를 탭한다
Future<void> userTapsBookmark(BookmarkWorld world) async {
  expect(world.panel, isNotEmpty);
  final entry = world.panel!.first;
  world.tappedBookmark = entry;
  // 호스트는 저장된 토큰을 복원해 session.jumpTo로 이동시킨다.
  await world.requireSession.jumpTo(entry.position);
  await world.settle();
}

/// Usage: Then 뷰어가 BookPosition으로 이동한다
Future<void> viewerMovesToBookmarkPosition(BookmarkWorld world) async {
  final tapped = world.tappedBookmark;
  expect(tapped, isNotNull, reason: '탭한 북마크가 있어야 합니다');
  expect(world.requireSession.position, tapped!.position);
  await viewerJumpsToBookPosition(world);
}

/// Usage: Given 북마크 패널에 북마크가 표시되어 있다
Future<void> bookmarkPanelShowsBookmarks(BookmarkWorld world) async {
  await world.openSession();
  expect(world.lastError, isNull);
  world.requireSession.recordBookmark();
  await world.settle();
  final event = world.toolUse.whereType<EpubBookmarkToolUse>().last;
  world.persistBookmark(event.position);
  await userOpensBookmarkPanel(world);
  expect(world.panel, isNotEmpty);
}

/// Usage: When 사용자가 항목을 좌로 스와이프하여 "Delete"를 탭한다
/// 스와이프 제스처·Delete 버튼은 kobic 패널 UI — 하니스에서는 항목 삭제
/// 동작(목록 제거 + 저장소 삭제 요청)으로 치환한다.
Future<void> userSwipesLeftAndTapsDelete(BookmarkWorld world) async {
  expect(world.panel, isNotEmpty);
  final entry = world.panel!.first;
  world.deletedBookmark = entry;
  world.panel!.remove(entry);
  world.store.removeWhere((e) => e.seq == entry.seq);
}

/// Usage: Then 해당 북마크가 목록에서 사라진다
Future<void> bookmarkRemovedFromList(BookmarkWorld world) async {
  final deleted = world.deletedBookmark;
  expect(deleted, isNotNull);
  expect(world.panel!.map((e) => e.seq), isNot(contains(deleted!.seq)));
}

/// Usage: Then 데이터 저장소에서도 삭제된다
Future<void> bookmarkDeletedFromStore(BookmarkWorld world) async {
  final deleted = world.deletedBookmark;
  expect(deleted, isNotNull);
  expect(world.store.map((e) => e.seq), isNot(contains(deleted!.seq)));
}

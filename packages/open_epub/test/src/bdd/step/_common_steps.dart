// BDD Common Steps — open_epub 1.0
// Story: S1.21 (#37) — BDD widget 통합
//
// 모든 feature가 공유하는 테스트 하니스([BddWorld])와 공통 step.
// 'kobic 사용자가 로그인되어 있다' 같은 호스트 앱 전제는 패키지 테스트
// 하니스에서 항상 충족된 것으로 간주한다 (실제 호스트 통합은 E3 범위).

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:open_epub/open_epub_v1.dart';

import '../../../unit/_fixtures/epub_fixtures.dart';

/// 시나리오 1개의 상태를 담는 테스트 하니스. 각 테스트에서 새로 만들고
/// tearDown에서 [dispose]한다.
class BddWorld {
  /// 다음 [openSession] 호출이 읽을 EPUB 바이트 (기본: validEpub3).
  Uint8List? bytes;

  EpubBookSession? session;

  /// 구독으로 수집된 분석 이벤트.
  final List<EpubLifecycleEvent> lifecycle = [];
  final List<EpubProgressEvent> progressEvents = [];
  final List<EpubToolUseEvent> toolUse = [];

  /// 저장된 BookPosition v1 토큰 (이어 읽기 시나리오).
  String? savedToken;

  /// open 실패 시 잡힌 예외.
  Object? lastError;

  /// 테스트 기본은 throttle 없음. throttle 시나리오에서만 덮어쓴다.
  Duration progressThrottle = Duration.zero;

  EpubSecurityConfig security = const EpubSecurityConfig();

  final List<StreamSubscription<Object?>> _subs = [];

  /// [reopenWith]로 교체되어 은퇴한 세션들. tearDown(real async zone)에서
  /// 일괄 dispose — fake async(test 본문)에서의 dispose는 pump를 멈출 수 있다.
  final List<EpubBookSession> _retired = [];

  EpubBookSession get requireSession {
    expect(session, isNotNull,
        reason: '세션이 열려 있어야 합니다 (openSession 선행 필요)');
    return session!;
  }

  /// [bytes]로 세션을 연다. 실패는 [lastError]에 담는다.
  Future<void> openSession({EpubPosition? initialPosition}) async {
    bytes ??= validEpub3();
    EpubPosition? target = initialPosition;
    if (target == null && savedToken != null) {
      target = EpubPosition.fromToken(savedToken!);
    }
    try {
      final s = await EpubBookSession.open(
        EpubSource.bytes(bytes!),
        initialPosition: target,
        options: EpubSessionOptions(
          progressThrottle: progressThrottle,
          security: security,
        ),
      );
      session = s;
      _subs
        ..add(s.lifecycleEvents.listen(lifecycle.add))
        ..add(s.progressEvents.listen(progressEvents.add))
        ..add(s.toolUseEvents.listen(toolUse.add));
      await settle();
    } on Object catch (e) {
      lastError = e;
    }
  }

  /// 현재 세션을 은퇴시키고 [newBytes]로 새 세션을 연다. 테스트 본문
  /// (fake async) 안에서 책을 갈아끼울 때 사용 — dispose는 tearDown으로 미룬다.
  Future<void> reopenWith(Uint8List newBytes) async {
    final old = session;
    if (old != null) _retired.add(old);
    session = null;
    bytes = newBytes;
    await openSession();
  }

  /// broadcast stream 전달·lifecycle 버퍼 재생(microtask)을 흘려보낸다.
  /// timer를 쓰지 않으므로 testWidgets(fake async)에서도 안전하다.
  Future<void> settle() async {
    for (var i = 0; i < 8; i++) {
      await Future<void>.microtask(() {});
    }
  }

  /// 진단(보정 patchId + 미해결 이슈 code) 전체 목록.
  List<String> get diagnosticCodes {
    final d = requireSession.diagnostics;
    return [
      ...d.appliedPatches.map((p) => p.patchId),
      ...d.unresolvedIssues.map((i) => i.code),
    ];
  }

  Future<void> dispose() async {
    for (final sub in _subs) {
      await sub.cancel();
    }
    _subs.clear();
    for (final retired in _retired) {
      await retired.dispose();
    }
    _retired.clear();
    await session?.dispose();
    session = null;
  }
}

/// Usage: Given kobic 사용자가 로그인되어 있다
/// 호스트 앱 전제 — 패키지 하니스에서는 항상 충족 (E3에서 실제 통합).
Future<void> kobicUserIsLoggedIn(BddWorld world) async {}

/// Usage: Given 사용자 라이브러리에 EPUB 책 "`<filename>`"이 있다
Future<void> userLibraryHasEpubBook(BddWorld world, String filename) async {
  world.bytes ??= validEpub3();
}

/// Usage: Given 사용자가 라이브러리 화면에 있다
/// 호스트 앱 전제 — 패키지 하니스에서는 항상 충족.
Future<void> userIsOnLibraryScreen(BddWorld world) async {}

/// Usage: When 사용자가 "`<filename>`" 항목을 탭한다
Future<void> userTapsBookItem(BddWorld world, String filename) async {
  await world.openSession();
}

/// Usage: Given Reflowable EPUB "`<filename>`"이 열려 있다
Future<void> reflowableEpubIsOpen(BddWorld world, String filename) async {
  world.bytes = validEpub3();
  await world.openSession();
  expect(world.requireSession.book.layout, EpubLayout.reflowable);
}

/// Usage: Given Fixed Layout EPUB "`<filename>`"이 열려 있다
Future<void> fixedLayoutEpubIsOpen(BddWorld world, String filename) async {
  world.bytes = fixedLayoutEpub3();
  await world.openSession();
  expect(world.requireSession.book.layout, EpubLayout.fixedLayout);
}

/// Usage: Then 진단 이벤트 "`<name>`"가 기록된다
Future<void> diagnosticEventIsRecorded(BddWorld world, String name) async {
  expect(world.diagnosticCodes, contains(name));
}

/// Usage: Then 뷰어가 해당 BookPosition으로 이동한다
Future<void> viewerJumpsToBookPosition(BddWorld world) async {
  final session = world.requireSession;
  expect(
    session.book.spine.map((s) => s.href),
    contains(session.position.spineHref),
  );
}

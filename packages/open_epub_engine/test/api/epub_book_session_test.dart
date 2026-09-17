// Story: S1.21 (#37) — EpubBookSession.open() end-to-end tests
// BDD: F1 (첫 열람), F1.2/F1.3 (위치 복원/fallback), F11 (analytics)

import 'package:test/test.dart';
import 'package:open_epub_engine/src/api/epub_analytics.dart';
import 'package:open_epub_engine/src/api/epub_book_session.dart';
import 'package:open_epub_engine/src/api/epub_position.dart';
import 'package:open_epub_engine/src/api/epub_source.dart';

import 'package:open_epub_engine/testing.dart';

Future<void> _tick() => Future<void>.delayed(Duration.zero);

void main() {
  group('EpubBookSession.open — 첫 열람 (F1)', () {
    test('책을 열면 메타데이터·spine·목차가 조립된다', () async {
      final session = await EpubBookSession.open(
        EpubSource.bytes(validEpub3()),
      );
      addTearDown(session.dispose);

      expect(session.book.metadata.title, '테스트 책');
      expect(session.book.spine, hasLength(2));
      expect(session.book.outline.items, hasLength(2));
    });

    test('첫 열람의 진도는 0.0이고 첫 spine을 가리킨다', () async {
      final session = await EpubBookSession.open(
        EpubSource.bytes(validEpub3()),
      );
      addTearDown(session.dispose);

      expect(session.progress, 0.0);
      expect(session.position.spineHref, 'ch1.xhtml');
    });

    test('sparse-NCX 책은 open 시 보정이 적용된다 (목차 1→4)', () async {
      final session = await EpubBookSession.open(
        EpubSource.bytes(sparseNcxEpub2()),
      );
      addTearDown(session.dispose);

      expect(session.book.outline.items, hasLength(4));
      final ids = session.diagnostics.appliedPatches.map((p) => p.patchId);
      expect(ids, contains('sparse-ncx'));
    });
  });

  group('analytics (F11)', () {
    test('lifecycleEvents에 SessionStarted가 발사된다', () async {
      final session = await EpubBookSession.open(
        EpubSource.bytes(validEpub3()),
      );
      addTearDown(session.dispose);

      final events = <EpubLifecycleEvent>[];
      session.lifecycleEvents.listen(events.add);
      await _tick(); // onListen 버퍼 flush

      final started = events.whereType<EpubSessionStarted>();
      expect(started, isNotEmpty);
      expect(started.first.epubVersion, '3.0');
    });

    test('dispose 시 SessionEnded가 발사된다', () async {
      final session = await EpubBookSession.open(
        EpubSource.bytes(validEpub3()),
      );

      final events = <EpubLifecycleEvent>[];
      session.lifecycleEvents.listen(events.add);
      await _tick();

      await session.dispose();
      await _tick();

      expect(events.whereType<EpubSessionEnded>(), isNotEmpty);
    });

    test('페이지 이동 시 progressEvents가 발사된다', () async {
      final session = await EpubBookSession.open(
        EpubSource.bytes(validEpub3()),
      );
      addTearDown(session.dispose);

      final events = <EpubProgressEvent>[];
      session.progressEvents.listen(events.add);

      await session.nextPage();
      await _tick();

      expect(events, isNotEmpty);
      expect(events.last.progress, 1.0);
    });
  });

  group('페이지 네비게이션', () {
    test('nextPage/previousPage가 spine을 이동하고 경계를 지킨다', () async {
      final session = await EpubBookSession.open(
        EpubSource.bytes(validEpub3()),
      );
      addTearDown(session.dispose);

      expect(session.position.spineHref, 'ch1.xhtml');

      await session.nextPage();
      expect(session.position.spineHref, 'ch2.xhtml');
      expect(session.progress, 1.0);

      await session.nextPage(); // 끝 — 변화 없음
      expect(session.position.spineHref, 'ch2.xhtml');

      await session.previousPage();
      expect(session.position.spineHref, 'ch1.xhtml');
      expect(session.progress, 0.0);

      await session.previousPage(); // 처음 — 변화 없음
      expect(session.position.spineHref, 'ch1.xhtml');
    });

    test('jumpTo는 위치를 갱신한다', () async {
      final session = await EpubBookSession.open(
        EpubSource.bytes(validEpub3()),
      );
      addTearDown(session.dispose);

      const target = EpubReflowablePosition(
        spineHref: 'ch2.xhtml',
        progress: 0.7,
        charOffset: 42,
      );
      await session.jumpTo(target);
      expect(session.position, target);
    });
  });

  group('위치 복원 (F1.2 / F1.3)', () {
    test('유효한 initialPosition은 그대로 복원된다', () async {
      // ch2 본문("2장")은 평문 2자 — charOffset은 그 범위 내여야 '유효'다.
      // (S12.3부터 open 시 out-of-range charOffset은 콘텐츠 길이로 clamp된다.)
      const saved = EpubReflowablePosition(
        spineHref: 'ch2.xhtml',
        progress: 0.45,
        charOffset: 1,
      );
      final session = await EpubBookSession.open(
        EpubSource.bytes(validEpub3()),
        initialPosition: saved,
      );
      addTearDown(session.dispose);

      expect(session.position, saved);
      expect(session.progress, 0.45);
      expect(
        session.diagnostics.unresolvedIssues.map((i) => i.code),
        isNot(contains('position-restore-failed')),
      );
    });

    test('spineHref 소실 시 첫 페이지 fallback + 진단 기록', () async {
      const saved = EpubReflowablePosition(
        spineHref: 'deleted.xhtml',
        progress: 0.8,
        charOffset: 9,
      );
      final session = await EpubBookSession.open(
        EpubSource.bytes(validEpub3()),
        initialPosition: saved,
      );
      addTearDown(session.dispose);

      expect(session.position.spineHref, 'ch1.xhtml');
      expect(session.progress, 0.0);
      expect(
        session.diagnostics.unresolvedIssues.map((i) => i.code),
        contains('position-restore-failed'),
      );
    });
  });

  group('toolUse & progress throttle (S1.23)', () {
    test('recordHighlight/recordBookmark가 toolUseEvents에 발사된다', () async {
      final session = await EpubBookSession.open(
        EpubSource.bytes(validEpub3()),
      );
      addTearDown(session.dispose);

      final events = <EpubToolUseEvent>[];
      session.toolUseEvents.listen(events.add);

      session.recordHighlight();
      session.recordBookmark();
      await _tick();

      expect(events.whereType<EpubHighlightToolUse>(), isNotEmpty);
      expect(events.whereType<EpubBookmarkToolUse>(), isNotEmpty);
      expect(
        (events.first as EpubHighlightToolUse).position.spineHref,
        'ch1.xhtml',
      );
    });

    test('progressEvents는 throttle 간격 내 중복을 억제한다', () async {
      final session = await EpubBookSession.open(
        EpubSource.bytes(validEpub3()),
        options: const EpubSessionOptions(
          progressThrottle: Duration(minutes: 1),
        ),
      );
      addTearDown(session.dispose);

      final events = <EpubProgressEvent>[];
      session.progressEvents.listen(events.add);

      await session.nextPage();
      await session.previousPage();
      await _tick();

      expect(events, hasLength(1)); // 첫 발사만, 이후 throttle로 억제
    });

    test('throttle 0이면 매 이동마다 발사', () async {
      final session = await EpubBookSession.open(
        EpubSource.bytes(validEpub3()),
        options: const EpubSessionOptions(progressThrottle: Duration.zero),
      );
      addTearDown(session.dispose);

      final events = <EpubProgressEvent>[];
      session.progressEvents.listen(events.add);

      await session.nextPage();
      await session.previousPage();
      await _tick();

      expect(events.length, greaterThanOrEqualTo(2));
    });
  });

  group('hot-swap (F10 / S1.22)', () {
    test('같은 spineHref면 위치를 보존하며 책을 교체한다', () async {
      final session = await EpubBookSession.open(
        EpubSource.bytes(validEpub3()),
      );
      addTearDown(session.dispose);

      await session.nextPage(); // ch2
      expect(session.position.spineHref, 'ch2.xhtml');

      await session.swapSource(EpubSource.bytes(swappedEpub3()));

      expect(session.book.metadata.title, '교체된 책');
      expect(session.position.spineHref, 'ch2.xhtml'); // 보존
    });

    test('교체 대상에 위치가 없으면 fallback + 진단 기록', () async {
      final session = await EpubBookSession.open(
        EpubSource.bytes(validEpub3()),
      );
      addTearDown(session.dispose);

      await session.nextPage(); // ch2
      await session.swapSource(EpubSource.bytes(singleChapterEpub3()));

      expect(session.book.metadata.title, '단일 챕터 책');
      expect(session.position.spineHref, 'ch1.xhtml'); // fallback
      expect(
        session.diagnostics.unresolvedIssues.map((i) => i.code),
        contains('position-restore-failed'),
      );
    });

    test('dispose 후 swapSource는 StateError', () async {
      final session = await EpubBookSession.open(
        EpubSource.bytes(validEpub3()),
      );
      await session.dispose();
      expect(
        session.swapSource(EpubSource.bytes(validEpub3())),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('dispose 이후 보호', () {
    test('dispose 후 nextPage는 StateError', () async {
      final session = await EpubBookSession.open(
        EpubSource.bytes(validEpub3()),
      );
      await session.dispose();
      expect(session.nextPage(), throwsA(isA<StateError>()));
    });
  });
}

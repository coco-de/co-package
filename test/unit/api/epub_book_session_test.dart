// Story: S1.21 (#37) — EpubBookSession.open() end-to-end tests
// BDD: F1 (첫 열람), F1.2/F1.3 (위치 복원/fallback), F11 (analytics)

import 'package:flutter_test/flutter_test.dart';
import 'package:open_epub/src/api/epub_analytics.dart';
import 'package:open_epub/src/api/epub_book_session.dart';
import 'package:open_epub/src/api/epub_position.dart';
import 'package:open_epub/src/api/epub_source.dart';

import '../_fixtures/epub_fixtures.dart';

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
      const saved = EpubReflowablePosition(
        spineHref: 'ch2.xhtml',
        progress: 0.45,
        charOffset: 100,
      );
      final session = await EpubBookSession.open(
        EpubSource.bytes(validEpub3()),
        initialPosition: saved,
      );
      addTearDown(session.dispose);

      expect(session.position, saved);
      expect(session.progress, 0.45);
      expect(
        session.diagnostics.unresolvedIssues
            .map((i) => i.code),
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

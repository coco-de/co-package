// Story: S1.5-2/3/4/6/7/8 (E1.5) — EpubBookSession selection/highlight/search 통합

import 'package:flutter_test/flutter_test.dart';
import 'package:open_epub/src/api/epub_book_session.dart';
import 'package:open_epub/src/api/epub_source.dart';
import 'package:open_epub/src/domain/entity/epub_highlight.dart';
import 'package:open_epub/src/domain/entity/epub_selection.dart';

import '../_fixtures/epub_fixtures.dart';

Future<void> _tick() => Future<void>.delayed(Duration.zero);

void main() {
  Future<EpubBookSession> open() =>
      EpubBookSession.open(EpubSource.bytes(searchableEpub3()));

  group('resolveSelection (S1.5-3)', () {
    test('본문 텍스트를 EpubSelection으로 변환', () async {
      final session = await open();
      addTearDown(session.dispose);

      final sel = session.resolveSelection('ch1.xhtml', '바다에');
      expect(sel, isNotNull);
      expect(sel!.selectedText, '바다에');
      expect(sel.length, 3);
      expect(sel.spineHref, 'ch1.xhtml');
    });

    test('일치하지 않으면 null', () async {
      final session = await open();
      addTearDown(session.dispose);
      expect(session.resolveSelection('ch1.xhtml', '없는문장'), isNull);
    });
  });

  group('selectionStream (S1.5-2)', () {
    test('reportSelection이 stream으로 전달된다', () async {
      final session = await open();
      addTearDown(session.dispose);

      final seen = <EpubSelection?>[];
      final sub = session.selectionStream.listen(seen.add);

      final sel = session.resolveSelection('ch1.xhtml', '바다에');
      session.reportSelection(sel);
      session.reportSelection(null);
      await _tick();

      expect(seen, [sel, null]);
      await sub.cancel();
    });
  });

  group('readSpineXhtmlWithHighlights (S1.5-4/7)', () {
    test('선택으로 만든 하이라이트가 본문에 배경색 span으로 렌더된다', () async {
      final session = await open();
      addTearDown(session.dispose);

      final sel = session.resolveSelection('ch1.xhtml', '바다에')!;
      final h =
          EpubHighlight.fromSelection(sel, id: 'h1', colorArgb: 0xFFFFF59D);

      final rendered = session.readSpineXhtmlWithHighlights('ch1.xhtml', [h]);
      expect(rendered, isNotNull);
      expect(
        rendered,
        contains('background-color:#FFF59D;">바다에</span>'),
      );
    });

    test('다른 spine의 하이라이트는 무시한다', () async {
      final session = await open();
      addTearDown(session.dispose);

      final h = EpubHighlight(
        id: 'h1',
        spineHref: 'ch2.xhtml',
        start: 0,
        end: 2,
        selectedText: '사자',
        colorArgb: 0xFFFFF59D,
      );
      final rendered = session.readSpineXhtmlWithHighlights('ch1.xhtml', [h]);
      expect(rendered, isNot(contains('<span')));
    });
  });

  group('buildSearchIndex + positionForHit (S1.5-5/6/8)', () {
    test('전체 spine을 인덱싱하고 hit을 점프 위치로 변환', () async {
      final session = await open();
      addTearDown(session.dispose);

      final index = await session.buildSearchIndex();
      final hits = await index.search('바다');
      expect(hits, isNotEmpty);

      // ch1이 첫 spine — 첫 hit은 ch1을 가리킨다.
      final first = hits.first;
      expect(first.spineHref, 'ch1.xhtml');

      final pos = session.positionForHit(first);
      expect(pos.spineHref, 'ch1.xhtml');
      expect(pos.charOffset, first.charOffset);
      expect(pos.progress, 0.0);
    });

    test('outline getter는 책 목차를 노출한다 (S1.5-8)', () async {
      final session = await open();
      addTearDown(session.dispose);
      expect(session.outline.items, hasLength(3));
    });
  });
}

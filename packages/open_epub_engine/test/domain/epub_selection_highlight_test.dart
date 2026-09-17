// Story: S1.5-1/4 (E1.5) — EpubSelection / EpubHighlight 엔티티 테스트

import 'package:test/test.dart';
import 'package:open_epub_engine/src/api/epub_position.dart';
import 'package:open_epub_engine/src/domain/entity/epub_highlight.dart';
import 'package:open_epub_engine/src/domain/entity/epub_selection.dart';

void main() {
  group('EpubSelection', () {
    test('length / isCollapsed', () {
      final sel = EpubSelection(
        spineHref: 'ch.xhtml',
        start: 4,
        end: 7,
        selectedText: '바다에',
      );
      expect(sel.length, 3);
      expect(sel.isCollapsed, isFalse);
    });

    test('toStartPosition은 charOffset=start인 Reflowable 위치', () {
      final sel = EpubSelection(
        spineHref: 'ch.xhtml',
        start: 12,
        end: 20,
        selectedText: 'abcdefgh',
      );
      final pos = sel.toStartPosition(progress: 0.5);
      expect(pos, isA<EpubReflowablePosition>());
      expect(pos.charOffset, 12);
      expect(pos.spineHref, 'ch.xhtml');
      expect(pos.progress, 0.5);
    });

    test('값 동등성', () {
      EpubSelection make() => EpubSelection(
            spineHref: 'a',
            start: 1,
            end: 2,
            selectedText: 'x',
          );
      expect(make(), make());
      expect(make().hashCode, make().hashCode);
    });
  });

  group('EpubHighlight', () {
    test('fromSelection으로 생성', () {
      final sel = EpubSelection(
        spineHref: 'ch.xhtml',
        start: 4,
        end: 7,
        selectedText: '바다에',
      );
      final h = EpubHighlight.fromSelection(
        sel,
        id: 'h1',
        colorArgb: 0xFFFFF59D,
        note: '중요',
      );
      expect(h.spineHref, 'ch.xhtml');
      expect(h.start, 4);
      expect(h.end, 7);
      expect(h.selectedText, '바다에');
      expect(h.colorArgb, 0xFFFFF59D);
      expect(h.note, '중요');
    });

    test('toJson/fromJson 라운드트립', () {
      final h = EpubHighlight(
        id: 'h1',
        spineHref: 'ch.xhtml',
        start: 4,
        end: 7,
        selectedText: '바다에',
        colorArgb: 0xFFC8E6C9,
        note: '메모',
      );
      final back = EpubHighlight.fromJson(h.toJson());
      expect(back, h);
    });

    test('copyWith는 color/note만 교체', () {
      final h = EpubHighlight(
        id: 'h1',
        spineHref: 'ch.xhtml',
        start: 0,
        end: 1,
        selectedText: 'x',
        colorArgb: 0xFFFFF59D,
      );
      final c = h.copyWith(colorArgb: 0xFFBBDEFB, note: '추가');
      expect(c.colorArgb, 0xFFBBDEFB);
      expect(c.note, '추가');
      expect(c.id, h.id);
      expect(c.start, h.start);
    });
  });
}

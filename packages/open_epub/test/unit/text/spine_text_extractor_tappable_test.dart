// Story: S7.3 (E7) — 탭 가능한 하이라이트 주입 + 링크 스킴 파서

import 'package:flutter_test/flutter_test.dart';
import 'package:open_epub/src/data/text/spine_text_extractor.dart';
import 'package:open_epub/src/domain/entity/epub_highlight.dart';

const _extractor = SpineTextExtractor();

EpubHighlight _hl(String id, int start, int end) => EpubHighlight(
      id: id,
      spineHref: 'ch.xhtml',
      start: start,
      end: end,
      selectedText: '',
      colorArgb: 0xFFFFF59D,
    );

void main() {
  test('tappable: true는 openepub-hl 스킴의 <a>로 감싼다', () {
    const xhtml = '<body><p>abcdef</p></body>';
    final out = _extractor.injectHighlights(
      xhtml,
      [_hl('h1', 0, 3)],
      tappable: true,
    );
    expect(out, contains('<a href="openepub-hl:h1"'));
    expect(out, contains('background-color:#FFF59D;'));
    expect(out, contains('text-decoration:none;'));
    expect(out, contains('>abc</a>'));
  });

  test('tappable: false(기본)는 <span>으로 감싼다', () {
    const xhtml = '<body><p>abcdef</p></body>';
    final out = _extractor.injectHighlights(xhtml, [_hl('h1', 0, 3)]);
    expect(out, contains('<span style="background-color:#FFF59D;">abc</span>'));
    expect(out, isNot(contains('<a href')));
  });

  group('highlightIdFromHref', () {
    test('하이라이트 링크에서 id 추출', () {
      expect(SpineTextExtractor.highlightIdFromHref('openepub-hl:h42'), 'h42');
    });
    test('일반 링크는 null', () {
      expect(SpineTextExtractor.highlightIdFromHref('ch2.xhtml'), isNull);
      expect(
        SpineTextExtractor.highlightIdFromHref('https://example.com'),
        isNull,
      );
    });
  });
}

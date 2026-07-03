// Story: S1.2 (#8) — NCX parser tests
// BDD: F4 (목차)

import 'package:flutter_test/flutter_test.dart';
import 'package:open_epub_engine/src/data/parser/ncx_parser.dart';
import 'package:open_epub_engine/src/domain/entity/epub_outline.dart';

void main() {
  const parser = NcxParser();

  group('NcxParser.parse — 표준 구조', () {
    test('단일 레벨 navPoint 3개', () {
      const ncx = '''
<?xml version="1.0" encoding="UTF-8"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <head/>
  <docTitle><text>책</text></docTitle>
  <navMap>
    <navPoint id="np1" playOrder="1">
      <navLabel><text>1장. 시작</text></navLabel>
      <content src="ch01.xhtml"/>
    </navPoint>
    <navPoint id="np2" playOrder="2">
      <navLabel><text>2장. 본론</text></navLabel>
      <content src="ch02.xhtml"/>
    </navPoint>
    <navPoint id="np3" playOrder="3">
      <navLabel><text>3장. 결론</text></navLabel>
      <content src="ch03.xhtml"/>
    </navPoint>
  </navMap>
</ncx>''';
      final outline = parser.parse(ncx);
      expect(outline.items, hasLength(3));
      expect(outline.items[0].title, '1장. 시작');
      expect(outline.items[0].spineHref, 'ch01.xhtml');
      expect(outline.items[0].children, isEmpty);
      expect(outline.items[2].title, '3장. 결론');
    });

    test('중첩 navPoint (2 레벨)', () {
      const ncx = '''
<?xml version="1.0"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <navMap>
    <navPoint id="np1" playOrder="1">
      <navLabel><text>1장</text></navLabel>
      <content src="ch01.xhtml"/>
      <navPoint id="np1-1" playOrder="2">
        <navLabel><text>1.1절</text></navLabel>
        <content src="ch01.xhtml#sec1"/>
      </navPoint>
      <navPoint id="np1-2" playOrder="3">
        <navLabel><text>1.2절</text></navLabel>
        <content src="ch01.xhtml#sec2"/>
      </navPoint>
    </navPoint>
  </navMap>
</ncx>''';
      final outline = parser.parse(ncx);
      expect(outline.items, hasLength(1));
      final chapter = outline.items[0];
      expect(chapter.title, '1장');
      expect(chapter.children, hasLength(2));
      expect(chapter.children[0].title, '1.1절');
      expect(chapter.children[0].spineHref, 'ch01.xhtml');
      expect(chapter.children[1].spineHref, 'ch01.xhtml');
    });

    test('5 레벨 중첩까지 정상 파싱', () {
      const ncx = '''
<?xml version="1.0"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <navMap>
    <navPoint id="l1"><navLabel><text>L1</text></navLabel><content src="a.xhtml"/>
      <navPoint id="l2"><navLabel><text>L2</text></navLabel><content src="a.xhtml#l2"/>
        <navPoint id="l3"><navLabel><text>L3</text></navLabel><content src="a.xhtml#l3"/>
          <navPoint id="l4"><navLabel><text>L4</text></navLabel><content src="a.xhtml#l4"/>
            <navPoint id="l5"><navLabel><text>L5</text></navLabel><content src="a.xhtml#l5"/>
            </navPoint>
          </navPoint>
        </navPoint>
      </navPoint>
    </navPoint>
  </navMap>
</ncx>''';
      final outline = parser.parse(ncx);
      EpubOutlineItem cur = outline.items[0];
      for (final expected in ['L1', 'L2', 'L3', 'L4', 'L5']) {
        expect(cur.title, expected);
        if (expected != 'L5') {
          expect(cur.children, hasLength(1));
          cur = cur.children[0];
        } else {
          expect(cur.children, isEmpty);
        }
      }
    });

    test('content src fragment(#)는 spineHref에서 제외', () {
      const ncx = '''
<?xml version="1.0"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <navMap>
    <navPoint><navLabel><text>x</text></navLabel><content src="ch.xhtml#anchor-42"/></navPoint>
  </navMap>
</ncx>''';
      final outline = parser.parse(ncx);
      expect(outline.items[0].spineHref, 'ch.xhtml');
    });
  });

  group('NcxParser.parse — 결측·엣지', () {
    test('navMap이 비어 있으면 EpubOutline.empty', () {
      const ncx = '''
<?xml version="1.0"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <navMap/>
</ncx>''';
      final outline = parser.parse(ncx);
      expect(outline.items, isEmpty);
    });

    test('navMap 자체가 없으면 EpubOutline.empty', () {
      const ncx = '''
<?xml version="1.0"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <head/>
</ncx>''';
      final outline = parser.parse(ncx);
      expect(outline.items, isEmpty);
    });

    test('navLabel/text 없는 navPoint는 결과에서 skip', () {
      const ncx = '''
<?xml version="1.0"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <navMap>
    <navPoint><navLabel><text>OK</text></navLabel><content src="ok.xhtml"/></navPoint>
    <navPoint><content src="no-label.xhtml"/></navPoint>
  </navMap>
</ncx>''';
      final outline = parser.parse(ncx);
      expect(outline.items, hasLength(1));
      expect(outline.items[0].title, 'OK');
    });

    test('content src 없는 navPoint는 skip', () {
      const ncx = '''
<?xml version="1.0"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <navMap>
    <navPoint><navLabel><text>OK</text></navLabel><content src="ok.xhtml"/></navPoint>
    <navPoint><navLabel><text>NoSrc</text></navLabel></navPoint>
  </navMap>
</ncx>''';
      final outline = parser.parse(ncx);
      expect(outline.items, hasLength(1));
      expect(outline.items[0].title, 'OK');
    });

    test('빈 text는 skip', () {
      const ncx = '''
<?xml version="1.0"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <navMap>
    <navPoint><navLabel><text>OK</text></navLabel><content src="ok.xhtml"/></navPoint>
    <navPoint><navLabel><text></text></navLabel><content src="empty.xhtml"/></navPoint>
  </navMap>
</ncx>''';
      final outline = parser.parse(ncx);
      expect(outline.items, hasLength(1));
    });
  });

  group('NcxParser.parse — error cases', () {
    test('잘못된 XML이면 NcxParseException', () {
      expect(
        () => parser.parse('not <xml>'),
        throwsA(isA<NcxParseException>()),
      );
    });

    test('root가 <ncx>가 아니면 NcxParseException', () {
      expect(
        () => parser.parse('<?xml version="1.0"?><root/>'),
        throwsA(isA<NcxParseException>()),
      );
    });

    test('NCX namespace가 아니면 NcxParseException', () {
      const wrongNs = '''
<?xml version="1.0"?>
<ncx xmlns="http://example.com/wrong" version="2005-1"/>''';
      expect(
        () => parser.parse(wrongNs),
        throwsA(isA<NcxParseException>()),
      );
    });
  });
}

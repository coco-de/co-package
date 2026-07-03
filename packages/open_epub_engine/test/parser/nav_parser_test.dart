// Story: S1.3 (#9) — nav.xhtml parser tests
// BDD: F4 (EPUB 3 nav 목차)

import 'package:test/test.dart';
import 'package:open_epub_engine/src/data/parser/nav_parser.dart';

void main() {
  const parser = NavParser();

  group('NavParser.parse — 표준 구조', () {
    test('epub:type="toc" nav에서 5 챕터 추출 (BDD F4.1)', () {
      const xml = '''
<?xml version="1.0" encoding="utf-8"?>
<html xmlns="http://www.w3.org/1999/xhtml"
      xmlns:epub="http://www.idpf.org/2007/ops">
  <head><title>TOC</title></head>
  <body>
    <nav epub:type="toc">
      <h1>Contents</h1>
      <ol>
        <li><a href="ch01.xhtml">1장. 시작</a></li>
        <li><a href="ch02.xhtml">2장. 기초</a></li>
        <li><a href="ch03.xhtml">3장. 시작하기</a></li>
        <li><a href="ch04.xhtml">4장. 심화</a></li>
        <li><a href="ch05.xhtml">5장. 마무리</a></li>
      </ol>
    </nav>
  </body>
</html>''';
      final outline = parser.parse(xml);
      expect(outline.items, hasLength(5));
      expect(outline.items[0].title, '1장. 시작');
      expect(outline.items[0].spineHref, 'ch01.xhtml');
      expect(outline.items[2].title, '3장. 시작하기');
      expect(outline.items[4].title, '5장. 마무리');
    });

    test('중첩 ol/li 트리', () {
      const xml = '''
<?xml version="1.0"?>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
  <body>
    <nav epub:type="toc">
      <ol>
        <li><a href="ch01.xhtml">1장</a>
          <ol>
            <li><a href="ch01.xhtml#sec1">1.1절</a></li>
            <li><a href="ch01.xhtml#sec2">1.2절</a></li>
          </ol>
        </li>
        <li><a href="ch02.xhtml">2장</a></li>
      </ol>
    </nav>
  </body>
</html>''';
      final outline = parser.parse(xml);
      expect(outline.items, hasLength(2));
      expect(outline.items[0].children, hasLength(2));
      expect(outline.items[0].children[0].title, '1.1절');
      expect(outline.items[0].children[0].spineHref, 'ch01.xhtml');
      expect(outline.items[1].title, '2장');
      expect(outline.items[1].children, isEmpty);
    });

    test('href fragment(#)는 spineHref에서 제외', () {
      const xml = '''
<?xml version="1.0"?>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
  <body><nav epub:type="toc"><ol>
    <li><a href="ch.xhtml#anchor-42">x</a></li>
  </ol></nav></body>
</html>''';
      final outline = parser.parse(xml);
      expect(outline.items[0].spineHref, 'ch.xhtml');
    });

    test('epub:type 없는 첫 nav를 fallback으로 사용', () {
      const xml = '''
<?xml version="1.0"?>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
  <body>
    <nav>
      <ol><li><a href="a.xhtml">A</a></li></ol>
    </nav>
  </body>
</html>''';
      final outline = parser.parse(xml);
      expect(outline.items, hasLength(1));
      expect(outline.items[0].title, 'A');
    });

    test('여러 nav 중 epub:type="toc"를 우선 선택', () {
      const xml = '''
<?xml version="1.0"?>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
  <body>
    <nav epub:type="landmarks">
      <ol><li><a href="land.xhtml">L</a></li></ol>
    </nav>
    <nav epub:type="toc">
      <ol><li><a href="toc-item.xhtml">T</a></li></ol>
    </nav>
  </body>
</html>''';
      final outline = parser.parse(xml);
      expect(outline.items, hasLength(1));
      expect(outline.items[0].title, 'T');
    });
  });

  group('NavParser.parse — 결측·엣지', () {
    test('body 없음 → empty', () {
      const xml = '''
<?xml version="1.0"?>
<html xmlns="http://www.w3.org/1999/xhtml"/>''';
      expect(parser.parse(xml).items, isEmpty);
    });

    test('nav 없음 → empty', () {
      const xml = '''
<?xml version="1.0"?>
<html xmlns="http://www.w3.org/1999/xhtml"><body><p>no nav</p></body></html>''';
      expect(parser.parse(xml).items, isEmpty);
    });

    test('nav 안에 ol 없음 → empty', () {
      const xml = '''
<?xml version="1.0"?>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
  <body><nav epub:type="toc"><h1>Empty</h1></nav></body>
</html>''';
      expect(parser.parse(xml).items, isEmpty);
    });

    test('li에 a 없음 → skip', () {
      const xml = '''
<?xml version="1.0"?>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
  <body><nav epub:type="toc"><ol>
    <li><a href="ok.xhtml">OK</a></li>
    <li><span>no anchor</span></li>
  </ol></nav></body>
</html>''';
      final outline = parser.parse(xml);
      expect(outline.items, hasLength(1));
      expect(outline.items[0].title, 'OK');
    });

    test('a에 href 없음 → skip', () {
      const xml = '''
<?xml version="1.0"?>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
  <body><nav epub:type="toc"><ol>
    <li><a href="ok.xhtml">OK</a></li>
    <li><a>no href</a></li>
  </ol></nav></body>
</html>''';
      final outline = parser.parse(xml);
      expect(outline.items, hasLength(1));
    });

    test('a 안의 빈 text → skip', () {
      const xml = '''
<?xml version="1.0"?>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
  <body><nav epub:type="toc"><ol>
    <li><a href="ok.xhtml">OK</a></li>
    <li><a href="empty.xhtml"></a></li>
  </ol></nav></body>
</html>''';
      final outline = parser.parse(xml);
      expect(outline.items, hasLength(1));
    });
  });

  group('NavParser.parse — error cases', () {
    test('잘못된 XML이면 NavParseException', () {
      expect(
        () => parser.parse('not <xml>'),
        throwsA(isA<NavParseException>()),
      );
    });

    test('root가 <html>이 아니면 NavParseException', () {
      expect(
        () => parser.parse('<?xml version="1.0"?><root/>'),
        throwsA(isA<NavParseException>()),
      );
    });

    test('XHTML namespace가 아니면 NavParseException', () {
      const wrongNs = '''
<?xml version="1.0"?>
<html xmlns="http://example.com/wrong"/>''';
      expect(() => parser.parse(wrongNs), throwsA(isA<NavParseException>()));
    });
  });
}

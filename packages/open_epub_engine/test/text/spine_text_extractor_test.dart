// Story: S1.5-3/4/5 (E1.5) — SpineTextExtractor 단위 테스트

import 'package:test/test.dart';
import 'package:open_epub_engine/src/data/text/spine_text_extractor.dart';
import 'package:open_epub_engine/src/domain/entity/epub_highlight.dart';

const _extractor = SpineTextExtractor();

EpubHighlight _hl(int start, int end, {int color = 0xFFFFF59D}) =>
    EpubHighlight(
      id: 'h$start',
      spineHref: 'ch.xhtml',
      start: start,
      end: end,
      selectedText: '',
      colorArgb: color,
    );

void main() {
  group('extractPlainText (S1.5-5)', () {
    test('body 내 태그 밖 텍스트만 이어붙인다', () {
      const xhtml = '<html><head><title>무시</title></head>'
          '<body><p>Hello <b>World</b> end</p></body></html>';
      expect(_extractor.extractPlainText(xhtml), 'Hello World end');
    });

    test('body가 없으면 전체에서 태그 밖 텍스트를 추출', () {
      expect(_extractor.extractPlainText('<p>abc</p>'), 'abc');
    });

    test('script/style 요소 내용은 제외한다', () {
      const xhtml = '<body><p>keep</p>'
          '<script>var drop = 1;</script>'
          '<style>.x{color:red}</style><p>also</p></body>';
      expect(_extractor.extractPlainText(xhtml), 'keepalso');
    });
  });

  group('resolveSelection (S1.5-3)', () {
    const xhtml = '<body><p>고래는 바다에 산다. 바다는 넓다.</p></body>';

    test('첫 일치 위치를 start/end로 변환', () {
      final sel = _extractor.resolveSelection(
        spineHref: 'ch.xhtml',
        xhtml: xhtml,
        selectedText: '바다에',
      );
      expect(sel, isNotNull);
      expect(sel!.start, 4);
      expect(sel.end, 7);
      expect(sel.selectedText, '바다에');
    });

    test('occurrence로 N번째 일치 선택', () {
      final first = _extractor.resolveSelection(
        spineHref: 'ch.xhtml',
        xhtml: xhtml,
        selectedText: '바다',
      );
      final second = _extractor.resolveSelection(
        spineHref: 'ch.xhtml',
        xhtml: xhtml,
        selectedText: '바다',
        occurrence: 1,
      );
      expect(first!.start, 4);
      expect(second!.start, greaterThan(first.start));
    });

    test('앞뒤 공백은 정리 후 재시도', () {
      final sel = _extractor.resolveSelection(
        spineHref: 'ch.xhtml',
        xhtml: xhtml,
        selectedText: '  산다.  ',
      );
      expect(sel, isNotNull);
      expect(sel!.selectedText, '산다.');
    });

    test('일치하지 않으면 null', () {
      final sel = _extractor.resolveSelection(
        spineHref: 'ch.xhtml',
        xhtml: xhtml,
        selectedText: '존재하지않는문장',
      );
      expect(sel, isNull);
    });
  });

  group('resolveSelection — 정규화 폴백 (open-epub#62)', () {
    test('소스 개행·들여쓰기를 걸친 선택을 원본 offset으로 해석한다', () {
      // 렌더된 텍스트는 공백 접기로 "고래는 바다에 산다." — SelectionArea가
      // 반환하는 선택 평문에는 소스 개행이 없다.
      const xhtml = '<body><p>고래는 바다에\n      산다. 바다는 넓다.</p></body>';
      final sel = _extractor.resolveSelection(
        spineHref: 'ch.xhtml',
        xhtml: xhtml,
        selectedText: '바다에 산다',
      );
      expect(sel, isNotNull);
      final plain = _extractor.extractPlainText(xhtml);
      // 원본 공간 offset — 개행·들여쓰기가 포함된 구간을 정확히 가리킨다.
      expect(plain.substring(sel!.start, sel.end), '바다에\n      산다');
      expect(sel.selectedText, '바다에 산다');
    });

    test('탭·CR·연속 공백도 하나로 접어 매칭한다', () {
      const xhtml = '<body><p>alpha\t\r\n  beta</p></body>';
      final sel = _extractor.resolveSelection(
        spineHref: 'ch.xhtml',
        xhtml: xhtml,
        selectedText: 'alpha beta',
      );
      expect(sel, isNotNull);
      final plain = _extractor.extractPlainText(xhtml);
      expect(plain.substring(sel!.start, sel.end), 'alpha\t\r\n  beta');
    });

    test('named 엔티티(&amp; 등)를 디코드해 매칭한다', () {
      const xhtml = '<body><p>Tom &amp; Jerry\nshow</p></body>';
      // 렌더: "Tom & Jerry show"
      final sel = _extractor.resolveSelection(
        spineHref: 'ch.xhtml',
        xhtml: xhtml,
        selectedText: 'Tom & Jerry show',
      );
      expect(sel, isNotNull);
      final plain = _extractor.extractPlainText(xhtml);
      expect(plain.substring(sel!.start, sel.end), 'Tom &amp; Jerry\nshow');
    });

    test('숫자 문자 참조(&#8217; 등)를 디코드해 매칭한다', () {
      const xhtml = '<body><p>It&#8217;s\nfine</p></body>';
      // 렌더: "It’s fine"
      final sel = _extractor.resolveSelection(
        spineHref: 'ch.xhtml',
        xhtml: xhtml,
        selectedText: 'It’s fine',
      );
      expect(sel, isNotNull);
      final plain = _extractor.extractPlainText(xhtml);
      expect(plain.substring(sel!.start, sel.end), 'It&#8217;s\nfine');
    });

    test('&nbsp;는 일반 스페이스와 동일하게 매칭한다', () {
      const xhtml = '<body><p>hello&nbsp;world</p></body>';
      final sel = _extractor.resolveSelection(
        spineHref: 'ch.xhtml',
        xhtml: xhtml,
        selectedText: 'hello world',
      );
      expect(sel, isNotNull);
      final plain = _extractor.extractPlainText(xhtml);
      expect(plain.substring(sel!.start, sel.end), 'hello&nbsp;world');
    });

    test('검색어(렌더된 텍스트)는 디코드하지 않는다 — 리터럴 "&amp;" 표시 매칭', () {
      // 원본 "&amp;amp;" 는 렌더에서 "&amp;" 로 표시. 개행 때문에 정확 일치가
      // 실패해 정규화 폴백을 타더라도, 검색어를 디코드하지 않아야 원본 디코드
      // 결과("&amp;")와 일치한다.
      const xhtml = '<body><p>code:\n&amp;amp; token</p></body>';
      final sel = _extractor.resolveSelection(
        spineHref: 'ch.xhtml',
        xhtml: xhtml,
        selectedText: 'code: &amp;',
      );
      expect(sel, isNotNull);
      final plain = _extractor.extractPlainText(xhtml);
      expect(plain.substring(sel!.start, sel.end), 'code:\n&amp;amp;');
    });

    test('정규화 폴백 결과가 injectHighlights와 offset 계약을 유지한다', () {
      const xhtml = '<body><p>고래는 바다에\n  산다.</p></body>';
      final sel = _extractor.resolveSelection(
        spineHref: 'ch.xhtml',
        xhtml: xhtml,
        selectedText: '바다에 산다',
      )!;
      final out = _extractor.injectHighlights(xhtml, [
        _hl(sel.start, sel.end),
      ]);
      expect(
        out,
        contains('<span style="background-color:#FFF59D;">바다에\n  산다</span>'),
      );
    });

    test('occurrence는 정규화 공간에서 N번째 일치를 선택한다', () {
      const xhtml = '<body><p>바다는\n넓다. 바다는\n깊다.</p></body>';
      final first = _extractor.resolveSelection(
        spineHref: 'ch.xhtml',
        xhtml: xhtml,
        selectedText: '바다는 넓다',
      );
      final second = _extractor.resolveSelection(
        spineHref: 'ch.xhtml',
        xhtml: xhtml,
        selectedText: '바다는 깊다',
      );
      expect(first, isNotNull);
      expect(second, isNotNull);
      expect(second!.start, greaterThan(first!.end));
    });

    test('정규화해도 일치하지 않으면 null', () {
      const xhtml = '<body><p>고래는 바다에\n산다.</p></body>';
      final sel = _extractor.resolveSelection(
        spineHref: 'ch.xhtml',
        xhtml: xhtml,
        selectedText: '고래는 하늘에 산다',
      );
      expect(sel, isNull);
    });
  });

  group('injectHighlights (S1.5-4)', () {
    test('단일 텍스트 노드를 배경색 span으로 감싼다', () {
      const xhtml = '<body><p>고래는 바다에 산다.</p></body>';
      // "바다에" = [4,7)
      final out = _extractor.injectHighlights(xhtml, [_hl(4, 7)]);
      expect(
        out,
        contains('<span style="background-color:#FFF59D;">바다에</span>'),
      );
      // 태그는 파손되지 않는다.
      expect(out, startsWith('<body><p>고래는 '));
      expect(out, endsWith(' 산다.</p></body>'));
    });

    test('여러 텍스트 노드에 걸친 하이라이트는 노드별로 분할 감싼다', () {
      const xhtml = '<body><p>Hello <b>World</b> end</p></body>';
      // plain="Hello World end"; [3,9) → "lo " + "Wor"
      final out = _extractor.injectHighlights(xhtml, [_hl(3, 9)]);
      expect(out, contains('>lo </span>'));
      expect(out, contains('>Wor</span>'));
      // 태그 구조 보존
      expect(out, contains('<b>'));
      expect(out, contains('</b>'));
    });

    test('범위를 벗어나는 끝은 평문 길이로 clamp', () {
      const xhtml = '<body><p>abc</p></body>';
      final out = _extractor.injectHighlights(xhtml, [_hl(1, 999)]);
      expect(out, contains('>bc</span>'));
    });

    test('빈/역전 범위는 건너뛴다', () {
      const xhtml = '<body><p>abc</p></body>';
      expect(_extractor.injectHighlights(xhtml, [_hl(2, 2)]), xhtml);
      expect(_extractor.injectHighlights(xhtml, const []), xhtml);
    });

    test('여러 하이라이트를 동시에 주입', () {
      const xhtml = '<body><p>abcdef</p></body>';
      final out = _extractor.injectHighlights(xhtml, [
        _hl(0, 2, color: 0xFFFF0000),
        _hl(4, 6, color: 0xFF00FF00),
      ]);
      expect(out, contains('background-color:#FF0000;">ab</span>'));
      expect(out, contains('background-color:#00FF00;">ef</span>'));
    });
  });
}

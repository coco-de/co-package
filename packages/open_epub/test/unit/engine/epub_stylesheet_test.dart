// Issue: #278 — 문서 <style> 선택자 매칭

import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:open_epub/src/presentation/engine/reflowable/epub_stylesheet.dart';
import 'package:open_epub/src/presentation/engine/reflowable/epub_xhtml.dart';
import 'package:open_epub/src/presentation/engine/reflowable/vertical_text_block.dart';

void main() {
  group('extractRenderableHtml — title 누출 차단 (#278)', () {
    test('head title을 버리고 body만 남긴다', () {
      const xhtml = '<html><head><title>CHAPTER_TITLE_LEAK</title></head>'
          '<body><p>BODY_TEXT</p></body></html>';
      final out = extractRenderableHtml(xhtml);
      expect(out, isNot(contains('CHAPTER_TITLE_LEAK')));
      expect(out, contains('BODY_TEXT'));
      expect(out.toLowerCase(), contains('<body'));
    });

    test('body가 없으면 head만 제거한다', () {
      const fragment = '<head><title>X</title></head><p>keep</p>';
      expect(extractRenderableHtml(fragment), contains('keep'));
      expect(extractRenderableHtml(fragment), isNot(contains('X')));
    });
  });

  group('declaresVerticalWriting — 미사용 클래스 오탐 금지 (#278)', () {
    test('style 블록의 미사용 .vert 만으로는 false', () {
      const html = '<html><head><style>.vert{writing-mode:vertical-rl}</style>'
          '</head><body><p>English chapter</p></body></html>';
      expect(declaresVerticalWriting(html), isFalse);
    });

    test('인라인 style의 writing-mode는 true', () {
      const html = '<body style="writing-mode: vertical-rl"><p>세로</p></body>';
      expect(declaresVerticalWriting(html), isTrue);
      expect(isVerticalLr(html), isFalse);
    });
  });

  group('EpubStylesheet — 선택자 매칭 (#278)', () {
    test('클래스 선택자가 선언을 반환한다', () {
      final sheet = EpubStylesheet.parse(
        '<style>.red{color:red;margin-left:1em}</style><p class="red">x</p>',
      );
      final p = html_parser.parse('<p class="red">x</p>').querySelector('p')!;
      expect(sheet.stylesFor(p), containsPair('color', 'red'));
      expect(sheet.stylesFor(p), containsPair('margin-left', '1em'));
    });

    test('매칭되지 않는 클래스는 null', () {
      final sheet = EpubStylesheet.parse(
        '<style>.red{color:red}</style><p>x</p>',
      );
      final p = html_parser.parse('<p>x</p>').querySelector('p')!;
      expect(sheet.stylesFor(p), isNull);
    });

    test('자손 선택자 div p', () {
      final sheet = EpubStylesheet.parse(
        '<style>div p{font-size:18px}</style>',
      );
      final doc = html_parser.parse('<div><p>x</p></div>');
      final p = doc.querySelector('p')!;
      expect(sheet.stylesFor(p), containsPair('font-size', '18px'));
    });

    test('id가 클래스보다 특이도가 높다', () {
      final sheet = EpubStylesheet.parse(
        '<style>.x{color:blue}#i{color:red}</style>',
      );
      final el =
          html_parser.parse('<p class="x" id="i">x</p>').querySelector('p')!;
      expect(sheet.stylesFor(el), containsPair('color', 'red'));
    });

    test('미사용 .vert는 rootIsVerticalWriting이 아니다', () {
      final sheet = EpubStylesheet.parse(
        '<html><head><style>.vert{writing-mode:vertical-rl}</style></head>'
        '<body><p>English</p></body></html>',
      );
      expect(sheet.rootIsVerticalWriting, isFalse);
    });

    test('body에 매칭된 writing-mode는 rootIsVerticalWriting', () {
      final sheet = EpubStylesheet.parse(
        '<html><head><style>body{writing-mode:vertical-rl}</style></head>'
        '<body><p>세로</p></body></html>',
      );
      expect(sheet.rootIsVerticalWriting, isTrue);
      expect(sheet.rootIsVerticalLr, isFalse);
    });

    test('인라인 style이 스타일시트보다 우선한다 (root writing-mode)', () {
      final sheet = EpubStylesheet.parse(
        '<html><head><style>body{writing-mode:vertical-rl}</style></head>'
        '<body style="writing-mode:horizontal-tb"><p>x</p></body></html>',
      );
      expect(sheet.rootIsVerticalWriting, isFalse);
    });
  });
}

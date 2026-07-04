// Story: S15.3 (#110) — 낭독 하이라이트 주입/파싱 유닛 테스트 (gap #6 동기화분)

import 'package:flutter_test/flutter_test.dart';
import 'package:open_epub/src/presentation/media_overlay/media_overlay_highlight.dart';

void main() {
  group('injectMediaOverlayHighlight', () {
    test('style 없는 요소에 배경색 추가', () {
      const html = '<p id="s1">첫 문장.</p>';
      final out = injectMediaOverlayHighlight(html, 's1');
      expect(out, contains('background-color'));
      expect(out, contains('id="s1"'));
      expect(out, contains('style="background-color:'));
    });

    test('기존 style에 병합(세미콜론 처리)', () {
      const html = '<span id="s1" style="color:red">x</span>';
      final out = injectMediaOverlayHighlight(html, 's1');
      expect(out, contains('style="color:red;background-color:'));
    });

    test('기존 style이 세미콜론으로 끝나면 중복 세미콜론 없음', () {
      const html = '<span id="s1" style="color:red;">x</span>';
      final out = injectMediaOverlayHighlight(html, 's1');
      expect(out, contains('style="color:red;background-color:'));
      expect(out, isNot(contains(';;')));
    });

    test('self-closing 요소에도 style 삽입', () {
      const html = '<img id="s1" src="x.png"/>';
      final out = injectMediaOverlayHighlight(html, 's1');
      expect(out, contains('background-color'));
      expect(out.trimRight(), endsWith('/>'));
    });

    test('single-quote id 매칭', () {
      const html = "<p id='s1'>x</p>";
      final out = injectMediaOverlayHighlight(html, 's1');
      expect(out, contains('background-color'));
    });

    test('해당 id 없으면 원본 그대로', () {
      const html = '<p id="other">x</p>';
      expect(injectMediaOverlayHighlight(html, 's1'), html);
    });

    test('빈 fragment는 no-op', () {
      const html = '<p id="s1">x</p>';
      expect(injectMediaOverlayHighlight(html, ''), html);
    });

    test('여러 요소 중 대상만 강조(다른 요소 불변)', () {
      const html = '<p id="s1">a</p><p id="s2">b</p>';
      final out = injectMediaOverlayHighlight(html, 's2');
      // s2만 style, s1은 그대로
      expect(out, contains('<p id="s1">a</p>'));
      expect(out, matches(RegExp(r'id="s2"[^>]*style=')));
    });
  });

  group('splitTextSrc', () {
    test('경로+fragment 분리', () {
      final r = splitTextSrc('ch1.xhtml#s1');
      expect(r.path, 'ch1.xhtml');
      expect(r.fragment, 's1');
    });

    test('fragment 없음', () {
      final r = splitTextSrc('ch1.xhtml');
      expect(r.path, 'ch1.xhtml');
      expect(r.fragment, isNull);
    });

    test('빈 fragment(# 뒤 없음)는 null', () {
      final r = splitTextSrc('ch1.xhtml#');
      expect(r.path, 'ch1.xhtml');
      expect(r.fragment, isNull);
    });
  });
}

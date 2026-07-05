// #67 S9.3 회귀 — 하이라이트 contentRevision 판정을 참조(identical)가 아닌
// 내용(listEquals)으로 비교해, 내용이 같은 새 List 인스턴스가 전 spine을
// 불필요하게 재로딩하지 않도록 한다.
//
// epubContentRevisionChanged가 _contentRevision 갱신(=엔진 _loads.clear() →
// spine 재로딩)의 게이트이므로, 이 판정 함수를 직접 검증하는 것이 재로딩
// 트리거 여부에 대한 정확한 회귀 가드다.

import 'package:flutter_test/flutter_test.dart';
import 'package:open_epub/src/presentation/widgets/epub_reader.dart';
import 'package:open_epub_engine/open_epub_engine.dart';

EpubHighlight _h(
  String id, {
  int start = 0,
  int end = 5,
  int color = 0xFF00FF00,
}) =>
    EpubHighlight(
      id: id,
      spineHref: 'ch1.xhtml',
      start: start,
      end: end,
      selectedText: 'text',
      colorArgb: color,
    );

void main() {
  group('epubContentRevisionChanged (#67 S9.3)', () {
    test('내용이 같은 새 List 인스턴스 → 변경 아님(재로딩 트리거 안 함)', () {
      final prev = [_h('a'), _h('b')];
      final next = [_h('a'), _h('b')]; // 새 인스턴스, 동일 내용
      expect(identical(prev, next), isFalse, reason: '참조는 서로 다름');
      expect(
        epubContentRevisionChanged(
          prevHighlights: prev,
          nextHighlights: next,
          prevActiveTextSrc: null,
          nextActiveTextSrc: null,
        ),
        isFalse,
      );
    });

    test('하이라이트가 추가되면 변경으로 판정(재로딩)', () {
      expect(
        epubContentRevisionChanged(
          prevHighlights: [_h('a')],
          nextHighlights: [_h('a'), _h('b')],
          prevActiveTextSrc: null,
          nextActiveTextSrc: null,
        ),
        isTrue,
      );
    });

    test('하이라이트 속성(색)만 바뀌어도 변경으로 판정', () {
      expect(
        epubContentRevisionChanged(
          prevHighlights: [_h('a', color: 0xFF00FF00)],
          nextHighlights: [_h('a', color: 0xFFFF0000)],
          prevActiveTextSrc: null,
          nextActiveTextSrc: null,
        ),
        isTrue,
      );
    });

    test('최초(prev=null) → 변경으로 판정', () {
      expect(
        epubContentRevisionChanged(
          prevHighlights: null,
          nextHighlights: [_h('a')],
          prevActiveTextSrc: null,
          nextActiveTextSrc: null,
        ),
        isTrue,
      );
    });

    test('빈 목록끼리(내용 동일)는 변경 아님', () {
      expect(
        epubContentRevisionChanged(
          prevHighlights: const [],
          nextHighlights: const [],
          prevActiveTextSrc: null,
          nextActiveTextSrc: null,
        ),
        isFalse,
      );
    });

    test('낭독 활성 par(textSrc) 변경은 재로딩으로 판정', () {
      expect(
        epubContentRevisionChanged(
          prevHighlights: const [],
          nextHighlights: const [],
          prevActiveTextSrc: null,
          nextActiveTextSrc: 'ch1.xhtml#p3',
        ),
        isTrue,
      );
    });
  });
}

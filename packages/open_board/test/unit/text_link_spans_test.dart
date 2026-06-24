import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_board/src/module/text/link_hit_test.dart';
import 'package:open_board/src/module/text/link_span_offsets.dart';
import 'package:open_board/src/module/text/text_drawable_extensions.dart';
import 'package:open_board/src/module/text/text_span_builder.dart';

import '../helpers/test_helpers.dart';

TextLinkSpan _span(int start, int end, [String url = 'https://example.com']) =>
    TextLinkSpan()
      ..start = start
      ..end = end
      ..url = url;

void main() {
  group('computeTextEditDelta', () {
    test('insert 를 단일 범위로 환원한다', () {
      final delta = computeTextEditDelta('abcdef', 'abXYZcdef');
      expect(delta.start, 2);
      expect(delta.oldEnd, 2);
      expect(delta.newLength, 3);
    });

    test('delete 를 단일 범위로 환원한다', () {
      final delta = computeTextEditDelta('abcdef', 'abef');
      expect(delta.start, 2);
      expect(delta.oldEnd, 4);
      expect(delta.newLength, 0);
    });

    test('replace 를 단일 범위로 환원한다', () {
      final delta = computeTextEditDelta('abcdef', 'abXef');
      expect(delta.start, 2);
      expect(delta.oldEnd, 4);
      expect(delta.newLength, 1);
    });

    test('변경 없음', () {
      final delta = computeTextEditDelta('abc', 'abc');
      expect(delta.start, 3);
      expect(delta.oldEnd, 3);
      expect(delta.newLength, 0);
    });
  });

  group('shiftLinkSpans', () {
    test('편집 앞쪽 삽입 시 링크가 오른쪽으로 밀린다', () {
      final result = shiftLinkSpans(
        [_span(4, 8)],
        const TextEditDelta(start: 0, oldEnd: 0, newLength: 2),
      );
      expect(result.single.start, 6);
      expect(result.single.end, 10);
    });

    test('링크 내부 삽입 시 링크가 확장된다', () {
      final result = shiftLinkSpans(
        [_span(2, 6)],
        const TextEditDelta(start: 4, oldEnd: 4, newLength: 3),
      );
      expect(result.single.start, 2);
      expect(result.single.end, 9);
    });

    test('링크를 완전히 덮는 삭제 시 링크가 제거된다', () {
      final result = shiftLinkSpans(
        [_span(2, 6)],
        const TextEditDelta(start: 0, oldEnd: 8, newLength: 0),
      );
      expect(result, isEmpty);
    });

    test('링크 뒤 삭제는 링크에 영향 없다', () {
      final result = shiftLinkSpans(
        [_span(0, 3)],
        const TextEditDelta(start: 5, oldEnd: 7, newLength: 0),
      );
      expect(result.single.start, 0);
      expect(result.single.end, 3);
    });

    test('링크 일부 삭제 시 링크가 축소된다', () {
      final result = shiftLinkSpans(
        [_span(2, 6)],
        const TextEditDelta(start: 4, oldEnd: 8, newLength: 0),
      );
      expect(result.single.start, 2);
      expect(result.single.end, 4);
    });

    test('url 을 보존한다', () {
      final result = shiftLinkSpans(
        [_span(4, 8, 'https://kept.com')],
        const TextEditDelta(start: 0, oldEnd: 0, newLength: 1),
      );
      expect(result.single.url, 'https://kept.com');
    });
  });

  group('sanitizeLinkSpans', () {
    test('정렬·클램프·빈범위/overlap/url없음 제거', () {
      final spans = [
        _span(10, 20, 'https://a.com'),
        _span(0, 5, 'https://b.com'),
        _span(3, 8, 'https://c.com'), // b 와 overlap → drop
        _span(5, 5, 'https://d.com'), // empty → drop
        _span(6, 9, ''), // url 없음 → drop
      ];
      final result = sanitizeLinkSpans(spans, 12);
      expect(result.length, 2);
      expect(result[0].start, 0);
      expect(result[0].end, 5);
      expect(result[0].url, 'https://b.com');
      expect(result[1].start, 10);
      expect(result[1].end, 12); // 20 → textLength 로 clamp
    });

    test('역전 범위 제거', () {
      final result = sanitizeLinkSpans([_span(8, 3)], 12);
      expect(result, isEmpty);
    });
  });

  group('linkSpanAtOffset', () {
    test('반열린 구간 [start, end)', () {
      final drawable = createTextDrawable(text: 'hello world')
        ..linkSpans.add(_span(0, 5, 'https://a.com'));
      expect(linkSpanAtOffset(drawable, 0)?.url, 'https://a.com');
      expect(linkSpanAtOffset(drawable, 4)?.url, 'https://a.com');
      expect(linkSpanAtOffset(drawable, 5), isNull);
      expect(linkSpanAtOffset(drawable, 7), isNull);
    });
  });

  group('buildLinkAwareTextSpan', () {
    test('링크 없으면 단일 span', () {
      final drawable = createTextDrawable(text: 'hello world');
      final span = buildLinkAwareTextSpan(drawable);
      expect(span.text, 'hello world');
      expect(span.children, isNull);
    });

    test('링크 범위는 파란색+밑줄로 분할된다', () {
      final drawable = createTextDrawable(text: 'hello world')
        ..linkSpans.add(_span(0, 5, 'https://a.com'));
      final span = buildLinkAwareTextSpan(drawable);
      expect(span.children, isNotNull);
      expect(span.children!.length, 2);

      final linkChild = span.children!.first as TextSpan;
      expect(linkChild.text, 'hello');
      expect(linkChild.style?.color, kTextLinkColor);
      expect(linkChild.style?.decoration, TextDecoration.underline);

      final rest = span.children![1] as TextSpan;
      expect(rest.text, ' world');
    });
  });

  group('copyWithLinkSpans + 직렬화 round-trip', () {
    test('copyWithLinkSpans 는 원본을 변경하지 않는다', () {
      final original = createTextDrawable(text: 'hello')
        ..linkSpans.add(_span(0, 5, 'https://a.com'));
      final copy = original.copyWithLinkSpans([_span(1, 3, 'https://b.com')]);

      expect(original.linkSpans.single.url, 'https://a.com');
      expect(copy.linkSpans.single.url, 'https://b.com');
      expect(copy.linkSpans.single.start, 1);
      expect(copy.linkSpans.single.end, 3);
    });

    test('protobuf writeToBuffer/fromBuffer 로 linkSpans 가 보존된다', () {
      final drawable = createTextDrawable(text: 'hello world')
        ..linkSpans.add(_span(0, 5, 'https://a.com'))
        ..linkSpans.add(_span(6, 11, 'https://b.com'));

      final restored = TextDrawable.fromBuffer(drawable.writeToBuffer());

      expect(restored.linkSpans.length, 2);
      expect(restored.linkSpans[0].start, 0);
      expect(restored.linkSpans[0].end, 5);
      expect(restored.linkSpans[0].url, 'https://a.com');
      expect(restored.linkSpans[1].url, 'https://b.com');
    });
  });

  group('findLinkAtCanvasPoint', () {
    setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

    test('링크 글자 위 탭이면 링크를 반환한다', () {
      final drawable = createTextDrawable(
        text: 'hello world',
        x: 100,
        y: 100,
      )..linkSpans.add(_span(0, 5, 'https://a.com'));

      // left 정렬: 첫 글자 근처(좌상단 영역) 탭.
      final hit = findLinkAtCanvasPoint([drawable], const Offset(102, 100));
      expect(hit?.url, 'https://a.com');
    });

    test('영역 밖 탭이면 null', () {
      final drawable = createTextDrawable(text: 'hello world', x: 100, y: 100)
        ..linkSpans.add(_span(0, 5, 'https://a.com'));
      expect(
        findLinkAtCanvasPoint([drawable], const Offset(1000, 1000)),
        isNull,
      );
    });

    test('링크 없는 텍스트는 null', () {
      final drawable = createTextDrawable(text: 'plain', x: 100, y: 100);
      expect(findLinkAtCanvasPoint([drawable], const Offset(102, 100)), isNull);
    });
  });
}

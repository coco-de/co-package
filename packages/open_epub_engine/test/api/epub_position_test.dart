// Story: S1.10 / S1.11 / S1.12 — EpubPosition + token codec tests
// BDD: F1.2 (이어 읽기 round-trip), F1.3 (복원 실패 fallback)

import 'dart:convert';

import 'package:test/test.dart';
import 'package:open_epub_engine/src/api/epub_position.dart';

void main() {
  group('EpubReflowablePosition — toToken / fromToken round-trip', () {
    test('charOffset만 있는 케이스', () {
      const original = EpubReflowablePosition(
        spineHref: 'ch01.xhtml',
        progress: 0.45,
        charOffset: 512,
      );
      final token = original.toToken();
      final decoded = EpubPosition.fromToken(token);
      expect(decoded, original);
      expect(decoded, isA<EpubReflowablePosition>());
    });

    test('charOffset + pageIndex hint', () {
      const original = EpubReflowablePosition(
        spineHref: 'ch07/section.xhtml',
        progress: 0.821,
        charOffset: 9876,
        pageIndex: 42,
      );
      final decoded = EpubPosition.fromToken(original.toToken())
          as EpubReflowablePosition;
      expect(decoded, original);
      expect(decoded.pageIndex, 42);
    });

    test('charOffset 0 / progress 0.0 / progress 1.0 boundary', () {
      for (final p in [0.0, 1.0]) {
        final pos = EpubReflowablePosition(
          spineHref: 'a.xhtml',
          progress: p,
          charOffset: 0,
        );
        expect(EpubPosition.fromToken(pos.toToken()), pos);
      }
    });

    test('JSON 토큰 schema (v=1, t="r")', () {
      const pos = EpubReflowablePosition(
        spineHref: 'a.xhtml',
        progress: 0.5,
        charOffset: 100,
      );
      final json = jsonDecode(pos.toToken()) as Map<String, dynamic>;
      expect(json['v'], 1);
      expect(json['t'], 'r');
      expect(json['s'], 'a.xhtml');
      expect(json['p'], 0.5);
      expect(json['c'], 100);
      expect(json.containsKey('x'), isFalse); // pageIndex 미설정 시 키 제외
      expect(json.containsKey('a'), isFalse); // scrollAlignment 미설정 시 키 제외
    });

    test('charOffset + scrollAlignment hint (음수 포함)', () {
      const original = EpubReflowablePosition(
        spineHref: 'ch03.xhtml',
        progress: 0.3,
        charOffset: 0,
        scrollAlignment: -1.35,
      );
      final json = jsonDecode(original.toToken()) as Map<String, dynamic>;
      expect(json['a'], -1.35);
      final decoded = EpubPosition.fromToken(original.toToken())
          as EpubReflowablePosition;
      expect(decoded, original);
      expect(decoded.scrollAlignment, -1.35);
    });

    test('pageIndex + scrollAlignment 동시 보존', () {
      const original = EpubReflowablePosition(
        spineHref: 'ch03.xhtml',
        progress: 0.3,
        charOffset: 0,
        pageIndex: 2,
        scrollAlignment: 0.0,
      );
      final decoded = EpubPosition.fromToken(original.toToken())
          as EpubReflowablePosition;
      expect(decoded, original);
    });

    test('scrollAlignment 없는 기존 v1 토큰도 하위 호환 디코드된다', () {
      const token = '{"v":1,"t":"r","s":"a.xhtml","p":0.1,"c":50}';
      final decoded =
          EpubPosition.fromToken(token) as EpubReflowablePosition;
      expect(decoded.scrollAlignment, isNull);
    });
  });

  group('EpubFixedPosition — toToken / fromToken round-trip', () {
    test('pageIndex 정상', () {
      const original = EpubFixedPosition(
        spineHref: 'p3.xhtml',
        progress: 0.05,
        pageIndex: 3,
      );
      final decoded = EpubPosition.fromToken(original.toToken())
          as EpubFixedPosition;
      expect(decoded, original);
      expect(decoded.pageIndex, 3);
    });

    test('JSON 토큰 schema (v=1, t="f", i=...)', () {
      const pos = EpubFixedPosition(
        spineHref: 'p1.xhtml',
        progress: 0.1,
        pageIndex: 0,
      );
      final json = jsonDecode(pos.toToken()) as Map<String, dynamic>;
      expect(json['v'], 1);
      expect(json['t'], 'f');
      expect(json['s'], 'p1.xhtml');
      expect(json['p'], 0.1);
      expect(json['i'], 0);
    });
  });

  group('Token size constraint (≤ 512 bytes, ADR-001)', () {
    test('일반적인 spineHref는 충분히 안전 (≪ 512 bytes)', () {
      const pos = EpubReflowablePosition(
        spineHref: 'OEBPS/text/chapter-23.xhtml',
        progress: 0.873,
        charOffset: 18472,
        pageIndex: 256,
      );
      expect(utf8.encode(pos.toToken()).length, lessThan(120));
    });

    test('spineHref가 매우 길어 512 bytes 초과면 EpubPositionTooLargeException', () {
      final longHref = 'OEBPS/${'verylongpath/' * 50}final.xhtml'; // ~660 chars
      final pos = EpubReflowablePosition(
        spineHref: longHref,
        progress: 0.5,
        charOffset: 0,
      );
      expect(() => pos.toToken(), throwsA(isA<EpubPositionTooLargeException>()));
    });
  });

  group('fromToken — error cases', () {
    test('잘못된 JSON → EpubPositionDecodeException', () {
      expect(
        () => EpubPosition.fromToken('not-json'),
        throwsA(isA<EpubPositionDecodeException>()),
      );
    });

    test('root가 객체가 아니면 EpubPositionDecodeException', () {
      expect(
        () => EpubPosition.fromToken('[1,2,3]'),
        throwsA(isA<EpubPositionDecodeException>()),
      );
    });

    test('schema version 불일치', () {
      const token = '{"v":2,"t":"r","s":"a","p":0,"c":0}';
      expect(
        () => EpubPosition.fromToken(token),
        throwsA(isA<EpubPositionDecodeException>()),
      );
    });

    test('알 수 없는 type t', () {
      const token = '{"v":1,"t":"q","s":"a","p":0}';
      expect(
        () => EpubPosition.fromToken(token),
        throwsA(isA<EpubPositionDecodeException>()),
      );
    });

    test('spineHref 누락', () {
      const token = '{"v":1,"t":"r","p":0,"c":0}';
      expect(
        () => EpubPosition.fromToken(token),
        throwsA(isA<EpubPositionDecodeException>()),
      );
    });

    test('progress 범위 위반', () {
      for (final p in [-0.1, 1.5]) {
        final token = '{"v":1,"t":"r","s":"a","p":$p,"c":0}';
        expect(
          () => EpubPosition.fromToken(token),
          throwsA(isA<EpubPositionDecodeException>()),
          reason: 'progress=$p',
        );
      }
    });

    test('Reflowable: charOffset 누락', () {
      const token = '{"v":1,"t":"r","s":"a","p":0}';
      expect(
        () => EpubPosition.fromToken(token),
        throwsA(isA<EpubPositionDecodeException>()),
      );
    });

    test('Reflowable: charOffset 음수', () {
      const token = '{"v":1,"t":"r","s":"a","p":0,"c":-1}';
      expect(
        () => EpubPosition.fromToken(token),
        throwsA(isA<EpubPositionDecodeException>()),
      );
    });

    test('Reflowable: scrollAlignment(a)가 숫자가 아니면 에러', () {
      const token = '{"v":1,"t":"r","s":"a","p":0,"c":0,"a":"oops"}';
      expect(
        () => EpubPosition.fromToken(token),
        throwsA(isA<EpubPositionDecodeException>()),
      );
    });

    test('Fixed: pageIndex 누락', () {
      const token = '{"v":1,"t":"f","s":"a","p":0}';
      expect(
        () => EpubPosition.fromToken(token),
        throwsA(isA<EpubPositionDecodeException>()),
      );
    });

    test('Fixed: pageIndex 음수', () {
      const token = '{"v":1,"t":"f","s":"a","p":0,"i":-3}';
      expect(
        () => EpubPosition.fromToken(token),
        throwsA(isA<EpubPositionDecodeException>()),
      );
    });
  });

  group('Equality + hashCode', () {
    test('동일한 Reflowable 위치는 ==', () {
      const a = EpubReflowablePosition(
        spineHref: 'x',
        progress: 0.1,
        charOffset: 1,
      );
      const b = EpubReflowablePosition(
        spineHref: 'x',
        progress: 0.1,
        charOffset: 1,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('Reflowable vs Fixed는 다른 타입이라 not ==', () {
      const a = EpubReflowablePosition(spineHref: 'x', progress: 0.0, charOffset: 0);
      const b = EpubFixedPosition(spineHref: 'x', progress: 0.0, pageIndex: 0);
      expect(a == b, isFalse);
    });

    test('scrollAlignment만 다르면 not ==', () {
      const a = EpubReflowablePosition(
        spineHref: 'x',
        progress: 0.1,
        charOffset: 1,
        scrollAlignment: -0.5,
      );
      const b = EpubReflowablePosition(
        spineHref: 'x',
        progress: 0.1,
        charOffset: 1,
        scrollAlignment: -0.6,
      );
      expect(a == b, isFalse);
    });
  });
}

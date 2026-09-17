// rank1 버그 회귀 — 하위 폴더 본문의 `<img>` 상대경로 해석.
//
// 본문이 OEBPS/text/ 같은 하위 폴더에 있고 `<img src="../images/x.png">`처럼
// 문서 기준 상대경로로 리소스를 가리킬 때, 이전 구현은 src를 OPF 디렉터리
// 기준으로만 결합해 `..`가 OPF 폴더를 지워 리소스를 못 찾고 이미지가 통째로
// 깨졌다(marionette 통합테스트: 아랍어 titlepage·mymedia 커버 placeholder).
// buildReflowableHtml에 baseHref(문서 자신의 spine href)를 주입해 문서 위치
// 기준으로 정규화한다.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_epub/src/presentation/engine/reflowable/reflowable_engine.dart';

void main() {
  group('resolveDocumentHref (rank1)', () {
    test('하위 폴더 문서의 ../ 상대경로 → OPF 상대 href로 정규화', () {
      expect(
        resolveDocumentHref('text/ch3.xhtml', '../images/x.png'),
        'images/x.png',
      );
      // 두 단계 하위 → 두 번 ../
      expect(
        resolveDocumentHref('a/b/ch.xhtml', '../../img/y.jpg'),
        'img/y.jpg',
      );
    });

    test('같은 폴더 상대경로 → 문서 폴더 접두', () {
      expect(
        resolveDocumentHref('text/ch3.xhtml', 'pics/x.png'),
        'text/pics/x.png',
      );
      expect(resolveDocumentHref('text/ch3.xhtml', './x.png'), 'text/x.png');
    });

    test('루트 문서(폴더 없음)는 src 그대로 정규화', () {
      expect(resolveDocumentHref('ch.xhtml', 'images/x.png'), 'images/x.png');
    });

    test('스킴(data:/http:/file:)·절대경로는 원문 유지', () {
      const data = 'data:image/png;base64,AAAA';
      expect(resolveDocumentHref('text/ch.xhtml', data), data);
      expect(
        resolveDocumentHref('text/ch.xhtml', 'https://x/y.png'),
        'https://x/y.png',
      );
      expect(resolveDocumentHref('text/ch.xhtml', '/abs/x.png'), '/abs/x.png');
    });

    test('baseHref 없음/빈 문자열은 src 그대로', () {
      expect(resolveDocumentHref(null, '../images/x.png'), '../images/x.png');
      expect(resolveDocumentHref('', 'images/x.png'), 'images/x.png');
    });

    test('zip-slip: ..가 루트 위로 못 올라간다', () {
      expect(resolveDocumentHref('ch.xhtml', '../../../x.png'), 'x.png');
    });
  });

  group('buildReflowableHtml — img src를 baseHref 기준으로 로더에 전달', () {
    testWidgets('하위 폴더 본문의 ../images src가 OPF 상대로 해석되어 로드된다', (tester) async {
      final requested = <String>[];
      Future<Uint8List?> spyLoader(String src) async {
        requested.add(src);
        return null; // 바이트는 불필요 — 로더가 받은 경로만 검증.
      }

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: buildReflowableHtml(
            data: '<body><p>본문</p>'
                '<img src="../images/cover.png" alt="cover"/></body>',
            baseHref: 'text/ch3.xhtml',
            fontSize: 16,
            lineHeight: 1.5,
            imageLoader: spyLoader,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // 버그였다면 로더가 '../images/cover.png' 원문을 받아 readBytes가
      // OPF 기준 결합에서 폴더를 지워 실패했다. 이제 문서 기준 정규화 후 전달.
      expect(requested, contains('images/cover.png'));
      expect(requested, isNot(contains('../images/cover.png')));
    });

    testWidgets('baseHref 미지정 시 기존 동작(원문 src) 유지', (tester) async {
      final requested = <String>[];
      Future<Uint8List?> spyLoader(String src) async {
        requested.add(src);
        return null;
      }

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: buildReflowableHtml(
            data: '<body><img src="images/x.png"/></body>',
            fontSize: 16,
            lineHeight: 1.5,
            imageLoader: spyLoader,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(requested, contains('images/x.png'));
    });
  });
}

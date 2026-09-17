// perf(reader) #264 — 세로 스크롤(reflowable) 끊김 완화 회귀 테스트.
//
// 이 PR이 다루는 두 가지 안전한 개선을 고정한다:
//   B) 전면/본문 이미지를 표시 폭(px) 기준으로 디코드(cacheWidth) — 원본 해상도
//      디코드로 인한 진입 프레임/메모리 스파이크 제거.
//   C) 각 spine(챕터) item을 RepaintBoundary로 감싸 연속 스크롤 중 재합성 비용을
//      챕터 단위로 격리.
//
// A(챕터 전체 동기 빌드, buildAsync:false)는 fwfh가 buildAsync에서 실제 isolate
// (`compute`)를 쓰는 탓에 결정적 위젯 테스트 하네스(pumpAndSettle)와 충돌해 이
// PR 범위 밖으로 분리했다 — 후속 이슈에서 증분/청킹 빌드로 다룬다.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_epub_engine/src/api/epub_book.dart';
import 'package:open_epub_engine/src/domain/entity/epub_metadata.dart';
import 'package:open_epub_engine/src/domain/entity/epub_outline.dart';
import 'package:open_epub_engine/src/domain/entity/epub_spine_item.dart';
import 'package:open_epub/src/presentation/engine/reflowable/reflowable_engine.dart';

void main() {
  group('Cause B — 이미지 표시폭 디코드 (cacheWidth, #264)', () {
    testWidgets('로드된 본문 이미지는 ResizeImage(표시폭 기준)로 디코드된다', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: buildReflowableHtml(
            data: '<body><p>before</p>'
                '<img src="cover.png" alt="cover"/><p>after</p></body>',
            fontSize: 16,
            lineHeight: 1.5,
            imageLoader: (_) async => _onePixelPng(),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final image = tester.widget<Image>(find.byType(Image));
      // 회귀 고정: 이전에는 cacheWidth 없이 `Image.memory` → provider가 순수
      // MemoryImage였다. 이제 표시폭 기준 ResizeImage로 감싸 디코드 크기를 제한한다.
      expect(image.image, isA<ResizeImage>());
      final resize = image.image as ResizeImage;
      expect(resize.width, isNotNull);
      expect(resize.width, greaterThan(0));
      // allowUpscaling 기본 false — 표시폭이 원본보다 커도 작은 이미지를
      // 업스케일 디코드하지 않는다(작은 인라인 이미지 메모리 낭비 방지).
      expect(resize.allowUpscaling, isFalse);
    });

    testWidgets('로드 실패 이미지는 여전히 placeholder (cacheWidth 경로가 오류를 삼키지 않음)',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: buildReflowableHtml(
            data: '<body><img src="missing.png" alt="x"/></body>',
            fontSize: 16,
            lineHeight: 1.5,
            imageLoader: (_) async => null,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(Image), findsNothing);
      expect(find.byIcon(Icons.image_not_supported_outlined), findsOneWidget);
    });
  });

  group('Cause C — spine item RepaintBoundary 격리 (#264)', () {
    testWidgets('스크롤 모드 각 spine 콘텐츠가 RepaintBoundary로 감싸진다', (tester) async {
      final book = _fakeBook(['ch01.xhtml']);
      await tester.pumpWidget(_wrap(
        ReflowableEngine(
          book: book,
          xhtmlLoader: (_) async => _wrapXhtml('<p>hello</p>'),
        ),
      ));
      await tester.pumpAndSettle();

      // 회귀 고정: 우리 RepaintBoundary가 spine 콘텐츠 Padding(all:16)을 직접
      // 감싸는지 확인한다(프레임워크가 다른 곳에 추가하는 경계와 구분).
      final boundaries = tester.widgetList<RepaintBoundary>(
        find.byType(RepaintBoundary),
      );
      final wrapsSpineContent = boundaries.any((rb) {
        final child = rb.child;
        return child is Padding && child.padding == const EdgeInsets.all(16);
      });
      expect(wrapsSpineContent, isTrue);
    });
  });
}

// -------- helpers --------

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(body: SizedBox(width: 400, height: 600, child: child)),
    );

String _wrapXhtml(String body) => '''
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml"><body>$body</body></html>
''';

EpubBook _fakeBook(List<String> hrefs) => _FakeEpubBook(
      spine: hrefs
          .map((h) => EpubSpineItem(
              idref: h, href: h, mediaType: 'application/xhtml+xml'))
          .toList(growable: false),
    );

class _FakeEpubBook implements EpubBook {
  _FakeEpubBook({required this.spine});
  @override
  final List<EpubSpineItem> spine;
  @override
  EpubMetadata get metadata =>
      const EpubMetadata(title: 'fake', epubVersion: '3.0');
  @override
  EpubOutline get outline => EpubOutline.empty;
  @override
  EpubLayout get layout => EpubLayout.reflowable;
}

/// 1×1 red PNG (smallest valid PNG)
Uint8List _onePixelPng() => Uint8List.fromList([
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG sig
      0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
      0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
      0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53,
      0xDE, 0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41,
      0x54, 0x08, 0x99, 0x63, 0xF8, 0xCF, 0xC0, 0x00,
      0x00, 0x00, 0x03, 0x00, 0x01, 0x5B, 0xFE, 0xB1,
      0xCC, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E,
      0x44, 0xAE, 0x42, 0x60, 0x82,
    ]);

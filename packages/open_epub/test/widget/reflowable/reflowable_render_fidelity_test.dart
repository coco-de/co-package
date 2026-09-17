// Issue: #278 — title 누출 · 세로쓰기 오탐 · SVG FXL 백지 · 스타일시트 적용

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:open_epub/src/presentation/engine/reflowable/reflowable_engine.dart';
import 'package:open_epub/src/presentation/engine/reflowable/vertical_text_block.dart';

Widget _host(String data, {ImageLoader? imageLoader}) => MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: buildReflowableHtml(
            data: data,
            fontSize: 16,
            lineHeight: 1.5,
            imageLoader: imageLoader,
          ),
        ),
      ),
    );

void main() {
  group('title 누출 (#278)', () {
    testWidgets('<head><title>이 본문 첫 줄로 새지 않는다', (tester) async {
      await tester.pumpWidget(_host(
        '<html><head><title>CHAPTER_TITLE_LEAK</title></head>'
        '<body><p>BODY_TEXT</p></body></html>',
      ));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('CHAPTER_TITLE_LEAK', findRichText: true),
        findsNothing,
      );
      expect(
        find.textContaining('BODY_TEXT', findRichText: true),
        findsOneWidget,
      );
    });
  });

  group('세로쓰기 오탐 (#278)', () {
    testWidgets('미사용 .vert 클래스만으로는 VerticalTextBlock이 아니다', (tester) async {
      await tester.pumpWidget(_host(
        '<html><head><style>.vert{writing-mode:vertical-rl}</style></head>'
        '<body><p>English chapter</p></body></html>',
      ));
      await tester.pumpAndSettle();
      expect(find.byType(VerticalTextBlock), findsNothing);
      expect(find.byType(HtmlWidget), findsOneWidget);
      expect(
        find.textContaining('English chapter', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('body에 매칭된 writing-mode는 세로 조판', (tester) async {
      await tester.pumpWidget(_host(
        '<html><head><style>body{writing-mode:vertical-rl}</style></head>'
        '<body><p>세로본문</p></body></html>',
      ));
      await tester.pumpAndSettle();
      expect(find.byType(VerticalTextBlock), findsOneWidget);
      expect(find.byType(HtmlWidget), findsNothing);
    });
  });

  group('SVG archive image (#278)', () {
    testWidgets('상대 href를 imageLoader로 로드해 SvgPicture로 렌더한다', (tester) async {
      String? requested;
      await tester.pumpWidget(_host(
        '<body><svg xmlns="http://www.w3.org/2000/svg" width="40" height="40">'
        '<image width="40" height="40" href="page.png"/></svg></body>',
        imageLoader: (src) async {
          requested = src;
          return _onePixelPng();
        },
      ));
      await tester.pumpAndSettle();
      expect(requested, 'page.png');
      expect(find.byType(Image), findsOneWidget);
      expect(find.byIcon(Icons.image_not_supported_outlined), findsNothing);
      expect(find.textContaining('표시할 내용이 없습니다'), findsNothing);
    });

    testWidgets('xlink:href 상대경로도 로드한다', (tester) async {
      String? requested;
      await tester.pumpWidget(_host(
        '<body><svg xmlns="http://www.w3.org/2000/svg" '
        'xmlns:xlink="http://www.w3.org/1999/xlink" width="40" height="40">'
        '<image width="40" height="40" xlink:href="leaf.jpg"/></svg></body>',
        imageLoader: (src) async {
          requested = src;
          return _onePixelPng();
        },
      ));
      await tester.pumpAndSettle();
      expect(requested, 'leaf.jpg');
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('이미지 로드 실패 + 다른 도형 없음 → placeholder (빈 화면 금지)', (tester) async {
      await tester.pumpWidget(_host(
        '<body><svg xmlns="http://www.w3.org/2000/svg" width="40" height="40">'
        '<image width="40" height="40" href="missing.png"/></svg></body>',
        imageLoader: (_) async => null,
      ));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.image_not_supported_outlined), findsOneWidget);
    });
  });

  group('스타일시트 customStylesBuilder (#278)', () {
    testWidgets('클래스 선택자 색이 본문에 반영된다', (tester) async {
      await tester.pumpWidget(_host(
        '<html><head><style>.red{color:#ff0000}</style></head>'
        '<body><p class="red">painted</p></body></html>',
      ));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('painted', findRichText: true),
        findsOneWidget,
      );
      expect(_richTextHasColor(tester, const Color(0xFFFF0000)), isTrue);
    });

    testWidgets('인라인 style이 스타일시트보다 우선한다', (tester) async {
      await tester.pumpWidget(_host(
        '<html><head><style>.red{color:#ff0000}</style></head>'
        '<body><p class="red" style="color:#0000ff">painted</p></body></html>',
      ));
      await tester.pumpAndSettle();
      expect(_richTextHasColor(tester, const Color(0xFF0000FF)), isTrue);
      expect(_richTextHasColor(tester, const Color(0xFFFF0000)), isFalse);
    });
  });
}

bool _richTextHasColor(WidgetTester tester, Color color) {
  return tester.widgetList<RichText>(find.byType(RichText)).any((rt) {
    var found = false;
    rt.text.visitChildren((span) {
      if (span is TextSpan && span.style?.color == color) {
        found = true;
        return false;
      }
      return true;
    });
    return found;
  });
}

Uint8List _onePixelPng() => Uint8List.fromList([
      0x89,
      0x50,
      0x4E,
      0x47,
      0x0D,
      0x0A,
      0x1A,
      0x0A,
      0x00,
      0x00,
      0x00,
      0x0D,
      0x49,
      0x48,
      0x44,
      0x52,
      0x00,
      0x00,
      0x00,
      0x01,
      0x00,
      0x00,
      0x00,
      0x01,
      0x08,
      0x02,
      0x00,
      0x00,
      0x00,
      0x90,
      0x77,
      0x53,
      0xDE,
      0x00,
      0x00,
      0x00,
      0x0C,
      0x49,
      0x44,
      0x41,
      0x54,
      0x08,
      0x99,
      0x63,
      0xF8,
      0xCF,
      0xC0,
      0x00,
      0x00,
      0x00,
      0x03,
      0x00,
      0x01,
      0x5B,
      0xFE,
      0xB1,
      0xCC,
      0x00,
      0x00,
      0x00,
      0x00,
      0x49,
      0x45,
      0x4E,
      0x44,
      0xAE,
      0x42,
      0x60,
      0x82,
    ]);

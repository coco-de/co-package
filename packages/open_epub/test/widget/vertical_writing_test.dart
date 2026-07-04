// Story: S15.4 (#111) — 세로쓰기 실용 조판 위젯/통합 테스트 (gap #4 조판분)

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:open_epub/open_epub.dart';
import 'package:open_epub/src/presentation/engine/reflowable/reflowable_engine.dart';
import 'package:open_epub_engine/testing.dart';

Widget _box(Widget child) => MaterialApp(
      home: Scaffold(
        body: SizedBox(width: 300, height: 400, child: child),
      ),
    );

Widget _html(String data, {bool forceVertical = false}) => _box(
      buildReflowableHtml(
        data: data,
        fontSize: 18,
        lineHeight: 1.6,
        imageLoader: null,
        forceVertical: forceVertical,
      ),
    );

void main() {
  group('VerticalTextBlock — 렌더 (S15.4)', () {
    testWidgets('글자를 upright로 렌더하고 가로 스크롤 제공', (tester) async {
      await tester.pumpWidget(_box(
        const VerticalTextBlock(text: '가나다라마', fontSize: 20),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      // 각 글자가 Text로 렌더된다.
      expect(find.text('가'), findsOneWidget);
      expect(find.text('마'), findsOneWidget);
      // 폭 넘침 대비 가로 스크롤.
      final scroll = tester.widget<SingleChildScrollView>(
        find.byType(SingleChildScrollView),
      );
      expect(scroll.scrollDirection, Axis.horizontal);
      expect(scroll.reverse, isTrue); // vertical-rl → 오른쪽에서 시작
    });

    testWidgets('vertical-lr은 정방향 스크롤', (tester) async {
      await tester.pumpWidget(_box(
        const VerticalTextBlock(text: '가나다', leftToRight: true),
      ));
      await tester.pumpAndSettle();
      final scroll = tester.widget<SingleChildScrollView>(
        find.byType(SingleChildScrollView),
      );
      expect(scroll.reverse, isFalse);
    });
  });

  group('buildReflowableHtml — 세로쓰기 분기 (S15.4)', () {
    testWidgets('인라인 writing-mode: vertical-rl + 단순 텍스트 → VerticalTextBlock',
        (tester) async {
      await tester.pumpWidget(_html(
        '<body style="writing-mode: vertical-rl"><p>세로 본문입니다</p></body>',
      ));
      await tester.pumpAndSettle();
      expect(find.byType(VerticalTextBlock), findsOneWidget);
      expect(find.byType(HtmlWidget), findsNothing);
    });

    testWidgets('세로쓰기 + 이미지 등 복잡 콘텐츠 → 가로(HtmlWidget) 폴백',
        (tester) async {
      await tester.pumpWidget(_html(
        '<body style="writing-mode: vertical-rl">'
        '<p>본문</p><img src="a.png"/></body>',
      ));
      await tester.pumpAndSettle();
      expect(find.byType(VerticalTextBlock), findsNothing);
      expect(find.byType(HtmlWidget), findsOneWidget);
    });

    testWidgets('forceVertical=true + 단순 텍스트 → VerticalTextBlock(인라인 미선언)',
        (tester) async {
      await tester.pumpWidget(_html(
        '<body><p>가로 선언 없는 본문</p></body>',
        forceVertical: true,
      ));
      await tester.pumpAndSettle();
      expect(find.byType(VerticalTextBlock), findsOneWidget);
    });

    testWidgets('가로쓰기(기본)는 HtmlWidget 유지(회귀)', (tester) async {
      await tester.pumpWidget(_html('<body><p>일반 가로 본문</p></body>'));
      await tester.pumpAndSettle();
      expect(find.byType(VerticalTextBlock), findsNothing);
      expect(find.byType(HtmlWidget), findsOneWidget);
    });
  });

  group('EpubReader — 세로쓰기 override 통합 (S15.4)', () {
    testWidgets('verticalWriting: true → 본문이 VerticalTextBlock으로 렌더',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: EpubReader(
            source: EpubSource.bytes(searchableEpub3()),
            paged: true,
            verticalWriting: true,
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.byType(VerticalTextBlock), findsWidgets);
    });

    testWidgets('verticalWriting 기본 false → 가로(HtmlWidget) 회귀', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: EpubReader(
            source: EpubSource.bytes(searchableEpub3()),
            paged: true,
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.byType(VerticalTextBlock), findsNothing);
      expect(find.byType(HtmlWidget), findsWidgets);
    });
  });
}

// Story: S11.5 (#92) — 렌더러 교체(fwfh) 후 선택/하이라이트 회귀 + script 차단
// BDD: F1-Adv1(script 차단), F2/F5 선택·하이라이트 재배치
//
// script/iframe 차단의 1차 방어는 엔진(readSpineXhtml→HtmlSanitizer)이지만,
// 여기서는 렌더러(fwfh) 자체가 script/style/이벤트 핸들러를 렌더·실행하지 않는
// 2차 방어(defense-in-depth)를 검증한다. 선택은 fwfh가 선택 가능한 RichText로
// 렌더하는지, 하이라이트는 openepub-hl 링크가 렌더·탭·재배치되는지 회귀한다.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:open_epub/src/presentation/engine/reflowable/reflowable_engine.dart';

Widget _host(String data,
        {double fontSize = 16, EpubLinkTapCallback? onLinkTap}) =>
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: buildReflowableHtml(
            data: data,
            fontSize: fontSize,
            lineHeight: 1.5,
            imageLoader: null,
            onLinkTap: onLinkTap,
          ),
        ),
      ),
    );

void main() {
  group('S11.5 — script 차단 defense-in-depth (fwfh 경로)', () {
    testWidgets('<script> 내용은 렌더되지 않고 본문만 표시', (tester) async {
      await tester.pumpWidget(
        _host('<body><script>alert("x9y7")</script>'
            '<p>안전한 본문</p></body>'),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.textContaining('안전한 본문', findRichText: true), findsOneWidget);
      expect(find.textContaining('x9y7', findRichText: true), findsNothing);
      expect(find.textContaining('alert', findRichText: true), findsNothing);
    });

    testWidgets('<style> 내용은 텍스트로 유출되지 않는다', (tester) async {
      await tester.pumpWidget(
        _host('<body><style>.h{color:red}</style><p>본문 스타일</p></body>'),
      );
      await tester.pumpAndSettle();
      expect(
          find.textContaining('color:red', findRichText: true), findsNothing);
      expect(find.textContaining('본문 스타일', findRichText: true), findsOneWidget);
    });

    testWidgets('inline 이벤트 핸들러(onclick)는 무시되고 크래시 없음', (tester) async {
      await tester.pumpWidget(
        _host('<body><p onclick="alert(1)">핸들러 본문</p></body>'),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.textContaining('핸들러 본문', findRichText: true), findsOneWidget);
    });
  });

  group('S11.5 — 텍스트 선택 회귀 (SelectionArea)', () {
    testWidgets('본문이 선택 가능한 RichText로 렌더되어 SelectionArea에 참여', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectionArea(
              child: SingleChildScrollView(
                child: buildReflowableHtml(
                  data: '<body><p>선택 가능한 본문</p></body>',
                  fontSize: 16,
                  lineHeight: 1.5,
                  imageLoader: null,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      // SelectionArea는 SelectableRegion을 구성하고, fwfh는 그 안에서 선택
      // 가능한 RichText로 본문을 렌더한다.
      expect(find.byType(SelectableRegion), findsOneWidget);
      expect(find.byType(RichText), findsWidgets);
      expect(
          find.textContaining('선택 가능한 본문', findRichText: true), findsOneWidget);
    });
  });

  group('S11.5 — 하이라이트 렌더·탭·재배치 회귀', () {
    // SpineTextExtractor가 주입하는 tappable 하이라이트 형식.
    const highlighted = '<body><p>앞 '
        '<a href="openepub-hl:h7" '
        'style="background-color:#FFF59D;color:inherit;text-decoration:none;">'
        '강조된 문구</a> 뒤</p></body>';

    testWidgets('하이라이트 문구가 렌더되고 탭 시 openepub-hl id가 전달된다', (tester) async {
      String? tapped;
      await tester.pumpWidget(_host(highlighted, onLinkTap: (h) => tapped = h));
      await tester.pumpAndSettle();

      expect(find.textContaining('강조된 문구', findRichText: true), findsOneWidget);
      await tester.tapOnText(find.textRange.ofSubstring('강조된 문구'));
      await tester.pump();
      expect(tapped, 'openepub-hl:h7');
    });

    testWidgets('글자 크기 변경(재배치) 후에도 하이라이트 탭이 유지된다 (F2.2 회귀)', (tester) async {
      String? tapped;
      // 16px 렌더
      await tester.pumpWidget(_host(highlighted, onLinkTap: (h) => tapped = h));
      await tester.pumpAndSettle();
      // 24px로 재배치
      await tester.pumpWidget(
        _host(highlighted, fontSize: 24, onLinkTap: (h) => tapped = h),
      );
      await tester.pumpAndSettle();

      final html = tester.widget<HtmlWidget>(find.byType(HtmlWidget));
      expect(html.textStyle?.fontSize, 24);
      expect(find.textContaining('강조된 문구', findRichText: true), findsOneWidget);

      await tester.tapOnText(find.textRange.ofSubstring('강조된 문구'));
      await tester.pump();
      expect(tapped, 'openepub-hl:h7');
    });
  });
}

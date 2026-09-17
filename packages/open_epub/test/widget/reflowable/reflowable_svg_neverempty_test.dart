// Story: S11.4 (#91) — 인라인 SVG 렌더(fwfh_svg) + never-empty 계약(ADR-009)
// BDD: F2.5 확장 (이미지/SVG/수식 placeholder), design gate C-coverage

import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_epub/src/presentation/engine/reflowable/reflowable_engine.dart';

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
  group('S11.4 — 인라인 SVG 렌더 (fwfh_svg)', () {
    testWidgets('본문 내 <svg>가 SvgPicture로 렌더된다', (tester) async {
      const svg = '<body><p>도형:</p>'
          '<svg xmlns="http://www.w3.org/2000/svg" width="40" height="40">'
          '<rect width="40" height="40" fill="#3366cc"/></svg></body>';
      await tester.pumpWidget(_host(svg));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(SvgPicture), findsOneWidget);
      // 본문 텍스트도 함께 렌더 (SVG가 본문을 밀어내지 않음)
      expect(find.textContaining('도형', findRichText: true), findsOneWidget);
    });
  });

  group('S11.4 — never-empty 계약', () {
    testWidgets('렌더 가능한 콘텐츠가 없으면 공백 대신 안내를 표시', (tester) async {
      await tester.pumpWidget(_host('<body></body>'));
      await tester.pumpAndSettle();
      expect(find.textContaining('표시할 내용이 없습니다'), findsOneWidget);
    });

    testWidgets('공백/엔티티만 있는 본문도 안내로 대체', (tester) async {
      await tester.pumpWidget(_host('<body><p>&nbsp;</p>\n  </body>'));
      await tester.pumpAndSettle();
      expect(find.textContaining('표시할 내용이 없습니다'), findsOneWidget);
    });

    testWidgets('이미지만 있는 본문은 빈 것이 아니다 (안내 미표시)', (tester) async {
      await tester.pumpWidget(
        _host('<body><img src="only.png"/></body>',
            imageLoader: (_) async => null),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('표시할 내용이 없습니다'), findsNothing);
      // 이미지 로드 실패 → placeholder 아이콘 (공백 금지)
      expect(find.byIcon(Icons.image_not_supported_outlined), findsOneWidget);
    });
  });

  group('S11.4 — 이미지 alt 대체 (alttext→placeholder)', () {
    testWidgets('로드 실패 시 alt 텍스트가 placeholder에 표시된다', (tester) async {
      await tester.pumpWidget(
        _host('<body><img src="broken.png" alt="고래 삽화"/></body>',
            imageLoader: (_) async => null),
      );
      await tester.pumpAndSettle();
      expect(find.text('고래 삽화'), findsOneWidget);
      expect(find.byIcon(Icons.image_not_supported_outlined), findsOneWidget);
    });

    testWidgets('alt가 없으면 아이콘 placeholder만 (공백 금지)', (tester) async {
      await tester.pumpWidget(
        _host('<body><img src="broken.png"/></body>',
            imageLoader: (_) async => throw Exception('load fail')),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.image_not_supported_outlined), findsOneWidget);
    });
  });

  // S14.2 (#106) — MathML을 TeX로 변환해 flutter_math_fork(Math)로 렌더.
  // (S11.4의 "E14 전까지 placeholder" 동작을 대체)
  group('S14.2 — <math> TeX 렌더 (gap #5)', () {
    testWidgets('<math>는 Math 위젯으로 렌더된다(placeholder 아님)', (tester) async {
      await tester.pumpWidget(
        _host('<body><math><mi>x</mi><mo>+</mo><mn>1</mn></math></body>'),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(Math), findsOneWidget);
      // 정상 변환 → placeholder 아이콘 없음
      expect(find.byIcon(Icons.functions), findsNothing);
    });

    testWidgets('분수·지수 중첩 MathML도 Math로 렌더', (tester) async {
      await tester.pumpWidget(
        _host('<body><math><mfrac><msup><mi>x</mi><mn>2</mn></msup>'
            '<mn>2</mn></mfrac></math></body>'),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(Math), findsOneWidget);
    });

    testWidgets('본문 텍스트와 수식이 함께 렌더(수식이 본문을 밀어내지 않음)', (tester) async {
      await tester.pumpWidget(
        _host('<body><p>공식:</p><math><msup><mi>e</mi>'
            '<mi>x</mi></msup></math></body>'),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Math), findsOneWidget);
      expect(find.textContaining('공식', findRichText: true), findsOneWidget);
    });

    testWidgets('변환 불가(빈 math)는 never-empty placeholder로 폴백', (tester) async {
      // 자식·alttext·annotation 모두 없어 mathmlToTex=null → placeholder.
      await tester.pumpWidget(_host('<body><math></math></body>'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(Math), findsNothing);
      expect(find.byIcon(Icons.functions), findsOneWidget);
      expect(find.text('수식'), findsOneWidget);
    });

    // 회귀 방지: <math>가 InlineCustomWidget으로 감싸지지 않으면 fwfh가
    // WidgetBit.block으로 취급해(core_build_tree._addBitsFromNode) 문단 중간의
    // 인라인 수식마다 강제 줄바꿈이 생긴다 — 문장이 앞/뒤로 쪼개져 별도
    // RichText가 된다. "…예제에서 컨텐츠를 불러오지 못하는 오류"로 보고된
    // MathML 문단 붕괴의 원인.
    testWidgets('한 문단 안의 인라인 수식이 앞뒤 텍스트를 분리하지 않는다', (tester) async {
      await tester.pumpWidget(
        _host('<body><p>before <math><mi>x</mi></math> after</p></body>'),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final merged = tester
          .widgetList<RichText>(find.byType(RichText))
          .map((rt) => rt.text.toPlainText())
          .any((text) => text.contains('before') && text.contains('after'));
      expect(
        merged,
        isTrue,
        reason: '수식이 블록으로 렌더되어 문단이 "before"/"after"로 쪼개짐(인라인 회귀)',
      );
    });
  });
}

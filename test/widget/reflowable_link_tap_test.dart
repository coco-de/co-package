// Story: S7.3/S7.5 (E7) — buildReflowableHtml onLinkTap 라우팅 위젯 테스트

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_epub/src/presentation/engine/reflowable/reflowable_engine.dart';

void main() {
  testWidgets('링크 탭 시 onLinkTap이 href와 함께 호출된다', (tester) async {
    String? tapped;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: buildReflowableHtml(
            data: '<body><p>본문 <a href="ch2.xhtml">링크</a> 끝</p></body>',
            fontSize: 16,
            lineHeight: 1.5,
            imageLoader: null,
            onLinkTap: (href) => tapped = href,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tapOnText(find.textRange.ofSubstring('링크'));
    await tester.pump();

    expect(tapped, 'ch2.xhtml');
  });

  testWidgets('하이라이트 링크 탭 시 openepub-hl 스킴 href가 전달된다', (tester) async {
    String? tapped;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: buildReflowableHtml(
            data: '<body><p>앞 '
                '<a href="openepub-hl:h1" style="background-color:#FFF59D;'
                'color:inherit;text-decoration:none;">강조</a> 뒤</p></body>',
            fontSize: 16,
            lineHeight: 1.5,
            imageLoader: null,
            onLinkTap: (href) => tapped = href,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tapOnText(find.textRange.ofSubstring('강조'));
    await tester.pump();

    expect(tapped, 'openepub-hl:h1');
  });
}

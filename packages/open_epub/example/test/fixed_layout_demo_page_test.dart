// fixed_layout_demo_page.dart 회귀 테스트.
//
// A4 크기 pre-paginated 데모 책이 FixedLayoutEngine으로 렌더되는지, 상태바가
// layout/크기를 올바르게 보여주는지, 다음 페이지 버튼으로 페이지가 넘어가는지
// 검증한다.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_epub/open_epub.dart';

import 'package:open_epub_example/fixed_layout_demo_page.dart';

void main() {
  testWidgets(
    'FixedLayoutDemoPage는 A4 pre-paginated 본문을 FixedLayoutEngine으로 렌더한다',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: FixedLayoutDemoPage()));
      await tester.pumpAndSettle();

      expect(find.byType(FixedLayoutEngine), findsOneWidget);

      final status = tester.widget<Text>(
        find.byKey(const ValueKey('fixed-layout-a4-status')),
      );
      expect(status.data, contains('layout:fixedLayout'));
      expect(status.data, contains('794×1123'));
      expect(status.data, contains('1/3쪽'));
    },
  );

  testWidgets('다음 페이지 버튼으로 페이지가 넘어간다', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: FixedLayoutDemoPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('fixed-layout-a4-next')));
    await tester.pumpAndSettle();

    final status = tester.widget<Text>(
      find.byKey(const ValueKey('fixed-layout-a4-status')),
    );
    expect(status.data, contains('2/3쪽'));
  });
}

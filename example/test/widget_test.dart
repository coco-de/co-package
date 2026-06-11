// example 앱 스모크 테스트.

import 'package:flutter_test/flutter_test.dart';

import 'package:open_epub_example/main.dart';

void main() {
  testWidgets('Home renders demo entries', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // 앱 타이틀 (AppBar)
    expect(find.text('EPUB Viewer Kit Demo'), findsOneWidget);

    // 1.0 코어 데모 진입 타일
    expect(find.text('1.0 코어 데모'), findsOneWidget);

    // 기존 0.1.x 데모 진입 버튼 (ListView 하단 — 스크롤해야 빌드된다)
    await tester.scrollUntilVisible(find.text('Open Reader'), 200);
    expect(find.text('Open Reader'), findsOneWidget);
  });
}

// example 앱 스모크 테스트.

import 'package:flutter_test/flutter_test.dart';

import 'package:open_epub_example/main.dart';

void main() {
  testWidgets('Home renders demo entries', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // 앱 타이틀 (AppBar) — 기본 언어는 한국어 (co-package#44)
    expect(find.text('open_epub 데모'), findsOneWidget);

    // EPUB3 샘플 라이브러리 진입 타일
    expect(find.text('EPUB3 샘플 라이브러리'), findsOneWidget);

    // 1.0 코어 데모 진입 타일
    expect(find.text('1.0 코어 데모'), findsOneWidget);

    // 하이라이트 데모 진입 타일 (#43)
    expect(find.text('하이라이트 데모'), findsOneWidget);

    // Fixed Layout A4 데모 진입 타일
    expect(find.text('Fixed Layout A4 데모'), findsOneWidget);
  });
}

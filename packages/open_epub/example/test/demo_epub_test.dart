// buildDemoEpub() 회귀 테스트 (#235).
//
// "1.0 코어 데모"·"하이라이트 데모"가 저장소에 없는 assets/example.epub에
// 의존해 클린 체크아웃(CI·GitHub Pages)에서 항상 asset 로드에 실패하던
// 문제의 재발 방지 — 두 데모 페이지가 override 없이(=기본 경로) 정상적으로
// EPUB을 열 수 있는지 검증한다.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_epub/open_epub.dart';
import 'package:open_epub_example/demo_epub.dart'
    show buildDemoEpub, buildFixedLayoutA4DemoEpub, kA4PageHeight, kA4PageWidth;
import 'package:open_epub_example/highlight_demo_page.dart';
import 'package:open_epub_example/v1_demo_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'buildDemoEpub()는 EpubBookSession.open으로 열 수 있는 유효한 EPUB을 생성한다',
    () async {
      final session = await EpubBookSession.open(
        EpubSource.bytes(buildDemoEpub()),
      );
      addTearDown(session.dispose);
      expect(session.book.spine, hasLength(2));
      expect(session.book.metadata.title, 'open_epub 데모 책');
    },
  );

  test(
    'buildFixedLayoutA4DemoEpub()는 pre-paginated·A4 3페이지 EPUB을 생성한다',
    () async {
      final session = await EpubBookSession.open(
        EpubSource.bytes(buildFixedLayoutA4DemoEpub()),
      );
      addTearDown(session.dispose);
      expect(session.book.layout, EpubLayout.fixedLayout);
      expect(session.book.spine, hasLength(3));
      expect(session.book.metadata.title, 'Fixed Layout A4 데모 책');
      final p1 = session.readSpineXhtml(session.book.spine.first.href);
      expect(p1, contains('width=${kA4PageWidth.toInt()}'));
      expect(p1, contains('height=${kA4PageHeight.toInt()}'));
    },
  );

  testWidgets('V1DemoPage는 assets/example.epub 없이도 정상적으로 열린다 (#235)', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: V1DemoPage()));
    await tester.pumpAndSettle();

    expect(find.textContaining('로드 실패'), findsNothing);
    expect(find.text('open_epub 데모 책'), findsOneWidget);
  });

  testWidgets(
    'HighlightDemoPage는 assets/example.epub 없이도(override 없이) 정상적으로 열린다 (#235)',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HighlightDemoPage()));
      await tester.pumpAndSettle();

      expect(find.textContaining('로드 실패'), findsNothing);
      expect(find.textContaining('열 수 없습니다'), findsNothing);
      final state = tester.state<HighlightDemoPageState>(
        find.byType(HighlightDemoPage),
      );
      expect(state.session, isNotNull);
    },
  );
}

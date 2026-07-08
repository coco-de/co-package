// reader_demo_page.dart 회귀 테스트 (#248).
//
// EPUB3 샘플 라이브러리 8종 중 라이선스 확인 후 저장소에 실제로 커밋된 6종은
// 정상적으로 렌더되고, 저작권 사유로 여전히 로컬 전용인 나머지는 안내
// 메시지를 유지하는지 검증한다.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:open_epub_example/reader_demo_page.dart';
import 'package:open_epub_example/sample_book.dart';

SampleBook _book(String id) => kSampleBooks.firstWhere((b) => b.id == id);

void main() {
  testWidgets('번들된 샘플(georgia-cfi)은 asset에서 정상적으로 열린다 (#248)', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: ReaderDemoPage(book: _book('cfi'))),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('reader-error')), findsNothing);
    expect(find.byKey(const ValueKey('epub-reader-cfi')), findsOneWidget);
  });

  testWidgets('저작권 미확인 샘플(accessible_epub_3)은 여전히 안내 메시지를 보여준다', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: ReaderDemoPage(book: _book('accessible'))),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('reader-error')), findsOneWidget);
    expect(find.textContaining('로컬 전용 테스트 픽스처'), findsOneWidget);
  });

  testWidgets('세로 스크롤 토글은 스와이프(paged) ↔ 스크롤 모드를 전환한다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: ReaderDemoPage(book: _book('cfi'))),
    );
    await tester.pumpAndSettle();

    // 기본값 — 스와이프(paged) 모드.
    Text status = tester.widget(find.byKey(const ValueKey('reader-status')));
    expect(status.data, contains('모드:스와이프'));

    await tester.tap(find.byKey(const ValueKey('reader-scroll-toggle')));
    await tester.pumpAndSettle();

    status = tester.widget(find.byKey(const ValueKey('reader-status')));
    expect(status.data, contains('모드:스크롤'));

    await tester.tap(find.byKey(const ValueKey('reader-scroll-toggle')));
    await tester.pumpAndSettle();

    status = tester.widget(find.byKey(const ValueKey('reader-status')));
    expect(status.data, contains('모드:스와이프'));
  });
}

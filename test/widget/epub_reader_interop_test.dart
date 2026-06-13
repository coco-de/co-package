// Story: S8.1/S8.2 (E8) — EpubReader 페이지·위치·viewport 콜백 (open-board 연동)

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_epub/src/api/epub_position.dart';
import 'package:open_epub/src/api/epub_source.dart';
import 'package:open_epub/src/presentation/widgets/epub_reader.dart';

import '../unit/_fixtures/epub_fixtures.dart';

void main() {
  testWidgets('paged EpubReader가 초기 페이지·위치·viewport를 보고한다', (tester) async {
    final pages = <List<int>>[];
    final positions = <EpubPosition>[];
    Size? viewport;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EpubReader(
            source: EpubSource.bytes(searchableEpub3()),
            paged: true,
            onPageChanged: (index, count) => pages.add([index, count]),
            onPositionChanged: positions.add,
            onViewportChanged: (size) => viewport = size,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(pages, isNotEmpty);
    expect(pages.first, [0, 3]); // 첫 spine, 총 3개
    expect(positions, isNotEmpty);
    expect(positions.first.spineHref, 'ch1.xhtml');
    expect(viewport, isNotNull);
    expect(viewport!.width, greaterThan(0));
  });

  testWidgets('스와이프 시 페이지 전환이 보고된다', (tester) async {
    final pages = <int>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EpubReader(
            source: EpubSource.bytes(searchableEpub3()),
            paged: true,
            onPageChanged: (index, _) => pages.add(index),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.fling(find.byType(PageView), const Offset(-500, 0), 1500);
    await tester.pumpAndSettle();

    expect(pages.last, 1); // 2번째 spine으로 전환
  });
}

// #68 S9.4 회귀 — 진행률 표시를 좁은 범위 ValueListenableBuilder로 분리해,
// 스크롤/페이지 이동 시 진행률 갱신이 엔진(리스트 본문) 리빌드를 유발하지 않게
// 한다. 부수적으로, 이전에는 _handlePageChanged가 setState를 하지 않아 진행률
// %가 페이지 이동에도 stale하게 남던 버그도 함께 고친다.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_epub/src/api/epub_reader_controller.dart';
import 'package:open_epub/src/presentation/widgets/epub_reader.dart';
import 'package:open_epub_engine/src/api/epub_source.dart';
import 'package:open_epub_engine/testing.dart';

void main() {
  testWidgets('진행률 %가 페이지 이동 시 라이브로 갱신된다 (#68 S9.4)',
      (tester) async {
    final controller = EpubViewController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: EpubReader(
          source: EpubSource.bytes(searchableEpub3()),
          controller: controller,
          paged: true,
          showProgressIndicator: true,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    // 초기 진행률 0%.
    expect(find.text('0%'), findsOneWidget);

    // 마지막 spine으로 이동 → 진행률이 100%로 라이브 갱신(이전엔 stale).
    final last = controller.spineCount - 1;
    final toLast = controller.goToSpine(last);
    await tester.pumpAndSettle();
    await toLast;

    expect(find.text('100%'), findsOneWidget);
    expect(find.text('0%'), findsNothing);
  });

  testWidgets('진행률 표시는 ValueListenableBuilder<double>로 분리되어 있다 (#68)',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: EpubReader(
          source: EpubSource.bytes(searchableEpub3()),
          paged: true,
          showProgressIndicator: true,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    // % 표시가 ValueListenableBuilder<double> 아래에 있어야 한다(엔진과 분리).
    expect(
      find.ancestor(
        of: find.text('0%'),
        matching: find.byType(ValueListenableBuilder<double>),
      ),
      findsOneWidget,
    );
  });

  testWidgets('showProgressIndicator=false면 진행률 표시가 없다', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: EpubReader(
          source: EpubSource.bytes(searchableEpub3()),
          paged: true,
          showProgressIndicator: false,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(ValueListenableBuilder<double>), findsNothing);
    expect(find.text('0%'), findsNothing);
  });
}

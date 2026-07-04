// BDD widget tests — epub_search.feature
// Story: S1.19 (#35), S1.21 (#37) — 본문 검색
//
// Source: test/src/bdd/epub_search.feature
// Steps:  test/src/bdd/step/epub_search_steps.dart + _common_steps.dart
//
// 검색 패널 UI(진행 표시·결과 목록·footer 안내·시각 하이라이트)는
// EpubSearchResults(S2.11)/EpubSearchPage(S3.15) — E2/E3 범위라 하니스
// 치환으로 검증한다 (steps 파일 각 step 주석 참고).

import 'package:flutter_test/flutter_test.dart';

import 'step/_common_steps.dart';
import 'step/epub_search_steps.dart';

void main() {
  group('F7: 본문 검색', () {
    late SearchWorld world;

    setUp(() => world = SearchWorld());
    tearDown(() => world.dispose());

    test('첫 검색 시 인덱스 빌드 (@P0)', () async {
      await fiftyMbBookOpen(world);
      await searchIndexNotBuilt(world);
      await userOpensSearchPanelFirstTime(world);
      await searchIndexPreparingShown(world);
      await indexBuildCompletesWithin(world, 3.0);
    });

    test('검색어 입력 및 결과 (@P0)', () async {
      await searchIndexIsBuilt(world);
      await userTypesSearchQuery(world, 'Flutter');
      await matchingResultListShown(world);
      await resultShowsSnippetAndPage(world);
    });

    test('검색 결과 이동 (@P0)', () async {
      await searchResultListShown(world);
      await userTapsFirstResult(world);
      await viewerJumpsToBookPosition(world);
      await wordVisuallyHighlightedInBody(world, 'Flutter');
    });

    test('Fixed Layout 이미지-온리 페이지는 검색 제외 (@P0)', () async {
      await bookHasFixedLayoutWithoutTextLayer(world);
      await userPerformsSearch(world);
      await pageExcludedFromResults(world);
      await searchPanelFooterShowsMessage(
          world, '1개 페이지는 텍스트 레이어가 없어 검색에서 제외되었습니다');
    });
  });
}

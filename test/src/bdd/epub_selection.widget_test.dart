// BDD widget tests — epub_selection.feature
// Story: S1.13 (#37) — Fixed Layout 텍스트 레이어 감지 (F5.5/F5.6)
//
// Source: test/src/bdd/epub_selection.feature
// Steps:  test/src/bdd/step/epub_selection_steps.dart + _common_steps.dart
//
// E1 패키지 범위의 selection 산출물은 DetectTextLayerUseCase(S1.13)뿐이다.
// 선택 제스처·컨텍스트 메뉴·하이라이트 영속(BookHighlight start/end/color)·
// 메모 UI는 kobic 호스트 E3(S3.13 EpubHighlightPage, S3.2/S3.5/S3.8 영속)
// 범위 — 해당 4개 시나리오는 skip 처리한다. Fixed Layout 텍스트 레이어
// 시나리오 2개는 S1.13 판정 계약으로 검증한다.

import 'package:flutter_test/flutter_test.dart';

import 'step/_common_steps.dart';
import 'step/epub_selection_steps.dart';

void main() {
  group('F5: 텍스트 선택, 하이라이트, 메모', () {
    late BddWorld world;

    setUp(() => world = BddWorld());
    tearDown(() => world.dispose());

    test(
      'Reflowable 텍스트 선택 (@P0)',
      () async {
        await reflowableEpubOpen(world);
        await userLongPressesSelectWord(world);
        await contextMenuShown(world);
      },
      skip: '텍스트 선택 제스처/컨텍스트 메뉴 UI 미구현 — E3(S3.13 EpubHighlightPage) 범위',
    );

    test(
      '하이라이트 부여 (4색) (@P0)',
      () async {
        await userHasSelectedText(world, '중요한 문장');
        await userTapsHighlightColor(world, '노란');
        await textHighlightedWithColor(world, '노란');
        await bookHighlightStoredWithColor(world, 'yellow');
      },
      skip: 'BookHighlight(start/end/color) 영속 미구현 — E3(S3.2/S3.5/S3.13) 범위',
    );

    test(
      '메모 추가 (@P0)',
      () async {
        await yellowHighlightAppliedTo(world, '중요한 문장');
        await userTapsHighlightNote(world);
        await userInputsNote(world, '이 부분 다시 보기');
        await noteLinkedToHighlight(world);
        await highlightListShowsNotePreview(world);
      },
      skip: '메모 입력/연결 UI·영속 미구현 — E3(S3.13/S3.5) 범위',
    );

    test(
      '하이라이트 삭제 (@P0)',
      () async {
        await yellowHighlightExists(world);
        await userTapsHighlightDelete(world);
        await highlightVisuallyRemoved(world);
        await dataStoreAlsoDeletes(world);
      },
      skip: '하이라이트 삭제 UI·영속 미구현 — E3(S3.13/S3.5/S3.8) 범위',
    );

    test('Fixed Layout 텍스트 레이어 있는 페이지 선택 (@P0)', () async {
      await fixedLayoutTextLayerHasNChars(world, 50);
      await userSelectsText(world);
      await selectionEnabledAndContextMenuShown(world);
    });

    test('Fixed Layout 이미지-온리 페이지 선택 시도 (@P0)', () async {
      await fixedLayoutPageImageOnly(world);
      await userLongPresses(world);
      await contextMenuNotShown(world);
      await toastMessageShown(world, '이 페이지는 텍스트 선택을 지원하지 않습니다');
    });
  });
}

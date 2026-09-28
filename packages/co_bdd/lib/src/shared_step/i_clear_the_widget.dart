import 'package:co_bdd/src/driver/test_driver.dart';
import 'package:flutter/foundation.dart';

/// Usage: I clear the {'search_field'} widget
/// # 입력 필드를 비웁니다
///
/// 검색어 **삭제**는 입력과 대칭인 별개의 계약이다
/// (목록 화면의 검색 계약). 지우면 목록이 전체로
/// 돌아와야 하고, 그 "지움"이 이후 재조회에도 유지돼야 한다.
///
/// ⚠️ `I enter {''} in the ...` 로 대신하지 말 것 — 빈 문자열 파라미터는
/// `.feature` 에서 읽는 사람에게 "무엇을 입력한다"로 보이고, 생성기에 따라
/// 빈 인자가 잘리기도 한다. 지움은 지움이라고 쓴다.
///
/// 이 step 은 `onChanged('')` 경로를 탄다. 지우기 **버튼**(`search_clear_button`)
/// 은 별개 경로이므로 그쪽을 검증하려면 `I tap the {'search_clear_button'} widget`
/// 을 쓸 것 — 두 경로가 같은 결과를 내는지는 그 자체로 검증 대상이다.
Future<void> iClearTheWidget(TestDriver driver, String keyName) async {
  await driver.enterText(Key(keyName), '');
  await driver.settle();
}

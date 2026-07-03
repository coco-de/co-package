# Feature scope: epub_selection
# BDD doc anchor: F5
# Architecture: lib/src/domain/entity/text_layer_verdict.dart + detect_text_layer_use_case
# Stories: S1.13

Feature: 텍스트 선택, 하이라이트, 메모
  사용자는 본문 텍스트를 선택하고 하이라이트·메모를 부여할 수 있다.

  @P0
  Scenario: Reflowable 텍스트 선택
    Given Reflowable EPUB이 열려 있다
    When 사용자가 본문 텍스트를 길게 눌러 단어를 선택한다
    Then 선택 영역에 컨텍스트 메뉴(Highlight/Copy/Note)가 표시된다

  @P0
  Scenario: 하이라이트 부여 (4색)
    Given 사용자가 텍스트 "중요한 문장"을 선택했다
    When 사용자가 컨텍스트 메뉴에서 "Highlight" 노란색을 탭한다
    Then 해당 텍스트에 노란색 하이라이트가 시각화된다
    And BookHighlight가 BookPosition start, end와 color=yellow로 저장된다

  @P0
  Scenario: 메모 추가
    Given "중요한 문장"에 노란 하이라이트가 적용되어 있다
    When 사용자가 하이라이트를 탭하여 "Note" 액션을 선택한다
    And "이 부분 다시 보기"라고 입력한다
    Then 메모가 하이라이트와 연결되어 저장된다
    And 하이라이트 목록에서 메모 미리보기가 표시된다

  @P0
  Scenario: 하이라이트 삭제
    Given 노란색 하이라이트가 적용되어 있다
    When 사용자가 하이라이트를 탭하여 "Delete"를 선택한다
    Then 해당 하이라이트가 시각적으로 제거된다
    And 데이터 저장소에서도 삭제된다

  @P0
  Scenario: Fixed Layout 텍스트 레이어 있는 페이지 선택
    Given Fixed Layout 페이지의 텍스트 레이어가 50자 이상 가시 텍스트를 갖는다
    When 사용자가 텍스트를 선택한다
    Then 선택이 활성화되고 컨텍스트 메뉴가 표시된다

  @P0
  Scenario: Fixed Layout 이미지-온리 페이지 선택 시도
    Given Fixed Layout 페이지가 이미지만 있고 텍스트 레이어가 없다
    When 사용자가 길게 누른다
    Then 컨텍스트 메뉴는 표시되지 않는다
    And toast 메시지 "이 페이지는 텍스트 선택을 지원하지 않습니다"가 표시된다

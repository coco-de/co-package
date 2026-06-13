# Feature scope: example 앱 하이라이트 데모
# BDD doc anchor: F5-demo
# Architecture: example/lib/highlight_demo_page.dart
# Stories: #43
# 1.0 공개 API(open_epub_v1.dart)만 사용 — 코어 하이라이트 영속은 E3(S3.13) 범위

Feature: 텍스트 선택 → 색상 하이라이트 + 메모 기록
  독자는 본문 텍스트를 선택해 원하는 색으로 하이라이트하고 메모를 남길 수 있다.

  Background:
    Given 하이라이트 데모 페이지에 EPUB 책이 열려 있다

  @P0
  Scenario: 선택 시 하이라이트 버튼 노출 (데스크톱 웹 진입점, #45)
    Given 선택이 없으면 하이라이트 버튼이 보이지 않는다
    When 사용자가 본문 텍스트를 선택한다
    Then "하이라이트" 버튼이 나타난다
    And 버튼을 눌러 색을 칠하면 선택이 소비되고 버튼이 사라진다

  @P0 @smoke
  Scenario: 텍스트 선택 후 색상 하이라이트
    When 사용자가 본문 텍스트 "고래는 바다에"를 선택한다
    And 컨텍스트 메뉴에서 "하이라이트"를 탭한다
    And 색상 "초록"을 선택하고 저장한다
    Then 본문에서 "고래는 바다에" 구간이 초록 배경으로 표시된다
    And 하이라이트 목록에 1개 항목이 추가된다
    And toolUseEvents에 EpubHighlightToolUse가 발사된다

  @P0
  Scenario: 메모와 함께 하이라이트
    When 사용자가 본문 텍스트 "바다는 넓다"를 선택한다
    And 색상 "파랑"과 메모 "중요한 문장"을 입력하고 저장한다
    Then 하이라이트 목록 항목에 메모 "중요한 문장"이 표시된다

  @P0
  Scenario: 하이라이트 영속 — 재시작 후 유지
    Given 하이라이트 "고래는 바다에"(노랑)가 저장되어 있다
    When 데모 페이지를 다시 연다
    Then 본문에서 "고래는 바다에" 구간이 노랑 배경으로 표시된다
    And 하이라이트 목록에 1개 항목이 있다

  @P0
  Scenario: 하이라이트 목록에서 이동
    Given 2장에 하이라이트 "사자는 초원의"(분홍)가 저장되어 있다
    And 뷰어는 1장을 표시하고 있다
    When 하이라이트 목록에서 해당 항목을 탭한다
    Then 뷰어는 2장으로 이동한다

  @P1
  Scenario: 메모 편집
    Given 하이라이트 1개가 저장되어 있다
    When 하이라이트 목록에서 메모 편집을 탭해 "다시 읽기"를 입력하고 저장한다
    Then 하이라이트 항목의 메모가 "다시 읽기"로 갱신된다

  @P0
  Scenario: 비선형 cover가 있는 책 — 챕터·하이라이트 정합
    Given linear="no" cover가 spine 첫 항목인 책이 열려 있다
    Then 첫 화면은 cover가 아닌 첫 linear 챕터를 표시한다
    When 하이라이트를 추가하면
    Then 표시 중인 챕터의 href로 저장되고 본문에 렌더된다

  @P0
  Scenario: 챕터 이동 후 하이라이트 — analytics 위치 정합
    Given 사용자가 2장으로 이동했다
    When 하이라이트를 추가한다
    Then toolUseEvents의 position은 2장을 가리킨다

  @P1
  Scenario: 하이라이트 삭제
    Given 하이라이트 1개가 저장되어 있다
    When 하이라이트 목록에서 삭제를 탭한다
    Then 본문 하이라이트 표시가 사라진다
    And 하이라이트 목록은 비어 있다

  @edge
  Scenario: 본문과 일치하지 않는 선택 텍스트
    Given 여러 문단에 걸친 선택으로 본문 원문과 일치하지 않는 텍스트가 저장된다
    Then 하이라이트 목록에는 항목이 보이지만 본문 표시는 생략된다
    And 앱은 크래시 없이 동작한다

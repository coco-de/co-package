# Feature scope: epub_search
# BDD doc anchor: F7
# Architecture: lib/src/data/search/text_index_builder.dart + build_search_index_use_case
# Stories: S1.19

Feature: 본문 검색
  사용자는 본문 텍스트로 검색하고 결과로 점프할 수 있다.

  @P0
  Scenario: 첫 검색 시 인덱스 빌드
    Given 50MB EPUB 책이 열려 있다
    And 검색 인덱스가 아직 빌드되지 않았다
    When 사용자가 검색 패널을 처음 연다
    Then "검색 인덱스 준비 중..." 진행 표시가 보인다
    And 3.0초 안에 인덱스 빌드가 완료된다

  @P0
  Scenario: 검색어 입력 및 결과
    Given 검색 인덱스가 빌드되어 있다
    When 사용자가 검색어 "Flutter"를 입력한다
    Then 매칭되는 본문 결과 목록이 표시된다
    And 각 결과는 스니펫과 페이지 정보를 보여준다

  @P0
  Scenario: 검색 결과 이동
    Given 검색 결과 목록이 표시되어 있다
    When 사용자가 첫 번째 결과를 탭한다
    Then 뷰어가 해당 BookPosition으로 이동한다
    And 본문에서 "Flutter" 단어가 시각적으로 하이라이트된다

  @P0
  Scenario: Fixed Layout 이미지-온리 페이지는 검색 제외
    Given 책에 텍스트 레이어가 없는 Fixed Layout 페이지가 있다
    When 사용자가 검색을 수행한다
    Then 그 페이지는 결과에 포함되지 않는다
    And 검색 패널 하단에 "X개 페이지는 텍스트 레이어가 없어 검색에서 제외되었습니다" 안내가 표시된다

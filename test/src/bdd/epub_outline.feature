# Feature scope: epub_outline
# BDD doc anchor: F4
# Architecture: lib/src/data/parser/{ncx,nav}_parser.dart + sparse_ncx + empty_toc patch
# Stories: S1.2, S1.3, S1.15

Feature: 목차 표시 및 점프
  사용자는 NCX/nav 기반 목차로 책 어디로든 즉시 이동할 수 있다.

  @P0
  Scenario: EPUB 3 nav 목차 표시
    Given EPUB 3 책의 nav.xhtml에 5개 챕터가 정의되어 있다
    When 사용자가 목차 패널을 연다
    Then 목차 트리에 5개 챕터가 표시된다

  @P0
  Scenario: 목차 항목 클릭 시 이동
    Given 목차 패널이 열려 있다
    When 사용자가 "3장. 시작하기" 항목을 탭한다
    Then 뷰어가 해당 BookPosition으로 이동한다
    And 본문 첫 부분이 표시된다

  @P0
  Scenario: sparse-NCX 자동 보정
    Given EPUB 2의 NCX에 spine 항목의 30%만 등록되어 있다
    When 책이 열린다
    Then 누락 spine이 NCX에 자동 추가되어 표시된다
    And BookSessionDiagnostics에 "sparse-ncx" patch가 기록된다

  @P0
  Scenario: 빈 목차 fallback
    Given EPUB의 NCX와 nav가 모두 비어 있다
    When 책이 열린다
    Then spine 기반 자동 목차가 생성된다
    And BookSessionDiagnostics에 "empty-toc" patch가 기록된다

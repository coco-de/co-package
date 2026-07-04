# Feature scope: epub_source
# BDD doc anchor: F1 + F11
# Architecture: lib/src/api/{epub_source,epub_book_session,epub_analytics}.dart
# Stories: S1.20, S1.21, S1.23, S1.25

Feature: EPUB 책 열기 및 마지막 위치 복원
  학습자(P1)는 kobic 라이브러리에서 EPUB을 선택하여 즉시 읽기 시작할 수 있다.

  Background:
    Given kobic 사용자가 로그인되어 있다
    And 사용자 라이브러리에 EPUB 책 "사용자_매뉴얼.epub"이 있다

  @P0 @smoke
  Scenario: 새 EPUB 책 첫 열람
    Given 사용자가 라이브러리 화면에 있다
    When 사용자가 "사용자_매뉴얼.epub" 항목을 탭한다
    Then EPUB 뷰어가 2.0초 안에 첫 페이지를 표시한다
    And book_session_started 이벤트가 발사된다
    And 진도는 0.0이다

  @P0
  Scenario: 마지막 위치에서 이어 읽기
    Given 사용자가 "사용자_매뉴얼.epub"을 진도 0.45에서 닫은 적이 있다
    And BookPosition v1 토큰이 저장되어 있다
    When 사용자가 같은 책을 다시 연다
    Then 뷰어는 BookPosition을 복원하고 정확히 0.45 지점을 표시한다
    And 진도 인디케이터는 "45%"를 보여준다

  @P0
  Scenario: 위치 복원 실패 시 fallback
    Given 저장된 BookPosition의 spineHref가 더 이상 존재하지 않는다
    When 사용자가 책을 연다
    Then 뷰어는 spine의 첫 페이지를 표시한다
    And 진단 이벤트 "position-restore-failed"가 기록된다
    And 사용자에게 "마지막 위치를 찾을 수 없어 처음부터 표시합니다" 메시지가 표시된다

  @P0
  Scenario Outline: 5플랫폼 모두에서 EPUB 첫 페이지가 보인다
    Given 사용자가 <platform>에서 kobic을 실행 중이다
    When 사용자가 50MB EPUB 책을 연다
    Then 첫 페이지가 <maxTime>초 안에 표시된다

    Examples:
      | platform | maxTime |
      | iOS      | 2.0     |
      | Android  | 2.0     |
      | Web      | 3.0     |
      | Windows  | 2.0     |
      | macOS    | 2.0     |

  @P0
  Scenario: lifecycleEvents 발사
    Given kobic이 BookSession을 시작한다
    When session이 정상 open된다
    Then lifecycleEvents에 SessionStarted 이벤트가 발사된다
    And kobic이 "book_session_started" 외부 이벤트로 변환한다

  @P0
  Scenario: progressEvents debounce
    Given session이 진행 중이다
    When 사용자가 1초 안에 5번 페이지를 넘긴다
    Then progressEvents는 30초마다 1번만 발사된다
    And kobic은 마지막 진도를 받는다

  @P0
  Scenario: toolUseEvents 분류
    Given session이 진행 중이다
    When 사용자가 하이라이트를 부여하고 북마크를 추가한다
    Then toolUseEvents에 EpubToolUseEvent.highlight + EpubToolUseEvent.bookmark가 발사된다
    And 각 이벤트는 BookPosition을 포함한다

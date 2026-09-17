# Feature scope: epub_fixed_layout
# BDD doc anchor: F3
# Architecture: lib/src/presentation/engine/fixed_layout/
# Stories: S1.7, S1.8, S1.9

Feature: Fixed Layout EPUB 본문 렌더링
  그림책·만화·전공서의 디자인 고정 페이지를 깨짐 없이 표시한다.

  Background:
    Given Fixed Layout EPUB "picture_book.epub"이 열려 있다
    And rendition:layout은 "pre-paginated"이다

  @P0
  Scenario: SVG 단일 페이지 viewport fit
    When 페이지가 표시된다
    Then 페이지가 화면 viewport 비율에 fit된다
    And 디자인이 깨지지 않는다

  @P0
  Scenario: 핀치 줌
    Given Fixed Layout 페이지가 표시되어 있다
    When 사용자가 두 손가락으로 핀치 줌 인 한다
    Then 페이지가 줌 인된다
    And 줌 배율은 최대 4.0까지 가능하다
    And 더블 탭으로 줌이 원복된다

  @P0
  Scenario Outline: 화면 폭에 따른 자동 spread
    Given EPUB 메타 rendition:spread가 "auto"이다
    And 화면 폭이 <width>이다
    When 페이지가 표시된다
    Then spread 모드는 <mode>이다

    Examples:
      | width | mode      |
      | 480   | 1-page    |
      | 768   | 1-page    |
      | 1024  | 2-page    |
      | 1440  | 2-page    |

  @P0
  Scenario: page-spread-left/right 표기 존중
    Given spine item에 page-spread-left가 명시되어 있다
    When 2-page spread 모드에서 표시된다
    Then 해당 페이지는 좌측 슬롯에 표시된다

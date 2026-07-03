# Feature scope: epub_input
# BDD doc anchor: F8
# Architecture: lib/src/presentation/input/{desktop,touch}_input.dart
# Stories: S3.18 (kobic 측 wiring 동반)

Feature: 데스크톱·모바일 통합 입력
  사용자는 디바이스에 맞는 입력 방식으로 책을 읽을 수 있다.

  @P0 @mobile
  Scenario: 모바일 터치 스와이프
    Given 모바일에서 책이 열려 있다
    When 사용자가 좌로 스와이프한다
    Then 다음 페이지가 표시된다

  @P0 @desktop
  Scenario Outline: 데스크톱 키보드 단축키
    Given 데스크톱 <platform>에서 책이 열려 있다
    When 사용자가 키 "<key>"를 누른다
    Then "<action>"이 수행된다

    Examples:
      | platform | key        | action          |
      | macOS    | RightArrow | next page       |
      | macOS    | LeftArrow  | prev page       |
      | macOS    | Home       | go to start     |
      | macOS    | End        | go to end       |
      | macOS    | Cmd+F      | open search     |
      | macOS    | Cmd+B      | toggle bookmark |
      | Windows  | RightArrow | next page       |
      | Windows  | PageDown   | next page       |
      | Windows  | Ctrl+F     | open search     |
      | Windows  | F11        | fullscreen      |

  @P0 @desktop
  Scenario: 마우스 휠 페이지 전환
    Given 데스크톱에서 책이 페이지 모드로 열려 있다
    When 사용자가 마우스 휠을 아래로 굴린다
    Then 다음 페이지가 표시된다

  @P0 @desktop
  Scenario: 우클릭 컨텍스트 메뉴
    Given 데스크톱에서 텍스트를 선택했다
    When 사용자가 우클릭한다
    Then 컨텍스트 메뉴(Highlight/Copy/Note)가 표시된다

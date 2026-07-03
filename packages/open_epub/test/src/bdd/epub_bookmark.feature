# Feature scope: epub_bookmark
# BDD doc anchor: F6
# Architecture: lib/src/api/epub_position.dart + lib/src/data/codec/book_position_codec.dart
# Stories: S1.10, S1.11, S1.12

Feature: 북마크 추가·삭제·이동
  사용자는 현재 위치를 북마크하고 나중에 돌아올 수 있다.

  @P0
  Scenario: 북마크 추가
    Given 사용자가 책의 진도 0.6 지점에 있다
    When 사용자가 북마크 버튼을 탭한다
    Then 현재 BookPosition이 북마크로 저장된다
    And 북마크 아이콘이 "추가됨" 상태로 변한다

  @P0
  Scenario: 북마크 목록 표시
    Given 사용자가 책에 3개의 북마크를 저장했다
    When 사용자가 북마크 패널을 연다
    Then 3개의 북마크가 시간 역순으로 표시된다
    And 각 항목에 페이지 번호 또는 진도가 보인다

  @P0
  Scenario: 북마크 이동
    Given 북마크 패널에 진도 0.6 북마크가 있다
    When 사용자가 해당 북마크를 탭한다
    Then 뷰어가 BookPosition으로 이동한다

  @P0
  Scenario: 북마크 삭제 (스와이프)
    Given 북마크 패널에 북마크가 표시되어 있다
    When 사용자가 항목을 좌로 스와이프하여 "Delete"를 탭한다
    Then 해당 북마크가 목록에서 사라진다
    And 데이터 저장소에서도 삭제된다

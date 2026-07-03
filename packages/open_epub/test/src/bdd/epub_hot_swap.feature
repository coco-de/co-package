# Feature scope: epub_hot_swap
# BDD doc anchor: F10
# Architecture: lib/src/api/epub_book_session.dart (swapSource)
# Stories: S1.22

Feature: 에디터 EpubSourceBytes hot-swap
  Author(P2)는 EPUB을 수정하고 즉시 미리보기로 검수할 수 있다.

  @P0
  Scenario: 같은 EPUB의 hot-swap
    Given Author가 EPUB "draft.epub"을 미리보기로 열었다
    And 현재 BookPosition은 spineHref="ch03.xhtml" charOffset=5이다
    When Author가 EPUB을 수정하여 새 bytes를 전달한다
    And spine 구조가 동일하다
    Then 뷰어가 즉시 갱신된다
    And BookPosition이 복원된다

  @P1
  Scenario: spine 구조가 변경된 hot-swap
    Given Author가 책을 미리보기 중이다
    When Author가 spine 항목 순서를 변경한 새 EPUB을 전달한다
    Then 뷰어가 갱신된다
    And BookPosition 복원이 실패하면 spine의 첫 페이지로 fallback한다
    And 알림 "마지막 위치를 찾을 수 없어 처음부터 표시합니다"가 표시된다

  @P0
  Scenario: Fixed Layout hot-swap
    Given Fixed Layout EPUB이 미리보기로 열려 있다
    When Author가 새 페이지를 추가하고 bytes를 갱신한다
    Then 새 페이지가 spine에 반영된다

# Feature scope: epub_reflowable
# BDD doc anchor: F2
# Architecture: lib/src/presentation/engine/reflowable/
# Stories: S1.5, S1.6

Feature: Reflowable EPUB 본문 렌더링
  Reflowable EPUB은 사용자 글자 크기·줄간격 설정에 따라 동적 재배치된다.

  Background:
    Given Reflowable EPUB "novel.epub"이 열려 있다

  @P0
  Scenario: 글자 크기 변경
    Given 현재 글자 크기는 "보통"(100%)이다
    When 사용자가 글자 크기를 "크게"(140%)로 변경한다
    Then 본문 텍스트가 재배치되어 모두 140% 크기로 표시된다
    And 현재 BookPosition은 보존된다

  @P0
  Scenario: 줄간격 변경
    Given 현재 줄간격은 1.5이다
    When 사용자가 줄간격을 2.0으로 변경한다
    Then 본문이 새 줄간격으로 재배치된다
    And 페이지 전환 시 깨짐이 없다

  @P0
  Scenario: 페이지 전환 응답 시간
    Given Reflowable EPUB이 페이지 모드로 열려 있다
    When 사용자가 다음 페이지로 스와이프한다
    Then 다음 페이지가 150ms 안에 화면에 그려진다

  @P0
  Scenario: 이미지 인라인 렌더
    Given 본문에 이미지가 포함된 페이지가 있다
    When 페이지가 표시된다
    Then 이미지가 본문과 함께 렌더된다
    And 이미지 로딩 실패 시 placeholder가 보인다

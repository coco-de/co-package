# Feature scope: epub_compat
# BDD doc anchor: F9
# Architecture: lib/src/data/compat/patch_catalog.dart + patches/*
# Stories: S1.14~S1.18

Feature: 호환성 보정 및 진단 패널
  CS/품질 운영자(P4)는 보정 결과를 확인하고 사용자 응답을 작성할 수 있다.

  @P0 @ops
  Scenario: 진단 패널 열기 (운영자 모드)
    Given 운영자가 디버그 메뉴에서 책을 열었다
    When 운영자가 "Diagnostics" 메뉴를 탭한다
    Then 적용된 보정 카드 목록이 표시된다
    And 각 카드는 patchId, description, severity, impact를 보여준다

  @P0
  Scenario Outline: 보정 적용 시 진단 기록
    Given EPUB에 <issue> 문제가 있다
    When 책이 열린다
    Then "<patchId>" 보정이 적용된다
    And BookSessionDiagnostics에 <patchId>가 severity=<severity>로 기록된다

    Examples:
      | issue                       | patchId           | severity |
      | NCX 항목 30%만 있음          | sparse-ncx        | medium   |
      | spine[0]에 cover 메타        | cover-skip        | low      |
      | spine href가 OPF에 없음      | broken-spine-href | high     |
      | mimetype 파일 누락           | missing-mimetype  | low      |
      | NCX/nav 모두 빈              | empty-toc         | high     |

  @P1
  Scenario: 진단 결과 클립보드 복사
    Given 진단 패널이 열려 있다
    When 운영자가 "Copy to Clipboard"를 탭한다
    Then 진단 결과 JSON이 클립보드에 복사된다

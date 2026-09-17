# Feature scope: epub_security
# BDD doc anchor: Edge Cases (security)
# Architecture: lib/src/api/epub_security_config.dart + container_parser.isSafePath
# Stories: S1.24, S5.7

Feature: 보안 가드 (zip slip / script / CORS / size limit)
  악의적이거나 손상된 EPUB이 사용자 디바이스를 위협하지 않도록 한다.

  @P0 @edge @security
  Scenario: zip slip 시도
    Given EPUB 안에 "../../../etc/passwd" 경로의 리소스가 있다
    When EPUB이 열린다
    Then 그 리소스는 무시되며 BookSessionDiagnostics에 보안 경고가 기록된다
    And 파일 시스템 외부에 어떤 파일도 생성되지 않는다

  @P0 @edge @security
  Scenario: 외부 script 차단
    Given EPUB XHTML에 외부 script src가 있다
    When 페이지가 렌더된다
    Then script는 실행되지 않는다
    And 본문 텍스트만 표시된다

  @P0 @edge
  Scenario: Web CORS 위반 이미지
    Given Web에서 cross-origin 이미지를 포함한 EPUB을 연다
    And 해당 도메인이 CORS를 허용하지 않는다
    When 페이지가 표시된다
    Then 이미지는 placeholder로 표시된다
    And 본문 텍스트는 정상 표시된다
    And 진단에 "image-cors-blocked" 항목이 기록된다

  @P0 @edge
  Scenario: 매우 큰 EPUB (100MB)
    Given 100MB EPUB이 있다
    When 사용자가 책을 연다
    Then 첫 페이지가 5.0초 안에 표시된다
    And 메모리 peak이 600MB를 넘지 않는다

  @P0 @edge
  Scenario: 매우 작은 EPUB (10KB)
    Given 10KB EPUB이 있다
    When 사용자가 책을 연다
    Then 100ms 안에 첫 페이지가 표시된다

  @P0 @edge
  Scenario: 손상된 EPUB
    Given EPUB 파일이 손상되어 OPF 파싱이 실패한다
    When 사용자가 책을 연다
    Then "이 파일을 열 수 없습니다" 에러 화면이 표시된다
    And BookSessionDiagnostics에 unresolvedIssue가 기록된다
    And kobic이 분석 이벤트 "book_open_failed"를 발사한다

  @P0 @edge @security
  Scenario: 200MB 초과 파일 거부
    Given 250MB EPUB이 EpubSource.bytes로 전달된다
    When 사용자가 책을 연다
    Then EpubFileTooLarge 에러가 반환된다
    And 파싱은 시작되지 않는다

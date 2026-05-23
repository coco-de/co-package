// BDD Steps for epub_security.feature
// Status: SCAFFOLD STUB. Implementation deferred to Story S1.24, S1.25, S5.7.

// ignore_for_file: type=lint, unused_import

typedef TestDriver = Object;

/// Usage: Given EPUB 안에 "<path>" 경로의 리소스가 있다
Future<void> epubContainsPathResource(TestDriver driver, String path) async {
  throw UnimplementedError('Step not yet implemented');
}

/// Usage: When EPUB이 열린다
Future<void> epubIsOpened(TestDriver driver) async {
  throw UnimplementedError('Step not yet implemented');
}

/// Usage: Then 그 리소스는 무시되며 보안 경고가 기록된다
Future<void> resourceIgnoredSecurityWarning(TestDriver driver) async {
  throw UnimplementedError('Step not yet implemented');
}

/// Usage: Then 파일 시스템 외부에 어떤 파일도 생성되지 않는다
Future<void> noFilesCreatedOutsideSandbox(TestDriver driver) async {
  throw UnimplementedError('Step not yet implemented');
}

/// Usage: Given EPUB XHTML에 외부 script src가 있다
Future<void> epubXhtmlHasExternalScript(TestDriver driver) async {
  throw UnimplementedError('Step not yet implemented');
}

/// Usage: When 페이지가 렌더된다
Future<void> pageRenders(TestDriver driver) async {
  throw UnimplementedError('Step not yet implemented');
}

/// Usage: Then script는 실행되지 않는다
Future<void> scriptNotExecuted(TestDriver driver) async {
  throw UnimplementedError('Step not yet implemented');
}

/// Usage: Then 본문 텍스트만 표시된다
Future<void> onlyBodyTextDisplayed(TestDriver driver) async {
  throw UnimplementedError('Step not yet implemented');
}

/// Usage: Given Web에서 cross-origin 이미지를 포함한 EPUB을 연다
Future<void> webOpensEpubWithCrossOriginImage(TestDriver driver) async {
  throw UnimplementedError('Step not yet implemented');
}

/// Usage: And 해당 도메인이 CORS를 허용하지 않는다
Future<void> domainDoesNotAllowCors(TestDriver driver) async {
  throw UnimplementedError('Step not yet implemented');
}

/// Usage: Then 이미지는 placeholder로 표시된다
Future<void> imageShownAsPlaceholder(TestDriver driver) async {
  throw UnimplementedError('Step not yet implemented');
}

/// Usage: Then 본문 텍스트는 정상 표시된다
Future<void> bodyTextDisplayedNormally(TestDriver driver) async {
  throw UnimplementedError('Step not yet implemented');
}

/// Usage: Then 진단에 "<patchId>" 항목이 기록된다
Future<void> diagnosticsContainsItem(TestDriver driver, String patchId) async {
  throw UnimplementedError('Step not yet implemented');
}

/// Usage: Given <sizeMB>MB EPUB이 있다
Future<void> nMbEpubExists(TestDriver driver, int sizeMB) async {
  throw UnimplementedError('Step not yet implemented');
}

/// Usage: Then 첫 페이지가 <seconds>초 안에 표시된다
Future<void> firstPageShownWithinSeconds(TestDriver driver, double seconds) async {
  throw UnimplementedError('Step not yet implemented');
}

/// Usage: Then 메모리 peak이 <mb>MB를 넘지 않는다
Future<void> memoryPeakNoMoreThan(TestDriver driver, int mb) async {
  throw UnimplementedError('Step not yet implemented');
}

/// Usage: Given <sizeKB>KB EPUB이 있다
Future<void> nKbEpubExists(TestDriver driver, int sizeKB) async {
  throw UnimplementedError('Step not yet implemented');
}

/// Usage: Then <ms>ms 안에 첫 페이지가 표시된다
Future<void> firstPageShownWithinMs(TestDriver driver, int ms) async {
  throw UnimplementedError('Step not yet implemented');
}

/// Usage: Given EPUB 파일이 손상되어 OPF 파싱이 실패한다
Future<void> epubFileCorruptedOpfParseFails(TestDriver driver) async {
  throw UnimplementedError('Step not yet implemented');
}

/// Usage: Then "<message>" 에러 화면이 표시된다
Future<void> errorScreenShown(TestDriver driver, String message) async {
  throw UnimplementedError('Step not yet implemented');
}

/// Usage: Then BookSessionDiagnostics에 unresolvedIssue가 기록된다
Future<void> diagnosticsRecordsUnresolvedIssue(TestDriver driver) async {
  throw UnimplementedError('Step not yet implemented');
}

/// Usage: Then kobic이 분석 이벤트 "<name>"를 발사한다
Future<void> kobicEmitsAnalyticsEvent(TestDriver driver, String name) async {
  throw UnimplementedError('Step not yet implemented');
}

/// Usage: Given <sizeMB>MB EPUB이 EpubSource.bytes로 전달된다
Future<void> nMbEpubViaBytesSource(TestDriver driver, int sizeMB) async {
  throw UnimplementedError('Step not yet implemented');
}

/// Usage: Then EpubFileTooLarge 에러가 반환된다
Future<void> epubFileTooLargeErrorReturned(TestDriver driver) async {
  throw UnimplementedError('Step not yet implemented');
}

/// Usage: Then 파싱은 시작되지 않는다
Future<void> parsingDoesNotStart(TestDriver driver) async {
  throw UnimplementedError('Step not yet implemented');
}

// BDD Steps for epub_compat.feature
// Status: SCAFFOLD STUB. Implementation deferred to Story S1.14~S1.18.

// ignore_for_file: type=lint, unused_import

typedef TestDriver = Object;

/// Usage: Given 운영자가 디버그 메뉴에서 책을 열었다
Future<void> operatorOpenedBookViaDebugMenu(TestDriver driver) async {
  throw UnimplementedError('Step not yet implemented');
}

/// Usage: When 운영자가 "Diagnostics" 메뉴를 탭한다
Future<void> operatorTapsDiagnostics(TestDriver driver) async {
  throw UnimplementedError('Step not yet implemented');
}

/// Usage: Then 적용된 보정 카드 목록이 표시된다
Future<void> appliedPatchCardsShown(TestDriver driver) async {
  throw UnimplementedError('Step not yet implemented');
}

/// Usage: Then 각 카드는 patchId, description, severity, impact를 보여준다
Future<void> eachCardShowsPatchFields(TestDriver driver) async {
  throw UnimplementedError('Step not yet implemented');
}

/// Usage: Given EPUB에 <issue> 문제가 있다
Future<void> epubHasIssue(TestDriver driver, String issue) async {
  throw UnimplementedError('Step not yet implemented');
}

/// Usage: Then "<patchId>" 보정이 적용된다
Future<void> patchApplied(TestDriver driver, String patchId) async {
  throw UnimplementedError('Step not yet implemented');
}

/// Usage: Then BookSessionDiagnostics에 <patchId>가 severity=<severity>로 기록된다
Future<void> diagnosticsRecordsPatchWithSeverity(TestDriver driver, String patchId, String severity) async {
  throw UnimplementedError('Step not yet implemented');
}

/// Usage: Given 진단 패널이 열려 있다
Future<void> diagnosticsPanelOpen(TestDriver driver) async {
  throw UnimplementedError('Step not yet implemented');
}

/// Usage: When 운영자가 "Copy to Clipboard"를 탭한다
Future<void> operatorTapsCopyToClipboard(TestDriver driver) async {
  throw UnimplementedError('Step not yet implemented');
}

/// Usage: Then 진단 결과 JSON이 클립보드에 복사된다
Future<void> diagnosticsJsonCopiedToClipboard(TestDriver driver) async {
  throw UnimplementedError('Step not yet implemented');
}

// BDD Steps for epub_outline.feature
// Status: SCAFFOLD STUB. Implementation deferred to Story S1.2, S1.3, S1.15.

// ignore_for_file: type=lint, unused_import

typedef TestDriver = Object;

/// Usage: Given EPUB 3 책의 nav.xhtml에 <n>개 챕터가 정의되어 있다
Future<void> navHasChapters(TestDriver driver, int n) async {
  throw UnimplementedError('Step not yet implemented');
}

/// Usage: When 사용자가 목차 패널을 연다
Future<void> userOpensOutlinePanel(TestDriver driver) async {
  throw UnimplementedError('Step not yet implemented');
}

/// Usage: Then 목차 트리에 <n>개 챕터가 표시된다
Future<void> outlineTreeShowsChapters(TestDriver driver, int n) async {
  throw UnimplementedError('Step not yet implemented');
}

/// Usage: Given 목차 패널이 열려 있다
Future<void> outlinePanelIsOpen(TestDriver driver) async {
  throw UnimplementedError('Step not yet implemented');
}

/// Usage: When 사용자가 "<title>" 항목을 탭한다
Future<void> userTapsOutlineItem(TestDriver driver, String title) async {
  throw UnimplementedError('Step not yet implemented');
}

/// Usage: Then 본문 첫 부분이 표시된다
Future<void> bodyShowsFirstPortion(TestDriver driver) async {
  throw UnimplementedError('Step not yet implemented');
}

/// Usage: Given EPUB 2의 NCX에 spine 항목의 <percent>%만 등록되어 있다
Future<void> ncxHasSparseSpineEntries(TestDriver driver, int percent) async {
  throw UnimplementedError('Step not yet implemented');
}

/// Usage: When 책이 열린다
Future<void> bookIsOpened(TestDriver driver) async {
  throw UnimplementedError('Step not yet implemented');
}

/// Usage: Then 누락 spine이 NCX에 자동 추가되어 표시된다
Future<void> missingSpineAutoAddedToNcx(TestDriver driver) async {
  throw UnimplementedError('Step not yet implemented');
}

/// Usage: Then BookSessionDiagnostics에 "<patchId>" patch가 기록된다
Future<void> diagnosticsRecordsPatch(TestDriver driver, String patchId) async {
  throw UnimplementedError('Step not yet implemented');
}

/// Usage: Given EPUB의 NCX와 nav가 모두 비어 있다
Future<void> ncxAndNavAreEmpty(TestDriver driver) async {
  throw UnimplementedError('Step not yet implemented');
}

/// Usage: Then spine 기반 자동 목차가 생성된다
Future<void> spineBasedOutlineGenerated(TestDriver driver) async {
  throw UnimplementedError('Step not yet implemented');
}

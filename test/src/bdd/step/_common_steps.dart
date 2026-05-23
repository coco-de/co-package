// BDD Common Steps — open_epub 1.0
// Status: SCAFFOLD STUB. Implementation deferred to Story-level BDD work.
// Shared steps across all feature files (background + reusable navigations).
//
// Replace `TestDriver` import with the actual driver once
// `bdd_widget_test` (or `co_test_gen`) is added to pubspec.yaml in Develop.

// ignore_for_file: type=lint, unused_import

typedef TestDriver = Object; // placeholder until BDD harness lands

/// Usage: Given kobic 사용자가 로그인되어 있다
Future<void> kobicUserIsLoggedIn(TestDriver driver) async {
  throw UnimplementedError('Step not yet implemented');
}

/// Usage: Given 사용자 라이브러리에 EPUB 책 "<filename>"이 있다
Future<void> userLibraryHasEpubBook(TestDriver driver, String filename) async {
  throw UnimplementedError('Step not yet implemented');
}

/// Usage: Given 사용자가 라이브러리 화면에 있다
Future<void> userIsOnLibraryScreen(TestDriver driver) async {
  throw UnimplementedError('Step not yet implemented');
}

/// Usage: When 사용자가 "<filename>" 항목을 탭한다
Future<void> userTapsBookItem(TestDriver driver, String filename) async {
  throw UnimplementedError('Step not yet implemented');
}

/// Usage: Given Reflowable EPUB "<filename>"이 열려 있다
Future<void> reflowableEpubIsOpen(TestDriver driver, String filename) async {
  throw UnimplementedError('Step not yet implemented');
}

/// Usage: Given Fixed Layout EPUB "<filename>"이 열려 있다
Future<void> fixedLayoutEpubIsOpen(TestDriver driver, String filename) async {
  throw UnimplementedError('Step not yet implemented');
}

/// Usage: Then 진단 이벤트 "<name>"가 기록된다
Future<void> diagnosticEventIsRecorded(TestDriver driver, String name) async {
  throw UnimplementedError('Step not yet implemented');
}

/// Usage: Then 뷰어가 해당 BookPosition으로 이동한다
Future<void> viewerJumpsToBookPosition(TestDriver driver) async {
  throw UnimplementedError('Step not yet implemented');
}

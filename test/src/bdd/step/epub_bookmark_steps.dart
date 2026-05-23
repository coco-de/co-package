// BDD Steps for epub_bookmark.feature
// Status: SCAFFOLD STUB. Implementation deferred to Story S1.10, S1.11, S1.12.

// ignore_for_file: type=lint, unused_import

typedef TestDriver = Object;

/// Usage: Given 사용자가 책의 진도 <progress> 지점에 있다
Future<void> userIsAtProgress(TestDriver driver, double progress) async {
  throw UnimplementedError('Step not yet implemented');
}

/// Usage: When 사용자가 북마크 버튼을 탭한다
Future<void> userTapsBookmarkButton(TestDriver driver) async {
  throw UnimplementedError('Step not yet implemented');
}

/// Usage: Then 현재 BookPosition이 북마크로 저장된다
Future<void> bookPositionStoredAsBookmark(TestDriver driver) async {
  throw UnimplementedError('Step not yet implemented');
}

/// Usage: Then 북마크 아이콘이 "추가됨" 상태로 변한다
Future<void> bookmarkIconBecomesAdded(TestDriver driver) async {
  throw UnimplementedError('Step not yet implemented');
}

/// Usage: Given 사용자가 책에 <n>개의 북마크를 저장했다
Future<void> userHasNBookmarks(TestDriver driver, int n) async {
  throw UnimplementedError('Step not yet implemented');
}

/// Usage: When 사용자가 북마크 패널을 연다
Future<void> userOpensBookmarkPanel(TestDriver driver) async {
  throw UnimplementedError('Step not yet implemented');
}

/// Usage: Then <n>개의 북마크가 시간 역순으로 표시된다
Future<void> nBookmarksShownInReverseChronological(TestDriver driver, int n) async {
  throw UnimplementedError('Step not yet implemented');
}

/// Usage: Then 각 항목에 페이지 번호 또는 진도가 보인다
Future<void> eachItemShowsPageOrProgress(TestDriver driver) async {
  throw UnimplementedError('Step not yet implemented');
}

/// Usage: Given 북마크 패널에 진도 <progress> 북마크가 있다
Future<void> bookmarkPanelHasBookmarkAtProgress(TestDriver driver, double progress) async {
  throw UnimplementedError('Step not yet implemented');
}

/// Usage: When 사용자가 해당 북마크를 탭한다
Future<void> userTapsBookmark(TestDriver driver) async {
  throw UnimplementedError('Step not yet implemented');
}

/// Usage: Given 북마크 패널에 북마크가 표시되어 있다
Future<void> bookmarkPanelShowsBookmarks(TestDriver driver) async {
  throw UnimplementedError('Step not yet implemented');
}

/// Usage: When 사용자가 항목을 좌로 스와이프하여 "Delete"를 탭한다
Future<void> userSwipesLeftAndTapsDelete(TestDriver driver) async {
  throw UnimplementedError('Step not yet implemented');
}

/// Usage: Then 해당 북마크가 목록에서 사라진다
Future<void> bookmarkRemovedFromList(TestDriver driver) async {
  throw UnimplementedError('Step not yet implemented');
}

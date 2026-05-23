// BDD Steps for epub_selection.feature
// Status: SCAFFOLD STUB. Implementation deferred to Story S1.13.

// ignore_for_file: type=lint, unused_import

typedef TestDriver = Object;

/// Usage: Given Reflowable EPUB이 열려 있다
Future<void> reflowableEpubOpen(TestDriver driver) async {
  throw UnimplementedError('Step not yet implemented');
}

/// Usage: When 사용자가 본문 텍스트를 길게 눌러 단어를 선택한다
Future<void> userLongPressesSelectWord(TestDriver driver) async {
  throw UnimplementedError('Step not yet implemented');
}

/// Usage: Then 선택 영역에 컨텍스트 메뉴(Highlight/Copy/Note)가 표시된다
Future<void> contextMenuShown(TestDriver driver) async {
  throw UnimplementedError('Step not yet implemented');
}

/// Usage: Given 사용자가 텍스트 "<text>"를 선택했다
Future<void> userHasSelectedText(TestDriver driver, String text) async {
  throw UnimplementedError('Step not yet implemented');
}

/// Usage: When 사용자가 컨텍스트 메뉴에서 "Highlight" <color>색을 탭한다
Future<void> userTapsHighlightColor(TestDriver driver, String color) async {
  throw UnimplementedError('Step not yet implemented');
}

/// Usage: Then 해당 텍스트에 <color>색 하이라이트가 시각화된다
Future<void> textHighlightedWithColor(TestDriver driver, String color) async {
  throw UnimplementedError('Step not yet implemented');
}

/// Usage: Then BookHighlight가 BookPosition start, end와 color=<color>로 저장된다
Future<void> bookHighlightStoredWithColor(TestDriver driver, String color) async {
  throw UnimplementedError('Step not yet implemented');
}

/// Usage: Given "<text>"에 노란 하이라이트가 적용되어 있다
Future<void> yellowHighlightAppliedTo(TestDriver driver, String text) async {
  throw UnimplementedError('Step not yet implemented');
}

/// Usage: When 사용자가 하이라이트를 탭하여 "Note" 액션을 선택한다
Future<void> userTapsHighlightNote(TestDriver driver) async {
  throw UnimplementedError('Step not yet implemented');
}

/// Usage: And "<note>"라고 입력한다
Future<void> userInputsNote(TestDriver driver, String note) async {
  throw UnimplementedError('Step not yet implemented');
}

/// Usage: Then 메모가 하이라이트와 연결되어 저장된다
Future<void> noteLinkedToHighlight(TestDriver driver) async {
  throw UnimplementedError('Step not yet implemented');
}

/// Usage: Then 하이라이트 목록에서 메모 미리보기가 표시된다
Future<void> highlightListShowsNotePreview(TestDriver driver) async {
  throw UnimplementedError('Step not yet implemented');
}

/// Usage: Given 노란색 하이라이트가 적용되어 있다
Future<void> yellowHighlightExists(TestDriver driver) async {
  throw UnimplementedError('Step not yet implemented');
}

/// Usage: When 사용자가 하이라이트를 탭하여 "Delete"를 선택한다
Future<void> userTapsHighlightDelete(TestDriver driver) async {
  throw UnimplementedError('Step not yet implemented');
}

/// Usage: Then 해당 하이라이트가 시각적으로 제거된다
Future<void> highlightVisuallyRemoved(TestDriver driver) async {
  throw UnimplementedError('Step not yet implemented');
}

/// Usage: Then 데이터 저장소에서도 삭제된다
Future<void> dataStoreAlsoDeletes(TestDriver driver) async {
  throw UnimplementedError('Step not yet implemented');
}

/// Usage: Given Fixed Layout 페이지의 텍스트 레이어가 <n>자 이상 가시 텍스트를 갖는다
Future<void> fixedLayoutTextLayerHasNChars(TestDriver driver, int n) async {
  throw UnimplementedError('Step not yet implemented');
}

/// Usage: When 사용자가 텍스트를 선택한다
Future<void> userSelectsText(TestDriver driver) async {
  throw UnimplementedError('Step not yet implemented');
}

/// Usage: Then 선택이 활성화되고 컨텍스트 메뉴가 표시된다
Future<void> selectionEnabledAndContextMenuShown(TestDriver driver) async {
  throw UnimplementedError('Step not yet implemented');
}

/// Usage: Given Fixed Layout 페이지가 이미지만 있고 텍스트 레이어가 없다
Future<void> fixedLayoutPageImageOnly(TestDriver driver) async {
  throw UnimplementedError('Step not yet implemented');
}

/// Usage: When 사용자가 길게 누른다
Future<void> userLongPresses(TestDriver driver) async {
  throw UnimplementedError('Step not yet implemented');
}

/// Usage: Then 컨텍스트 메뉴는 표시되지 않는다
Future<void> contextMenuNotShown(TestDriver driver) async {
  throw UnimplementedError('Step not yet implemented');
}

/// Usage: Then toast 메시지 "<message>"가 표시된다
Future<void> toastMessageShown(TestDriver driver, String message) async {
  throw UnimplementedError('Step not yet implemented');
}

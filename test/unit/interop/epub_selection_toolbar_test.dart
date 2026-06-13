// Story: S7.4 (E7) — 선택 툴바 액션 → ContextMenuButtonItem 변환

import 'package:flutter_test/flutter_test.dart';
import 'package:open_epub/src/presentation/interop/epub_selection_toolbar.dart';

void main() {
  test('액션 목록을 ContextMenuButtonItem으로 변환하고 onPressed를 보존', () {
    var tapped = '';
    final items = epubSelectionButtonItems([
      EpubSelectionAction(label: '하이라이트', onPressed: () => tapped = 'hl'),
      EpubSelectionAction(label: '사전', onPressed: () => tapped = 'dict'),
    ]);

    expect(items, hasLength(2));
    expect(items[0].label, '하이라이트');
    expect(items[1].label, '사전');

    items[1].onPressed?.call();
    expect(tapped, 'dict');
  });

  test('빈 액션은 빈 목록', () {
    expect(epubSelectionButtonItems(const []), isEmpty);
  });
}

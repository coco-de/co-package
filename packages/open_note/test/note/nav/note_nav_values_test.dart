import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/nav/nav.dart';

void main() {
  group('NoteNavStrings', () {
    const strings = NoteNavStrings();

    test('has English defaults', () {
      expect(strings.pageNumber(3), 'Page 3');
      expect(strings.removeTag('math'), 'Remove tag math');
      expect(strings.countedName('Math', 2), 'Math (2)');
      expect(strings.monthName(1), 'January');
      expect(strings.monthName(12), 'December');
      expect(strings.monthName(0), 'January');
      expect(strings.monthName(40), 'December');
      expect(
        [for (final kind in NoteSearchHitKind.values) strings.kindName(kind)],
        ['Text', 'Excerpt', 'Bookmark', 'Outline', 'Tag', 'Handwriting'],
      );
    });

    test('labels pages by their position', () {
      expect(strings.pageLabel('b', ['a', 'b']), 'Page 2');
      expect(strings.pageLabel('z', ['a', 'b']), 'Unknown page');
    });

    test('can be translated', () {
      const korean = NoteNavStrings(outlineTitle: '목차', pageNumber: _korean);

      expect(korean.outlineTitle, '목차');
      expect(korean.pageLabel('a', ['a']), '1쪽');
    });
  });

  group('NoteNavStyle', () {
    test('copyWith replaces only what is given', () {
      const style = NoteNavStyle();
      final copy = style.copyWith(rowHeight: 52);

      expect(style.copyWith(), style);
      expect(style.copyWith().hashCode, style.hashCode);
      expect(copy.rowHeight, 52);
      expect(copy.accentColor, style.accentColor);
      expect(copy, isNot(style));
      expect(
        style.copyWith(accentColor: const Color(0xFF000000)),
        isNot(style),
      );
    });
  });
}

String _korean(int number) => '$number쪽';

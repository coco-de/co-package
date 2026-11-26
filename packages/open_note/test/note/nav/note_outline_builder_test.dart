import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/nav/nav.dart';

import 'nav_test_support.dart';

void main() {
  final months = [for (var month = 1; month <= 12; month++) 'm$month'];

  test('builds a year with its twelve months', () {
    final outline = NoteOutlineBuilder.calendar(
      year: 2027,
      monthPageIds: months,
      idFactory: countingIds('c'),
    );

    final year = outline.entries.single;
    expect(year.title, '2027');
    expect(year.id, 'c1');
    expect(year.pageId, 'm1');
    expect(year.children.length, 12);
    expect(year.children.first.title, 'January');
    expect(year.children.last.title, 'December');
    expect(year.children[2].pageId, 'm3');
    expect(
      [for (final entry in outline.breadcrumb('m5')) entry.title],
      ['2027', 'May'],
    );
    expect({for (final row in outline.flatten()) row.entry.id}.length, 13);
  });

  test('uses titleOf and yearTitle, skipping months without a page', () {
    final outline = NoteOutlineBuilder.calendar(
      year: 2027,
      monthPageIds: ['', 'feb', '', 'apr'],
      titleOf: (month) => '$month월',
      yearTitle: '2027년',
      idFactory: countingIds('c'),
    );

    final year = outline.entries.single;
    expect(year.title, '2027년');
    expect(year.pageId, 'feb');
    expect([for (final month in year.children) month.title], ['2월', '4월']);
  });

  test('ignores extra pages and is empty without any month page', () {
    final long = NoteOutlineBuilder.calendar(
      year: 2027,
      monthPageIds: [...months, 'extra'],
      idFactory: countingIds('c'),
    );

    expect(long.entries.single.children.length, 12);
    expect(
      NoteOutlineBuilder.calendar(year: 2027, monthPageIds: []).isEmpty,
      isTrue,
    );
    expect(
      NoteOutlineBuilder.calendar(year: 2027, monthPageIds: ['', '']).isEmpty,
      isTrue,
    );
  });

  test('the new outline keeps using the id factory', () {
    final outline = NoteOutlineBuilder.calendar(
      year: 2027,
      monthPageIds: ['m1'],
      idFactory: countingIds('c'),
    );

    expect(outline.add('Notes', 'n')!.id, 'c3');
  });
}

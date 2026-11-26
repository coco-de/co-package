import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/view/view.dart';

import 'note_view_test_support.dart';

void main() {
  NoteTabsController abc({String activeId = 'a'}) => NoteTabsController(
    tabs: const [
      NoteTab(noteId: 'a', title: 'A'),
      NoteTab(noteId: 'b', title: 'B'),
      NoteTab(noteId: 'c', title: 'C'),
    ],
    activeId: activeId,
  );

  List<String> ids(NoteTabsController tabs) => [
    for (final tab in tabs.tabs) tab.noteId,
  ];

  test('starts empty', () {
    final tabs = NoteTabsController();

    expect(tabs.tabs, isEmpty);
    expect(tabs.activeId, isNull);
    expect(tabs.active, isNull);
  });

  test('skips duplicate and empty ids and picks an active tab', () {
    final tabs = NoteTabsController(
      tabs: const [
        NoteTab(noteId: ''),
        NoteTab(noteId: 'a', title: '1'),
        NoteTab(noteId: 'a', title: '2'),
        NoteTab(noteId: 'b'),
      ],
      activeId: 'missing',
    );

    expect(ids(tabs), ['a', 'b']);
    expect(tabs.activeId, 'a');
    expect(tabs.active!.title, '1');
  });

  group('open', () {
    test('appends a new tab and focuses it', () {
      final tabs = abc();

      tabs.open('d', 'D');

      expect(ids(tabs), ['a', 'b', 'c', 'd']);
      expect(tabs.activeId, 'd');
    });

    test('focuses an open note and updates its title', () {
      final tabs = abc();

      tabs.open('b', 'Renamed');

      expect(ids(tabs), ['a', 'b', 'c']);
      expect(tabs.activeId, 'b');
      expect(tabs.active!.title, 'Renamed');
    });

    test('notifies only on real changes and ignores empty ids', () {
      final tabs = abc();
      final counter = NotifyCounter(tabs);

      tabs.open('a', 'A');
      tabs.open('', 'nothing');

      expect(counter.count, 0);
    });
  });

  group('close', () {
    test('focuses the right neighbour of the closed active tab', () {
      final tabs = abc(activeId: 'b');

      expect(tabs.close('b'), isTrue);

      expect(ids(tabs), ['a', 'c']);
      expect(tabs.activeId, 'c');
    });

    test('focuses the left neighbour at the end', () {
      final tabs = abc(activeId: 'c');

      tabs.close('c');

      expect(tabs.activeId, 'b');
    });

    test('keeps the focus when another tab closes', () {
      final tabs = abc(activeId: 'a');

      tabs.close('b');

      expect(tabs.activeId, 'a');
    });

    test('leaves nothing active after the last tab', () {
      final tabs = NoteTabsController(tabs: const [NoteTab(noteId: 'a')]);

      tabs.close('a');

      expect(tabs.activeId, isNull);
      expect(tabs.close('a'), isFalse);
    });
  });

  test('closeOthers keeps and focuses one tab', () {
    final tabs = abc();
    final counter = NotifyCounter(tabs);

    tabs.closeOthers('c');
    tabs.closeOthers('c');
    tabs.closeOthers('missing');

    expect(ids(tabs), ['c']);
    expect(tabs.activeId, 'c');
    expect(counter.count, 1);
  });

  test('closeAll empties the strip once', () {
    final tabs = abc();
    final counter = NotifyCounter(tabs);

    tabs.closeAll();
    tabs.closeAll();

    expect(tabs.tabs, isEmpty);
    expect(counter.count, 1);
  });

  test('activate and rename ignore unknown ids', () {
    final tabs = abc();
    final counter = NotifyCounter(tabs);

    tabs.activate('c');
    tabs.activate('c');
    tabs.activate('zzz');
    tabs.rename('b', 'Bee');
    tabs.rename('b', 'Bee');
    tabs.rename('zzz', 'x');

    expect(tabs.activeId, 'c');
    expect(tabs.tabs[1].title, 'Bee');
    expect(counter.count, 2);
  });

  group('move', () {
    test('puts the tab at the requested position', () {
      final tabs = abc();

      tabs.move(0, 2);
      expect(ids(tabs), ['b', 'c', 'a']);

      tabs.move(2, 0);
      expect(ids(tabs), ['a', 'b', 'c']);
    });

    test('clamps the destination and ignores a bad source', () {
      final tabs = abc();
      final counter = NotifyCounter(tabs);

      tabs.move(0, 99);
      expect(ids(tabs), ['b', 'c', 'a']);
      tabs.move(-1, 0);
      tabs.move(9, 0);
      tabs.move(1, 1);
      expect(counter.count, 1);
    });

    test('keeps the active tab', () {
      final tabs = abc(activeId: 'a');

      tabs.move(0, 2);

      expect(tabs.activeId, 'a');
    });
  });

  group('json', () {
    test('round-trips', () {
      final tabs = abc(activeId: 'b');

      final restored = NoteTabsController.fromJson(tabs.toJson());

      expect(restored.tabs, tabs.tabs);
      expect(restored.activeId, 'b');
      expect(tabs.toJson()['active'], 'b');
      expect(NoteTabsController().toJson(), {'tabs': <Object?>[]});
    });

    test('survives junk', () {
      for (final junk in <Object?>[null, 'x', 1, <Object?>[]]) {
        expect(NoteTabsController.fromJson(junk).tabs, isEmpty);
      }
      final restored = NoteTabsController.fromJson({
        'tabs': [
          'bad',
          {'title': 'no id'},
          {'noteId': 'a', 'title': 5},
          {'noteId': 'a'},
          {'noteId': 'b', 'title': 'B'},
        ],
        'active': 'zzz',
      });

      expect(restored.tabs, const [
        NoteTab(noteId: 'a'),
        NoteTab(noteId: 'b', title: 'B'),
      ]);
      expect(restored.activeId, 'a');
    });
  });

  test('NoteTab compares by value', () {
    const tab = NoteTab(noteId: 'a', title: 'A');

    expect(tab.copyWith(), tab);
    expect(tab.copyWith().hashCode, tab.hashCode);
    expect(tab.copyWith(title: 'B'), isNot(tab));
    expect(NoteTab.fromJson(tab.toJson()), tab);
    expect(NoteTab.fromJson('tab'), isNull);
  });

  test('does nothing after dispose', () {
    final tabs = abc()..dispose();

    tabs.open('d', 'D');
    tabs.activate('b');
    tabs.rename('a', 'z');
    tabs.move(0, 1);
    tabs.closeOthers('b');
    tabs.closeAll();

    expect(tabs.close('a'), isFalse);
    expect(ids(tabs), ['a', 'b', 'c']);
    expect(tabs.activeId, 'a');
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/nav/nav.dart';

import 'nav_test_support.dart';

void main() {
  NoteBookmarks build() =>
      NoteBookmarks(idFactory: countingIds('b'), clock: frozenClock);

  group('NoteBookmark', () {
    final bookmark = NoteBookmark(
      id: 'b1',
      pageId: 'p1',
      title: '미분',
      createdAt: kNow,
    );

    test('round-trips through JSON', () {
      final decoded = NoteBookmark.fromJson(
        NoteJson.decodeMap(NoteJson.encode(bookmark.toJson())),
      );

      expect(decoded, bookmark);
      expect(decoded.hashCode, bookmark.hashCode);
    });

    test('keeps createdAt in UTC', () {
      final local = NoteBookmark(
        id: 'b',
        pageId: 'p',
        createdAt: DateTime(2026, 1, 2, 3, 4),
      );

      expect(local.createdAt.isUtc, isTrue);
    });

    test('rejects unusable JSON and repairs bad fields', () {
      expect(NoteBookmark.fromJson(null), isNull);
      expect(NoteBookmark.fromJson('nope'), isNull);
      expect(NoteBookmark.fromJson({'id': 'x'}), isNull);
      expect(NoteBookmark.fromJson({'id': '', 'pageId': 'p'}), isNull);
      final repaired = NoteBookmark.fromJson({
        'id': 'x',
        'pageId': 'p',
        'title': 42,
        'createdAt': 'yesterday',
      })!;

      expect(repaired.title, isEmpty);
      expect(repaired.createdAt, DateTime.utc(1970));
    });

    test('copyWith replaces only the given fields', () {
      final copy = bookmark.copyWith(title: '적분');

      expect(copy.title, '적분');
      expect(copy.id, 'b1');
      expect(copy, isNot(bookmark));
    });
  });

  group('NoteBookmarks', () {
    test('toggle adds then removes the bookmark of a page', () {
      final bookmarks = build();
      final counter = NotifyCounter(bookmarks);

      final added = bookmarks.toggle('p1', title: '  Intro  ');

      expect(added!.id, 'b1');
      expect(added.title, 'Intro');
      expect(added.createdAt, kNow);
      expect(bookmarks.isBookmarked('p1'), isTrue);
      expect(bookmarks.bookmarkFor('p1'), added);
      expect(bookmarks.byId('b1'), added);

      expect(bookmarks.toggle('p1'), isNull);
      expect(bookmarks.isEmpty, isTrue);
      expect(counter.count, 2);
    });

    test('toggle ignores an empty page id', () {
      final bookmarks = build();

      expect(bookmarks.toggle(''), isNull);
      expect(bookmarks.length, 0);
    });

    test('rename and remove notify only on real changes', () {
      final bookmarks = build()..toggle('p1');
      final counter = NotifyCounter(bookmarks);

      expect(bookmarks.rename('b1', ' Chapter '), isTrue);
      expect(bookmarks.rename('b1', 'Chapter'), isFalse);
      expect(bookmarks.rename('missing', 'x'), isFalse);
      expect(bookmarks.byId('b1')!.title, 'Chapter');
      expect(bookmarks.remove('missing'), isFalse);
      expect(bookmarks.removePage('other'), isFalse);
      expect(bookmarks.removePage('p1'), isTrue);
      expect(bookmarks.items, isEmpty);
      expect(counter.count, 2);
    });

    test('ordered follows the page order and puts unknown pages last', () {
      final bookmarks = build();
      for (final page in ['gone-a', 'p3', 'p1', 'gone-b', 'p2']) {
        bookmarks.toggle(page);
      }

      expect(
        [
          for (final bookmark in bookmarks.ordered(['p1', 'p2', 'p3']))
            bookmark.pageId,
        ],
        ['p1', 'p2', 'p3', 'gone-a', 'gone-b'],
      );
      expect(bookmarks.items.first.pageId, 'gone-a');
    });

    test('items is unmodifiable', () {
      final bookmarks = build()..toggle('p1');

      expect(bookmarks.items.clear, throwsUnsupportedError);
    });

    test('the constructor drops duplicates and unusable entries', () {
      NoteBookmark mark(String id, String page) =>
          NoteBookmark(id: id, pageId: page, createdAt: kNow);
      final bookmarks = NoteBookmarks(
        bookmarks: [
          mark('a', 'p1'),
          mark('a', 'p2'),
          mark('b', 'p1'),
          mark('', 'p3'),
          mark('c', ''),
          mark('d', 'p4'),
        ],
      );

      expect([for (final b in bookmarks.items) b.id], ['a', 'd']);
    });

    test('round-trips through JSON', () {
      final bookmarks = build()
        ..toggle('p2', title: 'Second')
        ..toggle('p1');
      final restored = NoteBookmarks.fromJson(
        NoteJson.decodeMap(NoteJson.encode(bookmarks.toJson())),
      );

      expect(restored.items, bookmarks.items);
      expect(bookmarks.toJson()['v'], 1);
    });

    test('fromJson survives malformed documents', () {
      expect(NoteBookmarks.fromJson(null).isEmpty, isTrue);
      expect(NoteBookmarks.fromJson([1, 2]).isEmpty, isTrue);
      expect(NoteBookmarks.fromJson({'bookmarks': 'x'}).isEmpty, isTrue);
      final restored = NoteBookmarks.fromJson({
        'bookmarks': [
          1,
          {'id': 'ok', 'pageId': 'p'},
          {'id': 'no-page'},
          null,
        ],
      });

      expect([for (final b in restored.items) b.id], ['ok']);
    });

    test('mutators do nothing after dispose', () {
      final bookmarks = build()..toggle('p1');
      bookmarks
        ..dispose()
        ..dispose();

      expect(bookmarks.isDisposed, isTrue);
      expect(bookmarks.toggle('p2'), isNull);
      expect(bookmarks.toggle('p1'), isNull);
      expect(bookmarks.rename('b1', 'x'), isFalse);
      expect(bookmarks.remove('b1'), isFalse);
      expect(bookmarks.removePage('p1'), isFalse);
      expect(bookmarks.length, 1);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/library/internal/note_library_dates.dart';
import 'package:open_note/src/note/library/library.dart';

import 'library_test_support.dart';

void main() {
  group('NoteSummary JSON', () {
    test('round-trips every field', () {
      final note = NoteSummary(
        id: 'n1',
        title: '대수학 1',
        cover: const NoteCover.builtIn('forest', size: NotePageSize.letter),
        tags: const ['math', 'school'],
        pinned: true,
        folderId: 'f1',
        createdAt: day(2),
        modifiedAt: day(3),
        pageCount: 12,
      );
      final text = NoteJson.encode(note.toJson());

      expect(NoteSummary.fromJson(NoteJson.decodeMap(text)), note);
    });

    test('omits the folder of a note outside every folder', () {
      expect(summary('a').toJson().containsKey('folderId'), isFalse);
    });

    test('is null without an object that has an id', () {
      for (final value in [null, 7, 'note', <Object?>[]]) {
        expect(NoteSummary.fromJson(value), isNull);
      }
      expect(NoteSummary.fromJson(<String, Object?>{}), isNull);
      expect(NoteSummary.fromJson({'id': ''}), isNull);
      expect(NoteSummary.fromJson({'id': 3}), isNull);
    });

    test('fills missing fields with defaults', () {
      final note = NoteSummary.fromJson({'id': 'a'})!;

      expect(note.title, '');
      expect(note.cover, NoteCover.standard);
      expect(note.tags, isEmpty);
      expect(note.pinned, isFalse);
      expect(note.folderId, isNull);
      expect(note.pageCount, 1);
      expect(note.createdAt, NoteLibraryDates.epoch);
      expect(note.modifiedAt, NoteLibraryDates.epoch);
    });

    test('uses the creation time for a missing modification time', () {
      final note = NoteSummary.fromJson({
        'id': 'a',
        'createdAt': '2026-01-05T00:00:00.000Z',
        'modifiedAt': 'yesterday',
      })!;

      expect(note.modifiedAt, day(5));
    });

    test('survives wrong types and out-of-range values', () {
      final note = NoteSummary.fromJson({
        'id': 'a',
        'title': 9,
        'cover': 'blue',
        'tags': 'math',
        'pinned': 'yes',
        'folderId': '',
        'createdAt': true,
        'modifiedAt': 1e300,
        'pageCount': -4,
      })!;

      expect(note.title, '');
      expect(note.cover, NoteCover.standard);
      expect(note.tags, isEmpty);
      expect(note.pinned, isFalse);
      expect(note.folderId, isNull);
      expect(note.createdAt, NoteLibraryDates.epoch);
      expect(note.modifiedAt, NoteLibraryDates.epoch);
      expect(note.pageCount, 0);
    });

    test('normalises tags and drops entries that are not strings', () {
      final note = NoteSummary.fromJson({
        'id': 'a',
        'tags': ['  Math ', 'math', 3, '', 'two   words'],
      })!;

      expect(note.tags, ['Math', 'two words']);
    });
  });

  group('NoteLibraryDates', () {
    test('writes UTC and reads ISO strings or milliseconds', () {
      final moment = DateTime.utc(2026, 3, 4, 5, 6, 7, 8, 9);
      final text = NoteLibraryDates.toJson(moment.toLocal());

      expect(text, endsWith('Z'));
      expect(NoteLibraryDates.tryFromJson(text), moment);
      expect(
        NoteLibraryDates.tryFromJson(moment.millisecondsSinceEpoch),
        DateTime.utc(2026, 3, 4, 5, 6, 7, 8),
      );
      expect(NoteLibraryDates.tryFromJson('not a date'), isNull);
      expect(NoteLibraryDates.tryFromJson(null), isNull);
      expect(NoteLibraryDates.tryFromJson(double.nan), isNull);
      expect(NoteLibraryDates.tryFromJson(-1e300), isNull);
    });
  });

  group('NoteSummary tags', () {
    test('trim and collapse white space', () {
      expect(NoteSummary.normalizeTag('  a \t b\n c  '), 'a b c');
      expect(NoteSummary.normalizeTag('   '), '');
    });

    test('are cut to forty code points without splitting characters', () {
      final long = 'a' * 50;
      final emoji = '😀' * 50;

      expect(NoteSummary.normalizeTag(long), 'a' * 40);
      expect(NoteSummary.normalizeTag(emoji), '😀' * 40);
      expect(NoteSummary.normalizeTag('${'b' * 39}  cd'), 'b' * 39);
    });

    test('de-duplicate ignoring case and keep the first spelling', () {
      expect(
        NoteSummary.normalizeTags(['Work', 'work', ' WORK ', '개인', '개인']),
        ['Work', '개인'],
      );
    });
  });

  group('NoteSummary values', () {
    test('compare by every field', () {
      final note = summary('a', tags: ['x'], folderId: 'f');

      expect(note, note.copyWith());
      expect(note.hashCode, note.copyWith().hashCode);
      for (final other in [
        note.copyWith(id: 'b'),
        note.copyWith(title: 'other'),
        note.copyWith(cover: const NoteCover.builtIn('plum')),
        note.copyWith(tags: ['y']),
        note.copyWith(pinned: true),
        note.copyWith(folderId: () => null),
        note.copyWith(createdAt: day(9)),
        note.copyWith(modifiedAt: day(9)),
        note.copyWith(pageCount: 3),
      ]) {
        expect(other, isNot(note));
      }
    });

    test('treat the same instant as equal whatever its time zone', () {
      final utc = summary('a', createdAt: day(4));
      final local = utc.copyWith(
        createdAt: day(4).toLocal(),
        modifiedAt: day(4).toLocal(),
      );

      expect(local, utc);
      expect(local.hashCode, utc.hashCode);
    });

    test('copyWith can leave the folder', () {
      final note = summary('a', folderId: 'f');

      expect(note.copyWith(folderId: () => null).folderId, isNull);
      expect(note.copyWith(folderId: () => 'g').folderId, 'g');
      expect(note.copyWith().folderId, 'f');
    });

    test('copyWith makes its own unmodifiable tag list', () {
      final source = ['a'];
      final note = summary('n').copyWith(tags: source);
      source.add('b');

      expect(note.tags, ['a']);
      expect(() => note.tags.add('c'), throwsUnsupportedError);
    });
  });
}

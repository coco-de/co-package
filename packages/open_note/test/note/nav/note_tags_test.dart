import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/nav/nav.dart';

import 'nav_test_support.dart';

const NoteTagRef _note = NoteTagRef(noteId: 'n1');
const NoteTagRef _page = NoteTagRef(noteId: 'n1', pageId: 'p1');
const NoteTagRef _other = NoteTagRef(noteId: 'n2', pageId: 'p9');

void main() {
  group('NoteTagRef', () {
    test('treats a blank page id as the note itself', () {
      expect(const NoteTagRef(noteId: 'n1', pageId: ''), _note);
      expect(_note.isNote, isTrue);
      expect(_page.isNote, isFalse);
      expect(_note, isNot(_page));
      expect(_note.hashCode, const NoteTagRef(noteId: 'n1').hashCode);
    });

    test('copyWith replaces fields and can drop the page', () {
      expect(_page.copyWith(), _page);
      expect(_page.copyWith(noteId: 'n2').noteId, 'n2');
      expect(_note.copyWith(pageId: 'p1'), _page);
      expect(_page.copyWith(clearPageId: true), _note);
    });

    test('round-trips through JSON', () {
      for (final ref in [_note, _page]) {
        expect(NoteTagRef.fromJson(ref.toJson()), ref);
      }
      expect(_note.toJson(), {'noteId': 'n1'});
      expect(NoteTagRef.fromJson({'pageId': 'p'}), isNull);
      expect(NoteTagRef.fromJson('x'), isNull);
      expect(NoteTagRef.fromJson({'noteId': 'n1', 'pageId': 4}), _note);
    });
  });

  group('NoteTags.normalize', () {
    test('trims and collapses whitespace, ideographic spaces included', () {
      expect(NoteTags.normalize('  미분   적분\n노트 '), '미분 적분 노트');
      expect(NoteTags.normalize('ab'), 'ab');
      expect(NoteTags.normalize('a　b c'), 'a b c');
      expect(NoteTags.normalize(' \t '), isNull);
      expect(NoteTags.normalize(''), isNull);
    });

    test('cuts at 40 user-perceived characters', () {
      expect(NoteTags.normalize('a' * 40), 'a' * 40);
      expect(NoteTags.normalize('a' * 55), 'a' * 40);
      expect(NoteTags.normalize('한' * 55), '한' * 40);
      expect(NoteTags.normalize('👨‍👩‍👧' * 41), '👨‍👩‍👧' * 40);
      expect(NoteTags.normalize('${'a' * 39} b'), 'a' * 39);
    });
  });

  group('NoteTags', () {
    test('add keeps the first spelling and compares case-insensitively', () {
      final tags = NoteTags();
      final counter = NotifyCounter(tags);

      expect(tags.add('  Math ', _note), isTrue);
      expect(tags.add('MATH', _note), isFalse);
      expect(tags.add('math', _page), isTrue);
      expect(tags.add('   ', _page), isFalse);
      expect(tags.add('x', const NoteTagRef(noteId: '')), isFalse);

      expect(tags.allTags, {'Math': 2});
      expect(tags.contains('mAtH'), isTrue);
      expect(tags.refsOf('MATH'), [_note, _page]);
      expect(counter.count, 2);
    });

    test('tagsOf is sorted and separate for notes and pages', () {
      final tags = NoteTags()
        ..add('zeta', _note)
        ..add('Alpha', _note)
        ..add('beta', _page);

      expect(tags.tagsOf(_note), ['Alpha', 'zeta']);
      expect(tags.tagsOf(_page), ['beta']);
      expect(tags.tagsOf(_other), isEmpty);
      expect(tags.allTags.keys.toList(), ['Alpha', 'beta', 'zeta']);
    });

    test('a tag left on nothing disappears', () {
      final tags = NoteTags()..add('Math', _note);

      expect(tags.remove('math', _page), isFalse);
      expect(tags.remove('nothing', _note), isFalse);
      expect(tags.remove(' MATH ', _note), isTrue);
      expect(tags.isEmpty, isTrue);
      tags.add('MATH', _note);
      expect(tags.allTags.keys, ['MATH']);
    });

    test('rename merges into the existing tag and keeps its spelling', () {
      final tags = NoteTags()
        ..add('maths', _note)
        ..add('maths', _page)
        ..add('Math', _page)
        ..add('Math', _other);
      final counter = NotifyCounter(tags);

      expect(tags.rename('maths', 'math'), isTrue);

      expect(tags.allTags, {'Math': 3});
      expect(tags.refsOf('math'), [_page, _other, _note]);
      expect(counter.count, 1);
    });

    test('rename to a new name or a new spelling', () {
      final tags = NoteTags()..add('draft', _note);
      final counter = NotifyCounter(tags);

      expect(tags.rename('draft', 'Draft'), isTrue);
      expect(tags.allTags.keys, ['Draft']);
      expect(tags.rename('DRAFT', 'Draft'), isFalse);
      expect(tags.rename('draft', 'done'), isTrue);
      expect(tags.allTags, {'done': 1});
      expect(tags.rename('missing', 'x'), isFalse);
      expect(tags.rename('done', '   '), isFalse);
      expect(counter.count, 2);
    });

    test('delete, removeNote and removePage', () {
      final tags = NoteTags()
        ..add('a', _note)
        ..add('a', _other)
        ..add('b', _page)
        ..add('c', _other);
      final counter = NotifyCounter(tags);

      expect(tags.delete('zzz'), isFalse);
      expect(tags.removePage('n1', 'p9'), isFalse);
      expect(tags.removePage('n1', 'p1'), isTrue);
      expect(tags.allTags, {'a': 2, 'c': 1});
      expect(tags.removeNote('n2'), isTrue);
      expect(tags.allTags, {'a': 1});
      expect(tags.delete('A'), isTrue);
      expect(tags.isEmpty, isTrue);
      expect(counter.count, 3);
    });

    test('exposes unmodifiable collections', () {
      final tags = NoteTags()..add('a', _note);

      expect(() => tags.allTags['b'] = 1, throwsUnsupportedError);
      expect(() => tags.refsOf('a').clear(), throwsUnsupportedError);
      expect(tags.refsOf('nope'), isEmpty);
    });

    test('round-trips through JSON', () {
      final tags = NoteTags()
        ..add('수학', _note)
        ..add('Physics', _page)
        ..add('Physics', _other);
      final restored = NoteTags.fromJson(
        NoteJson.decodeMap(NoteJson.encode(tags.toJson())),
      );

      expect(restored.allTags, tags.allTags);
      expect(restored.refsOf('physics'), [_page, _other]);
      expect(tags.toJson()['v'], 1);
    });

    test('fromJson skips bad entries and merges repeated names', () {
      expect(NoteTags.fromJson(null).isEmpty, isTrue);
      expect(NoteTags.fromJson({'tags': 'x'}).isEmpty, isTrue);
      final tags = NoteTags.fromJson({
        'tags': [
          7,
          {
            'name': '',
            'refs': [_note.toJson()],
          },
          {'name': 'empty', 'refs': <Object?>[]},
          {
            'name': 'Math',
            'refs': [_note.toJson(), 'junk', <String, Object?>{}],
          },
          {
            'name': 'MATH',
            'refs': [_page.toJson(), _note.toJson()],
          },
        ],
      });

      expect(tags.allTags, {'Math': 2});
    });

    test('mutators do nothing after dispose', () {
      final tags = NoteTags()..add('a', _note);
      tags.dispose();

      expect(tags.add('b', _note), isFalse);
      expect(tags.remove('a', _note), isFalse);
      expect(tags.rename('a', 'b'), isFalse);
      expect(tags.delete('a'), isFalse);
      expect(tags.removeNote('n1'), isFalse);
      expect(tags.allTags, {'a': 1});
    });
  });
}

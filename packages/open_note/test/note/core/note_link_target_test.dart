import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/core/note_link_target.dart';

void main() {
  group('NoteLinkTarget.parse', () {
    test('page links share the engine grammar (page:N, 1-based)', () {
      expect(NoteLinkTarget.parse('page:3'), const NotePageLink(3));
      expect(NoteLinkTarget.parse(' page:12 '), const NotePageLink(12));
      expect(NotePageLink(3).format(), 'page:3');
    });

    test('page:0 and malformed page links are not page links', () {
      expect(NoteLinkTarget.parse('page:0'), isA<NoteUrlLink>());
      expect(NoteLinkTarget.parse('page:x'), isA<NoteUrlLink>());
    });

    test('a page can be linked by its stable id', () {
      expect(NoteLinkTarget.parse(' pageid:p-1 '), const NotePageIdLink('p-1'));
      expect(const NotePageIdLink('p-1').format(), 'pageid:p-1');
      expect(NoteLinkTarget.parse('pageid:'), isNull);
    });

    test('note links with and without a page', () {
      expect(NoteLinkTarget.parse('note:abc'), const NoteNoteLink('abc'));
      expect(
        NoteLinkTarget.parse('note:abc#page:4'),
        const NoteNoteLink('abc', page: 4),
      );
      expect(const NoteNoteLink('abc', page: 4).format(), 'note:abc#page:4');
      expect(const NoteNoteLink('abc').format(), 'note:abc');
      expect(NoteLinkTarget.parse('note:'), isNull);
    });

    test('external links keep their scheme or default to https', () {
      expect(
        NoteLinkTarget.parse('https://example.com/a'),
        const NoteUrlLink('https://example.com/a'),
      );
      expect(
        NoteLinkTarget.parse('example.com'),
        const NoteUrlLink('https://example.com'),
      );
      expect(
        NoteLinkTarget.parse('mailto:a@b.c'),
        const NoteUrlLink('mailto:a@b.c'),
      );
    });

    test('blank input yields null', () {
      expect(NoteLinkTarget.parse(null), isNull);
      expect(NoteLinkTarget.parse('   '), isNull);
    });

    test('format then parse is the identity for every kind', () {
      for (final target in <NoteLinkTarget>[
        const NotePageLink(7),
        const NotePageIdLink('p-7'),
        const NoteNoteLink('n1'),
        const NoteNoteLink('n1', page: 2),
        const NoteUrlLink('https://x.y/z'),
      ]) {
        expect(NoteLinkTarget.parse(target.format()), target);
      }
    });
  });
}

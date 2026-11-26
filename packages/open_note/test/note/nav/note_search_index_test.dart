import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/nav/nav.dart';

import 'nav_test_support.dart';

List<String> _snippets(Iterable<NoteSearchHit> hits) => [
  for (final hit in hits) hit.snippet,
];

void main() {
  group('NoteSearchIndex matching', () {
    test('finds Hangul substrings without word boundaries', () {
      final index = NoteSearchIndex()..indexPage('n1', 'p1', ['미분 적분 노트']);

      for (final query in ['적분', '분 적', '분 노', '노트', '미', '미분 적분 노트']) {
        final hit = index.search(query).single;
        expect(hit.matchedText, query, reason: query);
        expect(hit.pageId, 'p1');
        expect(hit.kind, NoteSearchHitKind.text);
      }
      expect(index.search('미적분'), isEmpty);
    });

    test('finds CJK substrings and treats any whitespace as one space', () {
      final index = NoteSearchIndex()..indexPage('n', 'p', ['微積分のノート\n高等　数学']);

      expect(index.search('積分の').single.matchedText, '積分の');
      expect(index.search('ノート 高等').single.matchedText, 'ノート 高等');
      expect(index.search('高等   数学').single.matchedText, '高等 数学');
    });

    test('ignores case and keeps offsets in the original spelling', () {
      final index = NoteSearchIndex()
        ..indexPage('n', 'p', ['İstanbul Linear ALGEBRA']);

      final hit = index.search('algebra').single;
      expect(hit.matchedText, 'ALGEBRA');
      expect(hit.snippet, 'İstanbul Linear ALGEBRA');
      expect(index.search('LINEAR a').single.matchedText, 'Linear A');
    });

    test('ranks exact, then prefix, then substring, then shorter', () {
      final index = NoteSearchIndex()
        ..indexPage('n', 'p1', ['about the cat and more'])
        ..indexPage('n', 'p2', ['concatenate'])
        ..indexPage('n', 'p3', ['catalogue of things'])
        ..indexPage('n', 'p4', ['CAT'])
        ..indexPage('n', 'p5', ['cats']);

      expect(_snippets(index.search('cat')), [
        'CAT',
        'cats',
        'catalogue of things',
        'concatenate',
        'about the cat and more',
      ]);
    });

    test('equal rank and length keep the indexing order', () {
      final index = NoteSearchIndex()
        ..indexPage('n', 'p2', ['ab one'])
        ..indexPage('n', 'p1', ['ab two']);

      expect([for (final hit in index.search('ab')) hit.pageId], ['p2', 'p1']);
    });

    test('reports one hit per indexed text, at the first match', () {
      final index = NoteSearchIndex()..indexPage('n', 'p', ['na na na', 'na']);

      final hits = index.search('na');
      expect(hits.length, 2);
      expect(hits.last.matchStart, 0);
    });

    test('blank queries and non-positive limits give nothing', () {
      final index = NoteSearchIndex()..indexPage('n', 'p', ['abc']);

      expect(index.search(''), isEmpty);
      expect(index.search('  \n '), isEmpty);
      expect(index.search('a', limit: 0), isEmpty);
      expect(index.search('a', limit: -1), isEmpty);
    });

    test('limit keeps the best results', () {
      final index = NoteSearchIndex();
      for (var page = 0; page < 10; page++) {
        index.indexPage('n', 'p$page', ['item ${'x' * (10 - page)}']);
      }

      final hits = index.search('item', limit: 3);
      expect([for (final hit in hits) hit.pageId], ['p9', 'p8', 'p7']);
      expect(index.search('item').length, 10);
    });

    test('filters by kind and note', () {
      final index = NoteSearchIndex()
        ..indexPage('n1', 'p', ['algebra text'])
        ..indexPage('n1', 'p', [
          'algebra mark',
        ], kind: NoteSearchHitKind.bookmark)
        ..indexPage('n2', '', ['algebra tag'], kind: NoteSearchHitKind.tag);

      expect(index.search('algebra').length, 3);
      expect(
        _snippets(index.search('algebra', kinds: {NoteSearchHitKind.bookmark})),
        ['algebra mark'],
      );
      expect(index.search('algebra', kinds: {}), isEmpty);
      final tag = index.search('algebra', noteId: 'n2').single;
      expect(tag.pageId, isEmpty);
      expect(tag.kind, NoteSearchHitKind.tag);
    });
  });

  group('NoteSearchIndex snippets', () {
    test('are windows of long texts with correct offsets', () {
      final text = '${'가' * 100}찾는말${'나' * 100}';
      final index = NoteSearchIndex()..indexPage('n', 'p', [text]);

      final hit = index.search('찾는말').single;

      expect(hit.snippet, startsWith('…가'));
      expect(hit.snippet, endsWith('나…'));
      expect(hit.matchedText, '찾는말');
      expect(
        hit.snippet.length,
        NoteSearchIndex.snippetLead + 3 + NoteSearchIndex.snippetTail + 2,
      );
      expect(hit.matchStart, NoteSearchIndex.snippetLead + 1);
    });

    test('have no ellipsis at the ends of the text', () {
      final index = NoteSearchIndex()..indexPage('n', 'p', ['start middle']);

      expect(index.search('start').single.snippet, 'start middle');
      expect(index.search('middle').single.matchStart, 6);
    });

    test('never split a surrogate pair', () {
      // Both window edges would fall between the two halves of an emoji.
      final text = '${'😀' * 30}xkeyy${'😀' * 40}';
      final index = NoteSearchIndex()..indexPage('n', 'p', [text]);

      final hit = index.search('key').single;

      expect(hit.matchedText, 'key');
      final body = hit.snippet.substring(1, hit.snippet.length - 1);
      expect(body.runes.every((rune) => rune == 0x1F600 || rune < 128), isTrue);
    });
  });

  group('NoteSearchIndex updates', () {
    test('re-indexing replaces one kind of one page', () {
      final index = NoteSearchIndex()
        ..indexPage('n', 'p', ['old text'])
        ..indexPage('n', 'p', ['old title'], kind: NoteSearchHitKind.outline);

      index.indexPage('n', 'p', ['new text']);

      expect(_snippets(index.search('old')), ['old title']);
      expect(_snippets(index.search('new')), ['new text']);
      index.indexPage('n', 'p', [], kind: NoteSearchHitKind.outline);
      expect(index.search('old'), isEmpty);
    });

    test('notifies only on real changes', () {
      final index = NoteSearchIndex();
      final counter = NotifyCounter(index);

      index
        ..indexPage('n', 'p', ['a  b'])
        ..indexPage('n', 'p', ['a b', '   '])
        ..indexPage('n', 'q', [])
        ..indexPage('', 'p', ['x'])
        ..removePage('n', 'zzz')
        ..removeNote('zzz');
      expect(counter.count, 1);
      index.removePage('n', 'p');
      expect(counter.count, 2);
      expect(index.isEmpty, isTrue);
      index.clear();
      expect(counter.count, 2);
    });

    test('removePage and removeNote forget their pages', () {
      final index = NoteSearchIndex()
        ..indexPage('n1', 'p1', ['x one'])
        ..indexPage('n1', 'p2', ['x two'])
        ..indexPage('n2', 'p1', ['x three']);

      index.removePage('n1', 'p1');
      expect(_snippets(index.search('x')), ['x two', 'x three']);
      index.removeNote('n1');
      expect(_snippets(index.search('x')), ['x three']);
      index.clear();
      expect(index.isEmpty, isTrue);
    });

    test('mutators do nothing after dispose', () {
      final index = NoteSearchIndex()..indexPage('n', 'p', ['abc']);
      index
        ..dispose()
        ..indexPage('n', 'q', ['abc'])
        ..removePage('n', 'p')
        ..removeNote('n')
        ..clear();

      expect(index.search('abc').single.pageId, 'p');
    });
  });

  group('NoteSearchHit', () {
    const hit = NoteSearchHit(
      noteId: 'n',
      pageId: 'p',
      kind: NoteSearchHitKind.excerpt,
      snippet: 'abcdef',
      matchStart: 1,
      matchEnd: 3,
    );

    test('round-trips through JSON and compares by value', () {
      final decoded = NoteSearchHit.fromJson(
        NoteJson.decodeMap(NoteJson.encode(hit.toJson())),
      );

      expect(decoded, hit);
      expect(decoded.hashCode, hit.hashCode);
      expect(hit.matchedText, 'bc');
      expect(hit.copyWith(pageId: 'q'), isNot(hit));
    });

    test('fromJson clamps the range and falls back on unknown kinds', () {
      expect(NoteSearchHit.fromJson(null), isNull);
      expect(NoteSearchHit.fromJson({'snippet': 'x'}), isNull);
      final decoded = NoteSearchHit.fromJson({
        'noteId': 'n',
        'kind': 'telepathy',
        'snippet': 'abc',
        'matchStart': 9,
        'matchEnd': -2,
      })!;

      expect(decoded.kind, NoteSearchHitKind.text);
      expect(decoded.matchStart, 3);
      expect(decoded.matchEnd, 3);
      expect(decoded.matchedText, isEmpty);
    });

    test('keeps the persisted kind names', () {
      expect(
        [for (final kind in NoteSearchHitKind.values) kind.name],
        ['text', 'excerpt', 'bookmark', 'outline', 'tag', 'handwriting'],
      );
    });
  });
}

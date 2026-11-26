import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/nav/nav.dart';

import 'nav_test_support.dart';

/// A compact rendering of the tree: `a(b(c) d) e`.
String shape(List<NoteOutlineEntry> entries) => [
  for (final entry in entries)
    entry.hasChildren ? '${entry.id}(${shape(entry.children)})' : entry.id,
].join(' ');

/// `a(b(c) d) e`: ids are the titles; page ids are `p-<id>`.
NoteOutline sample() {
  NoteOutlineEntry node(String id, [List<NoteOutlineEntry> kids = const []]) =>
      NoteOutlineEntry(id: id, title: id, pageId: 'p-$id', children: kids);

  return NoteOutline(
    entries: [
      node('a', [
        node('b', [node('c')]),
        node('d'),
      ]),
      node('e'),
    ],
    idFactory: countingIds('n'),
  );
}

void main() {
  group('NoteOutlineEntry', () {
    test('compares deeply and exposes unmodifiable children', () {
      final first = sample().entries;
      final second = sample().entries;

      expect(first, second);
      expect(first.first.hashCode, second.first.hashCode);
      expect(first.first.children.clear, throwsUnsupportedError);
      expect(first.first.copyWith(title: 'x'), isNot(first.first));
    });

    test('fromJson skips bad children and rejects entries without id', () {
      expect(NoteOutlineEntry.fromJson({'title': 'x'}), isNull);
      expect(NoteOutlineEntry.fromJson(7), isNull);
      final decoded = NoteOutlineEntry.fromJson({
        'id': 'r',
        'title': 3,
        'children': [
          {'id': 'ok', 'title': 't', 'pageId': 'p'},
          {'title': 'no id'},
          'junk',
        ],
      })!;

      expect(decoded.title, isEmpty);
      expect(decoded.pageId, isEmpty);
      expect(shape(decoded.children), 'ok');
    });

    test('fromJson caps the nesting depth', () {
      Object? nested;
      for (var index = 0; index < 600; index++) {
        nested = {
          'id': 'n$index',
          'children': [?nested],
        };
      }
      var entry = NoteOutlineEntry.fromJson(nested);
      var depth = 0;
      while (entry != null) {
        depth++;
        entry = entry.hasChildren ? entry.children.single : null;
      }

      expect(depth, NoteOutlineEntry.maxDecodeDepth);
    });
  });

  group('NoteOutline editing', () {
    test('add appends roots and children and clamps the index', () {
      final outline = sample();

      final root = outline.add('  Root  ', 'p-x')!;
      final child = outline.add('Child', 'p-y', parentId: 'e', index: 99)!;
      final first = outline.add('First', 'p-z', parentId: 'a', index: -4)!;

      expect(root.title, 'Root');
      expect(root.id, 'n1');
      expect(shape(outline.entries), 'a(n3 b(c) d) e(n2) n1');
      expect(child.pageId, 'p-y');
      expect(outline.parentOf(first.id)!.id, 'a');
      expect(outline.parentOf('a'), isNull);
    });

    test('add under an unknown parent does nothing', () {
      final outline = sample();
      final counter = NotifyCounter(outline);

      expect(outline.add('x', 'p', parentId: 'nope'), isNull);
      expect(counter.count, 0);
    });

    test('remove drops the whole subtree', () {
      final outline = sample();

      expect(outline.remove('b'), isTrue);
      expect(shape(outline.entries), 'a(d) e');
      expect(outline.find('c'), isNull);
      expect(outline.remove('b'), isFalse);
    });

    test('rename and setTarget notify only on change', () {
      final outline = sample();
      final counter = NotifyCounter(outline);

      expect(outline.rename('c', ' Title '), isTrue);
      expect(outline.rename('c', 'Title'), isFalse);
      expect(outline.setTarget('c', 'p-new'), isTrue);
      expect(outline.setTarget('c', 'p-new'), isFalse);
      expect(outline.rename('zzz', 'x'), isFalse);
      expect(outline.find('c')!.title, 'Title');
      expect(outline.find('c')!.pageId, 'p-new');
      expect(counter.count, 2);
    });

    test('move reorders siblings and reparents, clamping the index', () {
      final outline = sample();

      expect(outline.move('d', 'a', 0), isTrue);
      expect(shape(outline.entries), 'a(d b(c)) e');
      expect(outline.move('c', null, 99), isTrue);
      expect(shape(outline.entries), 'a(d b) e c');
      expect(outline.move('e', 'c', -3), isTrue);
      expect(shape(outline.entries), 'a(d b) c(e)');
    });

    test('move counts the index after taking the entry out', () {
      final outline = sample();

      expect(outline.move('a', null, 1), isTrue);
      expect(shape(outline.entries), 'e a(b(c) d)');
    });

    test('move into itself or its own descendant is rejected', () {
      final outline = sample();
      final before = outline.entries;
      final counter = NotifyCounter(outline);

      for (final target in ['a', 'b', 'c', 'd']) {
        expect(outline.canMove('a', target), isFalse, reason: 'a → $target');
        expect(outline.move('a', target, 0), isFalse, reason: 'a → $target');
      }
      expect(outline.move('b', 'c', 0), isFalse);
      expect(outline.move('b', 'b', 0), isFalse);
      expect(outline.entries, before);
      expect(counter.count, 0);
    });

    test('move with unknown ids or without effect returns false', () {
      final outline = sample();
      final counter = NotifyCounter(outline);

      expect(outline.move('zzz', null, 0), isFalse);
      expect(outline.move('a', 'zzz', 0), isFalse);
      expect(outline.move('b', 'a', 0), isFalse);
      expect(outline.move('e', null, 1), isFalse);
      expect(outline.canMove('c', null), isTrue);
      expect(counter.count, 0);
    });

    test('indent nests under the previous sibling', () {
      final outline = sample();

      expect(outline.indent('d'), isTrue);
      expect(shape(outline.entries), 'a(b(c d)) e');
      expect(outline.indent('e'), isTrue);
      expect(shape(outline.entries), 'a(b(c d) e)');
    });

    test('the first sibling and unknown ids cannot be indented', () {
      final outline = sample();

      expect(outline.indent('a'), isFalse);
      expect(outline.indent('b'), isFalse);
      expect(outline.indent('c'), isFalse);
      expect(outline.indent('zzz'), isFalse);
      expect(shape(outline.entries), 'a(b(c) d) e');
    });

    test('outdent moves an entry right after its parent', () {
      final outline = sample();

      expect(outline.outdent('b'), isTrue);
      expect(shape(outline.entries), 'a(d) b(c) e');
      expect(outline.outdent('c'), isTrue);
      expect(shape(outline.entries), 'a(d) b c e');
    });

    test('outdent keeps the following siblings with the old parent', () {
      final outline = sample()..add('f', 'p', parentId: 'a');

      outline.outdent('b');

      expect(shape(outline.entries), 'a(d n1) b(c) e');
    });

    test('roots and unknown ids cannot be outdented', () {
      final outline = sample();

      expect(outline.outdent('a'), isFalse);
      expect(outline.outdent('zzz'), isFalse);
    });

    test('random moves never lose, duplicate or loop entries', () {
      final outline = sample();
      for (var index = 0; index < 6; index++) {
        outline.add('extra', 'p', parentId: index.isEven ? 'c' : null);
      }
      final ids = {for (final row in outline.flatten()) row.entry.id};
      final random = Random(7);
      final all = ids.toList();
      for (var step = 0; step < 600; step++) {
        final id = all[random.nextInt(all.length)];
        final target = random.nextInt(4) == 0
            ? null
            : all[random.nextInt(all.length)];
        switch (random.nextInt(3)) {
          case 0:
            outline.move(id, target, random.nextInt(5) - 1);
          case 1:
            outline.indent(id);
          default:
            outline.outdent(id);
        }
        final rows = outline.flatten();
        expect(rows.length, ids.length, reason: 'step $step');
        expect({for (final row in rows) row.entry.id}, ids);
      }
    });
  });

  group('NoteOutline queries', () {
    test('flatten is depth-first with depth and parent', () {
      final rows = sample().flatten();

      expect(
        [for (final row in rows) '${row.entry.id}:${row.depth}'],
        ['a:0', 'b:1', 'c:2', 'd:1', 'e:0'],
      );
      expect(
        [for (final row in rows) row.parentId],
        [null, 'a', 'b', 'a', null],
      );
      expect(rows, sample().flatten());
    });

    test('entryForPage picks the deepest entry, then the first', () {
      final outline = sample()
        ..setTarget('a', 'shared')
        ..setTarget('c', 'shared')
        ..setTarget('d', 'twin')
        ..setTarget('b', 'twin');

      expect(outline.entryForPage('shared')!.id, 'c');
      expect(outline.entryForPage('twin')!.id, 'b');
      expect(outline.entryForPage('none'), isNull);
    });

    test('breadcrumb runs from the root to the page entry', () {
      final outline = sample();

      expect(
        [for (final entry in outline.breadcrumb('p-c')) entry.id],
        ['a', 'b', 'c'],
      );
      expect(outline.breadcrumb('none'), isEmpty);
    });

    test('removePage drops entries and promotes their children', () {
      final outline = sample()..setTarget('d', 'p-b');
      final counter = NotifyCounter(outline);

      expect(outline.removePage('p-b'), 2);
      expect(shape(outline.entries), 'a(c) e');
      expect(outline.removePage('p-b'), 0);
      expect(counter.count, 1);
    });

    test('removePage promotes grandchildren in order', () {
      final outline = sample();

      outline.removePage('p-a');

      expect(shape(outline.entries), 'b(c) d e');
    });
  });

  group('NoteOutline persistence', () {
    test('round-trips through JSON', () {
      final outline = sample()..add('한글 목차', 'p-k', parentId: 'e');
      final restored = NoteOutline.fromJson(
        NoteJson.decodeMap(NoteJson.encode(outline.toJson())),
      );

      expect(restored.entries, outline.entries);
      expect(outline.toJson()['v'], 1);
    });

    test('fromJson survives malformed input and duplicate ids', () {
      expect(NoteOutline.fromJson(null).isEmpty, isTrue);
      expect(NoteOutline.fromJson({'entries': 3}).isEmpty, isTrue);
      final restored = NoteOutline.fromJson({
        'entries': [
          {
            'id': 'a',
            'children': [
              {'id': 'a'},
              {'id': 'b'},
            ],
          },
          {'id': 'b'},
          {'id': ''},
          false,
          {'id': 'c'},
        ],
      });

      expect(shape(restored.entries), 'a(b) c');
    });

    test('mutators do nothing after dispose', () {
      final outline = sample()..dispose();
      outline.dispose();

      expect(outline.add('x', 'p'), isNull);
      expect(outline.remove('a'), isFalse);
      expect(outline.rename('a', 'x'), isFalse);
      expect(outline.move('d', null, 0), isFalse);
      expect(outline.indent('d'), isFalse);
      expect(outline.outdent('b'), isFalse);
      expect(outline.removePage('p-a'), 0);
      expect(shape(outline.entries), 'a(b(c) d) e');
    });
  });
}

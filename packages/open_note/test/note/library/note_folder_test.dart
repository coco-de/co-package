import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/library/internal/note_folder_glyphs.dart';
import 'package:open_note/src/note/library/internal/note_library_dates.dart';
import 'package:open_note/src/note/library/library.dart';

import 'library_test_support.dart';

void main() {
  group('NoteFolder', () {
    test('round-trips through JSON', () {
      final entry = folder(
        'f',
        name: '학교',
        parentId: 'p',
        order: 3,
        iconKey: NoteFolderIcons.school,
      );
      final text = NoteJson.encode(entry.toJson());

      expect(NoteFolder.fromJson(NoteJson.decodeMap(text)), entry);
    });

    test('omits the parent of a top-level folder', () {
      expect(folder('f').toJson().containsKey('parentId'), isFalse);
    });

    test('is null without an object that has an id', () {
      for (final value in [null, 'f', 3, <Object?>[]]) {
        expect(NoteFolder.fromJson(value), isNull);
      }
      expect(NoteFolder.fromJson({'name': 'x'}), isNull);
    });

    test('repairs bad fields', () {
      final entry = NoteFolder.fromJson({
        'id': 'f',
        'name': 4,
        'iconKey': '',
        'parentId': '',
        'order': -2,
        'createdAt': 'soon',
      })!;

      expect(entry.name, '');
      expect(entry.iconKey, NoteFolderIcons.folder);
      expect(entry.parentId, isNull);
      expect(entry.order, 0);
      expect(entry.createdAt, NoteLibraryDates.epoch);
    });

    test('keeps unknown icon keys', () {
      expect(
        NoteFolder.fromJson({'id': 'f', 'iconKey': 'ufo'})!.iconKey,
        'ufo',
      );
    });

    test('compares by every field and copies', () {
      final entry = folder('f', parentId: 'p');

      expect(entry.copyWith(), entry);
      expect(entry.copyWith().hashCode, entry.hashCode);
      expect(entry.copyWith(name: 'z'), isNot(entry));
      expect(entry.copyWith(order: 2), isNot(entry));
      expect(entry.copyWith(parentId: () => null).parentId, isNull);
      expect(entry.copyWith(createdAt: day(2).toLocal()), isNot(entry));
      expect(entry.copyWith(createdAt: day(1).toLocal()), entry);
    });
  });

  group('NoteFolderIcons and glyphs', () {
    test('offers at least ten distinct keys including the default', () {
      expect(NoteFolderIcons.keys.length, greaterThanOrEqualTo(10));
      expect(
        NoteFolderIcons.keys.toSet(),
        hasLength(NoteFolderIcons.keys.length),
      );
      expect(NoteFolderIcons.keys, contains(NoteFolderIcons.folder));
      expect(NoteFolderIcons.contains('star'), isTrue);
      expect(NoteFolderIcons.contains('ufo'), isFalse);
    });

    test('every key draws its own outline inside the design box', () {
      const box = Rect.fromLTWH(
        0,
        0,
        NoteFolderGlyphs.designSize,
        NoteFolderGlyphs.designSize,
      );
      final signatures = <String>{};
      for (final key in NoteFolderIcons.keys) {
        final path = NoteFolderGlyphs.pathFor(key);
        final bounds = path.getBounds();
        final length = path.computeMetrics().fold<double>(
          0,
          (sum, metric) => sum + metric.length,
        );

        expect(length, greaterThan(20), reason: key);
        expect(box.contains(bounds.topLeft), isTrue, reason: '$key $bounds');
        expect(
          box.contains(bounds.bottomRight - const Offset(0.01, 0.01)),
          isTrue,
          reason: '$key $bounds',
        );
        signatures.add('$bounds ${length.toStringAsFixed(2)}');
      }

      expect(signatures, hasLength(NoteFolderIcons.keys.length));
    });

    test('draws unknown keys like a folder', () {
      expect(
        NoteFolderGlyphs.pathFor('ufo').getBounds(),
        NoteFolderGlyphs.pathFor(NoteFolderIcons.folder).getBounds(),
      );
    });
  });

  group('NoteFolderTree', () {
    final tree = [
      folder('a', order: 1),
      folder('b'),
      folder('a1', parentId: 'a'),
      folder('a2', parentId: 'a', order: 1),
      folder('a1x', parentId: 'a1'),
    ];

    test('orders children and flattens depth first', () {
      expect(folderIdsOf(NoteFolderTree.childrenOf(tree, null)), ['b', 'a']);
      expect(folderIdsOf(NoteFolderTree.childrenOf(tree, 'a')), ['a1', 'a2']);
      final nodes = NoteFolderTree.flatten(tree);

      expect(
        [for (final node in nodes) '${node.folder.id}:${node.depth}'],
        ['b:0', 'a:0', 'a1:1', 'a1x:2', 'a2:1'],
      );
    });

    test('skips the children of closed folders', () {
      final nodes = NoteFolderTree.flatten(tree, collapsed: {'a1'});

      expect(
        [for (final node in nodes) node.folder.id],
        ['b', 'a', 'a1', 'a2'],
      );
    });

    test('finds all descendants', () {
      expect(NoteFolderTree.descendantsOf(tree, 'a'), {'a1', 'a2', 'a1x'});
      expect(NoteFolderTree.descendantsOf(tree, 'b'), isEmpty);
    });

    test('siblings with equal orders are ordered by date then id', () {
      final twins = [
        folder('z'),
        folder('y').copyWith(createdAt: day(0)),
        folder('x'),
      ];

      expect(folderIdsOf(NoteFolderTree.childrenOf(twins, null)), [
        'y',
        'x',
        'z',
      ]);
    });

    test('sanitize drops repeated ids and renumbers siblings', () {
      final result = NoteFolderTree.sanitize([
        folder('a', name: 'first', order: 7),
        folder('a', name: 'second'),
        folder('b', order: 2),
      ]);

      expect(folderIdsOf(result), ['b', 'a']);
      expect([for (final entry in result) entry.order], [0, 1]);
      expect(result.last.name, 'first');
    });

    test('sanitize detaches missing parents', () {
      final result = NoteFolderTree.sanitize([folder('a', parentId: 'gone')]);

      expect(result.single.parentId, isNull);
    });

    test('sanitize breaks cycles without losing folders', () {
      final result = NoteFolderTree.sanitize([
        folder('tail', parentId: 'a'),
        folder('a', parentId: 'b'),
        folder('b', parentId: 'a'),
        folder('self', parentId: 'self'),
      ]);

      expect(folderIdsOf(result).toSet(), {'tail', 'a', 'b', 'self'});
      expect(NoteFolderTree.flatten(result), hasLength(4));
      final byId = {for (final entry in result) entry.id: entry};
      expect(byId['self']!.parentId, isNull);
      expect(byId['tail']!.parentId, 'a');
      expect(
        [byId['a']!.parentId, byId['b']!.parentId].whereType<String>(),
        hasLength(1),
        reason: 'exactly one link of the two-folder cycle is cut',
      );
    });
  });
}

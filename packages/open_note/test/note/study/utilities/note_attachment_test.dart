import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/study/utilities/utilities.dart';

import 'support/utility_test_helpers.dart';

final _time = DateTime.utc(2026, 5, 6, 7, 8, 9);

NoteAttachment _attachment(
  String id, {
  NoteAttachmentKind kind = NoteAttachmentKind.document,
}) => NoteAttachment(
  id: id,
  kind: kind,
  source: '$id.pdf',
  createdAt: _time,
  title: 'Title $id',
);

NoteAttachmentList _list([Iterable<NoteAttachment> items = const []]) {
  var next = 0;
  final list = NoteAttachmentList(
    items: items,
    idFactory: () => 'new-${++next}',
    clock: () => _time,
  );
  addTearDown(list.dispose);

  return list;
}

List<String> _ids(NoteAttachmentList list) =>
    list.items.map((item) => item.id).toList();

void main() {
  group('NoteAttachment', () {
    test('round-trips every kind through JSON', () {
      for (final kind in NoteAttachmentKind.values) {
        final attachment = _attachment('a', kind: kind);
        final json = attachment.toJson();

        expect(json['kind'], kind.name);
        expect(NoteAttachment.fromJson(json), attachment);
        expect(NoteAttachment.fromJson(json).hashCode, attachment.hashCode);
      }
    });

    test('keeps the persisted kind names', () {
      expect(NoteAttachmentKind.values.map((kind) => kind.name), [
        'audio',
        'video',
        'document',
        'link',
      ]);
    });

    test('reads malformed values leniently', () {
      for (final bad in [null, 1, 'text', <Object?>[]]) {
        final read = NoteAttachment.fromJson(bad);
        expect(read.id, '');
        expect(read.kind, NoteAttachmentKind.document);
        expect(read.createdAt.millisecondsSinceEpoch, 0);
      }
      final newer = NoteAttachment.fromJson({
        'id': 'x',
        'kind': 'hologram',
        'source': 7,
        'createdAt': 5,
      });
      expect(newer.kind, NoteAttachmentKind.document);
      expect(newer.source, '');
    });

    test('copies with changes', () {
      final attachment = _attachment('a');

      expect(attachment.copyWith(), attachment);
      expect(attachment.copyWith(title: 'New').title, 'New');
      expect(
        attachment.copyWith(kind: NoteAttachmentKind.link),
        isNot(attachment),
      );
    });
  });

  group('NoteAttachmentList', () {
    test('adds with a new id and time', () {
      final list = _list();

      final added = list.add(
        kind: NoteAttachmentKind.link,
        source: '  https://example.com  ',
        title: '  Example  ',
      );

      expect(added?.id, 'new-1');
      expect(added?.createdAt, _time);
      expect(added?.source, 'https://example.com');
      expect(added?.title, 'Example');
      expect(list.items, [added]);
    });

    test('titles an untitled attachment after its source', () {
      final added = _list().add(
        kind: NoteAttachmentKind.video,
        source: 'clip.mp4',
      );

      expect(added?.title, 'clip.mp4');
    });

    test('refuses a blank source', () {
      final list = _list();
      final calls = countNotifications(list);

      expect(list.add(kind: NoteAttachmentKind.audio, source: '   '), isNull);
      expect(calls, isEmpty);
    });

    test('skips unusable initial items', () {
      final list = _list([
        _attachment('a'),
        _attachment('a'),
        _attachment(''),
        _attachment('b').copyWith(source: ''),
        _attachment('c'),
      ]);

      expect(_ids(list), ['a', 'c']);
      expect(list.items.removeLast, throwsUnsupportedError);
    });

    test('inserts at an index, rejecting duplicates', () {
      final list = _list([_attachment('a'), _attachment('c')]);

      expect(list.insert(_attachment('b'), index: 1), isTrue);
      expect(list.insert(_attachment('b')), isFalse);
      expect(list.insert(_attachment('z'), index: 99), isTrue);
      expect(list.insert(_attachment('y'), index: -3), isTrue);

      expect(_ids(list), ['y', 'a', 'b', 'c', 'z']);
    });

    test('removes and renames', () {
      final list = _list([_attachment('a'), _attachment('b')]);
      final calls = countNotifications(list);

      expect(list.rename('a', '  Slides '), isTrue);
      expect(list.rename('a', 'Slides'), isFalse);
      expect(list.rename('a', ' '), isFalse);
      expect(list.rename('nope', 'X'), isFalse);
      expect(list.find('a')?.title, 'Slides');
      expect(list.remove('a'), isTrue);
      expect(list.remove('a'), isFalse);
      expect(_ids(list), ['b']);
      expect(calls, hasLength(2));
    });

    test('moves an item to its final index', () {
      final list = _list([for (final id in 'abcd'.split('')) _attachment(id)]);

      expect(list.move(0, 2), isTrue);
      expect(_ids(list), ['b', 'c', 'a', 'd']);
      expect(list.move(3, 0), isTrue);
      expect(_ids(list), ['d', 'b', 'c', 'a']);
      expect(list.move(1, 99), isTrue);
      expect(_ids(list), ['d', 'c', 'a', 'b']);
      expect(list.move(1, 1), isFalse);
      expect(list.move(-1, 0), isFalse);
      expect(list.move(9, 0), isFalse);
    });

    test('filters by kind', () {
      final list = _list([
        _attachment('a', kind: NoteAttachmentKind.audio),
        _attachment('b', kind: NoteAttachmentKind.video),
        _attachment('c', kind: NoteAttachmentKind.audio),
      ]);

      expect(list.byKind(NoteAttachmentKind.audio).map((item) => item.id), [
        'a',
        'c',
      ]);
      expect(list.byKind(NoteAttachmentKind.link), isEmpty);
    });

    test('round-trips through JSON', () {
      final list = _list([
        _attachment('a', kind: NoteAttachmentKind.link),
        _attachment('b'),
      ]);

      final restored = NoteAttachmentList.fromJson(list.toJson());
      addTearDown(restored.dispose);

      expect(restored.items, list.items);
    });

    test('skips malformed entries when reading', () {
      for (final bad in [null, 'x', <String, Object?>{}]) {
        final read = NoteAttachmentList.fromJson(bad);
        addTearDown(read.dispose);
        expect(read.items, isEmpty);
      }
      final read = NoteAttachmentList.fromJson({
        'items': [
          'junk',
          {'id': 'no-source'},
          _attachment('ok').toJson(),
          _attachment('ok').toJson(),
        ],
      });
      addTearDown(read.dispose);

      expect(_ids(read), ['ok']);
    });

    test('does nothing after dispose', () {
      final list = NoteAttachmentList(items: [_attachment('a')])..dispose();

      expect(list.add(kind: NoteAttachmentKind.link, source: 'x'), isNull);
      expect(list.insert(_attachment('b')), isFalse);
      expect(list.remove('a'), isFalse);
      expect(list.rename('a', 'x'), isFalse);
      expect(list.move(0, 0), isFalse);
      expect(list.dispose, returnsNormally);
      expect(_ids(list), ['a']);
    });
  });
}

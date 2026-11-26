import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/io/bundle/note_bundle_codec.dart';
import 'package:open_note/src/note/io/bundle/note_bundle_exception.dart';

Uint8List _bytes(List<int> values) => Uint8List.fromList(values);

Uint8List _bundle(Map<String, Object?> files, {Object? version = 1}) =>
    _bytes(utf8.encode(jsonEncode({'v': version, 'files': files})));

Map<String, Object?> _text(String data) => {'enc': 'utf8', 'data': data};

Future<Map<String, Object?>> _filesOf(Uint8List bundle) async {
  final document = jsonDecode(utf8.decode(bundle)) as Map<String, Object?>;

  return document['files']! as Map<String, Object?>;
}

void main() {
  group('pack and unpack', () {
    test('round trip text and binary files exactly', () async {
      final source = MemoryNoteStore();
      final binary = _bytes([0, 255, 1, 254, 128]);
      final withBom = _bytes([0xEF, 0xBB, 0xBF, 0x61]);
      final nulls = _bytes([0, 0, 0]);
      await source.writeString('library.json', '{"a": "한글\n\t"}');
      await source.writeBytes('notes/a/ink.bin', binary);
      await source.writeBytes('bom.txt', withBom);
      await source.writeBytes('nulls.bin', nulls);
      await source.writeBytes('empty', Uint8List(0));

      final bundle = await NoteBundleCodec.pack(source);
      final target = MemoryNoteStore();
      final result = await NoteBundleCodec.unpack(bundle, target);

      expect(result.written, await source.list(''));
      expect(result.skipped, isEmpty);
      for (final key in await source.list('')) {
        expect(
          await target.readBytes(key),
          await source.readBytes(key),
          reason: key,
        );
      }
    });

    test('is a self describing JSON document', () async {
      final store = MemoryNoteStore();
      await store.writeString('a.json', '{}');
      await store.writeBytes('b.bin', _bytes([200, 1]));

      final bundle = await NoteBundleCodec.pack(store);
      final document = jsonDecode(utf8.decode(bundle)) as Map;

      expect(document['v'], 1);
      expect(document['files'], {
        'a.json': {'enc': 'utf8', 'data': '{}'},
        'b.bin': {
          'enc': 'b64',
          'data': base64Encode([200, 1]),
        },
      });
    });

    test('stores control characters and byte order marks as base64', () async {
      final store = MemoryNoteStore();
      await store.writeBytes('control', _bytes([1, 65]));
      await store.writeBytes('bom', _bytes([0xEF, 0xBB, 0xBF, 65]));
      await store.writeBytes('newlines', _bytes(utf8.encode('a\r\n\tb')));

      final files = await _filesOf(await NoteBundleCodec.pack(store));

      expect((files['control']! as Map)['enc'], 'b64');
      expect((files['bom']! as Map)['enc'], 'b64');
      expect((files['newlines']! as Map)['enc'], 'utf8');
    });

    test('keys are relative to the prefix so a note can be copied', () async {
      final store = MemoryNoteStore();
      await store.writeString('notes/one/note.json', 'n');
      await store.writeString('notes/one/pages/1.bin', 'p');
      await store.writeString('notes/oneother/note.json', 'x');
      await store.writeString('library.json', 'l');

      final bundle = await NoteBundleCodec.pack(store, prefix: 'notes/one');
      await NoteBundleCodec.unpack(bundle, store, prefix: 'notes/copy/');

      expect((await _filesOf(bundle)).keys, ['note.json', 'pages/1.bin']);
      expect(await store.list('notes/copy/'), [
        'notes/copy/note.json',
        'notes/copy/pages/1.bin',
      ]);
      expect(await store.readString('notes/copy/pages/1.bin'), 'p');
    });

    test('keeps existing files unless overwriting', () async {
      final store = MemoryNoteStore();
      await store.writeString('keep', 'old');
      final bundle = _bundle({'keep': _text('new'), 'add': _text('added')});

      final cautious = await NoteBundleCodec.unpack(bundle, store);

      expect(cautious.written, ['add']);
      expect(cautious.skipped, ['keep']);
      expect(await store.readString('keep'), 'old');

      final forced = await NoteBundleCodec.unpack(
        bundle,
        store,
        overwrite: true,
      );

      expect(forced.written, ['add', 'keep']);
      expect(await store.readString('keep'), 'new');
    });

    test('packing an empty store gives an empty bundle', () async {
      final bundle = await NoteBundleCodec.pack(MemoryNoteStore());
      final result = await NoteBundleCodec.unpack(bundle, MemoryNoteStore());

      expect(result.written, isEmpty);
    });
  });

  group('unpack validation', () {
    Future<void> expectRejected(Uint8List bundle, {String prefix = ''}) async {
      final store = MemoryNoteStore();
      await expectLater(
        NoteBundleCodec.unpack(bundle, store, prefix: prefix),
        throwsA(isA<NoteBundleException>()),
      );
      expect(store.length, 0, reason: 'nothing may be written');
    }

    for (final key in [
      '../escape',
      'a/../../b',
      '/etc/passwd',
      'a//b',
      'a/./b',
      r'a\b',
      'nul\u0000',
      'new\nline',
      'del\u007f',
      '',
      'trailing/',
    ]) {
      test('rejects the unsafe key ${jsonEncode(key)}', () async {
        // A valid file first: it must not be written either.
        await expectRejected(
          _bundle({'good': _text('1'), key: _text('2')}),
          prefix: 'notes/x/',
        );
      });
    }

    test('rejects a file that is also a directory', () async {
      await expectRejected(_bundle({'a': _text('1'), 'a/b': _text('2')}));
      await expectRejected(_bundle({'a/b/c': _text('1'), 'a': _text('2')}));
    });

    test('rejects malformed entries before writing anything', () async {
      await expectRejected(_bundle({'a': _text('1'), 'b': 'not a map'}));
      await expectRejected(
        _bundle({
          'a': _text('1'),
          'b': {'enc': 'utf8'},
        }),
      );
      await expectRejected(
        _bundle({
          'a': _text('1'),
          'b': {'enc': 'rot13', 'data': 'x'},
        }),
      );
      await expectRejected(
        _bundle({
          'a': _text('1'),
          'b': {'enc': 'b64', 'data': '***'},
        }),
      );
    });

    test('rejects other versions and non-bundles', () async {
      await expectRejected(_bundle({}, version: 2));
      await expectRejected(_bundle({}, version: '1'));
      await expectRejected(_bytes(utf8.encode('[1, 2]')));
      await expectRejected(_bytes(utf8.encode('not json')));
      await expectRejected(_bytes([0xFF, 0xFE, 0x00]));
      await expectRejected(_bytes(utf8.encode('{"v": 1}')));
    });

    test('rejects unsafe prefixes', () async {
      await expectLater(
        NoteBundleCodec.pack(MemoryNoteStore(), prefix: '../x'),
        throwsA(isA<NoteStoreException>()),
      );
      await expectLater(
        NoteBundleCodec.unpack(_bundle({}), MemoryNoteStore(), prefix: '/abs'),
        throwsA(isA<NoteStoreException>()),
      );
    });

    test('errors describe themselves', () {
      expect(
        const NoteBundleException('broken').toString(),
        'NoteBundleException: broken',
      );
    });
  });
}

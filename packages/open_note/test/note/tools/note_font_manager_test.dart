import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/tools/tools.dart';

/// A minimal file with a valid sfnt table directory. The [marker] byte lands
/// in a table record, so two fonts can be told apart.
Uint8List _font({int version = 0x00010000, int tables = 1, int marker = 0}) {
  final data = ByteData(12 + 16 * tables)
    ..setUint32(0, version)
    ..setUint16(4, tables);
  if (tables > 0) data.setUint8(12, marker);

  return data.buffer.asUint8List();
}

const _otto = 0x4F54544F;

class _Registrar {
  final List<(String, Uint8List)> calls = [];
  Object? failure;

  List<String> get families => [for (final call in calls) call.$1];

  Future<void> load(String family, Uint8List bytes) {
    final error = failure;
    if (error != null) return Future<void>.error(error);
    calls.add((family, bytes));

    return Future<void>.value();
  }
}

/// A store whose writes can be made to fail.
class _FlakyStore extends MemoryNoteStore {
  bool failWrites = false;

  @override
  Future<void> writeBytes(String key, Uint8List bytes) async {
    if (failWrites) throw const NoteStoreException('disk full');
    await super.writeBytes(key, bytes);
  }
}

Future<List<Object?>> _index(NoteStore store) async {
  final json = NoteJson.decodeMap(await store.readString('fonts/index.json'));

  return NoteJson.list(json!, 'fonts');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NoteFontFormat.detect', () {
    test('recognises TrueType and OpenType headers', () {
      expect(NoteFontFormat.detect(_font()), NoteFontFormat.ttf);
      expect(
        NoteFontFormat.detect(_font(version: 0x74727565)),
        NoteFontFormat.ttf,
      );
      expect(NoteFontFormat.detect(_font(version: _otto)), NoteFontFormat.otf);
      expect(NoteFontFormat.ttf.fileExtension, 'ttf');
      expect(NoteFontFormat.otf.fileExtension, 'otf');
    });

    test('rejects everything else', () {
      final bad = <String, Uint8List>{
        'empty': Uint8List(0),
        'short': Uint8List(11),
        'text': Uint8List.fromList('hello world, not a font'.codeUnits),
        'woff': _font(version: 0x774F4646),
        'woff2': _font(version: 0x774F4632),
        'collection': _font(version: 0x74746366),
        'no tables': _font(tables: 0),
        'truncated directory': Uint8List.sublistView(_font(tables: 4), 0, 40),
      };

      bad.forEach((name, bytes) {
        expect(NoteFontFormat.detect(bytes), isNull, reason: name);
      });
    });

    test('works on a view into a larger buffer', () {
      final padded = Uint8List.fromList([9, 9, 9, ..._font()]);

      expect(
        NoteFontFormat.detect(Uint8List.sublistView(padded, 3)),
        NoteFontFormat.ttf,
      );
    });
  });

  group('NoteFontManager.registerFont', () {
    late _Registrar registrar;
    late MemoryNoteStore store;
    late NoteFontManager manager;
    late int notifications;

    setUp(() {
      registrar = _Registrar();
      store = MemoryNoteStore();
      manager = NoteFontManager(store: store, registrar: registrar.load);
      notifications = 0;
      manager.addListener(() => notifications++);
    });

    test('loads, lists and persists a font', () async {
      final added = await manager.registerFont('  Nanum Pen ', _font());

      expect(added, isTrue);
      expect(manager.families, ['Nanum Pen']);
      expect(manager.isRegistered('nanum pen'), isTrue);
      expect(registrar.families, ['Nanum Pen']);
      expect(notifications, 1);
      expect(await store.list('fonts/'), [
        'fonts/Nanum Pen.ttf',
        'fonts/index.json',
      ]);
      expect(await store.readBytes('fonts/Nanum Pen.ttf'), _font());
      expect(await _index(store), [
        {'family': 'Nanum Pen', 'ext': 'ttf'},
      ]);
    });

    test('stores OpenType fonts with the otf extension', () async {
      await manager.registerFont('Serif', _font(version: _otto));

      expect(await store.exists('fonts/Serif.otf'), isTrue);
    });

    test('ignores duplicates, also when only the case differs', () async {
      await manager.registerFont('Pen', _font());

      expect(await manager.registerFont('Pen', _font(marker: 1)), isFalse);
      expect(await manager.registerFont('PEN', _font(marker: 2)), isFalse);
      expect(manager.families, ['Pen']);
      expect(registrar.calls.length, 1);
      expect(notifications, 1);
      expect(await store.readBytes('fonts/Pen.ttf'), _font());
    });

    test('lets only one of two concurrent registrations win', () async {
      final results = await Future.wait([
        manager.registerFont('Pen', _font()),
        manager.registerFont('pen', _font()),
      ]);

      expect(results, [true, false]);
      expect(registrar.calls.length, 1);
    });

    test('rejects bytes without a font header', () async {
      await expectLater(
        manager.registerFont('Bad', Uint8List.fromList([1, 2, 3])),
        throwsA(isA<NoteFontException>()),
      );

      expect(manager.families, isEmpty);
      expect(registrar.calls, isEmpty);
      expect(store.length, 0);
    });

    test('rejects names that cannot be file names', () async {
      const names = [
        '',
        '   ',
        '.',
        '..',
        'a/b',
        r'a\b',
        'a:b',
        'a*b',
        'a?b',
        'a"b',
        'a<b',
        'a>b',
        'a|b',
        'a\nb',
        'a\u0000b',
      ];

      for (final name in names) {
        expect(NoteFontManager.isValidFamilyName(name), isFalse, reason: name);
        await expectLater(
          manager.registerFont(name, _font()),
          throwsA(isA<NoteFontException>()),
        );
      }
      expect(NoteFontManager.isValidFamilyName('x' * 80), isTrue);
      expect(NoteFontManager.isValidFamilyName('x' * 81), isFalse);
      expect(NoteFontManager.isValidFamilyName('나눔 손글씨'), isTrue);
      expect(store.length, 0);
    });

    test('keeps a copy of the bytes', () async {
      final bytes = _font(marker: 7);

      final pending = manager.registerFont('Copy', bytes);
      bytes[12] = 200;
      await pending;

      expect(registrar.calls.single.$2[12], 7);
      expect((await store.readBytes('fonts/Copy.ttf'))![12], 7);
    });

    test('passes registrar errors on and allows a retry', () async {
      registrar.failure = const NoteFontException('engine said no');

      await expectLater(
        manager.registerFont('Retry', _font()),
        throwsA(isA<NoteFontException>()),
      );
      expect(manager.families, isEmpty);
      expect(store.length, 0);

      registrar.failure = null;
      expect(await manager.registerFont('Retry', _font()), isTrue);
    });

    test('passes store errors on without blocking later writes', () async {
      final flaky = _FlakyStore()..failWrites = true;
      final broken = NoteFontManager(store: flaky, registrar: registrar.load);

      await expectLater(
        broken.registerFont('Lost', _font()),
        throwsA(isA<NoteStoreException>()),
      );
      expect(broken.families, isEmpty);

      flaky.failWrites = false;
      expect(await broken.registerFont('Kept', _font()), isTrue);
      expect(await _index(flaky), [
        {'family': 'Kept', 'ext': 'ttf'},
      ]);
    });

    test('keeps every entry when fonts are added at the same time', () async {
      await Future.wait([
        for (var i = 0; i < 5; i++) manager.registerFont('Font $i', _font()),
      ]);

      expect(await _index(store), hasLength(5));
      expect(manager.families, hasLength(5));
    });

    test('works without a store', () async {
      final memoryOnly = NoteFontManager(registrar: registrar.load);

      expect(await memoryOnly.registerFont('Temp', _font()), isTrue);
      expect(memoryOnly.families, ['Temp']);
    });

    test('replaces a stored entry of the same family', () async {
      await manager.registerFont('Pen', _font());
      final next = NoteFontManager(store: store, registrar: registrar.load);

      await next.registerFont('pen', _font(version: _otto));

      expect(await _index(store), [
        {'family': 'pen', 'ext': 'otf'},
      ]);
      expect(await store.exists('fonts/Pen.ttf'), isFalse);
      expect(await store.exists('fonts/pen.otf'), isTrue);
    });

    test('does nothing after dispose', () async {
      manager.dispose();

      expect(await manager.registerFont('Late', _font()), isFalse);
      expect(await manager.restore(store), 0);
      expect(registrar.calls, isEmpty);
    });

    test('does not notify when disposed while loading', () async {
      final pending = manager.registerFont('Slow', _font());
      manager.dispose();

      await pending;

      expect(notifications, 0);
    });

    test('returns an unmodifiable family list', () async {
      await manager.registerFont('Pen', _font());

      expect(() => manager.families.add('x'), throwsUnsupportedError);
    });
  });

  group('NoteFontManager.restore', () {
    late _Registrar registrar;
    late MemoryNoteStore store;

    setUp(() async {
      registrar = _Registrar();
      store = MemoryNoteStore();
      final writer = NoteFontManager(
        store: store,
        registrar: (family, bytes) async {},
      );
      await writer.registerFont('One', _font(marker: 1));
      await writer.registerFont('Two', _font(version: _otto, marker: 2));
    });

    NoteFontManager fresh() => NoteFontManager(registrar: registrar.load);

    test('loads the stored fonts again', () async {
      final manager = fresh();
      var notifications = 0;
      manager.addListener(() => notifications++);

      expect(await manager.restore(store), 2);
      expect(manager.families, ['One', 'Two']);
      expect(registrar.calls.first.$2, _font(marker: 1));
      expect(notifications, 1);
    });

    test('skips fonts that are already loaded', () async {
      final manager = fresh();
      await manager.restore(store);

      expect(await manager.restore(store), 0);
      expect(registrar.calls.length, 2);
    });

    test('keeps older fonts when registering before restoring', () async {
      final manager = NoteFontManager(store: store, registrar: registrar.load);

      await manager.registerFont('Three', _font(marker: 3));

      expect(await _index(store), hasLength(3));
      expect(await manager.restore(store), 2);
      expect(manager.families, ['Three', 'One', 'Two']);
    });

    test('loads nothing from an empty or corrupt index', () async {
      final empty = MemoryNoteStore();
      expect(await fresh().restore(empty), 0);

      for (final content in ['', 'nope', '[1]', '{"fonts": 3}']) {
        await empty.writeString('fonts/index.json', content);
        expect(await fresh().restore(empty), 0, reason: content);
      }
    });

    test('skips entries it cannot use', () async {
      await store.writeBytes('fonts/Broken.ttf', Uint8List.fromList([0, 1]));
      await store.writeString(
        'fonts/index.json',
        NoteJson.encode({
          'fonts': [
            'junk',
            {'family': '../escape', 'ext': 'ttf'},
            {'family': 'NoFile', 'ext': 'ttf'},
            {'family': 'Broken', 'ext': 'ttf'},
            {'family': 'Woff', 'ext': 'woff'},
            {'family': 'One', 'ext': 'ttf'},
          ],
        }),
      );

      final manager = fresh();

      expect(await manager.restore(store), 1);
      expect(manager.families, ['One']);
    });

    test('goes on when one font fails to load', () async {
      final manager = NoteFontManager(
        registrar: (family, bytes) async {
          if (family == 'One') throw const NoteFontException('bad');
        },
      );

      expect(await manager.restore(store), 1);
      expect(manager.families, ['Two']);
    });

    test('works with the real FontLoader', () async {
      final manager = NoteFontManager(store: MemoryNoteStore());

      expect(await manager.registerFont('Stub', _font()), isTrue);
      expect(manager.families, ['Stub']);
      await NoteFontManager.registerWithFontLoader('Stub 2', _font());
    });
  });

  group('NoteFontDescriptor', () {
    test('round trips through JSON and labels itself', () {
      const descriptor = NoteFontDescriptor(
        id: 'a',
        family: 'Fam',
        name: 'Name',
      );

      expect(NoteFontDescriptor.fromJson(descriptor.toJson()), descriptor);
      expect(descriptor.label, 'Name');
      expect(
        descriptor.hashCode,
        NoteFontDescriptor.fromJson(descriptor.toJson()).hashCode,
      );
      expect(const NoteFontDescriptor(id: 'a', family: 'Fam').label, 'Fam');
      expect(NoteFontDescriptor.fromJson(42).family, isEmpty);
      expect(descriptor.toString(), contains('Fam'));
      expect(descriptor.copyWith(), descriptor);
      expect(descriptor.copyWith(name: 'Other').label, 'Other');
    });
  });

  group('MemoryNoteFontSource', () {
    late MemoryNoteFontSource source;

    setUp(() {
      source = MemoryNoteFontSource()
        ..add(
          const NoteFontDescriptor(id: 'p', family: 'Nanum Pen'),
          _font(marker: 1),
        )
        ..add(
          const NoteFontDescriptor(id: 'g', family: 'Gaegu', name: '개구'),
          _font(marker: 2),
        );
    });

    Future<List<String>> ids(String? query) async => [
      for (final font in await source.list(query: query)) font.id,
    ];

    test('lists everything for a blank query', () async {
      expect(await ids(null), ['p', 'g']);
      expect(await ids('   '), ['p', 'g']);
    });

    test('searches family and name ignoring case', () async {
      expect(await ids(' nanum '), ['p']);
      expect(await ids('GAE'), ['g']);
      expect(await ids('개구'), ['g']);
      expect(await ids('zzz'), isEmpty);
    });

    test('downloads a copy of the bytes', () async {
      final bytes = await source.download('p');
      bytes[12] = 99;

      expect((await source.download('p'))[12], 1);
    });

    test('replaces a font with the same id', () async {
      source.add(
        const NoteFontDescriptor(id: 'p', family: 'Other'),
        _font(marker: 5),
      );

      expect(await ids(null), ['p', 'g']);
      expect((await source.download('p'))[12], 5);
    });

    test('throws for an unknown id', () async {
      await expectLater(
        source.download('nope'),
        throwsA(isA<NoteFontException>()),
      );
      expect(const NoteFontException('x').toString(), contains('x'));
    });

    test('feeds the manager', () async {
      final registrar = _Registrar();
      final manager = NoteFontManager(registrar: registrar.load);
      final descriptor = (await source.list(query: 'nanum')).single;

      await manager.registerFont(
        descriptor.family,
        await source.download(descriptor.id),
      );

      expect(manager.families, ['Nanum Pen']);
    });
  });
}

import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_board/src/module/managers/scribble_cache_manager.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

class _ScribblePersistenceTransformTest extends PathProviderPlatform {
  final String path;

  _ScribblePersistenceTransformTest(this.path);

  @override
  Future<String> getApplicationDocumentsPath() async => path;
}

Scribble _scribble(String id) => Scribble(strokes: [Stroke(id: id)]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late ScribbleCacheManager manager;
  late PathProviderPlatform originalProvider;

  Future<Scribble> readFile(String key) async => Scribble.fromBuffer(
    await File('${directory.path}/scribbles/$key.bin').readAsBytes(),
  );

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('scribble-transform-');
    originalProvider = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _ScribblePersistenceTransformTest(
      directory.path,
    );
    manager = ScribbleCacheManager();
  });

  tearDown(() async {
    manager.dispose();
    PathProviderPlatform.instance = originalProvider;
    await directory.delete(recursive: true);
  });

  test('should_transform_disk_only_with_normalized_key', () async {
    final visible = _scribble('visible');
    final keys = <String>[];
    manager.persistenceTransform = (key, snapshot) async {
      keys.add(key);
      snapshot.strokes.add(Stroke(id: 'retired'));
      return snapshot;
    };

    expect(
      await manager.saveScribble('book?/1', visible, immediate: true),
      isTrue,
    );
    expect(keys, ['book_/1']);
    expect((await readFile('book_/1')).strokes.map((s) => s.id), [
      'visible',
      'retired',
    ]);
    expect(visible.strokes.map((s) => s.id), ['visible']);
    expect((await manager.loadScribble('book?/1'))!.strokes.map((s) => s.id), [
      'visible',
    ]);
  });

  test('should_transform_scheduler_flush_and_save_debounce_flush', () async {
    var calls = 0;
    manager.persistenceTransform = (_, snapshot) async {
      calls++;
      snapshot.strokes.add(Stroke(id: 'retired'));
      return snapshot;
    };
    manager.scheduleAutoSave('book/1', _scribble('auto'));
    expect(await manager.flushSave('book/1'), isTrue);
    // Each read must observe the file after the preceding write.
    // ignore: prefer-moving-to-variable
    expect((await readFile('book/1')).strokes.map((s) => s.id), [
      'auto',
      'retired',
    ]);
    await manager.saveScribble('book/1', _scribble('debounced'));
    expect(await manager.flushSave('book/1'), isTrue);
    // Each read must observe the file after the preceding write.
    // ignore: prefer-moving-to-variable
    expect((await readFile('book/1')).strokes.map((s) => s.id), [
      'debounced',
      'retired',
    ]);
    expect(calls, 2);
  });

  test(
    'should_keep_existing_file_and_continue_queue_when_transform_throws',
    () async {
      await manager.saveScribble(
        'book/1',
        _scribble('original'),
        immediate: true,
      );
      manager.persistenceTransform = (_, _) async =>
          throw StateError('unavailable');
      expect(
        await manager.saveScribble(
          'book/1',
          _scribble('unsafe'),
          immediate: true,
        ),
        isFalse,
      );
      // Re-read the file after a different persistence attempt.
      // ignore: prefer-moving-to-variable
      expect((await readFile('book/1')).strokes.single.id, 'original');
      manager.persistenceTransform = null;
      expect(
        await manager.saveScribble(
          'book/1',
          _scribble('next'),
          immediate: true,
        ),
        isTrue,
      );
      // Re-read the file after a different persistence attempt.
      // ignore: prefer-moving-to-variable
      expect((await readFile('book/1')).strokes.single.id, 'next');
    },
  );

  test('should_serialize_same_key_without_blocking_other_keys', () async {
    final entered = Completer<void>();
    final release = Completer<void>();
    final calls = <String>[];
    manager.persistenceTransform = (key, snapshot) async {
      final id = snapshot.strokes.single.id;
      calls.add(id);
      if (id == 'first') {
        entered.complete();
        await release.future;
      }
      return snapshot;
    };
    final first = manager.saveScribble(
      'book/1',
      _scribble('first'),
      immediate: true,
    );
    await entered.future;
    final secondSnapshot = _scribble('second');
    final second = manager.saveScribble(
      'book/1',
      secondSnapshot,
      immediate: true,
    );
    secondSnapshot.strokes.single.id = 'mutated';
    expect(
      await manager.saveScribble('book/2', _scribble('other'), immediate: true),
      isTrue,
    );
    expect(calls, ['first', 'other']);
    release.complete();
    expect(await first, isTrue);
    expect(await second, isTrue);
    expect((await readFile('book/1')).strokes.single.id, 'second');
    expect(calls, ['first', 'other', 'second']);
  });

  for (final byPrefix in [false, true]) {
    test(
      'should_cancel_inflight_transform_before_delete_prefix_$byPrefix',
      () async {
        await manager.saveScribble(
          'user/book/1',
          _scribble('original'),
          immediate: true,
        );
        final entered = Completer<void>();
        final release = Completer<void>();
        manager.persistenceTransform = (_, snapshot) async {
          entered.complete();
          await release.future;
          return snapshot;
        };
        final saving = manager.saveScribble(
          'user/book/1',
          _scribble('late'),
          immediate: true,
        );
        await entered.future;
        final deleting = byPrefix
            ? manager.deleteScribblesByPrefix('user')
            : manager.deleteScribble('user/book/1');
        release.complete();
        expect(await saving, isFalse);
        expect(await deleting, isTrue);
        expect(
          await File('${directory.path}/scribbles/user/book/1.bin').exists(),
          isFalse,
        );
      },
    );
  }

  for (final byPrefix in [false, true]) {
    test('should_save_after_delete_barrier_prefix_$byPrefix', () async {
      final entered = Completer<void>();
      final release = Completer<void>();
      final calls = <String>[];
      manager.persistenceTransform = (_, snapshot) async {
        final id = snapshot.strokes.single.id;
        calls.add(id);
        if (id == 'old') {
          entered.complete();
          await release.future;
        }
        return snapshot;
      };
      final old = manager.saveScribble(
        'user/book/1',
        _scribble('old'),
        immediate: true,
      );
      await entered.future;
      final deleting = byPrefix
          ? manager.deleteScribblesByPrefix('user')
          : manager.deleteScribble('user/book/1');
      final next = manager.saveScribble(
        'user/book/1',
        _scribble('new'),
        immediate: true,
      );
      final another = byPrefix
          ? manager.saveScribble(
              'user/book/2',
              _scribble('other'),
              immediate: true,
            )
          : Future.value(true);
      await Future<void>.delayed(Duration.zero);
      expect(calls, ['old']);
      release.complete();
      expect(await old, isFalse);
      expect(await deleting, isTrue);
      expect(await next, isTrue);
      expect(await another, isTrue);
      expect((await readFile('user/book/1')).strokes.single.id, 'new');
      if (byPrefix)
        expect((await readFile('user/book/2')).strokes.single.id, 'other');
    });
  }

  test('should_order_overlapping_prefix_deletes_before_new_save', () async {
    final entered = Completer<void>();
    final release = Completer<void>();
    manager.persistenceTransform = (_, snapshot) async {
      if (snapshot.strokes.single.id == 'old') {
        entered.complete();
        await release.future;
      }
      return snapshot;
    };
    final old = manager.saveScribble(
      'user/book/1',
      _scribble('old'),
      immediate: true,
    );
    await entered.future;
    final parent = manager.deleteScribblesByPrefix('user');
    final child = manager.deleteScribblesByPrefix('user/book');
    final next = manager.saveScribble(
      'user/book/1',
      _scribble('new'),
      immediate: true,
    );
    release.complete();
    expect(await old, isFalse);
    expect(await parent, isTrue);
    expect(await child, isTrue);
    expect(await next, isTrue);
    expect((await readFile('user/book/1')).strokes.single.id, 'new');
  });

  test('should_cancel_inflight_transform_when_manager_is_disposed', () async {
    final other = ScribbleCacheManager();
    final entered = Completer<void>();
    final release = Completer<void>();
    other.persistenceTransform = (_, snapshot) async {
      entered.complete();
      await release.future;
      return snapshot;
    };
    final pending = other.saveScribble(
      'book/1',
      _scribble('late'),
      immediate: true,
    );
    await entered.future;
    other.dispose();
    release.complete();
    expect(await pending, isFalse);
    expect(
      await File('${directory.path}/scribbles/book/1.bin').exists(),
      isFalse,
    );
  });

  test('should_keep_transform_scoped_to_manager_instance', () async {
    final other = ScribbleCacheManager();
    try {
      manager.persistenceTransform = (_, snapshot) async {
        snapshot.strokes.add(Stroke(id: 'private'));
        return snapshot;
      };
      await other.saveScribble(
        'other/1',
        _scribble('visible'),
        immediate: true,
      );
      expect((await readFile('other/1')).strokes.map((s) => s.id), ['visible']);
    } finally {
      other.dispose();
    }
  });
}

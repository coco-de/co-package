import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/io/backup/directory_note_backup_driver.dart';
import 'package:open_note/src/note/io/backup/memory_note_backup_driver.dart';
import 'package:open_note/src/note/io/backup/note_backup_driver.dart';
import 'package:open_note/src/note/io/backup/note_backup_entry.dart';
import 'package:open_note/src/note/io/backup/note_backup_exception.dart';
import 'package:open_note/src/note/io/backup/note_backup_service.dart';
import 'package:open_note/src/note/io/bundle/note_bundle_exception.dart';

Uint8List _bytes(List<int> values) => Uint8List.fromList(values);

/// A clock that moves one minute per reading.
NoteClock _ticking() {
  var time = DateTime.utc(2026, 3, 1, 10);

  return () {
    time = time.add(const Duration(minutes: 1));

    return time;
  };
}

class _FailingDeleteDriver extends MemoryNoteBackupDriver {
  @override
  Future<void> delete(String name) async =>
      throw const NoteBackupException('read only');
}

Future<MemoryNoteStore> _store() async {
  final store = MemoryNoteStore();
  await store.writeString('library.json', '{"v":1}');
  await store.writeBytes('notes/a/ink.bin', _bytes([0, 1, 2]));

  return store;
}

/// The behaviour every driver must share.
void _driverContract(NoteBackupDriver Function() create) {
  test('stores, lists and deletes backups', () async {
    final driver = create();

    await driver.put('b.json', _bytes([1, 2, 3]));
    await driver.put('a.json', _bytes([4]));
    await driver.put('a.json', _bytes([5, 6]));

    final entries = await driver.list();
    expect(entries.map((e) => (e.name, e.size)), [
      ('a.json', 2),
      ('b.json', 3),
    ]);
    expect(await driver.get('a.json'), [5, 6]);
    await driver.delete('a.json');
    await driver.delete('missing.json');
    expect(await driver.get('a.json'), isNull);
    expect((await driver.list()).map((e) => e.name), ['b.json']);
  });

  test('rejects unsafe names', () async {
    final driver = create();

    for (final name in [
      '',
      '..',
      '.hidden',
      '../out',
      'a/b',
      r'a\b',
      'line\nbreak',
    ]) {
      await expectLater(
        () async => driver.put(name, _bytes([1])),
        throwsA(isA<NoteBackupException>()),
        reason: name,
      );
      await expectLater(
        () async => driver.get(name),
        throwsA(isA<NoteBackupException>()),
        reason: name,
      );
    }
  });
}

void main() {
  group('MemoryNoteBackupDriver', () {
    _driverContract(MemoryNoteBackupDriver.new);

    test('stamps entries with the clock and copies bytes', () async {
      final driver = MemoryNoteBackupDriver(clock: () => DateTime.utc(2026));
      final bytes = _bytes([1]);
      await driver.put('a', bytes);
      bytes[0] = 9;

      expect((await driver.list()).single.modified, DateTime.utc(2026));
      final read = (await driver.get('a'))!..[0] = 7;
      expect(read, [7]);
      expect(await driver.get('a'), [1]);
    });
  });

  group('DirectoryNoteBackupDriver', () {
    late Directory root;

    setUp(() => root = Directory.systemTemp.createTempSync('note_backup_'));
    tearDown(() => root.deleteSync(recursive: true));

    _driverContract(() => DirectoryNoteBackupDriver(root));

    test('creates the directory and ignores other entries', () async {
      final folder = Directory('${root.path}/nested/backups');
      final driver = DirectoryNoteBackupDriver(folder);

      expect(await driver.list(), isEmpty);
      expect(await driver.get('a.json'), isNull);
      await driver.put('a.json', _bytes([1, 2]));
      File('${folder.path}/.a.json.tmp').writeAsBytesSync([9]);
      Directory('${folder.path}/sub').createSync();

      final entries = await driver.list();
      expect(entries.map((e) => (e.name, e.size)), [('a.json', 2)]);
      expect(
        entries.single.modified,
        File('${folder.path}/a.json').statSync().modified,
      );
      expect(
        folder.listSync().map((e) => e.uri.pathSegments.last),
        isNot(contains('a.json.tmp')),
      );
    });

    test('handles names with spaces and unicode', () async {
      final driver = DirectoryNoteBackupDriver(root);

      await driver.put('my 백업.json', _bytes([1]));

      expect((await driver.list()).single.name, 'my 백업.json');
    });

    test('wraps file system errors', () async {
      final blocker = File('${root.path}/file')..writeAsStringSync('x');
      final driver = DirectoryNoteBackupDriver(
        Directory('${blocker.path}/inside'),
      );

      await expectLater(
        driver.put('a.json', _bytes([1])),
        throwsA(
          isA<NoteBackupException>().having(
            (e) => e.cause,
            'cause',
            isA<FileSystemException>(),
          ),
        ),
      );
    });
  });

  group('NoteBackupService', () {
    test('backs up and restores the whole store', () async {
      final driver = MemoryNoteBackupDriver();
      final service = NoteBackupService(
        await _store(),
        driver,
        clock: () => DateTime.utc(2026, 11, 26, 10, 15, 30, 123),
      );

      final entry = await service.backupNow();
      final target = MemoryNoteStore();
      final restored = await NoteBackupService(
        target,
        driver,
      ).restore(entry.name);

      expect(entry.name, 'open_note_backup_20261126T101530123Z.json');
      expect(entry.size, (await driver.get(entry.name))!.length);
      expect(restored.written, ['library.json', 'notes/a/ink.bin']);
      expect(await target.readBytes('notes/a/ink.bin'), [0, 1, 2]);
    });

    test('names backups made at the same instant in order', () async {
      final service = NoteBackupService(
        await _store(),
        MemoryNoteBackupDriver(),
        clock: () => DateTime.utc(2026),
      );

      final names = [
        for (var i = 0; i < 3; i++) (await service.backupNow()).name,
      ];

      expect(names, [
        'open_note_backup_20260101T000000000Z.json',
        'open_note_backup_20260101T000000000Z_2.json',
        'open_note_backup_20260101T000000000Z_3.json',
      ]);
      expect((await service.backups()).map((e) => e.name), names.reversed);
    });

    test('concurrent backups get distinct names', () async {
      final service = NoteBackupService(
        await _store(),
        MemoryNoteBackupDriver(),
        clock: () => DateTime.utc(2026),
      );

      final entries = await Future.wait([
        service.backupNow(),
        service.backupNow(),
      ]);

      expect(entries.map((e) => e.name).toSet(), hasLength(2));
      expect(await service.backups(), hasLength(2));
    });

    test('keeps only the newest and leaves other files alone', () async {
      final driver = MemoryNoteBackupDriver();
      await driver.put('holiday.jpg', _bytes([1]));
      await driver.put('open_note_backup_manual.json', _bytes([2]));
      final service = NoteBackupService(
        await _store(),
        driver,
        clock: _ticking(),
        retention: 3,
      );
      final made = [
        for (var i = 0; i < 5; i++) (await service.backupNow()).name,
      ];

      expect((await service.backups()).map((e) => e.name), [
        made[4],
        made[3],
        made[2],
      ]);
      expect(
        (await driver.list()).map((e) => e.name),
        containsAll(<String>['holiday.jpg', 'open_note_backup_manual.json']),
      );
      expect(await service.prune(), isEmpty);
    });

    test('prune reports what it deleted; retention is at least 1', () async {
      final driver = MemoryNoteBackupDriver();
      final keepAll = NoteBackupService(
        await _store(),
        driver,
        clock: _ticking(),
        retention: 100,
      );
      final first = (await keepAll.backupNow()).name;
      final second = (await keepAll.backupNow()).name;

      final strict = NoteBackupService(await _store(), driver, retention: 0);

      expect(strict.retention, 1);
      expect(await strict.prune(), [first]);
      expect((await strict.backups()).single.name, second);
    });

    test('keeps the backup when pruning fails', () async {
      final service = NoteBackupService(
        await _store(),
        _FailingDeleteDriver(),
        clock: _ticking(),
        retention: 1,
      );

      await service.backupNow();
      final second = await service.backupNow();

      expect((await service.backups()).first.name, second.name);
      await expectLater(service.prune(), throwsA(isA<NoteBackupException>()));
      // A failed operation does not block the queue.
      await service.backupNow();
      expect(await service.backups(), hasLength(3));
    });

    test('restore keeps newer files unless overwriting', () async {
      final store = await _store();
      final service = NoteBackupService(store, MemoryNoteBackupDriver());
      final entry = await service.backupNow();
      await store.writeString('library.json', 'changed');
      await store.writeString('new.json', 'added later');
      await store.delete('notes/a/ink.bin');

      final merged = await service.restore(entry.name);

      expect(merged.written, ['notes/a/ink.bin']);
      expect(await store.readString('library.json'), 'changed');

      await service.restore(entry.name, overwrite: true);

      expect(await store.readString('library.json'), '{"v":1}');
      expect(await store.readString('new.json'), 'added later');
    });

    test('restore reports missing and damaged backups', () async {
      final driver = MemoryNoteBackupDriver();
      final service = NoteBackupService(MemoryNoteStore(), driver);

      await expectLater(
        service.restore('nothing.json'),
        throwsA(isA<NoteBackupException>()),
      );
      await driver.put('bad.json', _bytes([1, 2, 3]));
      await expectLater(
        service.restore('bad.json'),
        throwsA(isA<NoteBundleException>()),
      );
    });
  });

  group('NoteBackupEntry', () {
    final entry = NoteBackupEntry(
      name: 'a.json',
      size: 12,
      modified: DateTime.utc(2026, 5, 6),
    );

    test('round trips through JSON', () {
      expect(NoteBackupEntry.fromJson(entry.toJson()), entry);
      expect(entry.hashCode, entry.copyWith().hashCode);
      expect(entry.copyWith(size: 1), isNot(entry));
      expect('$entry', contains('a.json'));
    });

    test('JSON is lenient', () {
      final read = NoteBackupEntry.fromJson({'size': -5, 'modified': 'soon'});

      expect(read.name, '');
      expect(read.size, 0);
      expect(
        read.modified,
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      );
    });

    test('exceptions describe themselves', () {
      expect(
        '${const NoteBackupException('failed', cause: 'disk')}',
        'NoteBackupException: failed (disk)',
      );
    });
  });
}

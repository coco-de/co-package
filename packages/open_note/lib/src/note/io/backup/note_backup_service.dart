import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/io/backup/note_backup_driver.dart';
import 'package:open_note/src/note/io/backup/note_backup_entry.dart';
import 'package:open_note/src/note/io/backup/note_backup_exception.dart';
import 'package:open_note/src/note/io/bundle/note_bundle_codec.dart';
import 'package:open_note/src/note/io/bundle/note_bundle_unpack_result.dart';

/// Backs a whole [NoteStore] up to a [NoteBackupDriver] as bundles, restores
/// them and keeps the newest [retention].
///
/// Backups are named `open_note_backup_<UTC yyyyMMddTHHmmssSSSZ>[_n].json`.
/// Only files with such names count as backups of this service: [prune] never
/// deletes anything else in the driver. Operations run one at a time.
class NoteBackupService {
  /// A service backing [store] up to [driver]. A [retention] below 1 is
  /// treated as 1.
  NoteBackupService(
    this.store,
    this.driver, {
    NoteClock clock = systemNoteClock,
    int retention = 10,
  }) : _clock = clock,
       retention = retention < 1 ? 1 : retention;

  static final RegExp _name = RegExp(
    r'^open_note_backup_(\d{8}T\d{9}Z)(?:_(\d+))?\.json$',
  );

  /// What is backed up.
  final NoteStore store;

  /// Where backups go.
  final NoteBackupDriver driver;

  /// How many backups [prune] keeps.
  final int retention;

  final NoteClock _clock;
  Future<void> _queue = Future<void>.value();

  /// Packs the store, stores it as a new backup and prunes old ones (a pruning
  /// failure is ignored: the backup itself succeeded and the next prune
  /// retries).
  Future<NoteBackupEntry> backupNow() => _serialized(() async {
    final bytes = await NoteBundleCodec.pack(store);
    final now = _clock();
    final name = _nextName(now, await backups());
    await driver.put(name, bytes);
    try {
      await _prune();
    } on Exception {
      // Reported by the next explicit prune.
    }

    return NoteBackupEntry(name: name, size: bytes.length, modified: now);
  });

  /// Writes the files of backup [name] into the store. Existing files are kept
  /// unless [overwrite] is true; files not in the backup are never deleted.
  ///
  /// Throws [NoteBackupException] when there is no such backup and
  /// `NoteBundleException` when it is damaged.
  Future<NoteBundleUnpackResult> restore(
    String name, {
    bool overwrite = false,
  }) => _serialized(() async {
    final bytes = await driver.get(name);
    if (bytes == null) throw NoteBackupException('no backup named $name');

    return NoteBundleCodec.unpack(bytes, store, overwrite: overwrite);
  });

  /// This service's backups, newest first (by the time in their names).
  Future<List<NoteBackupEntry>> backups() async {
    final entries = [
      for (final entry in await driver.list())
        if (_name.hasMatch(entry.name)) entry,
    ];

    return entries..sort((a, b) => _compare(b.name, a.name));
  }

  /// Deletes all but the newest [retention] backups and returns the deleted
  /// names.
  Future<List<String>> prune() => _serialized(_prune);

  Future<List<String>> _prune() async {
    final stale = [
      for (final entry in (await backups()).skip(retention)) entry.name,
    ];
    for (final name in stale) {
      await driver.delete(name);
    }

    return stale;
  }

  Future<T> _serialized<T>(Future<T> Function() operation) {
    final result = _queue.then((_) => operation());
    _queue = result.then<void>((_) {}, onError: (Object _) {});

    return result;
  }

  static String _nextName(DateTime now, List<NoteBackupEntry> existing) {
    final stamp = _stamp(now);
    var highest = 0;
    for (final entry in existing) {
      final match = _name.firstMatch(entry.name)!;
      if (match.group(1) != stamp) continue;
      final sequence = _sequence(match);
      if (sequence > highest) highest = sequence;
    }
    final suffix = highest == 0 ? '' : '_${highest + 1}';

    return 'open_note_backup_$stamp$suffix.json';
  }

  static String _stamp(DateTime time) {
    final utc = time.toUtc();
    String digits(int value, [int width = 2]) =>
        value.toString().padLeft(width, '0');

    return '${digits(utc.year, 4)}${digits(utc.month)}${digits(utc.day)}T'
        '${digits(utc.hour)}${digits(utc.minute)}${digits(utc.second)}'
        '${digits(utc.millisecond, 3)}Z';
  }

  static int _sequence(RegExpMatch match) =>
      int.tryParse(match.group(2) ?? '') ?? 1;

  /// Orders backup names by time, then by their same-instant sequence.
  static int _compare(String first, String second) {
    final a = _name.firstMatch(first)!;
    final b = _name.firstMatch(second)!;
    final byTime = a.group(1)!.compareTo(b.group(1)!);

    return byTime != 0 ? byTime : _sequence(a).compareTo(_sequence(b));
  }
}

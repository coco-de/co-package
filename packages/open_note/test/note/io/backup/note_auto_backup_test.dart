import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/io/backup/memory_note_backup_driver.dart';
import 'package:open_note/src/note/io/backup/note_auto_backup.dart';
import 'package:open_note/src/note/io/backup/note_backup_exception.dart';
import 'package:open_note/src/note/io/backup/note_backup_service.dart';

/// Virtual time: timers fire only when [elapse] reaches them.
class _FakeScheduler {
  Duration now = Duration.zero;
  final List<_FakeTimer> timers = [];

  Timer call(Duration delay, void Function() callback) {
    final timer = _FakeTimer(now + delay, callback);
    timers.add(timer);

    return timer;
  }

  Iterable<_FakeTimer> get active => timers.where((timer) => timer.isActive);

  Future<void> elapse(Duration duration) async {
    final end = now + duration;
    while (true) {
      final due = active.where((timer) => timer.due <= end).toList()
        ..sort((a, b) => a.due.compareTo(b.due));
      if (due.isEmpty) break;
      now = due.first.due;
      due.first.fire();
      await _settle();
    }
    now = end;
    await _settle();
  }
}

class _FakeTimer implements Timer {
  _FakeTimer(this.due, this._callback);

  final Duration due;
  final void Function() _callback;

  @override
  bool isActive = true;

  @override
  int get tick => 0;

  void fire() {
    isActive = false;
    _callback();
  }

  @override
  void cancel() => isActive = false;
}

/// Lets pending futures (the in-memory store and driver) complete.
Future<void> _settle() => Future<void>.delayed(Duration.zero);

/// A driver whose writes can fail or wait.
class _ControlledDriver extends MemoryNoteBackupDriver {
  int failures = 0;
  Completer<void>? gate;
  int puts = 0;

  @override
  Future<void> put(String name, Uint8List bytes) async {
    await gate?.future;
    if (failures > 0) {
      failures--;
      throw const NoteBackupException('disk full');
    }
    puts++;
    await super.put(name, bytes);
  }
}

const _debounce = Duration(seconds: 20);
const _interval = Duration(minutes: 1);

void main() {
  late _FakeScheduler scheduler;
  late _ControlledDriver driver;
  late NoteBackupService service;
  late List<Object> errors;
  var minute = 0;

  setUp(() async {
    scheduler = _FakeScheduler();
    driver = _ControlledDriver();
    final store = MemoryNoteStore();
    await store.writeString('a', 'b');
    service = NoteBackupService(
      store,
      driver,
      clock: () => DateTime.utc(2026, 1, 1, 0, minute++),
    );
    errors = [];
  });

  NoteAutoBackup autoBackup({
    Duration interval = _interval,
    bool backupWhenUnchanged = false,
  }) {
    final auto = NoteAutoBackup(
      service,
      interval: interval,
      debounce: _debounce,
      scheduler: scheduler.call,
      backupWhenUnchanged: backupWhenUnchanged,
      onError: (error, _) => errors.add(error),
    );
    addTearDown(auto.dispose);

    return auto;
  }

  test('backs up once, a debounce after the last change', () async {
    final auto = autoBackup(interval: Duration.zero);

    auto.markChanged();
    await scheduler.elapse(const Duration(seconds: 10));
    auto.markChanged();
    await scheduler.elapse(const Duration(seconds: 19));
    expect(driver.puts, 0);
    expect(auto.isDirty, isTrue);

    await scheduler.elapse(const Duration(seconds: 1));

    expect(driver.puts, 1);
    expect(auto.isDirty, isFalse);
    expect(auto.lastBackup!.name, startsWith('open_note_backup_'));
    expect(scheduler.active, isEmpty, reason: 'no interval, nothing pending');
  });

  test('the interval backs up while changes keep coming', () async {
    final auto = autoBackup();

    for (var i = 0; i < 6; i++) {
      auto.markChanged();
      await scheduler.elapse(const Duration(seconds: 15));
    }

    expect(driver.puts, 1, reason: 'the interval fired at 60 s');
  });

  test('idle intervals back up only when asked to', () async {
    autoBackup();
    await scheduler.elapse(const Duration(minutes: 3));
    expect(driver.puts, 0);
  });

  test('idle intervals can back up unchanged stores', () async {
    autoBackup(backupWhenUnchanged: true);

    await scheduler.elapse(const Duration(minutes: 3));

    expect(driver.puts, 3);
  });

  test('a failure stays pending and is retried', () async {
    final auto = autoBackup();
    driver.failures = 1;

    auto.markChanged();
    await scheduler.elapse(_debounce);

    expect(auto.lastError, isA<NoteBackupException>());
    expect(errors, hasLength(1));
    expect(auto.isDirty, isTrue);
    expect(auto.isBackingUp, isFalse);

    await scheduler.elapse(_interval);

    expect(driver.puts, 1);
    expect(auto.lastError, isNull);
    expect(auto.isDirty, isFalse);
  });

  test('a change during a backup is backed up afterwards', () async {
    final auto = autoBackup(interval: Duration.zero);
    driver.gate = Completer<void>();

    auto.markChanged();
    await scheduler.elapse(_debounce);
    expect(auto.isBackingUp, isTrue);
    auto.markChanged();
    // The debounce of the second change fires while still writing.
    await scheduler.elapse(_debounce);
    driver.gate!.complete();
    driver.gate = null;
    await _settle();

    expect(driver.puts, 1);
    expect(auto.isDirty, isTrue);

    await scheduler.elapse(_debounce);

    expect(driver.puts, 2);
    expect(auto.isDirty, isFalse);
  });

  test('flush backs up pending changes at once', () async {
    final auto = autoBackup(interval: Duration.zero);

    expect(await auto.flush(), isNull, reason: 'nothing to do');
    auto.markChanged();
    final entry = await auto.flush();

    expect(entry, isNotNull);
    expect(driver.puts, 1);
    expect(scheduler.active, isEmpty, reason: 'the debounce was cancelled');
    await scheduler.elapse(_debounce);
    expect(driver.puts, 1);
  });

  test('flush returns null when the backup fails', () async {
    final auto = autoBackup(interval: Duration.zero);
    driver.failures = 1;
    auto.markChanged();

    expect(await auto.flush(), isNull);
    expect(auto.isDirty, isTrue);
    expect(await auto.flush(), isNotNull);
  });

  test('flush waits for a running backup', () async {
    final auto = autoBackup(interval: Duration.zero);
    driver.gate = Completer<void>();
    auto.markChanged();
    await scheduler.elapse(_debounce);
    auto.markChanged();
    final flushing = auto.flush();
    driver.gate!.complete();
    driver.gate = null;

    expect(await flushing, isNotNull);
    expect(driver.puts, 2);
  });

  test('notifies when dirtiness and activity change', () async {
    final auto = autoBackup(interval: Duration.zero);
    final states = <(bool, bool)>[];
    auto.addListener(() => states.add((auto.isDirty, auto.isBackingUp)));

    auto
      ..markChanged()
      ..markChanged();
    await scheduler.elapse(_debounce);

    expect(states, [(true, false), (true, true), (false, false)]);
  });

  test('dispose cancels timers and ignores later changes', () async {
    final auto = NoteAutoBackup(
      service,
      interval: _interval,
      debounce: _debounce,
      scheduler: scheduler.call,
    );
    auto.markChanged();

    auto
      ..dispose()
      ..dispose()
      ..markChanged();

    expect(scheduler.active, isEmpty);
    expect(await auto.flush(), isNull);
    await scheduler.elapse(const Duration(hours: 1));
    expect(driver.puts, 0);
  });

  test('disposing during a backup is safe', () async {
    final auto = NoteAutoBackup(
      service,
      interval: Duration.zero,
      debounce: _debounce,
      scheduler: scheduler.call,
    );
    driver.gate = Completer<void>();
    auto.markChanged();
    await scheduler.elapse(_debounce);

    auto.dispose();
    driver.gate!.complete();
    await _settle();

    expect(driver.puts, 1);
    expect(scheduler.active, isEmpty);
  });

  test('uses real timers by default', () {
    final auto = NoteAutoBackup(service);

    expect(auto.interval, const Duration(minutes: 15));
    expect(auto.debounce, const Duration(seconds: 20));
    auto.dispose();
  });
}

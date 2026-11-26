import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:open_note/src/note/io/backup/note_backup_entry.dart';
import 'package:open_note/src/note/io/backup/note_backup_service.dart';

/// Starts a one-shot timer; `Timer.new` in production, a fake in tests.
typedef NoteBackupScheduler =
    Timer Function(Duration delay, void Function() callback);

/// Backs up automatically with a [NoteBackupService]:
///
/// - [debounce] after the last [markChanged] (each change restarts the wait);
/// - every [interval], so continuous editing is still backed up — only when
///   something changed since the last successful backup, unless
///   [backupWhenUnchanged] is true.
///
/// Only one backup runs at a time. A change made while one is running is backed
/// up after another [debounce]. A failure keeps the change pending, is reported
/// through [lastError] and [onError], and is retried at the next trigger.
/// Notifies listeners when [isDirty], [isBackingUp] or the last result change.
class NoteAutoBackup extends ChangeNotifier {
  /// Starts watching; the interval timer starts at once. A zero [interval]
  /// disables periodic backups.
  NoteAutoBackup(
    this.service, {
    this.interval = const Duration(minutes: 15),
    this.debounce = const Duration(seconds: 20),
    NoteBackupScheduler scheduler = Timer.new,
    this.backupWhenUnchanged = false,
    this.onError,
  }) : _scheduler = scheduler {
    _armInterval();
  }

  /// Makes the backups.
  final NoteBackupService service;

  /// Period of the interval trigger.
  final Duration interval;

  /// Quiet time after a change before it is backed up.
  final Duration debounce;

  /// Whether interval ticks back up even without changes.
  final bool backupWhenUnchanged;

  /// Told about every failed automatic backup.
  final void Function(Object error, StackTrace stackTrace)? onError;

  final NoteBackupScheduler _scheduler;
  Timer? _debounceTimer;
  Timer? _intervalTimer;
  Future<void>? _running;
  NoteBackupEntry? _lastBackup;
  Object? _lastError;
  int _revision = 0;
  int _savedRevision = 0;
  bool _disposed = false;

  /// Whether there are changes not yet backed up.
  bool get isDirty => _revision != _savedRevision;

  /// Whether a backup is running.
  bool get isBackingUp => _running != null;

  /// The newest backup made by this instance.
  NoteBackupEntry? get lastBackup => _lastBackup;

  /// The error of the last backup, or `null` after a success.
  Object? get lastError => _lastError;

  /// Records that the store changed and restarts the debounce wait. No effect
  /// after [dispose].
  void markChanged() {
    if (_disposed) return;
    final wasDirty = isDirty;
    _revision++;
    _armDebounce();
    if (!wasDirty) notifyListeners();
  }

  /// Backs up pending changes now (for example when the app is paused) and
  /// returns the new backup, or `null` when there was nothing to back up or it
  /// failed (see [lastError]). No effect after [dispose].
  Future<NoteBackupEntry?> flush() async {
    while (_running != null) {
      await _running;
    }
    if (_disposed || !isDirty) return null;
    _debounceTimer?.cancel();
    _debounceTimer = null;
    final before = _lastBackup;
    await _backUp();

    return identical(before, _lastBackup) ? null : _lastBackup;
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _debounceTimer?.cancel();
    _intervalTimer?.cancel();
    super.dispose();
  }

  void _armDebounce() {
    _debounceTimer?.cancel();
    _debounceTimer = _scheduler(debounce, () {
      _debounceTimer = null;
      if (isDirty) unawaited(_backUp());
    });
  }

  void _armInterval() {
    if (_disposed || interval <= Duration.zero) return;
    _intervalTimer = _scheduler(interval, () {
      _armInterval();
      if (isDirty || backupWhenUnchanged) unawaited(_backUp());
    });
  }

  /// Starts a backup, or joins the one already running (which re-arms the
  /// debounce if changes remain).
  Future<void> _backUp() {
    if (_disposed) return Future<void>.value();

    return _running ?? _start();
  }

  Future<void> _start() {
    final done = Completer<void>();
    _running = done.future;
    unawaited(_run(done));

    return done.future;
  }

  Future<void> _run(Completer<void> done) async {
    notifyListeners();
    final revision = _revision;
    try {
      final entry = await service.backupNow();
      _lastBackup = entry;
      _lastError = null;
      _savedRevision = revision;
    } on Object catch (error, stackTrace) {
      _lastError = error;
      onError?.call(error, stackTrace);
    } finally {
      _running = null;
      done.complete();
      if (!_disposed) {
        if (_revision != revision && _debounceTimer == null) _armDebounce();
        notifyListeners();
      }
    }
  }
}

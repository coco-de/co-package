import 'dart:async';

import 'package:co_demo_prefs/co_demo_prefs.dart';

/// Prepares a language before it is shown — for example warming the display
/// projection of the visible records, or loading deferred data.
typedef DemoLocalePreparer = FutureOr<void> Function(DemoLocale locale);

/// Called when a language becomes current. Switch the UI language and the
/// display projection here, in the same step.
typedef DemoLocaleCommit = void Function(DemoLocale previous, DemoLocale next);

/// Applies UI language requests so that **only the latest request wins**.
///
/// Every [request] starts a new generation. When its preparation finishes,
/// the language is committed only if no newer request arrived in the
/// meantime; older results are dropped. A failed preparation keeps the
/// current language and records [lastError]. While a request is preparing,
/// [isSwitching] is `true`, so the UI can show a clear loading state instead
/// of mixing the new UI language with old data.
class DemoLocaleSwitcher {
  /// Creates a switcher that starts at [initial].
  DemoLocaleSwitcher({
    required DemoLocale initial,
    DemoLocalePreparer? prepare,
    DemoLocaleCommit? onCommit,
  }) : _current = initial,
       _prepare = prepare,
       _onCommit = onCommit;

  final DemoLocalePreparer? _prepare;
  final DemoLocaleCommit? _onCommit;
  final StreamController<DemoLocale> _commits =
      StreamController<DemoLocale>.broadcast(sync: true);

  DemoLocale _current;
  DemoLocale? _pending;
  int _generation = 0;
  Object? _lastError;
  bool _disposed = false;

  /// The language currently shown.
  DemoLocale get current => _current;

  /// The language being prepared, or `null`.
  DemoLocale? get pending => _pending;

  /// Whether a request is being prepared.
  bool get isSwitching => _pending != null;

  /// The error of the last failed preparation, cleared by the next commit.
  Object? get lastError => _lastError;

  /// Emits each committed language, synchronously, after [DemoLocaleCommit].
  Stream<DemoLocale> get commits => _commits.stream;

  /// Requests [next] and completes with the language that is current once
  /// this request is settled — [next] when it was committed, otherwise the
  /// language that stayed (a newer request won, or preparation failed).
  Future<DemoLocale> request(DemoLocale next) async {
    if (_disposed) return _current;
    final generation = ++_generation;
    if (next == _current) {
      // Cancels an older pending request: the latest request is "stay here".
      _pending = null;
      return _current;
    }
    _pending = next;
    try {
      await _prepare?.call(next);
    } on Object catch (error) {
      if (generation == _generation && !_disposed) {
        _pending = null;
        _lastError = error;
      }
      return _current;
    }
    if (generation != _generation || _disposed) return _current;
    final previous = _current;
    _current = next;
    _pending = null;
    _lastError = null;
    _onCommit?.call(previous, next);
    _commits.add(next);
    return _current;
  }

  /// Stops accepting requests and closes [commits].
  Future<void> dispose() async {
    _disposed = true;
    _pending = null;
    await _commits.close();
  }
}

import 'package:flutter/foundation.dart';

/// Base class of the nav controllers (bookmarks, outline, excerpts, tags, the
/// search index and the excerpt flash).
///
/// It is a [ChangeNotifier] that tolerates use after [dispose]: every mutator of
/// a subclass checks [isDisposed] first and does nothing (returning `null`,
/// `false` or `0`), and [dispose] may be called more than once. Queries keep
/// working. Subclasses notify only on real changes.
abstract class NoteNavNotifier extends ChangeNotifier {
  bool _disposed = false;

  /// Whether [dispose] has run.
  bool get isDisposed => _disposed;

  /// Notifies listeners, unless the notifier has been disposed.
  @protected
  void notifyChanged() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    super.dispose();
  }
}

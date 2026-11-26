import 'package:flutter/foundation.dart';

/// Base class of the view controllers.
///
/// After [dispose] every mutating method of a subclass returns without doing
/// anything and nothing notifies, so a late gesture callback or timer cannot
/// crash a disposed controller. Calling [dispose] twice is harmless.
abstract class NoteViewNotifier extends ChangeNotifier {
  bool _disposed = false;

  /// Whether [dispose] has been called.
  bool get isDisposed => _disposed;

  /// Notifies the listeners unless the controller is disposed.
  @protected
  void notifyChanged() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    super.dispose();
  }
}

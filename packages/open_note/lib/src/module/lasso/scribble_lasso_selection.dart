import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// open_note: what the lasso holds in a `ScribbleWidget`, for tools outside the
/// widget (restyling, moving to another layer). Give one to
/// `ScribbleWidget.lassoSelection`; it follows the widget it is given to.
class ScribbleLassoSelection extends ChangeNotifier {
  List<int> _strokes = const [];
  List<int> _texts = const [];
  VoidCallback? _clearer;
  bool _isDisposed = false;
  bool _notificationPending = false;

  /// Indexes into the notifier's strokes (a lasso outline may be among them).
  List<int> get strokeIndexes => _strokes;

  /// Indexes into the notifier's text drawables.
  List<int> get textIndexes => _texts;

  bool get isEmpty => _strokes.isEmpty && _texts.isEmpty;

  /// Drops the selection in the widget. Call it after changing the selected
  /// content from outside in a way that moves indexes.
  void clear() {
    _clearer?.call();
    publish(const [], const []);
  }

  /// Called by the widget: how [clear] reaches it.
  void attach(VoidCallback clearer) => _clearer = clearer;

  /// Called by the widget when it stops using this selection.
  void detach(VoidCallback clearer) {
    if (_clearer != clearer) return;
    _clearer = null;
    publish(const [], const []);
  }

  /// Called by the widget whenever its selection may have changed.
  void publish(List<int> strokeIndexes, List<int> textIndexes) {
    if (_isDisposed ||
        (listEquals(strokeIndexes, _strokes) &&
            listEquals(textIndexes, _texts))) {
      return;
    }
    _strokes = List.unmodifiable(strokeIndexes);
    _texts = List.unmodifiable(textIndexes);
    _notify();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _clearer = null;
    super.dispose();
  }

  /// Listeners may rebuild widgets, so a change made while the framework is
  /// building (a widget being disposed) is announced after the frame.
  void _notify() {
    final scheduler = SchedulerBinding.instance;
    if (scheduler.schedulerPhase != SchedulerPhase.persistentCallbacks) {
      notifyListeners();

      return;
    }
    if (_notificationPending) return;
    _notificationPending = true;
    scheduler.addPostFrameCallback((_) {
      _notificationPending = false;
      if (!_isDisposed) notifyListeners();
    });
  }
}

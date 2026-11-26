import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/view/note_view_notifier.dart';

/// Whether zooming is locked. The host turns pinch zoom off while [locked]
/// (for example `InteractiveViewer.scaleEnabled: !lock.locked`); panning is
/// unaffected.
///
/// JSON: `{locked}`.
class NoteZoomLock extends NoteViewNotifier {
  /// Starts unlocked unless [locked].
  NoteZoomLock({bool locked = false}) : _locked = locked;

  /// Restores [toJson]; anything malformed means unlocked.
  factory NoteZoomLock.fromJson(Object? value) {
    final map = NoteJson.asMap(value) ?? <String, Object?>{};

    return NoteZoomLock(locked: NoteJson.boolean(map, 'locked'));
  }

  bool _locked;

  /// Whether zooming is locked.
  bool get locked => _locked;

  /// Locks or unlocks.
  void setLocked(bool locked) {
    if (isDisposed || locked == _locked) return;
    _locked = locked;
    notifyChanged();
  }

  /// Flips [locked].
  void toggle() => setLocked(!_locked);

  /// The persisted form `{locked}`.
  JsonMap toJson() => {'locked': _locked};
}

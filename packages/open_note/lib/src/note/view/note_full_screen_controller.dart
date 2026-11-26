import 'package:open_note/src/note/view/note_view_notifier.dart';

/// Whether the toolbars and other chrome are hidden so the page fills the
/// screen. Pair it with `NoteChromeVisibility`. Not persisted: a note always
/// opens with its chrome. System bars are the host's business.
class NoteFullScreenController extends NoteViewNotifier {
  /// Starts with the chrome shown unless [chromeHidden].
  NoteFullScreenController({bool chromeHidden = false})
    : _chromeHidden = chromeHidden;

  bool _chromeHidden;

  /// Whether the chrome is hidden (full screen).
  bool get chromeHidden => _chromeHidden;

  /// Hides or shows the chrome.
  void setChromeHidden(bool hidden) {
    if (isDisposed || hidden == _chromeHidden) return;
    _chromeHidden = hidden;
    notifyChanged();
  }

  /// Flips [chromeHidden].
  void toggle() => setChromeHidden(!_chromeHidden);

  /// Enters full screen.
  void hide() => setChromeHidden(true);

  /// Leaves full screen.
  void show() => setChromeHidden(false);
}

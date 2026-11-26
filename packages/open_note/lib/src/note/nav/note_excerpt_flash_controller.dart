import 'package:open_note/src/note/nav/note_flash_ticker.dart';
import 'package:open_note/src/note/nav/note_nav_notifier.dart';
import 'package:open_note/src/note/nav/note_scheduler_flash_ticker.dart';

/// Drives the "jump to an excerpt, then fade its highlight" effect.
///
/// [flash] names an excerpt and sets [progress] to `1`; over [duration] the
/// progress falls linearly to `0`, after which the controller is idle again
/// ([excerptId] is `null`). Draw it with `NoteExcerptFlashOverlay`. Jumping to
/// the page is the host's job.
class NoteExcerptFlashController extends NoteNavNotifier {
  /// Creates an idle controller fading over [duration] (1200 ms by default, must
  /// be positive). [ticker] drives time; the default ticks once per frame. The
  /// controller disposes the ticker.
  NoteExcerptFlashController({
    this.duration = const Duration(milliseconds: 1200),
    NoteFlashTicker? ticker,
  }) : assert(duration > Duration.zero, 'duration must be positive'),
       _ticker = ticker ?? NoteSchedulerFlashTicker();

  /// How long one flash takes to fade out.
  final Duration duration;

  final NoteFlashTicker _ticker;
  String? _excerptId;
  double _progress = 0;

  /// The excerpt being flashed, or `null` when idle.
  String? get excerptId => _excerptId;

  /// Remaining strength of the highlight, from `1` (just started) to `0`.
  double get progress => _progress;

  /// Whether a flash is running.
  bool get isFlashing => _excerptId != null;

  /// Starts (or restarts, at full strength) the flash of [excerptId]; an empty
  /// id is ignored.
  void flash(String excerptId) {
    if (isDisposed || excerptId.isEmpty) return;
    final changed = _excerptId != excerptId || _progress != 1;
    _excerptId = excerptId;
    _progress = 1;
    _ticker.start(_onTick);
    if (changed) notifyChanged();
  }

  /// Ends the flash now.
  void cancel() {
    if (isDisposed || _excerptId == null) return;
    _finish();
  }

  void _onTick(Duration elapsed) {
    if (isDisposed || _excerptId == null) return;
    final fraction = elapsed.inMicroseconds / duration.inMicroseconds;
    final next = (1 - fraction).clamp(0.0, 1.0);
    if (next <= 0) {
      _finish();
    } else if (next != _progress) {
      _progress = next;
      notifyChanged();
    }
  }

  void _finish() {
    _ticker.stop();
    _excerptId = null;
    _progress = 0;
    notifyChanged();
  }

  @override
  void dispose() {
    if (isDisposed) return;
    _ticker.dispose();
    super.dispose();
  }
}

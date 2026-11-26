import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:open_note/src/note/nav/note_flash_ticker.dart';

/// The frame-driven [NoteFlashTicker]: a Flutter [Ticker] that reports once per
/// frame (it needs the scheduler binding, which any Flutter app has).
class NoteSchedulerFlashTicker implements NoteFlashTicker {
  /// Creates an idle ticker.
  NoteSchedulerFlashTicker();

  Ticker? _ticker;
  ValueChanged<Duration>? _onTick;

  @override
  void start(ValueChanged<Duration> onTick) {
    _onTick = onTick;
    final ticker = _ticker ??= Ticker(_forward, debugLabel: 'NoteFlashTicker');
    ticker
      ..stop()
      ..start();
  }

  @override
  void stop() => _ticker?.stop();

  @override
  void dispose() {
    _ticker?.dispose();
    _ticker = null;
    _onTick = null;
  }

  void _forward(Duration elapsed) => _onTick?.call(elapsed);
}

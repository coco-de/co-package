/// What a [NoteAudioPlayer] is doing.
enum NoteAudioPlayerState {
  /// Nothing is loaded.
  idle,

  /// A source is loaded and has not played yet.
  ready,

  /// Audio is playing.
  playing,

  /// Playback stopped part-way.
  paused,

  /// Playback reached the end of the source.
  completed,
}

/// Plays audio. The package ships no audio code: the host implements this with
/// its plugin of choice (and `FakeNoteAudioPlayer` serves tests).
///
/// Failures throw `NoteAudioException` (or another [Exception]).
abstract interface class NoteAudioPlayer {
  /// The current state.
  NoteAudioPlayerState get state;

  /// The playback position. A report is also due whenever [state] changes on its
  /// own, such as on reaching the end, so that listeners can read [state] again.
  Stream<Duration> get position;

  /// Loads [source] (as stored in a recording) and rewinds, replacing what was
  /// loaded.
  Future<void> load(String source);

  /// Starts or resumes playback, restarting from the beginning after
  /// completion. Completes once playback has **started**, not when it ends:
  /// the caller waits for it before the next call, so a plugin whose `play`
  /// future lasts as long as the audio must not be awaited here.
  Future<void> play();

  /// Pauses playback; does nothing when not playing.
  Future<void> pause();

  /// Moves to [position].
  Future<void> seek(Duration position);

  /// Sets the playback rate (`1` is normal).
  Future<void> setSpeed(double speed);
}

import 'dart:async';

import 'package:open_note/src/note/study/utilities/note_audio_exception.dart';
import 'package:open_note/src/note/study/utilities/note_audio_player.dart';

/// A deterministic [NoteAudioPlayer] without sound, for tests and previews.
///
/// Nothing happens on its own: time passes only through [advance]. Positions
/// are reported synchronously, every call is recorded in [calls], and failures
/// can be provoked with [failingSources] and [loadGates].
class FakeNoteAudioPlayer implements NoteAudioPlayer {
  /// Each source lasts its entry in [durations], else [defaultDuration].
  FakeNoteAudioPlayer({
    this.defaultDuration = const Duration(seconds: 10),
    this.durations = const <String, Duration>{},
    this.failingSources = const <String>{},
  });

  /// Length of a source without an entry in [durations].
  final Duration defaultDuration;

  /// Length by source.
  final Map<String, Duration> durations;

  /// [load] throws for these sources.
  final Set<String> failingSources;

  /// The calls made, in order: `load <source>`, `play`, `pause`,
  /// `seek <milliseconds>`, `speed <speed>`.
  final List<String> calls = [];

  /// [load] of a source listed here waits until its completer completes, to
  /// test slow loading.
  final Map<String, Completer<void>> loadGates = {};

  final StreamController<Duration> _positions =
      StreamController<Duration>.broadcast(sync: true);
  NoteAudioPlayerState _state = NoteAudioPlayerState.idle;
  String? _source;
  Duration _position = Duration.zero;
  double _speed = 1;

  @override
  NoteAudioPlayerState get state => _state;

  @override
  Stream<Duration> get position => _positions.stream;

  /// The loaded source.
  String? get source => _source;

  /// The current position.
  Duration get currentPosition => _position;

  /// The current rate.
  double get speed => _speed;

  /// Length of the loaded source; zero when none is loaded.
  Duration get duration =>
      _source == null ? Duration.zero : durations[_source] ?? defaultDuration;

  @override
  Future<void> load(String source) async {
    calls.add('load $source');
    await loadGates[source]?.future;
    if (failingSources.contains(source)) {
      _source = null;
      _state = NoteAudioPlayerState.idle;
      throw NoteAudioException('cannot load $source');
    }
    _source = source;
    _position = Duration.zero;
    _state = NoteAudioPlayerState.ready;
    _report();
  }

  @override
  Future<void> play() async {
    calls.add('play');
    _requireSource();
    if (_state == NoteAudioPlayerState.completed) _position = Duration.zero;
    _state = NoteAudioPlayerState.playing;
    _report();
  }

  @override
  Future<void> pause() async {
    calls.add('pause');
    if (_state != NoteAudioPlayerState.playing) return;
    _state = NoteAudioPlayerState.paused;
    _report();
  }

  @override
  Future<void> seek(Duration position) async {
    calls.add('seek ${position.inMilliseconds}');
    _requireSource();
    _position = position < Duration.zero
        ? Duration.zero
        : (position > duration ? duration : position);
    if (_state == NoteAudioPlayerState.completed && _position < duration) {
      _state = NoteAudioPlayerState.paused;
    }
    _report();
  }

  @override
  Future<void> setSpeed(double speed) async {
    calls.add('speed $speed');
    if (!(speed > 0)) throw NoteAudioException('bad speed $speed');
    _speed = speed;
  }

  /// Lets [wallTime] pass: while playing, the position moves by that time times
  /// [speed], and playback completes at the end.
  void advance(Duration wallTime) {
    if (_state != NoteAudioPlayerState.playing) return;
    _position += wallTime * _speed;
    if (_position >= duration) {
      _position = duration;
      _state = NoteAudioPlayerState.completed;
    }
    _report();
  }

  /// Releases the position stream.
  Future<void> dispose() => _positions.close();

  void _requireSource() {
    if (_source == null) throw const NoteAudioException('nothing loaded');
  }

  void _report() {
    if (!_positions.isClosed) _positions.add(_position);
  }
}

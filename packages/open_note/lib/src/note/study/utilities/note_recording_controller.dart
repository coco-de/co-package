import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/study/utilities/note_audio_player.dart';
import 'package:open_note/src/note/study/utilities/note_recording.dart';

/// The recordings of a note and their playback through one [NoteAudioPlayer].
///
/// At most one recording is current. Player calls run one after another, and a
/// request overtaken by a newer play, pause or stop is dropped, so quick taps
/// or a slow load cannot start the wrong audio. A failing player call clears the
/// current recording and sets [error] and [failedId]. The player is owned by
/// the host; this controller never disposes it.
///
/// JSON: `{"recordings": [NoteRecording…]}`. Reading skips entries without an
/// id or source, and repeated ids. Every method does nothing after [dispose].
class NoteRecordingController extends ChangeNotifier {
  /// Manages [recordings] (unusable ones are skipped) and plays them through
  /// [player].
  NoteRecordingController({
    required NoteAudioPlayer player,
    Iterable<NoteRecording> recordings = const [],
  }) : _player = player {
    _addUsable(recordings);
    _positions = _player.position.listen(_onPosition);
  }

  /// The playback rates a recording can be cycled through.
  static const List<double> speedPresets = [0.5, 0.75, 1, 1.25, 1.5, 2];

  final NoteAudioPlayer _player;
  final List<NoteRecording> _recordings = [];
  late final StreamSubscription<Duration> _positions;

  /// The last queued player call. Created lazily, in the zone of the caller.
  Future<void>? _queue;
  int _intent = 0;
  String? _currentId;
  String? _loadedId;
  bool _wantsPlaying = false;
  bool _starting = false;
  bool _playing = false;
  Duration _position = Duration.zero;
  Object? _error;
  String? _failedId;
  bool _disposed = false;

  /// The recordings, in the order they were added.
  List<NoteRecording> get recordings => UnmodifiableListView(_recordings);

  /// The recording that is loaded, loading or paused.
  String? get currentId => _currentId;

  /// The recording named by [currentId].
  NoteRecording? get current => find(_currentId);

  /// Whether the current recording is audibly playing.
  bool get isPlaying => _playing;

  /// Position within the current recording.
  Duration get position => _position;

  /// What the player threw most recently, until the next [play].
  Object? get error => _error;

  /// The recording [error] belongs to.
  String? get failedId => _failedId;

  /// The preset closest to [speed].
  static double nearestSpeed(double speed) => speedPresets.reduce(
    (best, next) => (next - speed).abs() < (best - speed).abs() ? next : best,
  );

  /// The first preset faster than [speed], wrapping to the slowest.
  static double nextSpeed(double speed) => speedPresets.firstWhere(
    (preset) => preset > speed + 1e-9,
    orElse: () => speedPresets.first,
  );

  /// The recording with [id], or `null`.
  NoteRecording? find(String? id) {
    final index = _indexOf(id);

    return index < 0 ? null : _recordings[index];
  }

  /// The recordings attached to the 1-based [pageNumber].
  List<NoteRecording> forPage(int pageNumber) => [
    for (final recording in _recordings)
      if (recording.pageNumber == pageNumber) recording,
  ];

  /// Appends [recording]. Returns `false` when its id or source is empty or the
  /// id is taken.
  bool add(NoteRecording recording) {
    if (_disposed || !_addUsable([recording])) return false;
    notifyListeners();

    return true;
  }

  /// Renames a recording to the trimmed [title]; blank titles are ignored.
  bool rename(String id, String title) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return false;

    return _update(id, (recording) => recording.copyWith(title: trimmed));
  }

  /// Attaches a recording to the 1-based [pageNumber], or detaches it with
  /// `null`. Page numbers below 1 are ignored.
  bool attachToPage(String id, int? pageNumber) {
    if (pageNumber != null && pageNumber < 1) return false;

    return _update(
      id,
      (recording) => recording.copyWith(
        pageNumber: pageNumber,
        detachFromPage: pageNumber == null,
      ),
    );
  }

  /// Removes a recording, stopping it first if it is current. Deleting the
  /// audio itself is up to the host.
  bool remove(String id) {
    if (_disposed || find(id) == null) return false;
    if (id == _currentId) unawaited(stop());
    if (id == _loadedId) _loadedId = null;
    if (id == _failedId) _clearError();
    _recordings.removeWhere((recording) => recording.id == id);
    notifyListeners();

    return true;
  }

  /// Plays a recording: resumes it where it was paused, restarts it after it
  /// finished, or loads it first. Unknown ids are ignored.
  Future<void> play(String id) {
    if (_disposed || find(id) == null) return Future<void>.value();
    final intent = ++_intent;
    final changed = _currentId != id || _error != null;
    if (_currentId != id) {
      _currentId = id;
      _position = Duration.zero;
      _playing = false;
    }
    _wantsPlaying = true;
    _starting = true;
    _clearError();
    if (changed) notifyListeners();

    return _enqueue(() => _start(id, intent), id: id, intent: intent);
  }

  /// Pauses the current recording.
  Future<void> pause() {
    if (_disposed || !_wantsPlaying) return Future<void>.value();
    _intent++;
    _wantsPlaying = false;
    _starting = false;
    _refresh();

    return _enqueue(_pausePlayer);
  }

  /// Pauses [id] when it is playing or about to, else plays it.
  Future<void> toggle(String id) {
    final active = _currentId == id && _wantsPlaying && (_playing || _starting);

    return active ? pause() : play(id);
  }

  /// Pauses and leaves no recording current; playing one again starts over.
  Future<void> stop() {
    if (_disposed || _currentId == null) return Future<void>.value();
    _intent++;
    _wantsPlaying = false;
    _starting = false;
    _currentId = null;
    // Forget the loaded source: playing it again starts from the beginning.
    _loadedId = null;
    _playing = false;
    _position = Duration.zero;
    notifyListeners();

    return _enqueue(_pausePlayer);
  }

  /// Moves within the current recording (clamped to it when its length is
  /// known).
  Future<void> seek(Duration position) {
    final recording = current;
    if (_disposed || recording == null) return Future<void>.value();
    var target = position < Duration.zero ? Duration.zero : position;
    final length = recording.duration;
    if (length > Duration.zero && target > length) target = length;
    _refresh(position: target);

    return _enqueue(() async {
      if (_loadedId == recording.id) await _player.seek(target);
    }, id: recording.id);
  }

  /// Sets the preset nearest to [speed] for a recording and applies it if the
  /// recording is current.
  Future<void> setSpeed(String id, double speed) {
    if (_disposed || find(id) == null) return Future<void>.value();
    final preset = nearestSpeed(speed);
    _update(id, (recording) => recording.copyWith(playbackSpeed: preset));
    if (id != _currentId) return Future<void>.value();

    return _enqueue(() async {
      if (_loadedId == id) await _player.setSpeed(preset);
    }, id: id);
  }

  /// Moves a recording to the next speed preset.
  Future<void> cycleSpeed(String id) {
    final recording = find(id);
    if (recording == null) return Future<void>.value();

    return setSpeed(id, nextSpeed(recording.playbackSpeed));
  }

  /// The JSON form described in the class comment.
  JsonMap toJson() => {
    'recordings': [for (final recording in _recordings) recording.toJson()],
  };

  /// Replaces the recordings with those in [value] (see the class comment),
  /// stopping playback.
  void loadJson(Object? value) {
    if (_disposed) return;
    unawaited(stop());
    _loadedId = null;
    _clearError();
    _recordings.clear();
    final json = NoteJson.asMap(value) ?? const <String, Object?>{};
    _addUsable(
      NoteJson.mapList(json, 'recordings').map(NoteRecording.fromJson),
    );
    notifyListeners();
  }

  bool _addUsable(Iterable<NoteRecording> added) {
    var changed = false;
    for (final recording in added) {
      if (recording.id.isEmpty || recording.source.isEmpty) continue;
      if (find(recording.id) != null) continue;
      _recordings.add(recording);
      changed = true;
    }

    return changed;
  }

  int _indexOf(String? id) =>
      _recordings.indexWhere((recording) => recording.id == id);

  bool _update(String id, NoteRecording Function(NoteRecording) change) {
    final index = _indexOf(id);
    if (_disposed || index < 0) return false;
    final next = change(_recordings[index]);
    if (next == _recordings[index]) return false;
    _recordings[index] = next;
    notifyListeners();

    return true;
  }

  /// Runs [action] after the earlier ones. A failure is recorded against [id]
  /// unless a newer play, pause or stop has since replaced the request.
  Future<void> _enqueue(
    Future<void> Function() action, {
    String? id,
    int? intent,
  }) {
    final result = (_queue ?? Future<void>.value()).then((_) async {
      if (_disposed) return;
      try {
        await action();
      } on Exception catch (error) {
        if (intent == null || intent == _intent) _fail(id, error);
      }
    });
    // A programming error is reported and does not block later calls.
    _queue = result.then((_) {}, onError: _report);

    return result;
  }

  static void _report(Object error, StackTrace stack) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'open_note',
        context: ErrorDescription('while controlling audio playback'),
      ),
    );
  }

  bool _superseded(int intent) => _disposed || intent != _intent;

  Future<void> _start(String id, int intent) async {
    if (_superseded(intent)) return;
    if (_loadedId != id) {
      await _load(id);
    } else if (_player.state == NoteAudioPlayerState.completed) {
      await _player.seek(Duration.zero);
      _refresh(position: Duration.zero);
    }
    final recording = find(id);
    if (_superseded(intent) || recording == null) return;
    await _player.setSpeed(recording.playbackSpeed);
    if (_superseded(intent)) return;
    await _player.play();
    // Disposed while starting: nothing else would stop the audio.
    if (_disposed) return _silence();
    if (_superseded(intent)) return;
    _starting = false;
    _refresh();
  }

  Future<void> _load(String id) async {
    final recording = find(id);
    if (recording == null) return;
    await _pausePlayer();
    _loadedId = null;
    await _player.load(recording.source);
    _loadedId = id;
  }

  Future<void> _pausePlayer() async {
    if (_player.state == NoteAudioPlayerState.playing) await _player.pause();
    _refresh();
  }

  void _fail(String? id, Object error) {
    if (_disposed) return;
    _error = error;
    _failedId = id;
    if (id != null && id == _currentId) {
      _currentId = null;
      _loadedId = null;
      _wantsPlaying = false;
      _starting = false;
      _playing = false;
      _position = Duration.zero;
    }
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    _failedId = null;
  }

  void _onPosition(Duration position) {
    if (_disposed || _loadedId == null || _loadedId != _currentId) return;
    // While (re)starting, "completed" is left over from the previous run.
    if (!_starting && _player.state == NoteAudioPlayerState.completed) {
      _wantsPlaying = false;
    }
    _refresh(position: position);
  }

  /// Re-reads whether audio is playing and notifies if anything changed.
  void _refresh({Duration? position}) {
    if (_disposed) return;
    final playing =
        _wantsPlaying &&
        _loadedId != null &&
        _loadedId == _currentId &&
        _player.state == NoteAudioPlayerState.playing;
    final next = position ?? _position;
    if (playing == _playing && next == _position) return;
    _playing = playing;
    _position = next;
    notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _intent++;
    unawaited(_positions.cancel());
    if (_player.state == NoteAudioPlayerState.playing) {
      unawaited(_silence());
    }
    super.dispose();
  }

  Future<void> _silence() async {
    try {
      await _player.pause();
    } on Exception catch (error) {
      debugPrint('NoteRecordingController: pause failed: $error');
    }
  }
}

import 'dart:async';

import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/study/utilities/note_audio_exception.dart';
import 'package:open_note/src/note/study/utilities/note_audio_recorder.dart';
import 'package:open_note/src/note/study/utilities/note_recording.dart';

/// A deterministic [NoteAudioRecorder] without a microphone, for tests and
/// previews: time passes only through [advance].
class FakeNoteAudioRecorder implements NoteAudioRecorder {
  /// [idFactory] and [clock] stamp the recordings [stop] returns.
  FakeNoteAudioRecorder({
    this.idFactory = generateNoteId,
    this.clock = systemNoteClock,
  });

  /// Mints recording ids.
  final NoteIdFactory idFactory;

  /// Dates when a recording started.
  final NoteClock clock;

  final StreamController<Duration> _elapsed =
      StreamController<Duration>.broadcast(sync: true);
  Duration _length = Duration.zero;
  DateTime? _startedAt;
  int _count = 0;

  @override
  bool get isRecording => _startedAt != null;

  @override
  Stream<Duration> get elapsed => _elapsed.stream;

  @override
  Future<void> start() async {
    if (isRecording) throw const NoteAudioException('already recording');
    _length = Duration.zero;
    _startedAt = clock();
  }

  /// Lets [time] pass while recording.
  void advance(Duration time) {
    if (!isRecording || _elapsed.isClosed) return;
    _length += time;
    _elapsed.add(_length);
  }

  /// The recording's title is `Recording N` and its source
  /// `fake:recording-N`.
  @override
  Future<NoteRecording> stop() async {
    final startedAt = _startedAt;
    if (startedAt == null) throw const NoteAudioException('not recording');
    _startedAt = null;
    _count++;

    return NoteRecording(
      id: idFactory(),
      title: 'Recording $_count',
      source: 'fake:recording-$_count',
      createdAt: startedAt,
      duration: _length,
    );
  }

  /// Releases the elapsed stream.
  Future<void> dispose() => _elapsed.close();
}

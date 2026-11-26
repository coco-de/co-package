import 'package:open_note/src/note/study/utilities/note_recording.dart';

/// Records audio. The package ships no microphone code: the host implements
/// this with its plugin of choice (and `FakeNoteAudioRecorder` serves tests).
///
/// Failures (no permission, already or not recording) throw
/// `NoteAudioException`.
abstract interface class NoteAudioRecorder {
  /// Whether a recording is in progress.
  bool get isRecording;

  /// The recorded length, reported while recording.
  Stream<Duration> get elapsed;

  /// Starts a new recording.
  Future<void> start();

  /// Ends the recording and describes it, ready for
  /// `NoteRecordingController.add`.
  Future<NoteRecording> stop();
}

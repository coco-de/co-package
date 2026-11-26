import 'package:open_note/src/note/study/overlay/note_ai_pen_exception.dart';
import 'package:open_note/src/note/study/overlay/note_ai_pen_request.dart';
import 'package:open_note/src/note/study/overlay/note_ai_pen_result.dart';
import 'package:open_note/src/note/study/overlay/note_ai_pen_service.dart';

/// The default service of an app that set up no AI: every request fails with a
/// [NoteAiPenException] of code [NoteAiPenErrorCode.notConfigured].
class UnconfiguredNoteAiPenService implements NoteAiPenService {
  /// Creates the service.
  const UnconfiguredNoteAiPenService();

  @override
  Future<NoteAiPenResult> run(NoteAiPenRequest request) => Future.error(
    const NoteAiPenException(
      'No NoteAiPenService is configured.',
      code: NoteAiPenErrorCode.notConfigured,
    ),
  );
}

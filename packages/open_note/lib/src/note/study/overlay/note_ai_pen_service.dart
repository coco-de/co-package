import 'package:open_note/src/note/study/overlay/note_ai_pen_request.dart';
import 'package:open_note/src/note/study/overlay/note_ai_pen_result.dart';

/// The AI behind the AI pen. The package ships no network client: the host app
/// implements this with the model or API it uses.
abstract interface class NoteAiPenService {
  /// Answers [request]. Fails with a `NoteAiPenException` (other errors are
  /// reported as unknown failures). A caller that cancels simply ignores the
  /// late answer.
  Future<NoteAiPenResult> run(NoteAiPenRequest request);
}

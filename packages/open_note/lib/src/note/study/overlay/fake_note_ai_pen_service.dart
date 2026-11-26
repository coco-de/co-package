import 'dart:collection';

import 'package:open_note/src/note/study/overlay/note_ai_pen_exception.dart';
import 'package:open_note/src/note/study/overlay/note_ai_pen_kind.dart';
import 'package:open_note/src/note/study/overlay/note_ai_pen_request.dart';
import 'package:open_note/src/note/study/overlay/note_ai_pen_result.dart';
import 'package:open_note/src/note/study/overlay/note_ai_pen_service.dart';

/// A scripted [NoteAiPenService] for tests and demos.
///
/// Each [run] takes the next entry queued with [enqueue] or [enqueueError];
/// with an empty queue it answers from the per-kind answers, or with
/// `Fake <kind> answer`. A positive delay postpones every answer.
class FakeNoteAiPenService implements NoteAiPenService {
  /// Creates the fake. [wait] replaces [Future.delayed] in tests.
  FakeNoteAiPenService({
    Map<NoteAiPenKind, NoteAiPenResult> answers = const {},
    this.delay = Duration.zero,
    Future<void> Function(Duration delay)? wait,
  }) : _answers = Map.unmodifiable(answers),
       _wait = wait ?? ((duration) => Future<void>.delayed(duration));

  /// How long each answer takes.
  final Duration delay;

  final Map<NoteAiPenKind, NoteAiPenResult> _answers;
  final Future<void> Function(Duration delay) _wait;
  final Queue<Object> _script = Queue<Object>();
  final List<NoteAiPenRequest> _requests = [];

  /// Every request received, oldest first (unmodifiable).
  List<NoteAiPenRequest> get requests => List.unmodifiable(_requests);

  /// Queues [result] as the answer of the next unanswered request.
  void enqueue(NoteAiPenResult result) => _script.add(result);

  /// Queues a failure for the next unanswered request.
  void enqueueError(NoteAiPenException error) => _script.add(error);

  @override
  Future<NoteAiPenResult> run(NoteAiPenRequest request) async {
    _requests.add(request);
    // Taken now so the order of the calls decides who gets what.
    final scripted = _script.isEmpty ? null : _script.removeFirst();
    if (delay > Duration.zero) await _wait(delay);
    if (scripted is NoteAiPenException) throw scripted;
    if (scripted is NoteAiPenResult) return scripted;

    return _answers[request.kind] ??
        NoteAiPenResult(
          kind: request.kind,
          text: 'Fake ${request.kind.name} answer',
        );
  }
}

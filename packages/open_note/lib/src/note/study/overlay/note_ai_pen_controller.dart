import 'package:flutter/foundation.dart';
import 'package:open_note/src/note/study/overlay/note_ai_pen_exception.dart';
import 'package:open_note/src/note/study/overlay/note_ai_pen_request.dart';
import 'package:open_note/src/note/study/overlay/note_ai_pen_result.dart';
import 'package:open_note/src/note/study/overlay/note_ai_pen_service.dart';

/// Where an AI pen request stands.
enum NoteAiPenStatus {
  /// Nothing to show: never run, cancelled or reset.
  idle,

  /// Waiting for the service.
  running,

  /// [NoteAiPenController.result] holds the answer.
  done,

  /// [NoteAiPenController.error] holds the failure.
  error,
}

/// Runs AI pen requests one at a time.
///
/// Only the latest request counts: the late answer (or failure) of a request
/// that was cancelled, replaced by a newer [run] or outlived by [dispose] is
/// dropped. After [dispose] every method does nothing.
class NoteAiPenController extends ChangeNotifier {
  /// A controller that asks [service].
  NoteAiPenController({required this.service});

  /// The AI that answers.
  final NoteAiPenService service;

  NoteAiPenStatus _status = NoteAiPenStatus.idle;
  NoteAiPenRequest? _request;
  NoteAiPenResult? _result;
  NoteAiPenException? _error;
  int _ticket = 0;
  bool _disposed = false;

  /// The current state.
  NoteAiPenStatus get status => _status;

  /// Whether the service is working.
  bool get isRunning => _status == NoteAiPenStatus.running;

  /// The latest request (kept after [cancel], cleared by [reset]).
  NoteAiPenRequest? get request => _request;

  /// The answer, when [status] is [NoteAiPenStatus.done].
  NoteAiPenResult? get result => _result;

  /// The failure, when [status] is [NoteAiPenStatus.error].
  NoteAiPenException? get error => _error;

  /// Sends [request], replacing any request in flight. Completes when this
  /// request is settled or dropped; it never throws.
  Future<void> run(NoteAiPenRequest request) async {
    if (_disposed) return;
    final ticket = ++_ticket;
    _apply(NoteAiPenStatus.running, request: request);
    // A listener may have cancelled or replaced the request already.
    if (!_isCurrent(ticket)) return;
    try {
      final result = await service.run(request);
      if (_isCurrent(ticket)) {
        _apply(NoteAiPenStatus.done, request: request, result: result);
      }
    } on NoteAiPenException catch (failure) {
      _fail(ticket, request, failure);
    } on Object catch (failure) {
      _fail(ticket, request, NoteAiPenException('$failure', cause: failure));
    }
  }

  /// Runs the latest request again, if there is one.
  Future<void> retry() async {
    final request = _request;
    if (request != null) await run(request);
  }

  /// Stops waiting for the request in flight and goes back to idle. Does
  /// nothing unless running.
  void cancel() {
    if (_disposed || !isRunning) return;
    _ticket++;
    _apply(NoteAiPenStatus.idle, request: _request);
  }

  /// Forgets the request, the answer and the failure.
  void reset() {
    if (_disposed) return;
    _ticket++;
    if (_status == NoteAiPenStatus.idle && _request == null) return;
    _apply(NoteAiPenStatus.idle);
  }

  @override
  void dispose() {
    _disposed = true;
    _ticket++;
    super.dispose();
  }

  bool _isCurrent(int ticket) => !_disposed && ticket == _ticket;

  void _fail(int ticket, NoteAiPenRequest request, NoteAiPenException failure) {
    if (!_isCurrent(ticket)) return;
    _apply(NoteAiPenStatus.error, request: request, error: failure);
  }

  void _apply(
    NoteAiPenStatus status, {
    NoteAiPenRequest? request,
    NoteAiPenResult? result,
    NoteAiPenException? error,
  }) {
    _status = status;
    _request = request;
    _result = result;
    _error = error;
    notifyListeners();
  }
}

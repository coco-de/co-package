import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/study/overlay/overlay.dart';

/// A service whose every answer the test completes by hand.
class _ManualService implements NoteAiPenService {
  final List<Completer<NoteAiPenResult>> calls = [];

  @override
  Future<NoteAiPenResult> run(NoteAiPenRequest request) {
    final call = Completer<NoteAiPenResult>();
    calls.add(call);

    return call.future;
  }
}

class _ThrowingService implements NoteAiPenService {
  @override
  Future<NoteAiPenResult> run(NoteAiPenRequest request) =>
      throw StateError('broken');
}

const _solve = NoteAiPenRequest(kind: NoteAiPenKind.solve, text: '1+1');
const _explain = NoteAiPenRequest(kind: NoteAiPenKind.explain, text: '1+1');

NoteAiPenResult _answer(String text) =>
    NoteAiPenResult(kind: NoteAiPenKind.solve, text: text);

void main() {
  late _ManualService service;
  late NoteAiPenController controller;
  late int notified;

  setUp(() {
    service = _ManualService();
    controller = NoteAiPenController(service: service);
    notified = 0;
    controller.addListener(() => notified++);
  });

  test('starts idle', () {
    expect(controller.status, NoteAiPenStatus.idle);
    expect(controller.request, isNull);
    expect(controller.result, isNull);
    expect(controller.error, isNull);
    expect(controller.isRunning, isFalse);
  });

  test('goes through running to done', () async {
    final running = controller.run(_solve);

    expect(controller.status, NoteAiPenStatus.running);
    expect(controller.request, _solve);
    service.calls.single.complete(_answer('2'));
    await running;

    expect(controller.status, NoteAiPenStatus.done);
    expect(controller.result, _answer('2'));
    expect(controller.error, isNull);
    expect(notified, 2);
  });

  test('reports a typed failure', () async {
    final running = controller.run(_solve);
    const failure = NoteAiPenException(
      'offline',
      code: NoteAiPenErrorCode.network,
    );

    service.calls.single.completeError(failure);
    await running;

    expect(controller.status, NoteAiPenStatus.error);
    expect(controller.error, failure);
    expect(controller.result, isNull);
  });

  test('wraps any other failure, even a synchronous one', () async {
    final broken = NoteAiPenController(service: _ThrowingService());

    await broken.run(_solve);

    expect(broken.status, NoteAiPenStatus.error);
    expect(broken.error!.code, NoteAiPenErrorCode.unknown);
    expect(broken.error!.cause, isA<StateError>());
    broken.dispose();
  });

  test('drops the late answer of a cancelled request', () async {
    final running = controller.run(_solve);
    controller.cancel();
    final afterCancel = notified;

    service.calls.single.complete(_answer('too late'));
    await running;

    expect(controller.status, NoteAiPenStatus.idle);
    expect(controller.result, isNull);
    expect(controller.request, _solve);
    expect(notified, afterCancel);
  });

  test('drops the late failure of a cancelled request', () async {
    final running = controller.run(_solve);
    controller.cancel();

    service.calls.single.completeError(StateError('late'));
    await running;

    expect(controller.status, NoteAiPenStatus.idle);
    expect(controller.error, isNull);
  });

  test('only the latest request counts', () async {
    final first = controller.run(_solve);
    final second = controller.run(_explain);

    service.calls[1].complete(_answer('second'));
    await second;
    service.calls[0].complete(_answer('first'));
    await first;

    expect(controller.result, _answer('second'));
    expect(controller.request, _explain);
    expect(controller.status, NoteAiPenStatus.done);
  });

  test('an old failure does not disturb the newer request', () async {
    final first = controller.run(_solve);
    final second = controller.run(_explain);

    service.calls[0].completeError(StateError('old'));
    await first;
    expect(controller.status, NoteAiPenStatus.running);

    service.calls[1].complete(_answer('new'));
    await second;

    expect(controller.result, _answer('new'));
  });

  test('a listener may cancel before the service is asked', () async {
    controller.addListener(() {
      if (controller.isRunning) controller.cancel();
    });

    await controller.run(_solve);

    expect(service.calls, isEmpty);
    expect(controller.status, NoteAiPenStatus.idle);
  });

  test('cancel when not running changes nothing', () async {
    controller.cancel();
    expect(notified, 0);

    final running = controller.run(_solve);
    service.calls.single.complete(_answer('2'));
    await running;
    final settled = notified;
    controller.cancel();

    expect(controller.status, NoteAiPenStatus.done);
    expect(notified, settled);
  });

  test('retry asks again with the same request', () async {
    await controller.retry();
    expect(service.calls, isEmpty);

    final first = controller.run(_solve);
    service.calls.single.completeError(StateError('x'));
    await first;
    final again = controller.retry();

    expect(controller.status, NoteAiPenStatus.running);
    expect(controller.error, isNull);
    service.calls.last.complete(_answer('ok'));
    await again;
    expect(controller.request, _solve);
    expect(controller.result, _answer('ok'));
  });

  test('reset forgets everything and drops a pending answer', () async {
    controller.reset();
    expect(notified, 0);

    final running = controller.run(_solve);
    controller.reset();
    service.calls.single.complete(_answer('2'));
    await running;

    expect(controller.status, NoteAiPenStatus.idle);
    expect(controller.request, isNull);
    expect(controller.result, isNull);
  });

  test('after dispose nothing happens', () async {
    final running = controller.run(_solve);
    controller.dispose();

    service.calls.single.complete(_answer('late'));
    await running;
    await controller.run(_explain);
    await controller.retry();
    controller
      ..cancel()
      ..reset();

    expect(service.calls, hasLength(1));
  });

  test('the unconfigured service fails with a typed error', () async {
    final bare = NoteAiPenController(
      service: const UnconfiguredNoteAiPenService(),
    );

    await bare.run(_solve);

    expect(bare.status, NoteAiPenStatus.error);
    expect(bare.error!.code, NoteAiPenErrorCode.notConfigured);
    bare.dispose();
  });

  group('fake service', () {
    test('answers from the script, then by kind, then by default', () async {
      final fake = FakeNoteAiPenService(
        answers: {NoteAiPenKind.explain: _answer('by kind')},
      )..enqueue(_answer('scripted'));

      expect(await fake.run(_solve), _answer('scripted'));
      expect(await fake.run(_explain), _answer('by kind'));
      final other = await fake.run(_solve);

      expect(other.text, 'Fake solve answer');
      expect(other.kind, NoteAiPenKind.solve);
      expect(fake.requests, [_solve, _explain, _solve]);
      expect(() => fake.requests.clear(), throwsUnsupportedError);
    });

    test('throws scripted errors', () {
      final fake = FakeNoteAiPenService()
        ..enqueueError(
          const NoteAiPenException(
            'bad',
            code: NoteAiPenErrorCode.invalidRequest,
          ),
        );

      expect(
        fake.run(_solve),
        throwsA(
          isA<NoteAiPenException>().having(
            (error) => error.code,
            'code',
            NoteAiPenErrorCode.invalidRequest,
          ),
        ),
      );
    });

    test('waits through the injected wait', () async {
      final waited = <Duration>[];
      final fake = FakeNoteAiPenService(
        delay: const Duration(seconds: 3),
        wait: (delay) async => waited.add(delay),
      );

      await fake.run(_solve);

      expect(waited, [const Duration(seconds: 3)]);
    });

    test('delays its answer', () {
      fakeAsync((async) {
        final fake = FakeNoteAiPenService(delay: const Duration(seconds: 2));
        String? text;
        unawaited(fake.run(_solve).then((result) => text = result.text));

        async.elapse(const Duration(seconds: 1));
        expect(text, isNull);
        async.elapse(const Duration(seconds: 1));

        expect(text, 'Fake solve answer');
      });
    });
  });
}

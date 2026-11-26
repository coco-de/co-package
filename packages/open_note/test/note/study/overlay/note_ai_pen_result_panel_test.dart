import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/study/overlay/note_overlay_spinner.dart';
import 'package:open_note/src/note/study/overlay/overlay.dart';

import 'overlay_test_support.dart';

const _request = NoteAiPenRequest(kind: NoteAiPenKind.solve, text: '2x = 4');
const _cancel = ValueKey('note-ai-pen-cancel');
const _retry = ValueKey('note-ai-pen-retry');
const _copy = ValueKey('note-ai-pen-copy');
const _close = ValueKey('note-ai-pen-close');

ValueKey<String> _tab(String name) => ValueKey('note-ai-pen-tab-$name');

/// The service answers after 500 ms of fake time.
FakeNoteAiPenService _service() =>
    FakeNoteAiPenService(delay: const Duration(milliseconds: 500));

Future<void> _show(
  WidgetTester tester,
  NoteAiPenController controller, {
  ValueChanged<NoteAiPenKind>? onKindSelected,
  ValueChanged<String>? onCopy,
  VoidCallback? onClose,
  Size size = const Size(420, 400),
}) => tester.pumpWidget(
  boxed(
    Align(
      alignment: Alignment.topCenter,
      child: NoteAiPenResultPanel(
        controller: controller,
        onKindSelected: onKindSelected,
        onCopy: onCopy,
        onClose: onClose,
      ),
    ),
    size: size,
  ),
);

Future<void> _settle(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump();
}

void main() {
  testWidgets('starts with the hint and three tabs', (tester) async {
    final controller = NoteAiPenController(service: _service());
    await _show(tester, controller);

    expect(find.text('Select a region to start.'), findsOneWidget);
    expect(find.text('Solve'), findsOneWidget);
    expect(find.text('Explain'), findsOneWidget);
    expect(find.text('Translate'), findsOneWidget);
    expect(find.byKey(_retry), findsNothing);
    expect(find.byKey(_copy), findsNothing);
    expect(find.byKey(_close), findsNothing);
    controller.dispose();
  });

  testWidgets('shows busy, then the answer with steps and copy', (
    tester,
  ) async {
    final copied = <String>[];
    final service = _service()
      ..enqueue(
        NoteAiPenResult(
          kind: NoteAiPenKind.solve,
          text: 'x = 2',
          steps: const ['divide by 2'],
        ),
      );
    final controller = NoteAiPenController(service: service);
    await _show(tester, controller, onCopy: copied.add);

    controller.run(_request);
    await tester.pump();

    expect(find.byType(NoteOverlaySpinner), findsOneWidget);
    expect(find.text('Working…'), findsOneWidget);
    await _settle(tester);

    expect(find.byType(NoteOverlaySpinner), findsNothing);
    expect(find.text('x = 2'), findsOneWidget);
    expect(find.text('Steps'), findsOneWidget);
    expect(find.text('1. divide by 2'), findsOneWidget);
    await tester.tap(find.byKey(_copy));
    expect(copied, ['x = 2\n\n1. divide by 2']);
    controller.dispose();
  });

  testWidgets('without onCopy there is no copy button', (tester) async {
    final controller = NoteAiPenController(service: _service());
    await _show(tester, controller);

    controller.run(_request);
    await _settle(tester);

    expect(find.text('Fake solve answer'), findsOneWidget);
    expect(find.byKey(_copy), findsNothing);
    controller.dispose();
  });

  testWidgets('cancel stops the request and offers to run it again', (
    tester,
  ) async {
    final service = _service();
    final controller = NoteAiPenController(service: service);
    await _show(tester, controller);
    controller.run(_request);
    await tester.pump();

    await tester.tap(find.byKey(_cancel));
    await _settle(tester);

    expect(controller.status, NoteAiPenStatus.idle);
    expect(find.text('Fake solve answer'), findsNothing);
    await tester.tap(find.byKey(_retry));
    await _settle(tester);

    expect(service.requests, [_request, _request]);
    expect(find.text('Fake solve answer'), findsOneWidget);
    controller.dispose();
  });

  testWidgets('shows a localised error and retries', (tester) async {
    final service = _service()
      ..enqueueError(
        const NoteAiPenException(
          'socket closed',
          code: NoteAiPenErrorCode.network,
        ),
      );
    final controller = NoteAiPenController(service: service);
    await _show(tester, controller);

    controller.run(_request);
    await _settle(tester);

    expect(find.text('The AI service could not be reached.'), findsOneWidget);
    expect(find.text('socket closed'), findsNothing);
    await tester.tap(find.byKey(_retry));
    await _settle(tester);

    expect(find.text('Fake solve answer'), findsOneWidget);
    controller.dispose();
  });

  testWidgets('a tab runs the latest request with its kind', (tester) async {
    final service = _service();
    final controller = NoteAiPenController(service: service);
    await _show(tester, controller);
    controller.run(_request);
    await _settle(tester);

    await tester.tap(find.byKey(_tab('explain')));
    await tester.pump();

    expect(controller.request!.kind, NoteAiPenKind.explain);
    expect(controller.request!.text, '2x = 4');
    await _settle(tester);
    expect(find.text('Fake explain answer'), findsOneWidget);

    await tester.tap(find.byKey(_tab('explain')));
    await tester.pump();
    expect(service.requests, hasLength(2));
    controller.dispose();
  });

  testWidgets('onKindSelected takes over the tabs', (tester) async {
    final picked = <NoteAiPenKind>[];
    final service = _service();
    final controller = NoteAiPenController(service: service);
    await _show(tester, controller, onKindSelected: picked.add);
    controller.run(_request);
    await _settle(tester);

    await tester.tap(find.byKey(_tab('translate')));
    await tester.pump();

    expect(picked, [NoteAiPenKind.translate]);
    expect(service.requests, hasLength(1));
    expect(find.text('Fake solve answer'), findsNothing);
    expect(find.text('Select a region to start.'), findsOneWidget);

    await tester.tap(find.byKey(_tab('solve')));
    await tester.pump();
    expect(find.text('Fake solve answer'), findsOneWidget);
    controller.dispose();
  });

  testWidgets('without a request a tab only selects', (tester) async {
    final service = _service();
    final controller = NoteAiPenController(service: service);
    await _show(tester, controller);

    await tester.tap(find.byKey(_tab('translate')));
    await tester.pump();

    expect(service.requests, isEmpty);
    controller.dispose();
  });

  testWidgets('a request started elsewhere selects its tab', (tester) async {
    final handle = tester.ensureSemantics();
    final controller = NoteAiPenController(service: _service());
    await _show(tester, controller);

    controller.run(_request.copyWith(kind: NoteAiPenKind.translate));
    await _settle(tester);

    expect(find.text('Fake translate answer'), findsOneWidget);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Translate')),
      isSemantics(isButton: true, isSelected: true),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Solve')),
      isSemantics(isSelected: false),
    );
    handle.dispose();
    controller.dispose();
  });

  testWidgets('the close button calls back', (tester) async {
    var closed = 0;
    final controller = NoteAiPenController(service: _service());
    await _show(tester, controller, onClose: () => closed++);

    await tester.tap(find.byKey(_close));

    expect(closed, 1);
    controller.dispose();
  });

  testWidgets('long answers scroll within the maximum height', (tester) async {
    final service = _service()
      ..enqueue(
        NoteAiPenResult(
          kind: NoteAiPenKind.solve,
          text: List.filled(200, 'line').join('\n'),
        ),
      );
    final controller = NoteAiPenController(service: service);
    await _show(tester, controller, size: const Size(420, 500));
    controller.run(_request);
    await _settle(tester);

    expect(tester.getSize(find.byType(NoteAiPenResultPanel)).height, 360);
    expect(tester.takeException(), isNull);
    controller.dispose();
  });

  testWidgets('a narrow panel scrolls its tabs', (tester) async {
    final controller = NoteAiPenController(service: _service());

    await _show(tester, controller, size: const Size(160, 400));

    expect(tester.takeException(), isNull);
    controller.dispose();
  });

  testWidgets('moves to a new controller', (tester) async {
    final first = NoteAiPenController(service: _service());
    final second = NoteAiPenController(service: _service());
    await _show(tester, first);
    await _show(tester, second);

    second.run(_request);
    await _settle(tester);

    expect(find.text('Fake solve answer'), findsOneWidget);
    first.dispose();
    second.dispose();
  });
}

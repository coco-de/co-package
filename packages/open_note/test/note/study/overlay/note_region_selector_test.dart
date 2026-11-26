import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/study/overlay/overlay.dart';

import 'overlay_test_support.dart';

class _Log {
  final List<Rect> selected = [];
  final List<Rect?> changes = [];
  int cancels = 0;

  Rect? get region => changes.isEmpty ? null : changes.last;
}

const _confirm = ValueKey('note-region-confirm');
const _cancel = ValueKey('note-region-cancel');

Future<_Log> _pump(
  WidgetTester tester, {
  Rect? initial,
  bool confirmOnRelease = false,
  bool cancellable = true,
}) async {
  final log = _Log();
  await tester.pumpWidget(
    boxed(
      NoteRegionSelector(
        initialRegion: initial,
        confirmOnRelease: confirmOnRelease,
        onRegionSelected: log.selected.add,
        onRegionChanged: log.changes.add,
        onCancel: cancellable ? () => log.cancels++ : null,
      ),
      size: const Size(400, 500),
    ),
  );
  await tester.pump();

  return log;
}

Future<void> _drag(WidgetTester tester, Offset from, Offset to) async {
  await tester.dragFrom(from, to - from);
  await tester.pump();
}

void main() {
  testWidgets('a drag selects a rectangle that confirm reports', (
    tester,
  ) async {
    final log = await _pump(tester);
    expect(find.byKey(_confirm), findsNothing);

    await _drag(tester, const Offset(50, 60), const Offset(250, 200));

    expect(log.region, const Rect.fromLTRB(50, 60, 250, 200));
    expect(log.selected, isEmpty);
    await tester.tap(find.byKey(_confirm));
    expect(log.selected, [const Rect.fromLTRB(50, 60, 250, 200)]);
  });

  testWidgets('a drag past the page is clamped to it', (tester) async {
    final log = await _pump(tester);

    await _drag(tester, const Offset(300, 400), const Offset(700, 580));

    expect(log.region, const Rect.fromLTRB(300, 400, 400, 500));
  });

  testWidgets('a drag inside moves the selection and keeps it on the page', (
    tester,
  ) async {
    final log = await _pump(
      tester,
      initial: const Rect.fromLTRB(100, 100, 250, 220),
    );

    await _drag(tester, const Offset(170, 160), const Offset(200, 180));
    expect(log.region, const Rect.fromLTRB(130, 120, 280, 240));

    await _drag(tester, const Offset(200, 180), const Offset(-100, -100));
    expect(log.region, const Rect.fromLTRB(0, 0, 150, 120));
  });

  testWidgets('a drag on a handle resizes down to the minimum', (tester) async {
    final log = await _pump(
      tester,
      initial: const Rect.fromLTRB(100, 100, 250, 220),
    );

    await _drag(tester, const Offset(250, 220), const Offset(200, 190));
    expect(log.region, const Rect.fromLTRB(100, 100, 200, 190));

    await _drag(tester, const Offset(200, 145), const Offset(0, 145));
    expect(log.region, const Rect.fromLTRB(100, 100, 124, 190));
  });

  testWidgets('the middle of a small selection still moves it', (tester) async {
    final log = await _pump(
      tester,
      initial: const Rect.fromLTRB(100, 100, 124, 124),
    );

    await _drag(tester, const Offset(112, 112), const Offset(162, 132));

    expect(log.region, const Rect.fromLTRB(150, 120, 174, 144));
  });

  testWidgets('a tiny drag selects nothing', (tester) async {
    final log = await _pump(tester);

    await _drag(tester, const Offset(50, 50), const Offset(58, 61));

    expect(log.region, isNull);
    expect(find.byKey(_confirm), findsNothing);
  });

  testWidgets('a thin drag is widened to the minimum', (tester) async {
    final log = await _pump(tester);

    await _drag(tester, const Offset(50, 100), const Offset(250, 104));

    expect(log.region, const Rect.fromLTRB(50, 90, 250, 114));
  });

  testWidgets('a drag outside starts over, unless it is too small', (
    tester,
  ) async {
    const initial = Rect.fromLTRB(100, 100, 250, 220);
    final log = await _pump(tester, initial: initial);

    await _drag(tester, const Offset(300, 300), const Offset(308, 306));
    expect(log.region, initial);

    await _drag(tester, const Offset(300, 300), const Offset(390, 380));
    expect(log.region, const Rect.fromLTRB(300, 300, 390, 380));
  });

  testWidgets('a tap leaves the selection alone', (tester) async {
    const initial = Rect.fromLTRB(100, 100, 250, 220);
    final log = await _pump(tester, initial: initial);

    await tester.tapAt(const Offset(350, 450));
    await tester.tapAt(const Offset(150, 150));
    await tester.pump();

    expect(log.changes, isEmpty);
    await tester.tap(find.byKey(_confirm));
    expect(log.selected, [initial]);
  });

  testWidgets('the toolbar stays on the page near the selection', (
    tester,
  ) async {
    await _pump(tester, initial: const Rect.fromLTRB(300, 420, 400, 500));

    final bar = tester.getRect(find.byKey(_confirm));

    expect(bar.bottom, lessThanOrEqualTo(420));
    expect(bar.right, lessThanOrEqualTo(400));
  });

  testWidgets('cancel works with and without a selection', (tester) async {
    final log = await _pump(tester);

    await tester.tap(find.byKey(_cancel));
    expect(log.cancels, 1);

    await _drag(tester, const Offset(50, 60), const Offset(250, 200));
    await tester.tap(find.byKey(_cancel));

    expect(log.cancels, 2);
  });

  testWidgets('without onCancel there is no cancel button', (tester) async {
    await _pump(tester, cancellable: false);

    expect(find.byKey(_cancel), findsNothing);
  });

  testWidgets('Escape cancels and Enter confirms', (tester) async {
    const initial = Rect.fromLTRB(10, 20, 110, 120);
    final log = await _pump(tester, initial: initial);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);

    expect(log.selected, [initial]);
    expect(log.cancels, 1);
  });

  testWidgets('confirmOnRelease reports each finished drag', (tester) async {
    final log = await _pump(tester, confirmOnRelease: true);

    await _drag(tester, const Offset(50, 60), const Offset(250, 200));
    expect(log.selected, [const Rect.fromLTRB(50, 60, 250, 200)]);
    expect(find.byKey(_confirm), findsNothing);

    await _drag(tester, const Offset(300, 300), const Offset(305, 304));
    expect(log.selected, hasLength(1));
  });

  testWidgets('an initial region off the page is brought onto it', (
    tester,
  ) async {
    final log = await _pump(
      tester,
      initial: const Rect.fromLTWH(380, -20, 60, 60),
    );

    await tester.tap(find.byKey(_confirm));

    expect(log.selected, [const Rect.fromLTWH(340, 0, 60, 60)]);
  });

  testWidgets('labels the selector and its buttons', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, initial: const Rect.fromLTRB(10, 20, 110, 120));

    expect(
      find.bySemanticsLabel('Select a region of the page'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Use this selection'), findsOneWidget);
    expect(find.bySemanticsLabel('Cancel selection'), findsOneWidget);
    handle.dispose();
  });
}

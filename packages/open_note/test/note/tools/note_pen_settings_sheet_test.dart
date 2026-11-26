import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/tools/tools.dart';

import '../support/note_test_host.dart';

class _Events {
  final List<NotePenSettings> changes = [];
  final List<NotePenSettings> ends = [];

  Widget sheet({
    NotePenSettings settings = const NotePenSettings(),
    NoteToolsStrings strings = const NoteToolsStrings(),
  }) => noteTestHost(
    NotePenSettingsSheet(
      settings: settings,
      strings: strings,
      onChanged: changes.add,
      onChangeEnd: ends.add,
    ),
  );
}

Finder _in(Key row, Finder finder) =>
    find.descendant(of: find.byKey(row), matching: finder);

Finder _slider(Key row) => _in(row, find.byType(NoteSlider));

/// The point of [row]'s slider at [fraction] of its range.
Offset _point(WidgetTester tester, Key row, double fraction) {
  const thumb = 11.0;
  final rect = tester.getRect(_slider(row));

  return Offset(
    rect.left + thumb + fraction * (rect.width - 2 * thumb),
    rect.center.dy,
  );
}

void main() {
  testWidgets('shows the three sliders with their values', (tester) async {
    await tester.pumpWidget(_Events().sheet());

    expect(find.byType(NoteSlider), findsNWidgets(3));
    expect(
      _in(NotePenSettingsSheet.motionSmoothingKey, find.text('5')),
      findsOneWidget,
    );
    expect(
      _in(NotePenSettingsSheet.stabilizationKey, find.text('20%')),
      findsOneWidget,
    );
    expect(
      _in(NotePenSettingsSheet.pressureSensitivityKey, find.text('50%')),
      findsOneWidget,
    );
    expect(find.text('Motion smoothing'), findsOneWidget);
    expect(find.text('Stroke stabilization'), findsOneWidget);
    expect(find.text('Pressure sensitivity'), findsOneWidget);
  });

  testWidgets('moving a slider reports the setting and shows it live', (
    tester,
  ) async {
    final events = _Events();
    await tester.pumpWidget(events.sheet());

    await tester.tapAt(
      _point(tester, NotePenSettingsSheet.motionSmoothingKey, 1),
    );
    await tester.pump();

    expect(events.changes, [const NotePenSettings(motionSmoothing: 10)]);
    expect(events.ends, [const NotePenSettings(motionSmoothing: 10)]);
    expect(
      _in(NotePenSettingsSheet.motionSmoothingKey, find.text('10')),
      findsOneWidget,
    );

    await tester.tapAt(
      _point(tester, NotePenSettingsSheet.stabilizationKey, 0.5),
    );
    await tester.pump();

    expect(events.changes.last.stabilization, closeTo(0.5, 1e-9));
    expect(events.changes.last.motionSmoothing, 10);
    expect(
      _in(NotePenSettingsSheet.stabilizationKey, find.text('50%')),
      findsOneWidget,
    );
  });

  testWidgets('dragging reaches the ends of the range and ends once', (
    tester,
  ) async {
    final events = _Events();
    await tester.pumpWidget(events.sheet());

    await tester.drag(
      _slider(NotePenSettingsSheet.pressureSensitivityKey),
      const Offset(-1000, 0),
    );
    await tester.pump();

    expect(events.changes.last.pressureSensitivity, 0);
    expect(events.ends, [events.changes.last]);
    expect(
      _in(NotePenSettingsSheet.pressureSensitivityKey, find.text('0%')),
      findsOneWidget,
    );
  });

  testWidgets('does not report a value that did not change', (tester) async {
    final events = _Events();
    await tester.pumpWidget(events.sheet());

    await tester.tapAt(
      _point(tester, NotePenSettingsSheet.pressureSensitivityKey, 0.5),
    );
    await tester.pump();

    expect(events.changes, isEmpty);
  });

  testWidgets('the ? button shows and hides one help text each', (
    tester,
  ) async {
    const strings = NoteToolsStrings();
    await tester.pumpWidget(_Events().sheet());
    expect(find.text(strings.stabilizationHelp), findsNothing);

    await tester.tap(
      _in(NotePenSettingsSheet.stabilizationKey, find.text('?')),
    );
    await tester.pump();

    expect(find.text(strings.stabilizationHelp), findsOneWidget);
    expect(find.text(strings.motionSmoothingHelp), findsNothing);

    await tester.tap(
      _in(NotePenSettingsSheet.motionSmoothingKey, find.text('?')),
    );
    await tester.pump();
    await tester.tap(
      _in(NotePenSettingsSheet.pressureSensitivityKey, find.text('?')),
    );
    await tester.pump();

    expect(find.text(strings.motionSmoothingHelp), findsOneWidget);
    expect(find.text(strings.pressureSensitivityHelp), findsOneWidget);

    await tester.tap(
      _in(NotePenSettingsSheet.stabilizationKey, find.text('?')),
    );
    await tester.pump();

    expect(find.text(strings.stabilizationHelp), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('takes over settings that change from outside', (tester) async {
    final events = _Events();
    await tester.pumpWidget(events.sheet());

    await tester.pumpWidget(
      events.sheet(settings: const NotePenSettings(motionSmoothing: 2)),
    );

    expect(
      _in(NotePenSettingsSheet.motionSmoothingKey, find.text('2')),
      findsOneWidget,
    );
    expect(events.changes, isEmpty);
  });

  testWidgets('keeps its value while the parent rebuilds unchanged', (
    tester,
  ) async {
    final events = _Events();
    await tester.pumpWidget(events.sheet());

    await tester.tapAt(
      _point(tester, NotePenSettingsSheet.motionSmoothingKey, 0),
    );
    await tester.pump();
    await tester.pumpWidget(events.sheet());

    expect(
      _in(NotePenSettingsSheet.motionSmoothingKey, find.text('0')),
      findsOneWidget,
    );
  });

  testWidgets('uses translated strings', (tester) async {
    await tester.pumpWidget(
      _Events().sheet(
        strings: NoteToolsStrings(
          motionSmoothing: '손떨림 보정',
          percent: (value) => '$value 퍼센트',
        ),
      ),
    );

    expect(find.text('손떨림 보정'), findsOneWidget);
    expect(find.text('20 퍼센트'), findsOneWidget);
  });

  testWidgets('labels its controls for screen readers', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_Events().sheet());

    expect(find.bySemanticsLabel('Help: Stroke stabilization'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Motion smoothing')), findsWidgets);
    semantics.dispose();
  });

  testWidgets('scrolls instead of overflowing a small space', (tester) async {
    await tester.pumpWidget(
      noteTestHost(
        Center(
          child: SizedBox(
            width: 260,
            height: 120,
            child: NotePenSettingsSheet(
              settings: const NotePenSettings(),
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}

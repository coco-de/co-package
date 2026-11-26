import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/tools/tools.dart';

import '../support/note_test_host.dart';

class _Events {
  final List<NoteEraserSettings> changes = [];
  final List<NoteEraserSettings> ends = [];

  Widget panel({
    NoteEraserSettings settings = const NoteEraserSettings(),
    NoteToolsStrings strings = const NoteToolsStrings(),
  }) => noteTestHost(
    NoteEraserSettingsPanel(
      settings: settings,
      strings: strings,
      onChanged: changes.add,
      onChangeEnd: ends.add,
    ),
  );
}

Finder _slider(Key row) =>
    find.descendant(of: find.byKey(row), matching: find.byType(NoteSlider));

Offset _point(WidgetTester tester, Key row, double fraction) {
  const thumb = 11.0;
  final rect = tester.getRect(_slider(row));

  return Offset(
    rect.left + thumb + fraction * (rect.width - 2 * thumb),
    rect.center.dy,
  );
}

Size _preview(WidgetTester tester) =>
    tester.getSize(find.byKey(NoteEraserSettingsPanel.previewKey));

void main() {
  testWidgets('shows the mode, size, preview and threshold', (tester) async {
    await tester.pumpWidget(_Events().panel());

    expect(find.text('Stroke eraser'), findsOneWidget);
    expect(find.text('Pixel eraser'), findsOneWidget);
    expect(find.text('Eraser size'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('Erase when pressing hard'), findsOneWidget);
    expect(find.text('80%'), findsOneWidget);
    expect(_preview(tester), const Size(12, 12));
  });

  testWidgets('switches the eraser type once', (tester) async {
    final events = _Events();
    await tester.pumpWidget(events.panel());

    await tester.tap(find.byKey(NoteEraserSettingsPanel.pixelModeKey));
    await tester.pump();
    await tester.tap(find.byKey(NoteEraserSettingsPanel.pixelModeKey));
    await tester.pump();

    const expected = NoteEraserSettings(mode: NoteEraserMode.pixel);
    expect(events.changes, [expected]);
    expect(events.ends, [expected]);

    await tester.tap(find.byKey(NoteEraserSettingsPanel.strokeModeKey));
    await tester.pump();

    expect(events.changes.last, const NoteEraserSettings());
  });

  testWidgets('the size slider covers 2 to 80 and the preview follows', (
    tester,
  ) async {
    final events = _Events();
    await tester.pumpWidget(events.panel());

    await tester.tapAt(_point(tester, NoteEraserSettingsPanel.sizeKey, 1));
    await tester.pump();

    expect(events.changes.last.size, 80);
    expect(events.ends.last.size, 80);
    expect(find.text('80'), findsOneWidget);
    expect(_preview(tester), const Size(80, 80));

    await tester.tapAt(_point(tester, NoteEraserSettingsPanel.sizeKey, 0));
    await tester.pump();

    expect(events.changes.last.size, 2);
    expect(_preview(tester), const Size(2, 2));
  });

  testWidgets('the threshold only works while the switch is on', (
    tester,
  ) async {
    final events = _Events();
    await tester.pumpWidget(events.panel());
    final threshold = _point(tester, NoteEraserSettingsPanel.thresholdKey, 1);

    await tester.tapAt(threshold);
    await tester.pump();
    expect(events.changes, isEmpty);

    await tester.tap(find.byKey(NoteEraserSettingsPanel.pressureSwitchKey));
    await tester.pumpAndSettle();
    expect(events.changes.single.pressureSwitchEnabled, isTrue);
    expect(events.ends, [events.changes.single]);

    await tester.tapAt(threshold);
    await tester.pump();
    expect(events.changes.last.pressureThreshold, 1);
    expect(find.text('100%'), findsOneWidget);

    await tester.tapAt(_point(tester, NoteEraserSettingsPanel.thresholdKey, 0));
    await tester.pump();
    expect(events.changes.last.pressureThreshold, closeTo(0.1, 1e-9));
  });

  testWidgets('the switch turns off again', (tester) async {
    final events = _Events();
    await tester.pumpWidget(
      events.panel(
        settings: const NoteEraserSettings(pressureSwitchEnabled: true),
      ),
    );

    await tester.tap(find.byKey(NoteEraserSettingsPanel.pressureSwitchKey));
    await tester.pumpAndSettle();

    expect(events.changes.single.pressureSwitchEnabled, isFalse);
  });

  testWidgets('takes over settings that change from outside', (tester) async {
    final events = _Events();
    await tester.pumpWidget(events.panel());

    await tester.pumpWidget(
      events.panel(settings: const NoteEraserSettings(size: 40.5)),
    );

    expect(find.text('40.5'), findsOneWidget);
    expect(_preview(tester), const Size(40.5, 40.5));
    expect(events.changes, isEmpty);
  });

  testWidgets('describes the switch and the mode to screen readers', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_Events().panel());

    expect(
      tester.getSemantics(
        find.bySemanticsLabel('Erase when pressing hard').first,
      ),
      isNotNull,
    );
    expect(find.bySemanticsLabel('Eraser type'), findsOneWidget);
    expect(find.bySemanticsLabel('Pixel eraser'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('uses translated strings', (tester) async {
    await tester.pumpWidget(
      _Events().panel(
        strings: const NoteToolsStrings(
          strokeEraser: '획 지우개',
          pixelEraser: '픽셀 지우개',
        ),
      ),
    );

    expect(find.text('획 지우개'), findsOneWidget);
    expect(find.text('픽셀 지우개'), findsOneWidget);
  });

  testWidgets('scrolls instead of overflowing a small space', (tester) async {
    await tester.pumpWidget(
      noteTestHost(
        Center(
          child: SizedBox(
            width: 260,
            height: 150,
            child: NoteEraserSettingsPanel(
              settings: const NoteEraserSettings(),
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}

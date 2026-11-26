import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/tools/tools.dart';

import '../support/note_test_host.dart';

class _Events {
  final List<String> selected = [];
  final List<String> edits = [];

  Widget bar(NoteToolPresetStore store, {Axis axis = Axis.horizontal}) =>
      noteTestHost(
        Align(
          alignment: Alignment.topLeft,
          child: NoteToolPresetBar(
            store: store,
            axis: axis,
            onSelected: (preset) => selected.add(preset.id),
            onEditRequested: (preset) => edits.add(preset.id),
          ),
        ),
      );
}

Finder _item(String id) => find.byKey(NoteToolPresetBar.itemKey(id));

void main() {
  testWidgets('shows a swatch with its width label per preset', (tester) async {
    final store = NoteToolPresetStore.defaults();
    await tester.pumpWidget(_Events().bar(store));

    for (final preset in store.presets) {
      expect(_item(preset.id), findsOneWidget);
      expect(
        find.descendant(
          of: _item(preset.id),
          matching: find.text(preset.widthLabel),
        ),
        findsOneWidget,
      );
    }
    expect(find.text('0.5'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
  });

  testWidgets('a tap selects the preset and reports it each time', (
    tester,
  ) async {
    final store = NoteToolPresetStore.defaults();
    final events = _Events();
    await tester.pumpWidget(events.bar(store));

    await tester.tap(_item(NoteToolPresetStore.bluePenId));
    await tester.pump();

    expect(store.activeId, NoteToolPresetStore.bluePenId);
    expect(events.selected, [NoteToolPresetStore.bluePenId]);

    await tester.tap(_item(NoteToolPresetStore.bluePenId));
    await tester.pump();

    expect(events.selected, [
      NoteToolPresetStore.bluePenId,
      NoteToolPresetStore.bluePenId,
    ]);
    expect(events.edits, isEmpty);
  });

  testWidgets('a long press asks to edit without selecting', (tester) async {
    final store = NoteToolPresetStore.defaults();
    final events = _Events();
    await tester.pumpWidget(events.bar(store));

    await tester.longPress(_item(NoteToolPresetStore.redPenId));
    await tester.pump();

    expect(events.edits, [NoteToolPresetStore.redPenId]);
    expect(events.selected, isEmpty);
    expect(store.activeId, NoteToolPresetStore.blackPenId);
  });

  testWidgets('a secondary click asks to edit', (tester) async {
    final store = NoteToolPresetStore.defaults();
    final events = _Events();
    await tester.pumpWidget(events.bar(store));

    await tester.tap(
      _item(NoteToolPresetStore.whitePenId),
      buttons: kSecondaryButton,
    );
    await tester.pump();

    expect(events.edits, [NoteToolPresetStore.whitePenId]);
    expect(events.selected, isEmpty);
  });

  testWidgets('without callbacks a long press counts as a tap', (tester) async {
    final store = NoteToolPresetStore.defaults();
    await tester.pumpWidget(noteTestHost(NoteToolPresetBar(store: store)));

    await tester.tap(_item(NoteToolPresetStore.redPenId));
    await tester.pump();
    expect(store.activeId, NoteToolPresetStore.redPenId);

    await tester.longPress(_item(NoteToolPresetStore.bluePenId));
    await tester.pump();

    expect(store.activeId, NoteToolPresetStore.bluePenId);
    expect(tester.takeException(), isNull);
  });

  testWidgets('follows the store', (tester) async {
    final store = NoteToolPresetStore.defaults();
    await tester.pumpWidget(_Events().bar(store));

    store.addFrom(
      ink: NoteInkTypes.pen,
      color: const Color(0xFF123456),
      width: 7.5,
    );
    await tester.pump();
    expect(find.text('7.5'), findsOneWidget);

    store.remove(NoteToolPresetStore.blackPenId);
    await tester.pump();
    expect(_item(NoteToolPresetStore.blackPenId), findsNothing);
  });

  testWidgets('says so when there are no presets', (tester) async {
    await tester.pumpWidget(_Events().bar(NoteToolPresetStore()));

    expect(find.text('No presets'), findsOneWidget);
  });

  testWidgets('lines up vertically when asked', (tester) async {
    final store = NoteToolPresetStore.defaults();
    await tester.pumpWidget(_Events().bar(store, axis: Axis.vertical));
    final first = tester.getCenter(_item(NoteToolPresetStore.blackPenId));
    final second = tester.getCenter(_item(NoteToolPresetStore.redPenId));

    expect(second.dx, first.dx);
    expect(second.dy, greaterThan(first.dy));
  });

  testWidgets('lines up horizontally by default', (tester) async {
    final store = NoteToolPresetStore.defaults();
    await tester.pumpWidget(_Events().bar(store));
    final first = tester.getCenter(_item(NoteToolPresetStore.blackPenId));
    final second = tester.getCenter(_item(NoteToolPresetStore.redPenId));

    expect(second.dy, first.dy);
    expect(second.dx, greaterThan(first.dx));
  });

  testWidgets('scrolls when the presets do not fit', (tester) async {
    final store = NoteToolPresetStore(
      presets: [
        for (var i = 0; i < 24; i++)
          NoteToolPreset(
            id: 'p$i',
            ink: NoteInkTypes.pen,
            color: const Color(0xFF000000),
            width: i + 1,
          ),
      ],
    );
    await tester.pumpWidget(_Events().bar(store));

    await tester.scrollUntilVisible(
      _item('p23'),
      300,
      scrollable: find.byType(Scrollable),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('describes each preset to screen readers', (tester) async {
    final semantics = tester.ensureSemantics();
    final store = NoteToolPresetStore.defaults()
      ..addFrom(
        ink: NoteInkTypes.marker,
        color: const Color(0x8000FF00),
        width: 3,
        select: false,
      );
    await tester.pumpWidget(_Events().bar(store));

    expect(find.bySemanticsLabel('Black pen, width 0.5'), findsOneWidget);
    expect(find.bySemanticsLabel('Marker, width 3'), findsOneWidget);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Black pen, width 0.5')),
      matchesSemantics(
        label: 'Black pen, width 0.5',
        hint: 'Long press to edit',
        isButton: true,
        hasSelectedState: true,
        isSelected: true,
        hasTapAction: true,
        hasLongPressAction: true,
      ),
    );
    semantics.dispose();
  });
}

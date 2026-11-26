// Rendering, selection gestures and accessibility of NoteTableView.
import 'package:flutter/gestures.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/table/table.dart';

import '../support/note_test_host.dart';
import 'support/table_invariants.dart';
import 'support/table_probe.dart';

Finder get _highlight => find.byKey(NoteTableView.selectionKey);

Rect _highlightRect(WidgetTester tester) => tester
    .getRect(_highlight)
    .shift(-tester.getTopLeft(find.byType(NoteTableView)));

void main() {
  group('layout', () {
    testWidgets('fills tight constraints', (tester) async {
      final probe = TableProbe()..size = const Size(240, 90);
      await probe.pump(tester);

      expect(tester.getSize(find.byType(NoteTableView)), const Size(240, 90));
    });

    testWidgets('takes its bounds size when unconstrained', (tester) async {
      await tester.pumpWidget(
        noteTestHost(
          UnconstrainedBox(
            child: NoteTableView(
              table: labelledTable(
                bounds: const Rect.fromLTWH(50, 60, 210, 99),
              ),
              scope: const NoteObjectViewScope(interactive: false),
            ),
          ),
        ),
      );

      expect(tester.getSize(find.byType(NoteTableView)), const Size(210, 99));
      expect(tester.takeException(), isNull);
    });

    testWidgets('survives a table squeezed to nothing', (tester) async {
      final probe = TableProbe()..size = const Size(2, 2);
      await probe.pump(tester);

      expect(tester.takeException(), isNull);
    });

    testWidgets('paints with the shared table painter', (tester) async {
      final probe = TableProbe();
      await probe.pump(tester);

      final painter = tester
          .widget<CustomPaint>(
            find.descendant(
              of: find.byType(NoteTableView),
              matching: find.byType(CustomPaint),
            ),
          )
          .painter;

      expect(painter, isA<NoteTablePainter>());
      expect((painter! as NoteTablePainter).table, probe.table);
    });
  });

  group('tap', () {
    testWidgets('selects the tapped cell and highlights it', (tester) async {
      final probe = TableProbe();
      await probe.pump(tester);
      expect(_highlight, findsNothing);

      await probe.tap(1, 2);

      expect(probe.range, const NoteTableRange.cell(1, 2));
      final rect = _highlightRect(tester);
      final layout = NoteTableLayout(probe.table, Offset.zero & probe.size);
      expect(rect, layout.cellRect(1, 2));
      expect(probe.changes, isEmpty);
      expect(probe.editorText, isNull);
    });

    testWidgets('selects at once, without waiting for a double tap', (
      tester,
    ) async {
      final probe = TableProbe();
      await probe.pump(tester);

      await tester.tapAt(probe.center(2, 0));
      await tester.pump();

      expect(probe.range, const NoteTableRange.cell(2, 0));
      await tester.pump(const Duration(milliseconds: 400));
    });

    testWidgets('selects a merged cell as a whole', (tester) async {
      final probe = TableProbe(
        table: labelledTable().mergeCells(span(0, 0, 1, 1)),
      );
      await probe.pump(tester);

      await probe.tap(1, 1);

      expect(probe.range, span(0, 0, 1, 1));
    });

    testWidgets('works with a private selection', (tester) async {
      final probe = TableProbe()..privateSelection = true;
      await probe.pump(tester);

      await probe.tap(0, 1);

      expect(_highlight, findsOneWidget);
      expect(probe.range, isNull);
    });
  });

  group('drag', () {
    testWidgets('selects a rectangular range', (tester) async {
      final probe = TableProbe();
      await probe.pump(tester);

      await probe.drag((0, 0), (1, 2));

      expect(probe.range, span(0, 0, 1, 2));
      final layout = NoteTableLayout(probe.table, Offset.zero & probe.size);
      expect(_highlightRect(tester), layout.rectOf(span(0, 0, 1, 2)));
    });

    testWidgets('works backwards and shrinks again', (tester) async {
      final probe = TableProbe();
      await probe.pump(tester);

      await probe.drag((2, 2), (1, 1), through: [(0, 0)]);

      expect(probe.range, span(1, 1, 2, 2));
    });

    testWidgets('grows over merged cells', (tester) async {
      final probe = TableProbe(
        table: labelledTable().mergeCells(span(1, 1, 2, 2)),
      );
      await probe.pump(tester);

      await probe.drag((0, 0), (0, 2), through: [(1, 1)]);
      expect(probe.range, span(0, 0, 0, 2));

      await probe.drag((0, 0), (1, 1));
      expect(probe.range, span(0, 0, 2, 2));
    });

    testWidgets('clamps a drag that leaves the table', (tester) async {
      final probe = TableProbe();
      await probe.pump(tester);

      await probe.drag((1, 1), (9, 9));

      expect(probe.range, span(1, 1, 2, 2));
    });
  });

  group('read-only', () {
    testWidgets('ignores gestures when not interactive', (tester) async {
      final probe = TableProbe()..interactive = false;
      await probe.pump(tester);

      await probe.tap(1, 1);
      await probe.doubleTap(1, 1);
      await probe.drag((0, 0), (2, 2));

      expect(probe.range, isNull);
      expect(probe.editorText, isNull);
      expect(probe.editRequests, 0);
    });

    testWidgets('hides the selection when not interactive', (tester) async {
      final probe = TableProbe()..interactive = false;
      await probe.pump(tester);

      probe.selection.select('t', const NoteTableRange.cell(0, 0));
      await tester.pump();

      expect(_highlight, findsNothing);
    });

    testWidgets('lets a surrounding detector receive taps', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        noteTestHost(
          Center(
            child: GestureDetector(
              onTap: () => taps++,
              child: SizedBox(
                width: 300,
                height: 120,
                child: NoteTableView(
                  table: labelledTable(),
                  scope: const NoteObjectViewScope(interactive: false),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tapAt(tester.getCenter(find.byType(NoteTableView)));
      await tester.pump(const Duration(milliseconds: 400));

      expect(taps, 1);
    });

    testWidgets('an interactive table keeps taps and drags to itself', (
      tester,
    ) async {
      var taps = 0;
      var drags = 0;
      final selection = NoteTableSelectionController();
      addTearDown(selection.dispose);
      await tester.pumpWidget(
        noteTestHost(
          Center(
            child: GestureDetector(
              onTap: () => taps++,
              onPanStart: (_) => drags++,
              child: SizedBox(
                width: 300,
                height: 120,
                child: NoteTableView(
                  table: labelledTable(),
                  selectionController: selection,
                  scope: const NoteObjectViewScope(),
                ),
              ),
            ),
          ),
        ),
      );
      final center = tester.getCenter(find.byType(NoteTableView));

      await tester.tapAt(center);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.dragFrom(center, const Offset(120, 0));
      await tester.pump(const Duration(milliseconds: 400));

      expect((taps, drags), (0, 0));
      expect(selection.rangeFor('t'), span(1, 1, 1, 2));
    });

    testWidgets('selects but never edits without onChanged', (tester) async {
      final probe = TableProbe()..writable = false;
      await probe.pump(tester);

      await probe.doubleTap(1, 1);
      await probe.update(() => probe.editing = true);

      expect(probe.range, const NoteTableRange.cell(1, 1));
      expect(probe.editorText, isNull);
      expect(probe.editRequests, 0);
    });
  });

  group('selection state', () {
    testWidgets('is cleared when the object is deselected', (tester) async {
      final probe = TableProbe()..selected = true;
      await probe.pump(tester);
      await probe.tap(1, 1);

      await probe.update(() => probe.selected = false);

      expect(probe.range, isNull);
      expect(_highlight, findsNothing);
    });

    testWidgets('is shown clamped when the table shrinks', (tester) async {
      final probe = TableProbe();
      await probe.pump(tester);
      await probe.tap(2, 2);

      await probe.update(() => probe.table = probe.table.withSize(2, 2));

      final layout = NoteTableLayout(probe.table, Offset.zero & probe.size);
      expect(_highlightRect(tester), layout.cellRect(1, 1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('of another table is not shown', (tester) async {
      final probe = TableProbe();
      await probe.pump(tester);

      probe.selection.select('other', const NoteTableRange.cell(0, 0));
      await tester.pump();

      expect(_highlight, findsNothing);
    });

    testWidgets('follows the controller from outside', (tester) async {
      final probe = TableProbe();
      await probe.pump(tester);

      probe.selection.select('t', span(0, 0, 1, 0));
      await tester.pump();

      expect(_highlight, findsOneWidget);
    });

    testWidgets('moves to a new controller', (tester) async {
      final probe = TableProbe();
      final other = NoteTableSelectionController();
      addTearDown(other.dispose);
      await probe.pump(tester);
      await probe.tap(1, 1);

      await probe.update(() => probe.otherSelection = other);
      await probe.tap(2, 2);

      expect(other.rangeFor('t'), const NoteTableRange.cell(2, 2));
    });
  });

  group('accessibility', () {
    testWidgets('labels the table and every visible cell', (tester) async {
      final handle = tester.ensureSemantics();
      final probe = TableProbe(
        table: labelledTable().mergeCells(span(0, 0, 0, 1)),
      );
      await probe.pump(tester);

      expect(find.bySemanticsLabel('Table, 3 rows, 3 columns'), findsOneWidget);
      expect(find.semantics.byLabel('Row 1, column 1'), findsOne);
      expect(find.semantics.byLabel('Row 1, column 2'), findsNothing);
      expect(find.semantics.byLabel('Row 3, column 3'), findsOne);
      final cell = find.semantics.byLabel('Row 2, column 2').evaluate().single;
      expect(cell.value, 'r1c1');
      handle.dispose();
    });

    testWidgets('selects a cell through a semantic tap', (tester) async {
      final handle = tester.ensureSemantics();
      final probe = TableProbe();
      await probe.pump(tester);

      tester.semantics.performAction(
        find.semantics.byLabel('Row 2, column 3'),
        SemanticsAction.tap,
      );
      await tester.pump();

      expect(probe.range, const NoteTableRange.cell(1, 2));
      final node = find.semantics.byLabel('Row 2, column 3').evaluate().single;
      expect(node.flagsCollection.isSelected.toBoolOrNull(), isTrue);
      handle.dispose();
    });
  });

  testWidgets('does not pretend to be scrollable to screen readers', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final probe = TableProbe();
    await probe.pump(tester);

    for (final action in [
      SemanticsAction.scrollLeft,
      SemanticsAction.scrollRight,
      SemanticsAction.scrollUp,
      SemanticsAction.scrollDown,
    ]) {
      expect(find.semantics.byAction(action), findsNothing, reason: '$action');
    }
    handle.dispose();
  });

  testWidgets('a mouse can select and drag too', (tester) async {
    final probe = TableProbe();
    await probe.pump(tester);

    final gesture = await tester.startGesture(
      probe.center(0, 0),
      kind: PointerDeviceKind.mouse,
    );
    await gesture.moveTo(probe.center(2, 1));
    await tester.pump();
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 400));

    expect(probe.range, span(0, 0, 2, 1));
  });
}

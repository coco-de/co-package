import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/view/view.dart';

import '../support/note_test_host.dart';
import 'note_view_test_support.dart';

const _a = ValueKey<String>('a');
const _b = ValueKey<String>('b');
const _c = ValueKey<String>('c');

/// 800 wide test surface, 12 wide dividers.
const double _twoPaneSpace = 800 - 12;

Widget _panes({
  Axis axis = Axis.horizontal,
  List<double>? fractions,
  List<double>? initialFractions,
  double minFraction = 0.15,
  ValueChanged<List<double>>? onFractionsChanged,
  ValueChanged<List<double>>? onResizeEnd,
  bool three = false,
}) => noteTestHost(
  NoteResizablePanes(
    axis: axis,
    fractions: fractions,
    initialFractions: initialFractions,
    minFraction: minFraction,
    onFractionsChanged: onFractionsChanged,
    onResizeEnd: onResizeEnd,
    children: [
      const SizedBox.expand(key: _a),
      const SizedBox.expand(key: _b),
      if (three) const SizedBox.expand(key: _c),
    ],
  ),
);

Future<void> _drag(WidgetTester tester, int divider, Offset offset) async {
  await tester.drag(find.byKey(NoteResizablePanes.dividerKey(divider)), offset);
  await tester.pump();
}

double _widthOf(WidgetTester tester, Key key) =>
    tester.getSize(find.byKey(key)).width;

void main() {
  group('NoteResizablePanes', () {
    testWidgets('lays two equal panes around the divider', (tester) async {
      await tester.pumpWidget(_panes());

      expect(
        tester.getRect(find.byKey(_a)),
        const Rect.fromLTWH(0, 0, 394, 600),
      );
      expect(
        tester.getRect(find.byKey(_b)),
        const Rect.fromLTWH(406, 0, 394, 600),
      );
    });

    testWidgets('dragging the divider resizes both panes', (tester) async {
      await tester.pumpWidget(_panes());

      await _drag(tester, 0, const Offset(_twoPaneSpace * 0.1, 0));

      expect(_widthOf(tester, _a), closeTo(_twoPaneSpace * 0.6, 0.01));
      expect(_widthOf(tester, _b), closeTo(_twoPaneSpace * 0.4, 0.01));
    });

    testWidgets('stops at the minimum fraction both ways', (tester) async {
      await tester.pumpWidget(_panes());

      await _drag(tester, 0, const Offset(-2000, 0));
      expect(_widthOf(tester, _a), closeTo(_twoPaneSpace * 0.15, 0.01));

      await _drag(tester, 0, const Offset(2000, 0));
      expect(_widthOf(tester, _a), closeTo(_twoPaneSpace * 0.85, 0.01));
    });

    testWidgets('starts from initialFractions', (tester) async {
      await tester.pumpWidget(_panes(initialFractions: const [1, 3]));

      expect(_widthOf(tester, _a), closeTo(_twoPaneSpace / 4, 0.01));
    });

    testWidgets('reports every move and the final sizes', (tester) async {
      final changes = <List<double>>[];
      final ends = <List<double>>[];
      await tester.pumpWidget(
        _panes(onFractionsChanged: changes.add, onResizeEnd: ends.add),
      );

      await _drag(tester, 0, const Offset(_twoPaneSpace * 0.1, 0));

      expect(changes, isNotEmpty);
      expect(changes.last.first, closeTo(0.6, 1e-6));
      expect(changes.last.last, closeTo(0.4, 1e-6));
      expect(ends, hasLength(1));
      expect(ends.single.first, closeTo(0.6, 1e-6));
    });

    testWidgets('a controlled widget only moves with its fractions', (
      tester,
    ) async {
      final changes = <List<double>>[];
      await tester.pumpWidget(
        _panes(fractions: const [0.25, 0.75], onFractionsChanged: changes.add),
      );

      await _drag(tester, 0, const Offset(_twoPaneSpace * 0.25, 0));

      expect(changes.last.first, closeTo(0.5, 1e-6));
      expect(_widthOf(tester, _a), closeTo(_twoPaneSpace * 0.25, 0.01));
    });

    testWidgets('a controlled widget follows its owner', (tester) async {
      var fractions = <double>[0.5, 0.5];
      await tester.pumpWidget(
        noteTestHost(
          StatefulBuilder(
            builder: (context, setState) => NoteResizablePanes(
              fractions: fractions,
              onFractionsChanged: (next) => setState(() => fractions = next),
              children: const [
                SizedBox.expand(key: _a),
                SizedBox.expand(key: _b),
              ],
            ),
          ),
        ),
      );

      await _drag(tester, 0, const Offset(-_twoPaneSpace * 0.2, 0));

      expect(fractions.first, closeTo(0.3, 1e-6));
      expect(_widthOf(tester, _a), closeTo(_twoPaneSpace * 0.3, 0.01));
    });

    testWidgets('stacks panes along the vertical axis', (tester) async {
      await tester.pumpWidget(_panes(axis: Axis.vertical));
      const space = 600.0 - 12;

      expect(tester.getSize(find.byKey(_a)), const Size(800, space / 2));
      await _drag(tester, 0, const Offset(0, space * 0.1));

      expect(tester.getSize(find.byKey(_a)).height, closeTo(space * 0.6, 0.01));
      expect(
        tester.getTopLeft(find.byKey(_b)).dy,
        closeTo(space * 0.6 + 12, 0.01),
      );
    });

    testWidgets('a divider changes only its two neighbours', (tester) async {
      await tester.pumpWidget(_panes(three: true));
      const space = 800.0 - 24;
      final first = _widthOf(tester, _a);
      expect(first, closeTo(space / 3, 0.01));

      await _drag(tester, 1, const Offset(space * 0.1, 0));

      expect(_widthOf(tester, _a), closeTo(first, 0.01));
      expect(_widthOf(tester, _b), closeTo(space * (1 / 3 + 0.1), 0.01));
      expect(_widthOf(tester, _c), closeTo(space * (1 / 3 - 0.1), 0.01));
    });

    testWidgets('screen readers can resize', (tester) async {
      final semantics = tester.ensureSemantics();
      final ends = <List<double>>[];
      await tester.pumpWidget(_panes(onResizeEnd: ends.add));

      tester.semantics.increase(find.semantics.byLabel('Resize panes'));
      await tester.pump();

      expect(_widthOf(tester, _a), closeTo(_twoPaneSpace * 0.55, 0.01));
      expect(ends.single.first, closeTo(0.55, 1e-6));
      tester.semantics.decrease(find.semantics.byLabel('Resize panes'));
      await tester.pump();
      expect(_widthOf(tester, _a), closeTo(_twoPaneSpace * 0.5, 0.01));
      semantics.dispose();
    });

    testWidgets('keyed children keep their state when reordered', (
      tester,
    ) async {
      Widget build(List<Key> keys) => noteTestHost(
        NoteResizablePanes(
          children: [for (final key in keys) StatefulProbe(key: key)],
        ),
      );
      await tester.pumpWidget(build([_a, _b]));
      tester.state<StatefulProbeState>(find.byKey(_a)).marker = 7;

      await tester.pumpWidget(build([_b, _a]));

      expect(tester.state<StatefulProbeState>(find.byKey(_a)).marker, 7);
    });

    testWidgets('can be built const, also without children', (tester) async {
      const panes = NoteResizablePanes(children: []);

      await tester.pumpWidget(noteTestHost(panes));

      expect(tester.takeException(), isNull);
      expect(find.byKey(NoteResizablePanes.dividerKey(0)), findsNothing);
    });

    testWidgets('equalizes when the number of panes changes', (tester) async {
      await tester.pumpWidget(_panes(initialFractions: const [0.2, 0.8]));

      await tester.pumpWidget(_panes(three: true));
      await tester.pump();

      expect(_widthOf(tester, _a), closeTo((800 - 24) / 3, 0.01));
    });
  });

  group('NoteSplitView', () {
    Widget split({
      double? ratio,
      double initialRatio = 0.5,
      ValueChanged<double>? onRatioChanged,
      ValueChanged<double>? onResizeEnd,
      Axis axis = Axis.horizontal,
    }) => noteTestHost(
      NoteSplitView(
        axis: axis,
        ratio: ratio,
        initialRatio: initialRatio,
        onRatioChanged: onRatioChanged,
        onResizeEnd: onResizeEnd,
        first: const SizedBox.expand(key: _a),
        second: const SizedBox.expand(key: _b),
      ),
    );

    testWidgets('draws the given ratio', (tester) async {
      await tester.pumpWidget(split(ratio: 0.3));

      expect(_widthOf(tester, _a), closeTo(_twoPaneSpace * 0.3, 0.01));
      expect(_widthOf(tester, _b), closeTo(_twoPaneSpace * 0.7, 0.01));
    });

    testWidgets('keeps its own ratio when uncontrolled', (tester) async {
      await tester.pumpWidget(split(initialRatio: 0.7));

      await tester.drag(
        find.byKey(NoteResizablePanes.dividerKey(0)),
        const Offset(-_twoPaneSpace * 0.2, 0),
      );
      await tester.pump();

      expect(_widthOf(tester, _a), closeTo(_twoPaneSpace * 0.5, 0.01));
    });

    testWidgets('keeps the ratio within 0.2 to 0.8', (tester) async {
      final ratios = <double>[];
      final ends = <double>[];
      await tester.pumpWidget(
        split(onRatioChanged: ratios.add, onResizeEnd: ends.add),
      );

      await tester.drag(
        find.byKey(NoteResizablePanes.dividerKey(0)),
        const Offset(2000, 0),
      );

      expect(ratios.last, closeTo(0.8, 1e-9));
      expect(ends.single, closeTo(0.8, 1e-9));
    });

    testWidgets('can stack vertically', (tester) async {
      await tester.pumpWidget(split(axis: Axis.vertical, ratio: 0.25));

      expect(
        tester.getSize(find.byKey(_a)).height,
        closeTo((600 - 12) * 0.25, 0.01),
      );
    });
  });
}

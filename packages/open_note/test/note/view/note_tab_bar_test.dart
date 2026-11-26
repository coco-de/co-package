import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/view/view.dart';

import '../support/note_test_host.dart';

NoteTabsController _abc() => NoteTabsController(
  tabs: const [
    NoteTab(noteId: 'a', title: 'Alpha'),
    NoteTab(noteId: 'b', title: 'Beta'),
    NoteTab(noteId: 'c', title: 'Gamma'),
  ],
);

Widget _host(
  NoteTabsController controller, {
  ValueChanged<String>? onSelected,
  ValueChanged<String>? onCloseRequested,
  bool reorderable = true,
  Widget? trailing,
  Widget? below,
}) => noteTestHost(
  Column(
    children: [
      NoteTabBar(
        controller: controller,
        onSelected: onSelected,
        onCloseRequested: onCloseRequested,
        reorderable: reorderable,
        trailing: trailing,
      ),
      Expanded(child: below ?? const SizedBox.expand()),
    ],
  ),
);

List<String> _ids(NoteTabsController controller) => [
  for (final tab in controller.tabs) tab.noteId,
];

Future<TestGesture> _pickUp(WidgetTester tester, String noteId) async {
  final gesture = await tester.startGesture(
    tester.getCenter(find.byKey(NoteTabBar.tabKey(noteId))),
  );
  await tester.pump(const Duration(milliseconds: 400));

  return gesture;
}

void main() {
  testWidgets('shows every title and a placeholder for none', (tester) async {
    final controller = _abc()..open('d', '');
    await tester.pumpWidget(_host(controller));

    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Beta'), findsOneWidget);
    expect(find.text('Untitled'), findsOneWidget);
  });

  testWidgets('a tap selects the tab', (tester) async {
    final controller = _abc();
    final selected = <String>[];
    await tester.pumpWidget(_host(controller, onSelected: selected.add));

    await tester.tap(find.text('Gamma'));
    await tester.pump();

    expect(controller.activeId, 'c');
    expect(selected, ['c']);
  });

  testWidgets('the close button closes the tab', (tester) async {
    final controller = _abc();
    await tester.pumpWidget(_host(controller));

    await tester.tap(find.byKey(NoteTabBar.closeKey('b')));
    await tester.pump();

    expect(_ids(controller), ['a', 'c']);
    expect(controller.activeId, 'a');
    expect(find.text('Beta'), findsNothing);
  });

  testWidgets('a close request leaves closing to the host', (tester) async {
    final controller = _abc();
    final requests = <String>[];
    await tester.pumpWidget(_host(controller, onCloseRequested: requests.add));

    await tester.tap(find.byKey(NoteTabBar.closeKey('a')));

    expect(requests, ['a']);
    expect(_ids(controller), ['a', 'b', 'c']);
  });

  testWidgets('marks the active tab for screen readers', (tester) async {
    final semantics = tester.ensureSemantics();
    final controller = _abc()..activate('b');
    await tester.pumpWidget(_host(controller));

    expect(
      find.semantics.byLabel('Beta').evaluate().single,
      isSemantics(isSelected: true, isButton: true),
    );
    expect(
      find.semantics.byLabel('Alpha').evaluate().single,
      isSemantics(isSelected: false),
    );
    expect(find.semantics.byLabel('Close tab: Beta'), findsOne);
    semantics.dispose();
  });

  testWidgets('a long press drag reorders the tabs', (tester) async {
    final controller = _abc();
    await tester.pumpWidget(_host(controller));
    final gesture = await _pickUp(tester, 'a');

    await gesture.moveTo(tester.getCenter(find.byKey(NoteTabBar.tabKey('c'))));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(_ids(controller), ['b', 'c', 'a']);
  });

  testWidgets('dragging backwards puts the tab in front', (tester) async {
    final controller = _abc();
    await tester.pumpWidget(_host(controller));
    final gesture = await _pickUp(tester, 'c');

    await gesture.moveTo(tester.getCenter(find.byKey(NoteTabBar.tabKey('a'))));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(_ids(controller), ['c', 'a', 'b']);
  });

  testWidgets('does not pick tabs up when not reorderable', (tester) async {
    final controller = _abc();
    await tester.pumpWidget(_host(controller, reorderable: false));

    expect(find.byType(LongPressDraggable<NoteDragData>), findsNothing);
    final gesture = await _pickUp(tester, 'a');
    await gesture.moveTo(tester.getCenter(find.byKey(NoteTabBar.tabKey('c'))));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(_ids(controller), ['a', 'b', 'c']);
  });

  testWidgets('a picked-up tab can be dropped beside the page', (tester) async {
    final controller = _abc();
    final drops = <(String, NoteDropSide)>[];
    await tester.pumpWidget(
      _host(
        controller,
        below: NoteDropSplitTarget(
          onDrop: (data, side) => drops.add((data.noteId, side)),
          child: const SizedBox.expand(),
        ),
      ),
    );
    final gesture = await _pickUp(tester, 'b');

    await gesture.moveTo(const Offset(750, 300));
    await tester.pump();
    expect(find.text('Open on the right'), findsOneWidget);
    await gesture.up();
    await tester.pumpAndSettle();

    expect(drops, [('b', NoteDropSide.right)]);
    expect(_ids(controller), ['a', 'b', 'c']);
  });

  testWidgets('shows the trailing widget after the tabs', (tester) async {
    await tester.pumpWidget(
      _host(_abc(), trailing: const SizedBox(key: ValueKey('plus'), width: 40)),
    );

    expect(tester.getTopRight(find.byKey(const ValueKey('plus'))).dx, 800);
  });

  testWidgets('scrolls the newly active tab into view', (tester) async {
    final controller = NoteTabsController();
    await tester.pumpWidget(_host(controller));
    for (var i = 0; i < 20; i++) {
      controller.open('n$i', 'A rather long title $i');
    }
    await tester.pumpAndSettle();
    final last = tester.getRect(find.byKey(NoteTabBar.tabKey('n19')));
    expect(last.right, lessThanOrEqualTo(800.01));
    expect(last.left, greaterThanOrEqualTo(-0.01));

    controller.activate('n0');
    await tester.pumpAndSettle();

    final first = tester.getRect(find.byKey(NoteTabBar.tabKey('n0')));
    expect(first.left, closeTo(0, 0.01));
  });

  testWidgets('follows the controller', (tester) async {
    final controller = _abc();
    await tester.pumpWidget(_host(controller));

    controller.rename('a', 'Renamed');
    await tester.pump();

    expect(find.text('Renamed'), findsOneWidget);
  });
}

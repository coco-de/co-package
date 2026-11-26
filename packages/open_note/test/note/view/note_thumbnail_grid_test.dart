import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/view/view.dart';

import '../support/note_test_host.dart';

Key _cell(int index) => ValueKey<String>('note-thumbnail-$index');

const _currentRing = ValueKey<String>('note-thumbnail-current');
const _selectedRing = ValueKey<String>('note-thumbnail-selected');

Widget _grid(
  NoteThumbnailGridController controller, {
  int pages = 12,
  int? currentPage,
  ValueChanged<int>? onPageTap,
  ValueChanged<int>? onPageLongPress,
  ScrollController? scrollController,
}) => noteTestHost(
  NoteThumbnailGrid(
    controller: controller,
    pageCount: pages,
    currentPage: currentPage,
    onPageTap: onPageTap,
    onPageLongPress: onPageLongPress,
    scrollController: scrollController,
    itemBuilder: (context, index) => ColoredBox(
      key: ValueKey<String>('preview-$index'),
      color: const Color(0xFFEEEEEE),
    ),
  ),
);

/// Two fingers 100 apart on the same row.
Future<(TestGesture, TestGesture)> _touch(WidgetTester tester) async {
  final left = await tester.startGesture(const Offset(350, 200));
  final right = await tester.startGesture(const Offset(450, 200));
  await tester.pump();

  return (left, right);
}

Future<void> _spreadTo(
  WidgetTester tester,
  TestGesture right,
  double span,
) async {
  await right.moveTo(Offset(350 + span, 200));
  await tester.pump();
}

void main() {
  testWidgets('shows a preview and a number for every page', (tester) async {
    final controller = NoteThumbnailGridController();

    await tester.pumpWidget(_grid(controller, pages: 4));

    for (var i = 0; i < 4; i++) {
      expect(find.byKey(_cell(i)), findsOneWidget);
      expect(find.byKey(ValueKey<String>('preview-$i')), findsOneWidget);
      expect(find.text('${i + 1}'), findsOneWidget);
    }
  });

  testWidgets('lays out the controller columns', (tester) async {
    final controller = NoteThumbnailGridController();
    await tester.pumpWidget(_grid(controller, pages: 4));
    // (800 - 2 * 12 padding - 2 * 12 spacing) / 3
    expect(
      tester.getSize(find.byKey(_cell(0))).width,
      closeTo((800 - 48) / 3, 0.01),
    );

    controller.setColumns(2);
    await tester.pump();

    expect(tester.getSize(find.byKey(_cell(0))).width, closeTo(382, 0.01));
    expect(
      tester.getTopLeft(find.byKey(_cell(2))).dy,
      greaterThan(tester.getTopLeft(find.byKey(_cell(0))).dy),
    );
  });

  testWidgets('rings the current page', (tester) async {
    await tester.pumpWidget(
      _grid(NoteThumbnailGridController(), pages: 5, currentPage: 2),
    );

    expect(find.byKey(_currentRing), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(_cell(2)),
        matching: find.byKey(_currentRing),
      ),
      findsOneWidget,
    );
  });

  testWidgets('a tap opens a page, a long press reports it', (tester) async {
    final taps = <int>[];
    final holds = <int>[];
    await tester.pumpWidget(
      _grid(
        NoteThumbnailGridController(),
        onPageTap: taps.add,
        onPageLongPress: holds.add,
      ),
    );

    await tester.tap(find.byKey(_cell(1)));
    await tester.longPress(find.byKey(_cell(0)));

    expect(taps, [1]);
    expect(holds, [0]);
  });

  testWidgets('in selection mode a tap toggles the page', (tester) async {
    final controller = NoteThumbnailGridController()..setSelectionMode(true);
    final taps = <int>[];
    await tester.pumpWidget(_grid(controller, onPageTap: taps.add));

    await tester.tap(find.byKey(_cell(1)));
    await tester.tap(find.byKey(_cell(3)));
    await tester.pump();

    expect(controller.selection, {1, 3});
    expect(taps, isEmpty);
    expect(find.byKey(_selectedRing), findsNWidgets(2));

    await tester.tap(find.byKey(_cell(1)));
    await tester.pump();
    expect(controller.selection, {3});
  });

  testWidgets('announces pages to screen readers', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _grid(NoteThumbnailGridController(), pages: 3, currentPage: 1),
    );

    final node = tester.getSemantics(find.byKey(_cell(1)));

    expect(node.label, contains('Page 2'));
    expect(node.value, 'Current page');
    semantics.dispose();
  });

  testWidgets('pinching changes columns in steps', (tester) async {
    final controller = NoteThumbnailGridController();
    final taps = <int>[];
    await tester.pumpWidget(_grid(controller, onPageTap: taps.add));
    final (left, right) = await _touch(tester);

    await _spreadTo(tester, right, 120); // × 1.2
    expect(controller.columns, 3);
    await _spreadTo(tester, right, 126); // × 1.26 in total
    expect(controller.columns, 2);
    await _spreadTo(tester, right, 104); // back a little: no flicker
    expect(controller.columns, 2);
    await _spreadTo(tester, right, 96); // past the lower threshold
    expect(controller.columns, 3);

    await right.up();
    await left.up();
    await tester.pumpAndSettle();
    expect(taps, isEmpty, reason: 'the finger that did not move is no tap');
  });

  testWidgets('a new pinch starts from scratch', (tester) async {
    final controller = NoteThumbnailGridController();
    await tester.pumpWidget(_grid(controller));
    final first = await _touch(tester);
    await _spreadTo(tester, first.$2, 120);
    await first.$2.up();
    await first.$1.up();
    await tester.pump();

    final second = await _touch(tester);
    await _spreadTo(tester, second.$2, 110);
    await second.$2.up();
    await second.$1.up();
    await tester.pump();

    expect(controller.columns, 3);
  });

  testWidgets('does not scroll while two fingers are down', (tester) async {
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    await tester.pumpWidget(
      _grid(NoteThumbnailGridController(), scrollController: scroll),
    );
    final (left, right) = await _touch(tester);

    await left.moveBy(const Offset(0, -150));
    await right.moveBy(const Offset(0, -150));
    await tester.pump();

    expect(scroll.offset, 0);
    await left.up();
    await right.up();
    await tester.pumpAndSettle();
  });

  testWidgets('scrolls with one finger, also after a pinch', (tester) async {
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    await tester.pumpWidget(
      _grid(NoteThumbnailGridController(), scrollController: scroll),
    );
    final (left, right) = await _touch(tester);
    await left.up();
    await right.up();
    await tester.pump();

    await tester.drag(find.byKey(_cell(0)), const Offset(0, -200));
    await tester.pumpAndSettle();

    expect(scroll.offset, greaterThan(100));
  });

  testWidgets('a trackpad pinch changes columns', (tester) async {
    final controller = NoteThumbnailGridController();
    await tester.pumpWidget(_grid(controller));
    final pointer = await tester.createGesture(
      kind: PointerDeviceKind.trackpad,
    );

    await pointer.panZoomStart(const Offset(400, 300));
    await pointer.panZoomUpdate(const Offset(400, 300), scale: 1.3);
    await tester.pump();
    expect(controller.columns, 2);
    await pointer.panZoomUpdate(const Offset(400, 300), scale: 0.95);
    await tester.pump();
    expect(controller.columns, 3);
    await pointer.panZoomEnd();
    await tester.pumpAndSettle();
  });

  testWidgets('survives a width with no room for cells', (tester) async {
    await tester.pumpWidget(
      noteTestHost(
        Center(
          child: SizedBox(
            width: 20,
            height: 100,
            child: NoteThumbnailGrid(
              controller: NoteThumbnailGridController(),
              pageCount: 3,
              itemBuilder: (context, index) => const SizedBox(),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byKey(_cell(0)), findsNothing);
  });
}

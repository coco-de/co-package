import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/study/overlay/overlay.dart';

import '../../support/note_test_host.dart';
import 'overlay_test_support.dart';

/// A window body with state: a tap adds one.
class _Counter extends StatefulWidget {
  const _Counter(this.name);

  final String name;

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int _count = 0;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: () => setState(() => _count++),
    child: Center(child: Text('${widget.name}=$_count')),
  );
}

NoteFloatingWindowSpec _spec(
  String id, {
  Rect rect = const Rect.fromLTWH(40, 40, 300, 240),
  bool resizable = true,
  double opacity = 1,
}) => NoteFloatingWindowSpec(
  id: id,
  title: 'Window $id',
  initialRect: rect,
  resizable: resizable,
  opacity: opacity,
  builder: (context) => _Counter(id),
);

Finder _window(String id) => find.byKey(ValueKey('note-floating-window-$id'));

Finder _part(String part, String id) =>
    find.byKey(ValueKey('note-floating-$part-$id'));

/// The host fills the 800 x 600 test surface.
Future<NoteFloatingWindowController> _pump(
  WidgetTester tester,
  List<NoteFloatingWindowSpec> specs, {
  Widget? child,
}) async {
  final controller = NoteFloatingWindowController();
  addTearDown(controller.dispose);
  specs.forEach(controller.open);
  await tester.pumpWidget(
    noteTestHost(NoteFloatingWindowHost(controller: controller, child: child)),
  );
  await tester.pump();

  return controller;
}

Future<void> _drag(WidgetTester tester, Finder finder, Offset offset) async {
  await tester.drag(finder, offset);
  await tester.pump();
}

void main() {
  testWidgets('draws each window at its place with its title and body', (
    tester,
  ) async {
    await _pump(tester, [_spec('a')]);

    expect(tester.getRect(_window('a')), const Rect.fromLTWH(40, 40, 300, 240));
    expect(find.text('Window a'), findsOneWidget);
    expect(find.text('a=0'), findsOneWidget);
  });

  testWidgets('dragging the title bar moves the window with the pointer', (
    tester,
  ) async {
    final controller = await _pump(tester, [_spec('a')]);

    await _drag(tester, _part('title', 'a'), const Offset(120, 70));

    expect(
      controller.window('a')!.rect,
      const Rect.fromLTWH(160, 110, 300, 240),
    );
    expect(tester.getRect(_window('a')), controller.window('a')!.rect);
  });

  testWidgets('a window cannot be dragged out of the host', (tester) async {
    final controller = await _pump(tester, [_spec('a')]);

    await _drag(tester, _part('title', 'a'), const Offset(2000, 2000));
    expect(
      controller.window('a')!.rect,
      const Rect.fromLTWH(500, 360, 300, 240),
    );

    await _drag(tester, _part('title', 'a'), const Offset(-2000, -2000));
    expect(controller.window('a')!.rect, const Rect.fromLTWH(0, 0, 300, 240));
  });

  testWidgets('a window held at the edge waits for the pointer to return', (
    tester,
  ) async {
    final controller = await _pump(tester, [_spec('a')]);
    final gesture = await tester.startGesture(
      tester.getCenter(_part('title', 'a')),
    );

    await gesture.moveBy(const Offset(600, 0));
    await tester.pump();
    expect(controller.window('a')!.rect.left, 500);
    await gesture.moveBy(const Offset(-590, 0));
    await gesture.up();

    expect(controller.window('a')!.rect.left, 50);
  });

  testWidgets('the corner resizes between the minimum and the host', (
    tester,
  ) async {
    final controller = await _pump(tester, [_spec('a')]);

    await _drag(tester, _part('resize', 'a'), const Offset(60, 40));
    expect(controller.window('a')!.rect, const Rect.fromLTWH(40, 40, 360, 280));

    await _drag(tester, _part('resize', 'a'), const Offset(-1000, -1000));
    expect(controller.window('a')!.rect, const Rect.fromLTWH(40, 40, 200, 160));

    await _drag(tester, _part('resize', 'a'), const Offset(2000, 2000));
    expect(controller.window('a')!.rect, const Rect.fromLTWH(40, 40, 760, 560));
  });

  testWidgets('a tiny minimum size still leaves room for the title bar', (
    tester,
  ) async {
    final controller = await _pump(tester, [
      NoteFloatingWindowSpec(
        id: 'a',
        title: 'A very long window title that cannot fit',
        initialRect: const Rect.fromLTWH(40, 40, 10, 10),
        minSize: const Size(1, 1),
        builder: (context) => const SizedBox(),
      ),
    ]);

    expect(tester.takeException(), isNull);
    expect(tester.getSize(_window('a')), const Size(114, 58));
    expect(
      tester.getRect(_part('resize', 'a')).top,
      tester.getRect(_part('close', 'a')).bottom,
    );

    await _drag(tester, _part('resize', 'a'), const Offset(-500, -500));

    expect(tester.takeException(), isNull);
    expect(controller.window('a')!.rect.size, const Size(114, 58));
  });

  testWidgets('a fixed window has no resize corner', (tester) async {
    await _pump(tester, [_spec('a', resizable: false)]);

    expect(_part('resize', 'a'), findsNothing);
  });

  testWidgets('pressing a window focuses it and brings it to the front', (
    tester,
  ) async {
    final controller = await _pump(tester, [
      _spec('a'),
      _spec('b', rect: const Rect.fromLTWH(200, 100, 300, 240)),
    ]);
    expect(controller.focusedId, 'b');

    // (60, 220) is only in a; the overlap at (260, 220) belongs to b.
    await tester.tapAt(const Offset(260, 220));
    await tester.pump();
    expect(find.text('b=1'), findsOneWidget);
    expect(find.text('a=0'), findsOneWidget);

    await tester.tapAt(const Offset(60, 220));
    await tester.pump();
    expect(controller.focusedId, 'a');
    expect(controller.windows.last.id, 'a');

    await tester.tapAt(const Offset(260, 220));
    await tester.pump();

    expect(find.text('a=2'), findsOneWidget);
    expect(find.text('b=1'), findsOneWidget);
  });

  testWidgets('the body keeps its state across focus changes and minimize', (
    tester,
  ) async {
    final controller = await _pump(tester, [
      _spec('a'),
      _spec('b', rect: const Rect.fromLTWH(440, 40, 300, 240)),
    ]);
    await tester.tap(find.text('a=0'));
    await tester.pump();

    controller
      ..focus('b')
      ..focus('a')
      ..focus('b');
    await tester.pump();
    expect(find.text('a=1'), findsOneWidget);

    await tester.tap(_part('minimize', 'a'));
    await tester.pump();
    expect(find.text('a=1'), findsNothing);
    expect(find.text('a=1', skipOffstage: false), findsOneWidget);
    expect(tester.getRect(_window('a')), const Rect.fromLTWH(40, 40, 300, 36));
    expect(_part('resize', 'a'), findsNothing);

    await tester.tap(_part('minimize', 'a'));
    await tester.pump();

    expect(find.text('a=1'), findsOneWidget);
    expect(tester.getRect(_window('a')).height, 240);
  });

  testWidgets('a minimized window can sit at the bottom edge', (tester) async {
    final controller = await _pump(tester, [_spec('a')]);
    controller.minimize('a');
    await tester.pump();

    await _drag(tester, _part('title', 'a'), const Offset(0, 2000));
    expect(tester.getRect(_window('a')).bottom, 600);
    expect(controller.window('a')!.rect.height, 240);

    controller.restore('a');
    await tester.pump();

    expect(
      tester.getRect(_window('a')),
      const Rect.fromLTWH(40, 360, 300, 240),
    );
  });

  testWidgets('the pin button keeps a window above the others', (tester) async {
    final controller = await _pump(tester, [
      _spec('a'),
      _spec('b', rect: const Rect.fromLTWH(200, 100, 300, 240)),
    ]);
    controller.focus('a');
    await tester.pump();

    await tester.tap(_part('pin', 'a'));
    await tester.pump();
    expect(controller.window('a')!.pinned, isTrue);

    await tester.tapAt(const Offset(450, 200));
    await tester.pump();

    expect(controller.focusedId, 'b');
    expect(controller.windows.last.id, 'a');
  });

  testWidgets('the close button closes only its window', (tester) async {
    final controller = await _pump(tester, [
      _spec('a'),
      _spec('b', rect: const Rect.fromLTWH(440, 40, 300, 240)),
    ]);

    await tester.tap(_part('close', 'a'));
    await tester.pump();

    expect(controller.isOpen('a'), isFalse);
    expect(_window('a'), findsNothing);
    expect(_window('b'), findsOneWidget);
  });

  testWidgets('dragging a title bar button does not move the window', (
    tester,
  ) async {
    final controller = await _pump(tester, [_spec('a')]);

    await _drag(tester, _part('pin', 'a'), const Offset(80, 80));

    expect(controller.window('a')!.rect, const Rect.fromLTWH(40, 40, 300, 240));
  });

  testWidgets('a window placed off the host is drawn inside it', (
    tester,
  ) async {
    final controller = await _pump(tester, [
      _spec('a', rect: const Rect.fromLTWH(2000, 2000, 300, 240)),
    ]);

    expect(
      tester.getRect(_window('a')),
      const Rect.fromLTWH(500, 360, 300, 240),
    );
    expect(controller.window('a')!.rect.left, 2000);
  });

  testWidgets('a shrinking host moves windows in without forgetting them', (
    tester,
  ) async {
    final controller = NoteFloatingWindowController()
      ..open(_spec('a', rect: const Rect.fromLTWH(400, 300, 300, 240)));
    addTearDown(controller.dispose);
    Widget hostOf(Size size) =>
        boxed(NoteFloatingWindowHost(controller: controller), size: size);

    await tester.pumpWidget(hostOf(const Size(400, 300)));
    await tester.pump();
    expect(
      tester.getRect(_window('a')),
      const Rect.fromLTWH(100, 60, 300, 240),
    );

    await tester.pumpWidget(hostOf(const Size(800, 600)));

    expect(
      tester.getRect(_window('a')),
      const Rect.fromLTWH(400, 300, 300, 240),
    );
  });

  testWidgets('presses beside the windows reach the content beneath', (
    tester,
  ) async {
    await _pump(tester, [_spec('a')], child: const _Counter('page'));

    await tester.tapAt(const Offset(700, 500));
    await tester.tapAt(const Offset(100, 200));
    await tester.pump();

    expect(find.text('page=1'), findsOneWidget);
    expect(find.text('a=1'), findsOneWidget);
  });

  testWidgets('without content, presses pass through the host', (tester) async {
    final controller = NoteFloatingWindowController()..open(_spec('a'));
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      noteTestHost(
        Stack(
          children: [
            const Positioned.fill(child: _Counter('under')),
            Positioned.fill(
              child: NoteFloatingWindowHost(controller: controller),
            ),
          ],
        ),
      ),
    );
    await tester.pump();
    await tester.tapAt(const Offset(700, 500));
    await tester.pump();

    expect(find.text('under=1'), findsOneWidget);
  });

  testWidgets('applies the window opacity', (tester) async {
    final controller = await _pump(tester, [_spec('a', opacity: 0.5)]);

    double opacity() => tester
        .widget<Opacity>(
          find.ancestor(of: _window('a'), matching: find.byType(Opacity)),
        )
        .opacity;

    expect(opacity(), 0.5);
    controller.setOpacity('a', 0.8);
    await tester.pump();
    expect(opacity(), 0.8);
  });

  testWidgets('labels the window and its controls', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, [_spec('a')]);

    expect(find.bySemanticsLabel('Close window'), findsOneWidget);
    expect(find.bySemanticsLabel('Minimize window'), findsOneWidget);
    expect(find.bySemanticsLabel('Keep window on top'), findsOneWidget);
    expect(find.bySemanticsLabel('Resize window'), findsOneWidget);
    expect(find.bySemanticsLabel('Window a. Move window'), findsOneWidget);
    handle.dispose();
  });
}

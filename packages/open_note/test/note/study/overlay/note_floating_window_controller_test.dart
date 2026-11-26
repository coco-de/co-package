import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/study/overlay/overlay.dart';

Widget _body(BuildContext context) => const SizedBox();

NoteFloatingWindowSpec _spec(
  String id, {
  Rect rect = const Rect.fromLTWH(10, 10, 300, 200),
  Size minSize = const Size(200, 160),
  double opacity = 1,
}) => NoteFloatingWindowSpec(
  id: id,
  title: id,
  builder: _body,
  initialRect: rect,
  minSize: minSize,
  opacity: opacity,
);

List<String> _order(NoteFloatingWindowController controller) => [
  for (final window in controller.windows) window.id,
];

void main() {
  late NoteFloatingWindowController controller;
  late int notified;

  setUp(() {
    controller = NoteFloatingWindowController();
    notified = 0;
    controller.addListener(() => notified++);
  });

  group('open and close', () {
    test('a new window opens on top with focus', () {
      controller
        ..open(_spec('a'))
        ..open(_spec('b'));

      expect(_order(controller), ['a', 'b']);
      expect(controller.focusedId, 'b');
      expect(controller.isOpen('a'), isTrue);
      expect(
        controller.window('a')!.rect,
        const Rect.fromLTWH(10, 10, 300, 200),
      );
    });

    test('the first rect and opacity respect the limits', () {
      controller.open(
        _spec('a', rect: const Rect.fromLTWH(5, 5, 10, 10), opacity: 0),
      );

      final window = controller.window('a')!;
      expect(window.rect, const Rect.fromLTWH(5, 5, 200, 160));
      expect(window.opacity, NoteFloatingWindowController.minOpacity);
    });

    test('opening an open id keeps its place, restores and raises it', () {
      controller
        ..open(_spec('a'))
        ..open(_spec('b'))
        ..move('a', const Offset(90, 80))
        ..minimize('a')
        ..open(_spec('a', rect: const Rect.fromLTWH(0, 0, 400, 300)));

      final window = controller.window('a')!;
      expect(window.rect, const Rect.fromLTWH(90, 80, 300, 200));
      expect(window.minimized, isFalse);
      expect(_order(controller), ['b', 'a']);
      expect(controller.focusedId, 'a');
    });

    test('closing the focused window focuses the next visible one', () {
      controller
        ..open(_spec('a'))
        ..open(_spec('b'))
        ..open(_spec('c'))
        ..minimize('b')
        ..close('c');

      expect(controller.focusedId, 'a');
      controller.close('a');
      expect(controller.focusedId, 'b');
      controller.close('b');
      expect(controller.focusedId, isNull);
      expect(controller.windows, isEmpty);
    });

    test('closing another window keeps the focus', () {
      controller
        ..open(_spec('a'))
        ..open(_spec('b'))
        ..close('a');

      expect(controller.focusedId, 'b');
    });

    test('closeAll empties the host', () {
      controller
        ..open(_spec('a'))
        ..open(_spec('b'))
        ..closeAll();

      expect(controller.windows, isEmpty);
      expect(controller.focusedId, isNull);
    });
  });

  group('order', () {
    test('focus brings a window forward', () {
      controller
        ..open(_spec('a'))
        ..open(_spec('b'))
        ..open(_spec('c'))
        ..focus('a');

      expect(_order(controller), ['b', 'c', 'a']);
      expect(controller.focusedId, 'a');
    });

    test('pinned windows stay above the focused unpinned one', () {
      controller
        ..open(_spec('a'))
        ..open(_spec('b'))
        ..open(_spec('c'))
        ..togglePin('a')
        ..focus('b');

      expect(_order(controller), ['c', 'b', 'a']);
      expect(controller.focusedId, 'b');
      expect(controller.window('a')!.pinned, isTrue);
    });

    test('among pinned windows the focused one is on top', () {
      controller
        ..open(_spec('a'))
        ..open(_spec('b'))
        ..open(_spec('c'))
        ..togglePin('a')
        ..togglePin('b')
        ..focus('a');

      expect(_order(controller), ['c', 'b', 'a']);
    });

    test('unpinning drops a window to the top of the others', () {
      controller
        ..open(_spec('a'))
        ..open(_spec('b'))
        ..open(_spec('c'))
        ..togglePin('a')
        ..togglePin('c')
        ..togglePin('a');

      expect(_order(controller), ['b', 'a', 'c']);
    });

    test('a new window opens beneath the pinned ones', () {
      controller
        ..open(_spec('a'))
        ..togglePin('a')
        ..open(_spec('b'));

      expect(_order(controller), ['b', 'a']);
      expect(controller.focusedId, 'b');
    });
  });

  group('geometry', () {
    setUp(() => controller.open(_spec('a')));

    test('move keeps the size', () {
      controller.move('a', const Offset(50, 60));

      expect(
        controller.window('a')!.rect,
        const Rect.fromLTWH(50, 60, 300, 200),
      );
    });

    test('resize keeps the corner and respects the minimum size', () {
      controller.resize('a', const Size(500, 20));

      expect(
        controller.window('a')!.rect,
        const Rect.fromLTWH(10, 10, 500, 160),
      );
    });

    test('setRect moves and resizes in one step', () {
      final before = notified;

      controller.setRect('a', const Rect.fromLTWH(1, 2, 400, 300));

      expect(controller.window('a')!.rect, const Rect.fromLTWH(1, 2, 400, 300));
      expect(notified, before + 1);
    });

    test('non-finite values are ignored', () {
      final before = controller.window('a');

      controller
        ..move('a', const Offset(double.nan, 0))
        ..resize('a', const Size(double.infinity, 10))
        ..setRect('a', const Rect.fromLTWH(0, 0, double.nan, 1))
        ..setOpacity('a', double.nan);

      expect(controller.window('a'), before);
    });

    test('opacity is clamped so a window stays findable', () {
      controller.setOpacity('a', 0.01);
      expect(
        controller.window('a')!.opacity,
        NoteFloatingWindowController.minOpacity,
      );
      controller.setOpacity('a', 5);
      expect(controller.window('a')!.opacity, 1);
    });
  });

  test('minimize, restore and toggle', () {
    controller
      ..open(_spec('a'))
      ..open(_spec('b'))
      ..minimize('a');

    expect(controller.window('a')!.minimized, isTrue);
    expect(controller.focusedId, 'b');
    expect(_order(controller), ['a', 'b']);
    expect(controller.window('a')!.rect, const Rect.fromLTWH(10, 10, 300, 200));

    controller.toggleMinimize('a');
    expect(controller.window('a')!.minimized, isFalse);
    expect(controller.focusedId, 'a');
    expect(_order(controller), ['b', 'a']);

    controller.toggleMinimize('a');
    expect(controller.window('a')!.minimized, isTrue);
  });

  test('listeners hear only about real changes', () {
    controller
      ..open(_spec('a'))
      ..open(_spec('b'));
    final settled = notified;

    controller
      ..focus('b')
      ..move('b', const Offset(10, 10))
      ..restore('b')
      ..close('missing')
      ..focus('missing')
      ..move('missing', Offset.zero)
      ..togglePin('missing')
      ..toggleMinimize('missing')
      ..open(_spec('b'));

    expect(notified, settled);
  });

  test('the window list cannot be changed from outside', () {
    controller.open(_spec('a'));

    expect(() => controller.windows.clear(), throwsUnsupportedError);
  });

  test('after dispose every call is ignored', () {
    controller
      ..open(_spec('a'))
      ..dispose();
    final settled = notified;

    controller
      ..open(_spec('b'))
      ..close('a')
      ..move('a', Offset.zero)
      ..closeAll();

    expect(_order(controller), ['a']);
    expect(notified, settled);
  });

  test('specs and windows compare by value', () {
    expect(_spec('a'), _spec('a'));
    expect(_spec('a').copyWith(title: 'other'), isNot(_spec('a')));
    expect(_spec('a').copyWith().id, 'a');
    final window = NoteFloatingWindow(spec: _spec('a'), rect: Rect.zero);
    expect(window.copyWith(), window);
    expect(window.copyWith(pinned: true), isNot(window));
  });

  group('geometry rules', () {
    const host = Size(800, 600);
    const minSize = Size(200, 160);

    test('clamp shifts a window inside the host', () {
      expect(
        NoteFloatingWindowGeometry.clamp(
          const Rect.fromLTWH(700, -50, 300, 200),
          host,
        ),
        const Rect.fromLTWH(500, 0, 300, 200),
      );
    });

    test('clamp shrinks to the host and keeps the minimum when possible', () {
      expect(
        NoteFloatingWindowGeometry.clamp(
          const Rect.fromLTWH(0, 0, 2000, 10),
          host,
          minSize: minSize,
        ),
        const Rect.fromLTWH(0, 0, 800, 160),
      );
      expect(
        NoteFloatingWindowGeometry.clamp(
          const Rect.fromLTWH(30, 30, 300, 200),
          const Size(150, 100),
          minSize: minSize,
        ),
        const Rect.fromLTWH(0, 0, 150, 100),
      );
    });

    test('resize stops at the minimum and at the host edges', () {
      const start = Rect.fromLTWH(100, 100, 300, 200);

      expect(
        NoteFloatingWindowGeometry.resize(
          start,
          const Offset(-900, -900),
          host,
          minSize: minSize,
        ),
        const Rect.fromLTWH(100, 100, 200, 160),
      );
      expect(
        NoteFloatingWindowGeometry.resize(start, const Offset(900, 900), host),
        const Rect.fromLTWH(100, 100, 700, 500),
      );
    });

    test('resize in a host smaller than the minimum does not throw', () {
      expect(
        NoteFloatingWindowGeometry.resize(
          const Rect.fromLTWH(0, 0, 150, 100),
          const Offset(-20, -20),
          const Size(150, 100),
          minSize: minSize,
        ),
        const Rect.fromLTWH(0, 0, 150, 100),
      );
    });
  });
}

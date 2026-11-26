import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/tools/tools.dart';

import '../support/note_test_host.dart';

const _red = Color(0xFFFF0000);

/// Hosts a picker whose parent feeds every change back, and records events.
class _Harness {
  final Color initial;

  final Future<Color?> Function()? onEyedropper;
  final bool feedBack;
  final List<int> changes = [];
  final List<int> ends = [];
  late Color color = initial;
  _Harness({this.initial = _red, this.onEyedropper, this.feedBack = true});

  Widget build({double width = 400}) => noteTestHost(
    Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: width,
        child: StatefulBuilder(
          builder: (context, setState) => NoteColorPicker(
            color: color,
            onEyedropper: onEyedropper,
            onChanged: (next) {
              changes.add(next.toARGB32());
              if (feedBack) setState(() => color = next);
            },
            onChangeEnd: (next) => ends.add(next.toARGB32()),
          ),
        ),
      ),
    ),
  );
}

Finder get _hexInput => find.descendant(
  of: find.byKey(NoteColorPicker.hexFieldKey),
  matching: find.byType(EditableText),
);

String _hexText(WidgetTester tester) =>
    tester.widget<EditableText>(_hexInput).controller.text;

Rect _plane(WidgetTester tester) =>
    tester.getRect(find.byKey(NoteColorPicker.planeKey));

Rect _hue(WidgetTester tester) =>
    tester.getRect(find.byKey(NoteColorPicker.hueKey));

Future<void> _tapHue(WidgetTester tester, double fraction) async {
  final rect = _hue(tester);
  await tester.tapAt(Offset(rect.left + rect.width * fraction, rect.center.dy));
  await tester.pump();
}

Future<void> _submit(WidgetTester tester, String text) async {
  await tester.enterText(_hexInput, text);
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pump();
}

void main() {
  testWidgets('shows the colour as hex text and offers the swatches', (
    tester,
  ) async {
    await tester.pumpWidget(_Harness().build());

    expect(_hexText(tester), '#FF0000');
    expect(find.byKey(NoteColorPicker.planeKey), findsOneWidget);
    expect(find.byKey(NoteColorPicker.hueKey), findsOneWidget);
    expect(find.byKey(NoteColorPicker.swatchKey(0)), findsOneWidget);
    expect(
      find.byKey(
        NoteColorPicker.swatchKey(NoteColorPicker.defaultSwatches.length - 1),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows eight digits for a translucent colour', (tester) async {
    await tester.pumpWidget(_Harness(initial: const Color(0x80FF0000)).build());

    expect(_hexText(tester), '#80FF0000');
  });

  testWidgets('tapping the plane sets saturation and brightness', (
    tester,
  ) async {
    final harness = _Harness();
    await tester.pumpWidget(harness.build());

    await tester.tapAt(_plane(tester).center);
    await tester.pump();

    final expected = const NoteHsv(h: 0, s: 0.5, v: 0.5).toColor();
    expect(harness.changes, [expected.toARGB32()]);
    expect(harness.ends, [expected.toARGB32()]);
    expect(_hexText(tester), NoteColorUtils.toHex(expected));
  });

  testWidgets('dragging past the plane clamps and ends once', (tester) async {
    final harness = _Harness();
    await tester.pumpWidget(harness.build());
    final rect = _plane(tester);

    final gesture = await tester.startGesture(rect.center);
    await gesture.moveTo(rect.bottomLeft + const Offset(-80, 80));
    await gesture.up();
    await tester.pump();

    expect(harness.changes.last, 0xFF000000);
    expect(harness.ends, [0xFF000000]);
  });

  testWidgets('a drag on the plane wins over a scrolling parent', (
    tester,
  ) async {
    final harness = _Harness();
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    await tester.pumpWidget(
      noteTestHost(
        ListView(
          controller: scroll,
          children: [
            NoteColorPicker(color: _red, onChanged: harness.changes.addColor),
            const SizedBox(height: 900),
          ],
        ),
      ),
    );

    await tester.drag(
      find.byKey(NoteColorPicker.planeKey),
      const Offset(0, -60),
    );
    await tester.pump();

    expect(scroll.offset, 0);
    expect(harness.changes, isNotEmpty);
  });

  testWidgets('the hue strip changes the hue', (tester) async {
    final harness = _Harness();
    await tester.pumpWidget(harness.build());

    await _tapHue(tester, 1 / 3);

    expect(harness.changes.single, 0xFF00FF00);
    expect(_hexText(tester), '#00FF00');
  });

  testWidgets('the hue survives a grey', (tester) async {
    final harness = _Harness();
    await tester.pumpWidget(harness.build());

    await tester.tapAt(_plane(tester).topLeft);
    await tester.pump();
    expect(harness.changes, [0xFFFFFFFF]);

    await _tapHue(tester, 2 / 3);
    expect(harness.changes, [0xFFFFFFFF], reason: 'white has no hue');

    await tester.tapAt(_plane(tester).topRight - const Offset(0.01, 0));
    await tester.pump();
    expect(harness.changes.last, 0xFF0000FF);
  });

  testWidgets('saturation survives black', (tester) async {
    final harness = _Harness();
    await tester.pumpWidget(harness.build());
    final rect = _plane(tester);

    await tester.tapAt(rect.bottomRight - const Offset(0.01, 0.01));
    await tester.pump();
    expect(harness.changes.last, 0xFF000000);

    await _submit(tester, '#000000');
    await _tapHue(tester, 1 / 3);
    await tester.tapAt(rect.topRight - const Offset(0.01, 0));
    await tester.pump();

    expect(harness.changes.last, 0xFF00FF00);
  });

  testWidgets('applies hex text when submitted', (tester) async {
    final harness = _Harness();
    await tester.pumpWidget(harness.build());

    await _submit(tester, '0000ff');

    expect(harness.changes, [0xFF0000FF]);
    expect(harness.ends, [0xFF0000FF]);
    expect(_hexText(tester), '#0000FF');
  });

  testWidgets('does not apply hex text while it is being typed', (
    tester,
  ) async {
    final harness = _Harness();
    await tester.pumpWidget(harness.build());

    await tester.enterText(_hexInput, '#ABC');
    await tester.pump();

    expect(harness.changes, isEmpty);
  });

  testWidgets('applies hex text when the field loses focus', (tester) async {
    final harness = _Harness();
    await tester.pumpWidget(harness.build());

    await tester.enterText(_hexInput, '#00FF00');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();

    expect(harness.changes, [0xFF00FF00]);
    expect(harness.ends, [0xFF00FF00]);
  });

  testWidgets('replaces unreadable hex text with the current colour', (
    tester,
  ) async {
    final harness = _Harness();
    await tester.pumpWidget(harness.build());

    await _submit(tester, 'not a color');

    expect(_hexText(tester), '#FF0000');
    expect(harness.changes, isEmpty);
    expect(harness.ends, isEmpty);
  });

  testWidgets('short hex input keeps the opacity, long input sets it', (
    tester,
  ) async {
    final harness = _Harness(initial: const Color(0x80FF0000));
    await tester.pumpWidget(harness.build());

    await _submit(tester, '#0F0');
    expect(harness.changes.last, 0x8000FF00);
    expect(_hexText(tester), '#8000FF00');

    await _submit(tester, '#FF0000FF');
    expect(harness.changes.last, 0xFF0000FF);
    expect(_hexText(tester), '#0000FF');
  });

  testWidgets('the plane keeps the opacity', (tester) async {
    final harness = _Harness(initial: const Color(0x40FF0000));
    await tester.pumpWidget(harness.build());

    await tester.tapAt(_plane(tester).center);
    await tester.pump();

    expect(harness.changes.single >>> 24, 0x40);
  });

  testWidgets('a swatch applies its colour', (tester) async {
    final harness = _Harness();
    await tester.pumpWidget(harness.build());
    final index = NoteColorPicker.defaultSwatches.indexOf(
      const Color(0xFF1E88E5),
    );

    await tester.tap(find.byKey(NoteColorPicker.swatchKey(index)));
    await tester.pump();
    await tester.tap(find.byKey(NoteColorPicker.swatchKey(index)));
    await tester.pump();

    expect(harness.changes, [0xFF1E88E5]);
    expect(harness.ends, [0xFF1E88E5]);
    expect(_hexText(tester), '#1E88E5');
  });

  testWidgets('custom swatches replace the defaults and may be hidden', (
    tester,
  ) async {
    final picked = <int>[];
    await tester.pumpWidget(
      noteTestHost(
        NoteColorPicker(
          color: _red,
          swatches: const [Color(0xFF123456)],
          onChanged: picked.addColor,
        ),
      ),
    );

    expect(find.byKey(NoteColorPicker.swatchKey(1)), findsNothing);
    await tester.tap(find.byKey(NoteColorPicker.swatchKey(0)));
    expect(picked, [0xFF123456]);

    await tester.pumpWidget(
      noteTestHost(
        NoteColorPicker(color: _red, swatches: const [], onChanged: (_) {}),
      ),
    );
    expect(find.byKey(NoteColorPicker.swatchKey(0)), findsNothing);
  });

  testWidgets('hides the eyedropper without a callback', (tester) async {
    await tester.pumpWidget(_Harness().build());

    expect(find.byKey(NoteColorPicker.eyedropperKey), findsNothing);
  });

  testWidgets('applies the eyedropper result once', (tester) async {
    var calls = 0;
    final pick = Completer<Color?>();
    final harness = _Harness(
      onEyedropper: () {
        calls++;

        return pick.future;
      },
    );
    await tester.pumpWidget(harness.build());

    await tester.tap(find.byKey(NoteColorPicker.eyedropperKey));
    await tester.pump();
    await tester.tap(find.byKey(NoteColorPicker.eyedropperKey));
    await tester.pump();
    expect(calls, 1, reason: 'the button waits for the first pick');

    pick.complete(const Color(0xFF00ABCD));
    await tester.pump();

    expect(harness.changes, [0xFF00ABCD]);
    expect(harness.ends, [0xFF00ABCD]);
    expect(_hexText(tester), '#00ABCD');
  });

  testWidgets('ignores a cancelled eyedropper and allows another try', (
    tester,
  ) async {
    var calls = 0;
    final harness = _Harness(
      onEyedropper: () async {
        calls++;

        return null;
      },
    );
    await tester.pumpWidget(harness.build());

    await tester.tap(find.byKey(NoteColorPicker.eyedropperKey));
    await tester.pump();
    await tester.tap(find.byKey(NoteColorPicker.eyedropperKey));
    await tester.pump();

    expect(calls, 2);
    expect(harness.changes, isEmpty);
  });

  testWidgets('survives being removed while the eyedropper runs', (
    tester,
  ) async {
    final pick = Completer<Color?>();
    final harness = _Harness(onEyedropper: () => pick.future);
    await tester.pumpWidget(harness.build());

    await tester.tap(find.byKey(NoteColorPicker.eyedropperKey));
    await tester.pumpWidget(noteTestHost(const SizedBox()));
    pick.complete(const Color(0xFF00FF00));
    await tester.pump();

    expect(harness.changes, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('follows a colour changed from outside', (tester) async {
    Widget build(Color color) =>
        noteTestHost(NoteColorPicker(color: color, onChanged: (_) {}));
    await tester.pumpWidget(build(_red));

    await tester.pumpWidget(build(const Color(0xFF00FF00)));

    expect(_hexText(tester), '#00FF00');
  });

  testWidgets('keeps its state while the colour property stays the same', (
    tester,
  ) async {
    final harness = _Harness(feedBack: false);
    await tester.pumpWidget(harness.build());

    await _tapHue(tester, 1 / 3);
    await tester.pumpWidget(harness.build());

    expect(_hexText(tester), '#00FF00');
  });

  testWidgets('fits an unbounded width', (tester) async {
    await tester.pumpWidget(
      noteTestHost(
        Row(
          children: [NoteColorPicker(color: _red, onChanged: (_) {})],
        ),
      ),
    );

    expect(tester.getSize(find.byType(NoteColorPicker)).width, 280);
    expect(tester.takeException(), isNull);
  });

  testWidgets('describes its controls to screen readers', (tester) async {
    final semantics = tester.ensureSemantics();
    final harness = _Harness(onEyedropper: () async => null);
    await tester.pumpWidget(harness.build());

    expect(find.bySemanticsLabel('Color #000000'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('Saturation and brightness')),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Hue'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Eyedropper')), findsOneWidget);

    tester.semantics.increase(find.semantics.byLabel('Hue'));
    await tester.pump();

    expect(harness.changes, hasLength(1));
    expect(harness.ends, hasLength(1));
    semantics.dispose();
  });

  testWidgets('uses translated strings', (tester) async {
    await tester.pumpWidget(
      noteTestHost(
        NoteColorPicker(
          color: _red,
          strings: const NoteToolsStrings(eyedropper: '스포이트'),
          onEyedropper: () async => null,
          onChanged: (_) {},
        ),
      ),
    );

    expect(find.text('스포이트'), findsOneWidget);
  });
}

extension on List<int> {
  void addColor(Color color) => add(color.toARGB32());
}

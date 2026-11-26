import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/core/note_slider.dart';
import 'package:open_note/src/note/core/note_text_field.dart';

Widget _host(Widget child) => WidgetsApp(
  color: const Color(0xFFFFFFFF),
  builder: (context, _) => Directionality(
    textDirection: TextDirection.ltr,
    child: Center(child: SizedBox(width: 300, child: child)),
  ),
);

void main() {
  group('NoteSlider', () {
    testWidgets('tapping the track reports the matching value', (tester) async {
      double? reported;
      await tester.pumpWidget(
        _host(NoteSlider(value: 0, onChanged: (v) => reported = v)),
      );

      final rect = tester.getRect(find.byType(NoteSlider));
      await tester.tapAt(Offset(rect.center.dx, rect.center.dy));

      expect(reported, closeTo(0.5, 0.05));
    });

    testWidgets('dragging reports increasing values and respects bounds', (
      tester,
    ) async {
      final reported = <double>[];
      await tester.pumpWidget(
        _host(NoteSlider(value: 0, min: 10, max: 20, onChanged: reported.add)),
      );

      final rect = tester.getRect(find.byType(NoteSlider));
      await tester.dragFrom(
        rect.centerLeft + const Offset(5, 0),
        const Offset(400, 0),
      );

      expect(reported, isNotEmpty);
      expect(reported.every((v) => v >= 10 && v <= 20), isTrue);
      expect(reported.last, 20);
    });

    test('divisions snap values onto the grid', () {
      final slider = NoteSlider(
        value: 0,
        onChanged: (_) {},
        max: 10,
        divisions: 5,
      );

      expect(slider.snap(3.1), 4);
      expect(slider.snap(-5), 0);
      expect(slider.snap(99), 10);
    });

    testWidgets('semantics increase and decrease step the value', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      double? reported;
      await tester.pumpWidget(
        _host(
          NoteSlider(
            value: 5,
            max: 10,
            divisions: 10,
            semanticLabel: 'volume',
            onChanged: (v) => reported = v,
          ),
        ),
      );

      tester.semantics.increase(find.semantics.byLabel('volume'));
      expect(reported, 6);
      tester.semantics.decrease(find.semantics.byLabel('volume'));
      expect(reported, 4);
      handle.dispose();
    });
  });

  group('NoteTextField', () {
    testWidgets('typing reports changes and shows the hint when empty', (
      tester,
    ) async {
      final changes = <String>[];
      await tester.pumpWidget(
        _host(NoteTextField(hintText: 'Name', onChanged: changes.add)),
      );

      expect(find.text('Name'), findsOneWidget);

      await tester.enterText(find.byType(EditableText), 'hello');
      await tester.pump();

      expect(changes, ['hello']);
      expect(find.text('Name'), findsNothing);
    });

    testWidgets('submit reports the text', (tester) async {
      String? submitted;
      await tester.pumpWidget(
        _host(
          NoteTextField(initialText: 'abc', onSubmitted: (v) => submitted = v),
        ),
      );

      await tester.showKeyboard(find.byType(EditableText));
      await tester.testTextInput.receiveAction(TextInputAction.done);

      expect(submitted, 'abc');
    });

    testWidgets('an external controller drives the displayed text', (
      tester,
    ) async {
      final controller = TextEditingController(text: 'one');
      addTearDown(controller.dispose);
      await tester.pumpWidget(_host(NoteTextField(controller: controller)));

      controller.text = 'two';
      await tester.pump();

      expect(find.text('two'), findsOneWidget);
    });

    testWidgets('submitOnBlur reports when focus leaves', (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      String? submitted;
      await tester.pumpWidget(
        _host(
          NoteTextField(
            focusNode: node,
            initialText: 'kept',
            submitOnBlur: true,
            onSubmitted: (v) => submitted = v,
          ),
        ),
      );

      node.requestFocus();
      await tester.pump();
      node.unfocus();
      await tester.pump();

      expect(submitted, 'kept');
    });
  });
}

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/study/utilities/utilities.dart';

import '../../support/note_test_host.dart';
import 'support/utility_test_helpers.dart';

const _display = ValueKey('calculator-display');
const _detail = ValueKey('calculator-detail');

ValueKey<NoteCalculatorKey> _key(NoteCalculatorKey key) => ValueKey(key);

Future<void> _tapAll(WidgetTester tester, List<NoteCalculatorKey> keys) async {
  for (final key in keys) {
    await tapKey(tester, _key(key));
  }
}

void main() {
  late NoteCalculatorController controller;

  setUp(() => controller = NoteCalculatorController());
  tearDown(() => controller.dispose());

  Future<void> pumpView(
    WidgetTester tester, {
    bool showScientificKeys = true,
    NoteStudyUtilitiesStrings strings = const NoteStudyUtilitiesStrings(),
  }) => tester.pumpWidget(
    noteTestHost(
      NoteCalculatorView(
        controller: controller,
        showScientificKeys: showScientificKeys,
        strings: strings,
      ),
    ),
  );

  testWidgets('calculates from tapped keys', (tester) async {
    await pumpView(tester);
    expect(textOf(tester, _display), '0');

    await _tapAll(tester, [
      NoteCalculatorKey.digit7,
      NoteCalculatorKey.multiply,
      NoteCalculatorKey.digit6,
    ]);
    expect(textOf(tester, _display), '7×6');

    await _tapAll(tester, [NoteCalculatorKey.equals]);
    expect(textOf(tester, _display), '42');
    expect(textOf(tester, _detail), '7×6 =');
  });

  testWidgets('offers every key once', (tester) async {
    await pumpView(tester);

    for (final key in NoteCalculatorKey.values) {
      expect(find.byKey(_key(key)), findsOneWidget, reason: key.name);
    }
  });

  testWidgets('keys announce their names', (tester) async {
    await pumpView(tester);

    expect(
      semanticLabelOf(tester, _key(NoteCalculatorKey.sqrt)),
      'Square root',
    );
    expect(semanticLabelOf(tester, _key(NoteCalculatorKey.digit4)), '4');
    expect(
      semanticLabelOf(tester, _key(NoteCalculatorKey.backspace)),
      'Backspace',
    );
  });

  testWidgets('shows translated errors and memory', (tester) async {
    await pumpView(
      tester,
      strings: const NoteStudyUtilitiesStrings(
        calculatorDivisionByZeroError: '0으로 나눌 수 없음',
        calculatorMemory: '메모리',
      ),
    );
    expect(find.text('메모리'), findsNothing);

    await _tapAll(tester, [
      NoteCalculatorKey.digit1,
      NoteCalculatorKey.divide,
      NoteCalculatorKey.digit0,
      NoteCalculatorKey.equals,
    ]);
    expect(textOf(tester, _detail), '0으로 나눌 수 없음');
    expect(textOf(tester, _display), '1÷0');

    await _tapAll(tester, [
      NoteCalculatorKey.clear,
      NoteCalculatorKey.digit5,
      NoteCalculatorKey.memoryAdd,
    ]);
    expect(find.text('메모리'), findsOneWidget);
  });

  testWidgets('can hide the function keys', (tester) async {
    await pumpView(tester, showScientificKeys: false);

    for (final key in [
      NoteCalculatorKey.sqrt,
      NoteCalculatorKey.sin,
      NoteCalculatorKey.log,
      NoteCalculatorKey.power,
    ]) {
      expect(find.byKey(_key(key)), findsNothing, reason: key.name);
    }
    expect(find.byKey(_key(NoteCalculatorKey.openParenthesis)), findsOneWidget);
    expect(find.byKey(_key(NoteCalculatorKey.digit0)), findsOneWidget);
  });

  testWidgets('fits a small window', (tester) async {
    await tester.pumpWidget(
      noteTestHost(
        Center(
          child: SizedBox(
            width: 260,
            height: 420,
            child: NoteCalculatorView(controller: controller),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    await _tapAll(tester, [NoteCalculatorKey.digit9]);
    expect(textOf(tester, _display), '9');
  });

  testWidgets('lays out with an unbounded height', (tester) async {
    await tester.pumpWidget(
      noteTestHost(
        SingleChildScrollView(
          child: NoteCalculatorView(controller: controller),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byKey(_key(NoteCalculatorKey.digit5))).height,
      const NoteStudyUtilitiesStyle().keyHeight,
    );
  });

  testWidgets('a long expression shrinks instead of overflowing', (
    tester,
  ) async {
    await pumpView(tester);

    for (var i = 0; i < 60; i++) {
      controller.inputDigit(9);
    }
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(textOf(tester, _display), '9' * 60);
  });

  testWidgets('owns a controller when none is given', (tester) async {
    await tester.pumpWidget(noteTestHost(const NoteCalculatorView()));

    await _tapAll(tester, [
      NoteCalculatorKey.digit2,
      NoteCalculatorKey.add,
      NoteCalculatorKey.digit2,
      NoteCalculatorKey.equals,
    ]);

    expect(textOf(tester, _display), '4');
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });

  testWidgets('switches to a controller given later', (tester) async {
    await tester.pumpWidget(noteTestHost(const NoteCalculatorView()));
    controller.inputDigit(8);

    await pumpView(tester);

    expect(textOf(tester, _display), '8');
  });
}

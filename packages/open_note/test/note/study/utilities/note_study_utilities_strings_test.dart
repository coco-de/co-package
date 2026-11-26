import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/study/utilities/utilities.dart';

void main() {
  const strings = NoteStudyUtilitiesStrings();

  test('names and labels every calculator key', () {
    for (final key in NoteCalculatorKey.values) {
      expect(strings.calculatorKeyText(key), isNotEmpty, reason: key.name);
      expect(strings.calculatorKeyLabel(key), isNotEmpty, reason: key.name);
    }
    expect(strings.calculatorKeyText(NoteCalculatorKey.digit7), '7');
    expect(strings.calculatorKeyText(NoteCalculatorKey.sin), 'sin');
    expect(strings.calculatorKeyText(NoteCalculatorKey.multiply), '×');
  });

  test('has a message for every calculator error', () {
    expect({
      for (final error in NoteCalculatorError.values)
        strings.calculatorError(error),
    }, hasLength(NoteCalculatorError.values.length));
  });

  test('formats steps, laps, pages and speeds', () {
    expect(strings.timeStepLabel(const Duration(minutes: 1)), '+01:00');
    expect(strings.timeStepLabel(const Duration(minutes: -5)), '−05:00');
    expect(strings.lapTitle(3), 'Lap 3');
    expect(strings.pageLabel(12), 'Page 12');
    expect(
      [
        for (final s in NoteRecordingController.speedPresets)
          strings.speedLabel(s),
      ],
      ['0.5×', '0.75×', '1×', '1.25×', '1.5×', '2×'],
    );
  });

  test('keypad keys map to what they type', () {
    expect(NoteCalculatorKey.digit0.digit, 0);
    expect(NoteCalculatorKey.digit9.digit, 9);
    expect(NoteCalculatorKey.decimalPoint.digit, isNull);
    expect(
      NoteCalculatorKey.divide.arithmeticOperator,
      NoteCalculatorOperator.divide,
    );
    expect(NoteCalculatorKey.equals.arithmeticOperator, isNull);
    expect(NoteCalculatorKey.ln.function, NoteCalculatorFunction.ln);
    expect(NoteCalculatorKey.e.constant, NoteCalculatorConstant.e);
    for (final function in NoteCalculatorFunction.values) {
      expect(
        NoteCalculatorKey.values.where((key) => key.function == function),
        hasLength(1),
        reason: function.name,
      );
    }
  });

  test('style values compare and hash', () {
    expect(const NoteStudyUtilitiesStyle(), const NoteStudyUtilitiesStyle());
    expect(
      const NoteStudyUtilitiesStyle().hashCode,
      const NoteStudyUtilitiesStyle().hashCode,
    );
    expect(
      const NoteStudyUtilitiesStyle(fontSize: 18),
      isNot(const NoteStudyUtilitiesStyle()),
    );
  });
}

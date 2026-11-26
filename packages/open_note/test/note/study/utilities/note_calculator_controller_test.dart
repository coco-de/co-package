import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/study/utilities/utilities.dart';

import 'support/utility_test_helpers.dart';

typedef _Key = NoteCalculatorKey;

const _digits = [
  _Key.digit0,
  _Key.digit1,
  _Key.digit2,
  _Key.digit3,
  _Key.digit4,
  _Key.digit5,
  _Key.digit6,
  _Key.digit7,
  _Key.digit8,
  _Key.digit9,
];

const _symbols = {
  '.': _Key.decimalPoint,
  '+': _Key.add,
  '-': _Key.subtract,
  '*': _Key.multiply,
  '/': _Key.divide,
  '^': _Key.power,
  '%': _Key.percent,
  '(': _Key.openParenthesis,
  ')': _Key.closeParenthesis,
  '=': _Key.equals,
};

NoteCalculatorController _create({int maxHistory = 50}) {
  final controller = NoteCalculatorController(maxHistory: maxHistory);
  addTearDown(controller.dispose);

  return controller;
}

/// Presses the keys of [script]: digits and the symbols in [_symbols].
void _press(NoteCalculatorController controller, String script) {
  for (final character in script.split('')) {
    controller.press(_symbols[character] ?? _digits[int.parse(character)]);
  }
}

void main() {
  group('typing and evaluating', () {
    test('shows 0 until something is typed', () {
      final calculator = _create();

      expect(calculator.display, '0');
      expect(calculator.expression, '');
      expect(calculator.result, isNull);
      expect(calculator.error, isNull);
      expect(calculator.hasMemory, isFalse);
    });

    test('shows the expression, then the result with its history', () {
      final calculator = _create();

      _press(calculator, '2+3*4');
      expect(calculator.display, '2+3×4');

      _press(calculator, '=');
      expect(calculator.display, '14');
      expect(calculator.result, 14);
      expect(calculator.expression, '2+3×4');
      expect(calculator.history, const [
        NoteCalculatorEntry(expression: '2+3×4', result: '14'),
      ]);
    });

    test('closes open parentheses before evaluating', () {
      final calculator = _create()
        ..press(_Key.sqrt)
        ..press(_Key.digit1)
        ..press(_Key.digit6)
        ..press(_Key.equals);

      expect(calculator.display, '4');
      expect(calculator.expression, 'sqrt(16)');
      expect(calculator.history.single.expression, 'sqrt(16)');
    });

    test('equals does nothing on an empty or finished entry', () {
      final calculator = _create()..equals();
      expect(calculator.result, isNull);

      _press(calculator, '1+1==');
      expect(calculator.history, hasLength(1));
    });

    test('an operator continues from the result at full precision', () {
      final calculator = _create();

      _press(calculator, '1/3=');
      expect(calculator.display, '0.333333333333');
      _press(calculator, '*3=');

      expect(calculator.display, '1');
      expect(calculator.history.last.expression, '0.333333333333×3');
    });

    test('a negative result is squared as a whole', () {
      final calculator = _create();

      _press(calculator, '2-7=');
      _press(calculator, '^2=');

      expect(calculator.history.last.expression, '(-5)^2');
      expect(calculator.display, '25');
    });

    test('a digit, point, function or ( starts anew after a result', () {
      final calculator = _create();

      _press(calculator, '1+1=7');
      expect(calculator.expression, '7');
      expect(calculator.result, isNull);

      _press(calculator, '=.5');
      expect(calculator.display, '0.5');

      _press(calculator, '=(');
      expect(calculator.display, '(');

      _press(calculator, '9=');
      calculator.press(_Key.sqrt);
      expect(calculator.display, 'sqrt(');

      calculator.press(_Key.clear);
      _press(calculator, '2=');
      calculator.press(_Key.pi);
      expect(calculator.display, 'pi');
    });

    test('keys that do not apply leave a result alone', () {
      final calculator = _create();
      _press(calculator, '1+1=');
      final calls = countNotifications(calculator);

      _press(calculator, ')');

      expect(calculator.display, '2');
      expect(calls, isEmpty);
    });

    test('backspace deletes the last key, or the whole result', () {
      final calculator = _create();
      _press(calculator, '12+3');

      calculator.backspace();
      expect(calculator.display, '12+');

      _press(calculator, '1=');
      calculator.backspace();
      expect(calculator.display, '0');
    });

    test('clear keeps memory and history', () {
      final calculator = _create();
      _press(calculator, '5=');
      calculator
        ..memoryAdd()
        ..clear();

      expect(calculator.display, '0');
      expect(calculator.result, isNull);
      expect(calculator.hasMemory, isTrue);
      expect(calculator.history, hasLength(1));
    });

    test('percent and remainder follow the grammar', () {
      final percent = _create();
      _press(percent, '50%=');
      expect(percent.display, '0.5');

      final remainder = _create();
      _press(remainder, '17%5=');
      expect(remainder.display, '2');
    });
  });

  group('errors', () {
    test('keep the expression and explain what failed', () {
      for (final (script, expected) in [
        ('1/0=', NoteCalculatorError.divisionByZero),
        ('2+=', NoteCalculatorError.syntax),
        ('0^-1=', NoteCalculatorError.divisionByZero),
      ]) {
        final calculator = _create();
        _press(calculator, script);

        expect(calculator.error, expected, reason: script);
        expect(calculator.result, isNull, reason: script);
        expect(calculator.history, isEmpty, reason: script);
        expect(calculator.display, isNot('0'), reason: script);
      }
    });

    test('report domain and overflow errors', () {
      final domain = _create()
        ..press(_Key.sqrt)
        ..press(_Key.subtract)
        ..press(_Key.digit1)
        ..press(_Key.equals);
      expect(domain.error, NoteCalculatorError.domain);

      final overflow = _create();
      _press(overflow, '9^999=');
      expect(overflow.error, NoteCalculatorError.overflow);
    });

    test('are dismissed by the next edit', () {
      final calculator = _create();
      _press(calculator, '2+=');

      _press(calculator, '3');
      expect(calculator.error, isNull);
      expect(calculator.display, '2+3');

      _press(calculator, '=');
      expect(calculator.display, '5');
    });

    test('are dismissed by backspace and clear', () {
      final calculator = _create();
      _press(calculator, '2+=');
      calculator.backspace();
      expect(calculator.error, isNull);
      expect(calculator.display, '2');

      _press(calculator, '+=');
      calculator.clear();
      expect(calculator.error, isNull);
      expect(calculator.display, '0');
    });
  });

  group('memory', () {
    test('adds and subtracts the entry and shows its value', () {
      final calculator = _create();
      _press(calculator, '2+3');

      calculator.memoryAdd();
      expect(calculator.memory, 5);
      expect(calculator.display, '5');
      expect(calculator.history, isEmpty);

      _press(calculator, '1');
      calculator.memorySubtract();
      expect(calculator.memory, 4);
      _press(calculator, '7');
      expect(calculator.display, '7');
    });

    test('uses a shown result', () {
      final calculator = _create();
      _press(calculator, '6*7=');

      calculator.memoryAdd();

      expect(calculator.memory, 42);
    });

    test('recall types the value, negative ones in parentheses', () {
      final calculator = _create();
      _press(calculator, '0-5');
      calculator
        ..memoryAdd()
        ..clear();
      _press(calculator, '2*');
      calculator.memoryRecall();
      expect(calculator.display, '2×(-5)');

      _press(calculator, '=');
      expect(calculator.display, '-10');
    });

    test('recall after a result starts a new expression', () {
      final calculator = _create();
      _press(calculator, '8');
      calculator.memoryAdd();
      _press(calculator, '1+1=');

      calculator.memoryRecall();

      expect(calculator.display, '8');
      expect(calculator.result, isNull);
    });

    test('keeps full precision', () {
      final calculator = _create();
      _press(calculator, '1/3');
      calculator
        ..memoryAdd()
        ..clear()
        ..memoryRecall();
      _press(calculator, '*3=');

      expect(calculator.display, '1');
    });

    test('is cleared with MC and empty recall does nothing', () {
      final calculator = _create();
      calculator.memoryRecall();
      expect(calculator.display, '0');
      _press(calculator, '5');
      calculator
        ..memoryAdd()
        ..memoryClear();

      expect(calculator.hasMemory, isFalse);
      expect(calculator.memory, 0);
      calculator
        ..clear()
        ..memoryRecall();
      expect(calculator.display, '0');
    });

    test('ignores an empty entry and reports an invalid one', () {
      final calculator = _create()..memoryAdd();
      expect(calculator.hasMemory, isFalse);

      _press(calculator, '2+');
      calculator.memoryAdd();

      expect(calculator.hasMemory, isFalse);
      expect(calculator.error, NoteCalculatorError.syntax);
    });

    test('does not overflow', () {
      final calculator = _create();
      _press(calculator, '10^308=');
      calculator
        ..memoryAdd()
        ..memoryAdd();

      expect(calculator.error, NoteCalculatorError.overflow);
      expect(calculator.memory.isFinite, isTrue);
    });

    test('stores zero as a value', () {
      final calculator = _create();
      _press(calculator, '0');

      calculator.memoryAdd();

      expect(calculator.hasMemory, isTrue);
    });
  });

  group('history', () {
    test('keeps the newest entries up to the limit', () {
      final calculator = _create(maxHistory: 2);

      _press(calculator, '1=');
      _press(calculator, '2=');
      _press(calculator, '3=');

      expect(calculator.history.map((entry) => entry.result), ['2', '3']);
    });

    test('can be disabled and cleared', () {
      final none = _create(maxHistory: 0);
      _press(none, '1=');
      expect(none.history, isEmpty);

      final calculator = _create();
      _press(calculator, '1=');
      calculator.clearHistory();
      expect(calculator.history, isEmpty);
      expect(
        () => calculator.history.add(
          const NoteCalculatorEntry(expression: 'x', result: 'y'),
        ),
        throwsUnsupportedError,
      );
    });
  });

  group('keys and notifications', () {
    test('every key can be pressed', () {
      final calculator = _create();

      for (final key in NoteCalculatorKey.values) {
        expect(() => calculator.press(key), returnsNormally, reason: key.name);
      }
    });

    test('digit, operator, function and constant keys type their text', () {
      expect([
        for (final key in _digits) key.digit,
      ], List.generate(10, (i) => i));
      final calculator = _create();

      calculator
        ..press(_Key.sin)
        ..press(_Key.pi)
        ..press(_Key.add)
        ..press(_Key.e)
        ..press(_Key.closeParenthesis)
        ..press(_Key.multiply)
        ..press(_Key.ln)
        ..press(_Key.digit2);

      expect(calculator.display, 'sin(pi+e)×ln(2');
    });

    test('notify only when something changes', () {
      final calculator = _create();
      final calls = countNotifications(calculator);

      calculator
        ..clear()
        ..backspace()
        ..equals()
        ..memoryClear()
        ..memoryRecall()
        ..memoryAdd()
        ..clearHistory()
        ..inputCloseParenthesis()
        ..inputOperator(NoteCalculatorOperator.multiply);
      expect(calls, isEmpty);

      calculator.inputDigit(0);
      calculator.inputDigit(0);
      expect(calls, hasLength(1));
    });

    test('does nothing after dispose', () {
      final calculator = NoteCalculatorController()
        ..inputDigit(1)
        ..dispose();

      expect(
        () => calculator
          ..inputDigit(2)
          ..inputOperator(NoteCalculatorOperator.add)
          ..equals()
          ..backspace()
          ..clear()
          ..memoryAdd()
          ..memoryRecall()
          ..memoryClear()
          ..clearHistory()
          ..dispose(),
        returnsNormally,
      );
      expect(calculator.expression, '1');
    });
  });

  group('NoteCalculatorEntry', () {
    const entry = NoteCalculatorEntry(expression: '1+1', result: '2');

    test('round-trips through JSON', () {
      expect(entry.toJson(), {'expression': '1+1', 'result': '2'});
      expect(NoteCalculatorEntry.fromJson(entry.toJson()), entry);
      expect(
        NoteCalculatorEntry.fromJson(entry.toJson()).hashCode,
        entry.hashCode,
      );
    });

    test('reads malformed values leniently', () {
      const empty = NoteCalculatorEntry(expression: '', result: '');

      expect(NoteCalculatorEntry.fromJson(null), empty);
      expect(NoteCalculatorEntry.fromJson(3), empty);
      expect(
        NoteCalculatorEntry.fromJson({'expression': 3, 'result': false}),
        empty,
      );
    });

    test('copies with changes', () {
      expect(entry.copyWith(result: '3').result, '3');
      expect(entry.copyWith(), entry);
    });
  });
}

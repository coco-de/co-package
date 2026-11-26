import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/study/utilities/utilities.dart';

const _empty = NoteCalculatorExpression();

/// Types a script into an expression, one character per key: digits, `.`,
/// `+ - * / ^ %` and parentheses, `p` for pi, `s` for sqrt, `<` for backspace.
NoteCalculatorExpression _type(
  String keys, [
  NoteCalculatorExpression start = _empty,
]) => keys.split('').fold(start, _press);

NoteCalculatorExpression _press(NoteCalculatorExpression e, String key) {
  const operators = {
    '+': NoteCalculatorOperator.add,
    '-': NoteCalculatorOperator.subtract,
    '*': NoteCalculatorOperator.multiply,
    '/': NoteCalculatorOperator.divide,
    '^': NoteCalculatorOperator.power,
    '%': NoteCalculatorOperator.percent,
  };
  final operator = operators[key];
  if (operator != null) return e.appendOperator(operator);

  return switch (key) {
    '.' => e.appendDecimalPoint(),
    '(' => e.appendOpenParenthesis(),
    ')' => e.appendCloseParenthesis(),
    'p' => e.appendConstant(NoteCalculatorConstant.pi),
    's' => e.appendFunction(NoteCalculatorFunction.sqrt),
    '<' => e.backspace(),
    _ => e.appendDigit(int.parse(key)),
  };
}

void _expectTexts(Map<String, String> cases) {
  for (final MapEntry(key: keys, value: text) in cases.entries) {
    expect(_type(keys).text, text, reason: 'keys "$keys"');
  }
}

void main() {
  group('NoteCalculatorExpression', () {
    test('starts empty', () {
      expect(_empty.isEmpty, isTrue);
      expect(_empty.text, '');
      expect(_empty.openParentheses, 0);
    });

    test('builds numbers without redundant zeros', () {
      _expectTexts({
        '12': '12',
        '00': '0',
        '05': '5',
        '100': '100',
        '2+007': '2+7',
        '0.05': '0.05',
      });
    });

    test('accepts one point per number, starting with 0.', () {
      _expectTexts({
        '.': '0.',
        '.5': '0.5',
        '3..14': '3.14',
        '3.1.4': '3.14',
        '3.5+.': '3.5+0.',
        '(.': '(0.',
        ').': '0.',
      });
    });

    test('replaces an operator typed after another', () {
      _expectTexts({'2+*': '2×', '2*+': '2+', '2+-': '2-', '2-+': '2+'});
      expect(_type('2++'), _type('2+'));
    });

    test('keeps a minus sign after × ÷ and ^', () {
      _expectTexts({'2*-3': '2×-3', '2/-3': '2÷-3', '2^-3': '2^-3'});
      expect(_type('2*--').text, '2×-');
      expect(_type('2*-+').text, '2+');
      expect(_type('2^-*').text, '2×');
    });

    test('an expression or ( can only start with minus', () {
      _expectTexts({
        '+': '',
        '*': '',
        '^': '',
        '%': '',
        '-': '-',
        '-+': '-',
        '-*': '-',
        '--': '-',
        '(+': '(',
        '(-': '(-',
        '(-*': '(-',
        '2+(-5': '2+(-5',
      });
    });

    test('percent needs an operand and does not double', () {
      _expectTexts({
        '50%': '50%',
        '50%%': '50%',
        '2+%': '2+',
        '(%': '(',
        'p%': 'pi%',
        '7%3': '7%3',
        '7%(': '7%(',
        '7%p': '7%pi',
        '50%+1': '50%+1',
      });
    });

    test('inserts × before operands that follow an operand', () {
      _expectTexts({
        '2(': '2×(',
        '2p': '2×pi',
        '2s': '2×sqrt(',
        'p2': 'pi×2',
        'pp': 'pi×pi',
        '(2)3': '(2)×3',
        '(2)(': '(2)×(',
        '2.(': '2.×(',
        '2+(': '2+(',
        's2': 'sqrt(2',
      });
    });

    test(') needs an open parenthesis and an operand', () {
      _expectTexts({
        ')': '',
        '2)': '2',
        '()': '(',
        '(2+)': '(2+',
        '(2))': '(2)',
        's9))': 'sqrt(9)',
        '((1)': '((1)',
      });
      expect(_type('((1+s2').openParentheses, 3);
      expect(_type('((1+s2)))').openParentheses, 0);
    });

    test('closes parentheses when evaluating', () {
      final open = _type('s(9');

      expect(open.text, 'sqrt((9');
      expect(open.closed().text, 'sqrt((9))');
      expect(open.evaluationSource, 'sqrt((9))');
      expect(NoteCalculator.evaluate(open.evaluationSource), 3);
      expect(_type('2+3').closed(), _type('2+3'));
    });

    test('backspace removes one key press, functions whole', () {
      _expectTexts({
        '12<': '1',
        '2s<': '2×',
        '2s<<': '2',
        'p<': '',
        '<': '',
        '3.<': '3',
      });
    });

    test('inserts computed values as one unit with full precision', () {
      final third = _empty.appendValue(1 / 3);

      expect(third.text, '0.333333333333');
      expect(third.evaluationSource, '0.3333333333333333');
      expect(third.backspace(), _empty);
      expect(NoteCalculator.evaluate(_type('*3', third).evaluationSource), 1);
    });

    test('parenthesises negative values and ignores non-finite ones', () {
      final negative = _empty.appendValue(-5);

      expect(negative.text, '(-5)');
      expect(
        NoteCalculator.evaluate(_type('^2', negative).evaluationSource),
        25,
      );
      expect(_type('2').appendValue(-5).text, '2×(-5)');
      expect(_type('2+').appendValue(4).text, '2+4');
      expect(_empty.appendValue(double.nan), _empty);
      expect(_empty.appendValue(double.infinity), _empty);
      expect(_empty.appendValue(-0.0).text, '0');
    });

    test('a digit after a computed value multiplies', () {
      expect(_type('5', _empty.appendValue(12.5)).text, '12.5×5');
    });

    test('ignores digits outside 0–9', () {
      expect(_empty.appendDigit(10), same(_empty));
      expect(_empty.appendDigit(-1), same(_empty));
    });

    test('compares by content', () {
      expect(_type('2+3'), _type('2+3'));
      expect(_type('2+3').hashCode, _type('2+3').hashCode);
      expect(_type('2+3'), isNot(_type('2+4')));
    });
  });
}

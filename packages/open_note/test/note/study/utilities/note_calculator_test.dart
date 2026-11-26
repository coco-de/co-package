import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/study/utilities/utilities.dart';

double _eval(String source) => NoteCalculator.evaluate(source);

/// Expects each expression to evaluate to its value.
void _expectAll(Map<String, num> cases) {
  for (final MapEntry(key: source, value: expected) in cases.entries) {
    expect(_eval(source), closeTo(expected, 1e-9), reason: source);
  }
}

/// Expects each expression to fail with [error].
void _expectErrors(NoteCalculatorError error, List<String> sources) {
  for (final source in sources) {
    expect(
      () => _eval(source),
      throwsA(
        isA<NoteCalculatorException>().having(
          (failure) => failure.error,
          'error',
          error,
        ),
      ),
      reason: source.length > 40 ? '${source.substring(0, 40)}…' : source,
    );
  }
}

void main() {
  group('numbers', () {
    test('integers, decimals and scientific notation', () {
      _expectAll({
        '42': 42,
        '007': 7,
        '3.5': 3.5,
        '.5': 0.5,
        '5.': 5,
        '1.5e3': 1500,
        '2E-2': 0.02,
        '1.5e+2': 150,
      });
    });

    test('whitespace is ignored', () {
      _expectAll({'  1 +\t2\n* 3 ': 7, '( 4 )': 4});
    });

    test('never returns negative zero', () {
      expect(_eval('-0').isNegative, isFalse);
      expect(_eval('0*-1').isNegative, isFalse);
    });
  });

  group('precedence and associativity', () {
    test('* / bind tighter than + -', () {
      _expectAll({
        '2+3*4': 14,
        '2*3+4': 10,
        '20-6/2': 17,
        '2+3*4-5': 9,
        '(2+3)*4': 20,
      });
    });

    test('same precedence is left-associative', () {
      _expectAll({
        '10-4-3': 3,
        '8/4/2': 1,
        '100/10*2': 20,
        '1-2+3': 2,
        '10%4*3': 6,
      });
    });

    test('^ binds tighter than * and is right-associative', () {
      _expectAll({
        '2*3^2': 18,
        '2^3*4': 32,
        '2^3^2': 512,
        '(2^3)^2': 64,
        '4^0.5': 2,
        '2^3^0': 2,
        '0^0': 1,
      });
    });

    test('parentheses nest to any reasonable depth', () {
      _expectAll({
        '((((1+2)*3)-4)/5)': 1,
        '2*(3+(4*(5-2)))': 30,
        '((((((((((7))))))))))': 7,
      });
      expect(_eval('${'(' * 150}1${')' * 150}'), 1);
    });

    test('the unicode operators work like the ASCII ones', () {
      _expectAll({'6×7÷2−1': 20, '2*3/6': 1});
    });
  });

  group('unary signs', () {
    test('a leading minus binds looser than ^', () {
      _expectAll({'-2^2': -4, '(-2)^2': 4, '-2*3^2': -18, '-sqrt(4)^2': -4});
    });

    test('signs follow operators', () {
      _expectAll({
        '-3+5': 2,
        '2*-3': -6,
        '2--3': 5,
        '2+-3': -1,
        '6/-2': -3,
        '+5': 5,
        '--2': 2,
        '-(-2)': 2,
        '---2': -2,
        '-+2': -2,
      });
    });

    test('an exponent may carry a sign', () {
      _expectAll({
        '2^-1': 0.5,
        '2^-1^2': 0.5,
        '2^-2*4': 1,
        '2^-3*4': 0.5,
        '-2^-2': -0.25,
        '2^+3': 8,
      });
    });

    test('a leading minus binds tighter than the remainder', () {
      _expectAll({'-5%3': 1});
    });
  });

  group('percent', () {
    test('divides the number before it by 100', () {
      _expectAll({
        '50%': 0.5,
        '200*10%': 20,
        '50%*200': 100,
        '100+10%': 100.1,
        '-50%': -0.5,
        '(20+30)%': 0.5,
        'abs(-5)%': 0.05,
        '50%%': 0.005,
        '2^50%': math.sqrt2,
        '50%^2': 0.25,
      });
    });

    test('is a remainder when an operand follows', () {
      _expectAll({
        '7%3': 1,
        '7%(1+2)': 1,
        '10%pi': 10 - 3 * math.pi,
        '5.5%2': 1.5,
        '7%-0+1': 1.07,
      });
    });

    test('followed by a sign it is a percent', () {
      _expectAll({'10%-3': -2.9, '10%+3': 3.1});
    });
  });

  group('constants and functions', () {
    test('pi and e, in any case, π too', () {
      _expectAll({
        'pi': math.pi,
        'PI': math.pi,
        'π': math.pi,
        '2*π': 2 * math.pi,
        'e': math.e,
        'E': math.e,
        'e^2': math.e * math.e,
      });
    });

    test('every function', () {
      _expectAll({
        'sqrt(16)': 4,
        'sqrt(0)': 0,
        'sin(pi/2)': 1,
        'cos(0)': 1,
        'tan(pi/4)': 1,
        'log(1000)': 3,
        'log(0.001)': -3,
        'ln(e)': 1,
        'ln(1)': 0,
        'abs(-4)': 4,
        'abs(4)': 4,
        'SQRT(9)': 3,
      });
    });

    test('functions nest and combine', () {
      _expectAll({
        'sqrt(abs(-16))+1': 5,
        '2*sqrt(9)^2': 18,
        'log(100)*ln(e^3)': 6,
        'sin(0)+cos(pi)': -1,
      });
    });

    test('trigonometric noise snaps to zero', () {
      expect(_eval('sin(pi)'), 0);
      expect(_eval('cos(pi/2)'), 0);
      expect(_eval('tan(pi)'), 0);
    });

    test('exact powers of ten have exact logarithms', () {
      expect(_eval('log(1000)'), 3);
      expect(_eval('log(1e-5)'), -5);
    });
  });

  group('errors', () {
    test('syntax', () {
      _expectErrors(NoteCalculatorError.syntax, [
        '',
        '   ',
        '+',
        '-',
        '1+',
        '*2',
        '^2',
        '%',
        '1*/2',
        '(1+2',
        '1+2)',
        ')(',
        '()',
        '1 2',
        '2pi',
        '2(3)',
        '(2)(3)',
        'pi pi',
        'pi2',
        'foo(1)',
        'x',
        'sqrt',
        'sqrt 4',
        'sin()',
        'sin(1',
        'sin(1,2)',
        '1..2',
        '.',
        '1.2.3',
        '1,000',
        '#',
        '2 = 2',
        '2e',
        '2e+',
        '5%(',
      ]);
    });

    test('division by zero', () {
      _expectErrors(NoteCalculatorError.divisionByZero, [
        '1/0',
        '0/0',
        '1÷(2-2)',
        '5%0',
        '5%(1-1)',
        '0^-1',
        '0^-0.5',
        '1/sin(pi)',
      ]);
    });

    test('domain', () {
      _expectErrors(NoteCalculatorError.domain, [
        'sqrt(-1)',
        'log(0)',
        'log(-1)',
        'ln(0)',
        'ln(-2)',
        '(-8)^(1/3)',
        '(-1)^0.5',
      ]);
    });

    test('overflow', () {
      _expectErrors(NoteCalculatorError.overflow, [
        '10^400',
        '1e999',
        '1e308*10',
        '-1e308-1e308',
        '1e308+1e308',
        'abs(1e999)',
      ]);
    });

    test('limits length and nesting instead of overflowing the stack', () {
      _expectErrors(NoteCalculatorError.syntax, [
        '1+' * 600,
        '${'(' * 300}1${')' * 300}',
        '${'-' * 300}1',
        '2${'^2' * 300}',
        '(' * 999,
      ]);
    });

    test('report where the input is wrong', () {
      Object? failure;
      try {
        _eval('1+#');
      } on NoteCalculatorException catch (error) {
        failure = error;
      }

      expect(
        failure,
        isA<NoteCalculatorException>().having((f) => f.offset, 'offset', 2),
      );
      expect('$failure', contains('syntax'));
    });
  });

  group('format', () {
    test('writes whole numbers without a point', () {
      expect(NoteCalculator.format(14), '14');
      expect(NoteCalculator.format(-3), '-3');
      expect(NoteCalculator.format(0), '0');
      expect(NoteCalculator.format(-0.0), '0');
      expect(NoteCalculator.format(123456789012345), '123456789012345');
    });

    test('hides binary noise with 12 significant digits', () {
      expect(NoteCalculator.format(0.1 + 0.2), '0.3');
      expect(NoteCalculator.format(1 / 3), '0.333333333333');
      expect(NoteCalculator.format(2 / 3), '0.666666666667');
      expect(NoteCalculator.format(2.9999999999999996), '3');
      expect(NoteCalculator.format(-3.5), '-3.5');
      expect(NoteCalculator.format(0.000001), '0.000001');
    });

    test('uses scientific notation for very large and small values', () {
      expect(NoteCalculator.format(1e15), '1e+15');
      expect(NoteCalculator.format(-2.5e20), '-2.5e+20');
      expect(NoteCalculator.format(1.5e-7), '1.5e-7');
    });

    test('keeps non-finite values readable', () {
      expect(NoteCalculator.format(double.infinity), 'Infinity');
      expect(NoteCalculator.format(double.nan), 'NaN');
    });

    test('what it writes evaluates back', () {
      for (final value in <double>[
        0,
        -12.5,
        1 / 3,
        6.02214076e23,
        -1.6e-19,
        123456.789,
      ]) {
        expect(
          _eval(NoteCalculator.format(value)),
          closeTo(value, value.abs() * 1e-11 + 1e-30),
          reason: '$value',
        );
      }
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/style/style.dart';

void main() {
  const dashed = NoteLineStyleKind.dashed;
  const dotted = NoteLineStyleKind.dotted;

  group('NoteLineStyle', () {
    test('has the documented defaults', () {
      final line = NoteLineStyle.of(dashed);
      expect(line.dashLength, 1.4);
      expect(line.gap, 1.6);
      expect(NoteLineStyle.of(dotted).dashLength, 0.1);
      expect(NoteLineStyle.of(dotted).gap, 1.6);
      expect(line.amplitude, 1.5);
      expect(line.wavelength, 8);
      expect(line.doubleGap, 1.2);
      expect(NoteLineStyle(), NoteLineStyle.solid);
      expect(NoteLineStyleKind.values, hasLength(6));
    });

    test('clamps every parameter into its range', () {
      final low = NoteLineStyle(
        kind: dashed,
        dashLength: -1,
        gap: 0,
        amplitude: 0,
        wavelength: 0,
        doubleGap: 0,
      );
      expect(
        [low.dashLength, low.gap, low.amplitude, low.wavelength, low.doubleGap],
        [0.2, 0.2, 0.2, 1, 0.3],
      );
      final high = NoteLineStyle(
        kind: dashed,
        dashLength: 99,
        gap: 99,
        amplitude: 99,
        wavelength: 99,
        doubleGap: 99,
      );
      expect(
        [
          high.dashLength,
          high.gap,
          high.amplitude,
          high.wavelength,
          high.doubleGap,
        ],
        [10, 10, 6, 20, 6],
      );
    });

    test('only the dotted kind accepts a dash as short as 0.1', () {
      expect(NoteLineStyle(kind: dotted, dashLength: 0.1).dashLength, 0.1);
      expect(NoteLineStyle(kind: dotted, dashLength: 0).dashLength, 0.1);
      expect(NoteLineStyle(kind: dashed, dashLength: 0.1).dashLength, 0.2);
    });

    test('non-finite parameters take the defaults', () {
      final line = NoteLineStyle(
        kind: dashed,
        dashLength: double.nan,
        gap: double.infinity,
        wavelength: double.negativeInfinity,
      );
      expect(line, NoteLineStyle.of(dashed));
    });

    test('encode writes parameters up to the last non-default one', () {
      expect(NoteLineStyle.solid.encode(), 'solid');
      expect(NoteLineStyle.of(dashed).encode(), 'dashed');
      expect(NoteLineStyle.of(dotted).encode(), 'dotted');
      expect(
        NoteLineStyle(kind: dashed, dashLength: 2, gap: 3).encode(),
        'dashed:2:3',
      );
      expect(NoteLineStyle(kind: dotted, gap: 2).encode(), 'dotted:0.1:2');
      expect(
        NoteLineStyle(kind: NoteLineStyleKind.wavy, amplitude: 2).encode(),
        'wavy:1.4:1.6:2',
      );
      expect(
        NoteLineStyle(kind: NoteLineStyleKind.double, doubleGap: 0.5).encode(),
        'double:1.4:1.6:1.5:8:0.5',
      );
    });

    test('decode reads the documented grammar', () {
      expect(
        NoteLineStyle.decode('wavy:1.4:1.6:2:10'),
        NoteLineStyle(
          kind: NoteLineStyleKind.wavy,
          amplitude: 2,
          wavelength: 10,
        ),
      );
      expect(NoteLineStyle.decode('zigzag').kind, NoteLineStyleKind.zigzag);
      expect(NoteLineStyle.decode('double').kind, NoteLineStyleKind.double);
    });

    test('decode(encode(x)) == x for every kind and parameter mix', () {
      var checked = 0;
      for (final kind in NoteLineStyleKind.values) {
        for (final dash in [null, 0.1, 0.2, 1.4, 10 / 3, 10.0]) {
          for (final gap in [null, 0.2, 1.6, 0.1 + 0.2, 7.5]) {
            for (final amplitude in [null, 0.7, 6.0]) {
              for (final wavelength in [null, 1.0, 12.25]) {
                for (final doubleGap in [null, 0.3, 4.0]) {
                  final style = NoteLineStyle(
                    kind: kind,
                    dashLength: dash,
                    gap: gap,
                    amplitude: amplitude,
                    wavelength: wavelength,
                    doubleGap: doubleGap,
                  );
                  expect(NoteLineStyle.decode(style.encode()), style);
                  checked++;
                }
              }
            }
          }
        }
      }
      expect(checked, 6 * 6 * 5 * 3 * 3 * 3);
    });

    test('malformed strings decode to solid and never throw', () {
      final inputs = <String?>[
        null,
        '',
        ' ',
        ':',
        '::::::',
        'nope',
        'Dashed',
        'dashed ',
        'dashed:',
        'dashed:a',
        'dashed::2',
        'dashed:NaN',
        'dashed:Infinity',
        'dashed:1e999',
        'dashed:1:2:3:4:5x',
        'solid:x',
        '{"kind":"dashed"}',
        '\u0000',
        'a' * 100000,
        '${'dashed:' * 5000}1',
        '✏️:1',
      ];
      for (final input in inputs) {
        expect(
          NoteLineStyle.decode(input),
          NoteLineStyle.solid,
          reason: 'input: $input',
        );
      }
    });

    test('decode ignores parameters appended by a newer version', () {
      expect(
        NoteLineStyle.decode('dashed:2:3:1.5:8:1.2:99:abc'),
        NoteLineStyle(kind: dashed, dashLength: 2, gap: 3),
      );
    });

    test('decode clamps numbers that are out of range', () {
      final line = NoteLineStyle.decode('dashed:100:-4');
      expect(line.dashLength, 10);
      expect(line.gap, 0.2);
    });

    test('copyWith moves a default dash length with the kind', () {
      final dots = NoteLineStyle.of(dashed).copyWith(kind: dotted);
      expect(dots, NoteLineStyle.of(dotted));
      expect(dots.copyWith(kind: dashed), NoteLineStyle.of(dashed));
      final custom = NoteLineStyle(kind: dashed, dashLength: 3);
      expect(custom.copyWith(kind: dotted).dashLength, 3);
      expect(
        NoteLineStyle.solid.copyWith(kind: dotted, dashLength: 0.5).dashLength,
        0.5,
      );
      expect(custom.copyWith(gap: 5).gap, 5);
      expect(custom.copyWith(), custom);
    });

    test('JSON round trip and lenient reading', () {
      final line = NoteLineStyle(
        kind: NoteLineStyleKind.zigzag,
        amplitude: 3,
        wavelength: 5,
      );
      expect(NoteLineStyle.fromJson(line.toJson()), line);
      expect(
        NoteLineStyle.fromJson('dashed:2:3'),
        NoteLineStyle(kind: dashed, dashLength: 2, gap: 3),
      );
      for (final bad in <Object?>[null, 42, <Object?>[], true]) {
        expect(NoteLineStyle.fromJson(bad), NoteLineStyle.solid);
      }
      final odd = NoteLineStyle.fromJson({'kind': 'sparkly', 'gap': 3});
      expect(odd.kind, NoteLineStyleKind.solid);
      expect(odd.gap, 3);
      expect(
        NoteLineStyle.fromJson({'kind': 'dashed', 'dashLength': 'x'}),
        NoteLineStyle.of(dashed),
      );
    });

    test('equality, hashCode and toString', () {
      final a = NoteLineStyle(kind: dashed, gap: 2);
      final b = NoteLineStyle(kind: dashed, gap: 2);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(NoteLineStyle(kind: dashed, gap: 2.5)));
      expect(a, isNot(NoteLineStyle(kind: dotted, gap: 2, dashLength: 1.4)));
      expect(a.toString(), 'NoteLineStyle(dashed:1.4:2)');
    });
  });
}

import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/tools/tools.dart';

void _expectClose(Color actual, Color expected) {
  const tolerance = 1 / 255;

  expect(actual.r, closeTo(expected.r, tolerance));
  expect(actual.g, closeTo(expected.g, tolerance));
  expect(actual.b, closeTo(expected.b, tolerance));
  expect(actual.a, closeTo(expected.a, tolerance));
}

void main() {
  group('NoteHsv.fromColor', () {
    test('reads the primary and secondary hues', () {
      const hues = {
        0xFFFF0000: 0.0,
        0xFFFFFF00: 60.0,
        0xFF00FF00: 120.0,
        0xFF00FFFF: 180.0,
        0xFF0000FF: 240.0,
        0xFFFF00FF: 300.0,
      };

      hues.forEach((argb, hue) {
        final hsv = NoteHsv.fromColor(Color(argb));

        expect(hsv.h, closeTo(hue, 1e-9), reason: '$argb');
        expect(hsv.s, 1);
        expect(hsv.v, 1);
      });
    });

    test('gives greys no hue and black no saturation', () {
      final grey = NoteHsv.fromColor(const Color(0xFF808080));
      final black = NoteHsv.fromColor(const Color(0xFF000000));
      final white = NoteHsv.fromColor(const Color(0xFFFFFFFF));

      expect((grey.h, grey.s), (0, 0));
      expect(grey.v, closeTo(128 / 255, 1e-9));
      expect((black.s, black.v), (0, 0));
      expect((white.s, white.v), (0, 1));
    });

    test('keeps the hue of colours just below 360 degrees', () {
      final hsv = NoteHsv.fromColor(const Color(0xFFFF0001));

      expect(hsv.h, inInclusiveRange(359, 360));
    });

    test('keeps the opacity', () {
      expect(
        NoteHsv.fromColor(const Color(0x40FF0000)).a,
        closeTo(0x40 / 255, 1e-9),
      );
    });
  });

  group('NoteHsv.toColor', () {
    test('converts known values', () {
      expect(const NoteHsv(h: 0, s: 1, v: 1).toColor().toARGB32(), 0xFFFF0000);
      expect(
        const NoteHsv(h: 210, s: 0.5, v: 0.8).toColor().toARGB32(),
        0xFF6699CC,
      );
      expect(
        const NoteHsv(h: 45, s: 0, v: 0, a: 0).toColor().toARGB32(),
        0x00000000,
      );
    });

    test('round trips a grid of 8 bit colours exactly', () {
      for (var r = 0; r <= 255; r += 15) {
        for (var g = 0; g <= 255; g += 15) {
          for (var b = 0; b <= 255; b += 15) {
            final color = Color.fromARGB(200, r, g, b);

            expect(
              NoteHsv.fromColor(color).toColor().toARGB32(),
              color.toARGB32(),
              reason: '($r, $g, $b)',
            );
          }
        }
      }
    });

    test('round trips random 8 bit colours exactly', () {
      final random = math.Random(1);
      for (var i = 0; i < 20000; i++) {
        final argb = random.nextInt(1 << 32);

        expect(NoteHsv.fromColor(Color(argb)).toColor().toARGB32(), argb);
      }
    });

    test('round trips unrounded colours within 1/255 per channel', () {
      final random = math.Random(2);
      for (var i = 0; i < 2000; i++) {
        final color = Color.from(
          alpha: random.nextDouble(),
          red: random.nextDouble(),
          green: random.nextDouble(),
          blue: random.nextDouble(),
        );

        _expectClose(NoteHsv.fromColor(color).toColor(), color);
      }
    });
  });

  group('NoteHsv values', () {
    test('wraps the hue into 0-360', () {
      expect(const NoteHsv(h: 360, s: 1, v: 1).h, 0);
      expect(const NoteHsv(h: 725, s: 1, v: 1).h, 5);
      expect(const NoteHsv(h: -90, s: 1, v: 1).h, 270);
      expect(const NoteHsv(h: -1e-15, s: 1, v: 1).h, 0);
      expect(const NoteHsv(h: double.nan, s: 1, v: 1).h, 0);
    });

    test('clamps the other components', () {
      const hsv = NoteHsv(h: 0, s: 3, v: -1, a: 9);
      const broken = NoteHsv(
        h: 0,
        s: double.nan,
        v: double.infinity,
        a: double.nan,
      );

      expect((hsv.s, hsv.v, hsv.a), (1, 0, 1));
      expect((broken.s, broken.v, broken.a), (0, 0, 1));
    });

    test('has value equality and copyWith', () {
      const hsv = NoteHsv(h: 10, s: 0.2, v: 0.3, a: 0.4);

      expect(hsv.copyWith(), hsv);
      expect(hsv.copyWith().hashCode, hsv.hashCode);
      expect(hsv.copyWith(h: 370), hsv);
      expect(hsv.copyWith(s: 0.9), isNot(hsv));
      expect(hsv.copyWith(v: 0.9).v, 0.9);
      expect(hsv.copyWith(a: 0.9).a, 0.9);
      expect(hsv.toString(), contains('10'));
    });
  });
}

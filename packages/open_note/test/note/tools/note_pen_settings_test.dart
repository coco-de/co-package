import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/tools/tools.dart';

void main() {
  group('NotePenSettings', () {
    test('has the documented defaults', () {
      const settings = NotePenSettings();

      expect(settings.motionSmoothing, 5);
      expect(settings.stabilization, 0.2);
      expect(settings.pressureSensitivity, 0.5);
    });

    test('clamps values into their ranges', () {
      const low = NotePenSettings(
        motionSmoothing: -3,
        stabilization: -1,
        pressureSensitivity: -0.1,
      );
      const high = NotePenSettings(
        motionSmoothing: 42,
        stabilization: 7,
        pressureSensitivity: 1.1,
      );

      expect(
        low,
        const NotePenSettings(
          motionSmoothing: 0,
          stabilization: 0,
          pressureSensitivity: 0,
        ),
      );
      expect(
        high,
        const NotePenSettings(
          motionSmoothing: 10,
          stabilization: 1,
          pressureSensitivity: 1,
        ),
      );
    });

    test('reads NaN and infinity as the defaults', () {
      const settings = NotePenSettings(
        stabilization: double.nan,
        pressureSensitivity: double.infinity,
      );

      expect(settings.stabilization, 0.2);
      expect(settings.pressureSensitivity, 0.5);
    });

    test('round trips through JSON', () {
      const settings = NotePenSettings(
        motionSmoothing: 8,
        stabilization: 0.75,
        pressureSensitivity: 0.1,
      );

      expect(NotePenSettings.fromJson(settings.toJson()), settings);
      expect(settings.toJson(), {
        'motionSmoothing': 8,
        'stabilization': 0.75,
        'pressureSensitivity': 0.1,
      });
    });

    test('never throws on malformed JSON', () {
      for (final json in <Object?>[null, 3, 'x', <Object?>[], {}]) {
        expect(NotePenSettings.fromJson(json), const NotePenSettings());
      }
      expect(
        NotePenSettings.fromJson({
          'motionSmoothing': 7.9,
          'stabilization': 'a lot',
          'pressureSensitivity': 99,
          'extra': true,
        }),
        const NotePenSettings(motionSmoothing: 7, pressureSensitivity: 1),
      );
    });

    test('copyWith replaces only the given values', () {
      const settings = NotePenSettings(motionSmoothing: 2);

      expect(
        settings.copyWith(stabilization: 0.9),
        const NotePenSettings(motionSmoothing: 2, stabilization: 0.9),
      );
      expect(settings.copyWith(), settings);
      expect(settings.copyWith().hashCode, settings.hashCode);
    });
  });

  group('toEngineParams', () {
    NotePenEngineParams params({
      int motionSmoothing = 5,
      double stabilization = 0.2,
      double pressureSensitivity = 0.5,
    }) => NotePenSettings(
      motionSmoothing: motionSmoothing,
      stabilization: stabilization,
      pressureSensitivity: pressureSensitivity,
    ).toEngineParams();

    test('maps motion smoothing to smoothing = m / 10', () {
      expect(params(motionSmoothing: 0).smoothing, 0);
      expect(params().smoothing, 0.5);
      expect(params(motionSmoothing: 10).smoothing, 1);
    });

    test('maps stabilization to streamline = 0.1 + 0.8 * s', () {
      expect(params(stabilization: 0).streamline, closeTo(0.1, 1e-12));
      expect(params().streamline, closeTo(0.26, 1e-12));
      expect(params(stabilization: 1).streamline, closeTo(0.9, 1e-12));
    });

    test('maps pressure sensitivity to thinningScale in [0.25, 1.5]', () {
      expect(params(pressureSensitivity: 0).thinningScale, 0.25);
      expect(params().thinningScale, 1);
      expect(params(pressureSensitivity: 1).thinningScale, 1.5);
      expect(
        params(pressureSensitivity: 0.25).thinningScale,
        closeTo(0.625, 1e-12),
      );
      expect(
        params(pressureSensitivity: 0.75).thinningScale,
        closeTo(1.25, 1e-12),
      );
    });

    test('thinningScale never decreases as sensitivity grows', () {
      var previous = 0.0;
      for (var step = 0; step <= 100; step++) {
        final scale = params(pressureSensitivity: step / 100).thinningScale;
        expect(scale, greaterThanOrEqualTo(previous));
        expect(scale, inInclusiveRange(0.25, 1.5));
        previous = scale;
      }
    });

    test('maps pressure sensitivity to gamma = 2^(2 (p - 0.5))', () {
      expect(params(pressureSensitivity: 0).pressureGamma, 0.5);
      expect(params().pressureGamma, 1);
      expect(params(pressureSensitivity: 1).pressureGamma, 2);
    });

    test('keeps pressure untouched at the default sensitivity', () {
      final neutral = params();

      for (final pressure in [0.0, 0.25, 0.5, 0.9, 1.0]) {
        expect(neutral.applyPressure(pressure), closeTo(pressure, 1e-12));
      }
    });

    test('makes light touches thicker below 0.5 and thinner above', () {
      final soft = params(pressureSensitivity: 0);
      final firm = params(pressureSensitivity: 1);

      expect(soft.applyPressure(0.25), closeTo(0.5, 1e-12));
      expect(firm.applyPressure(0.25), closeTo(0.0625, 1e-12));
      for (final curve in [soft, firm]) {
        expect(curve.applyPressure(0), 0);
        expect(curve.applyPressure(1), 1);
        expect(curve.applyPressure(-1), 0);
        expect(curve.applyPressure(3), 1);
        expect(curve.applyPressure(double.nan), 0);
      }
    });

    test('has value equality', () {
      expect(params(), params());
      expect(params().hashCode, params().hashCode);
      expect(params(), isNot(params(motionSmoothing: 6)));
      expect(params().toString(), contains('streamline'));
    });
  });
}

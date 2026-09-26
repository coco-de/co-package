import 'package:co_golden/co_golden.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('naming', () {
    test('accepts lowercase path segments', () {
      for (final name in ['phone', 'phone-compact', 'login_default', 'v1.2']) {
        expect(isGoldenName(name), isTrue, reason: name);
      }
    });

    test('rejects names that would break paths', () {
      for (final name in ['', 'Phone', 'my phone', '-x', 'a/b', 'a..b']) {
        expect(isGoldenName(name), isFalse, reason: name);
        expect(() => checkGoldenName(name, 'name'), throwsArgumentError);
      }
    });

    test('formats locale and scale tokens', () {
      expect(goldenLocaleToken(const Locale('en')), 'en');
      expect(
        goldenLocaleToken(
          const Locale.fromSubtags(languageCode: 'pt', countryCode: 'BR'),
        ),
        'pt-br',
      );
      expect(goldenScaleToken(1), '1');
      expect(goldenScaleToken(1.3), '1.3');
    });
  });

  group('device', () {
    test('derives the physical size from the pixel ratio', () {
      expect(GoldenDevice.phoneCompact.physicalSize, const Size(640, 1136));
      expect(GoldenDevice.desktop.physicalSize, const Size(2560, 1600));
    });

    test('rotates geometry and insets', () {
      final landscape = GoldenDevice.phoneIos.rotated();

      expect(landscape.name, 'phone-ios-landscape');
      expect(landscape.logicalSize, const Size(852, 393));
      expect(landscape.isLandscape, isTrue);
      expect(landscape.safeArea, const EdgeInsets.only(left: 59, right: 34));
      expect(landscape.platform, TargetPlatform.iOS);
    });

    test('presets have unique names', () {
      final names = GoldenDevice.presets.map((device) => device.name);

      expect(names.toSet(), hasLength(GoldenDevice.presets.length));
      expect(names.every(isGoldenName), isTrue);
    });
  });

  group('environment', () {
    test('skips when the mode is missing or empty', () {
      expect(
        GoldenMatrixEnvironment.fromEnvironment(const {}).mode,
        GoldenMatrixMode.skip,
      );
      expect(
        GoldenMatrixEnvironment.fromEnvironment(const {
          'CO_GOLDEN_MODE': ' ',
        }).mode,
        GoldenMatrixMode.skip,
      );
    });

    test('reads the mode and output directory', () {
      final environment = GoldenMatrixEnvironment.fromEnvironment(const {
        'CO_GOLDEN_MODE': 'Capture',
        'CO_GOLDEN_OUTPUT': '/tmp/goldens',
      });

      expect(environment.mode, GoldenMatrixMode.capture);
      expect(environment.outputDirectory, '/tmp/goldens');
    });

    test('falls back to the default output directory', () {
      final environment = GoldenMatrixEnvironment.fromEnvironment(const {
        'CO_GOLDEN_MODE': 'compare',
      });

      expect(environment.mode, GoldenMatrixMode.compare);
      expect(
        environment.outputDirectory,
        GoldenMatrixEnvironment.defaultOutputDirectory,
      );
    });

    test('rejects an unknown mode instead of skipping silently', () {
      expect(
        () => GoldenMatrixEnvironment.fromEnvironment(const {
          'CO_GOLDEN_MODE': 'captur',
        }),
        throwsArgumentError,
      );
    });
  });

  group('fonts', () {
    test('registers package families under their plain name too', () {
      final families = goldenFontFamilies([
        {
          'family': 'packages/resources/Pretendard',
          'fonts': [
            {'asset': 'packages/resources/fonts/Pretendard-Regular.ttf'},
            {'asset': 'packages/resources/fonts/Pretendard-Bold.ttf'},
          ],
        },
        {
          'family': 'MaterialIcons',
          'fonts': [
            {'asset': 'fonts/MaterialIcons-Regular.otf'},
          ],
        },
      ]);

      expect(families.keys, [
        'packages/resources/Pretendard',
        'MaterialIcons',
        'Pretendard',
      ]);
      expect(families['Pretendard'], families['packages/resources/Pretendard']);
    });

    test('keeps a plain family that the manifest declares itself', () {
      final families = goldenFontFamilies([
        {
          'family': 'Pretendard',
          'fonts': [
            {'asset': 'fonts/Own.ttf'},
          ],
        },
        {
          'family': 'packages/resources/Pretendard',
          'fonts': [
            {'asset': 'packages/resources/fonts/Pretendard-Regular.ttf'},
          ],
        },
      ]);

      expect(families['Pretendard'], ['fonts/Own.ttf']);
    });

    test('drops families without assets and rejects other shapes', () {
      expect(
        goldenFontFamilies([
          {'family': 'Empty', 'fonts': <Object?>[]},
        ]),
        isEmpty,
      );
      expect(() => goldenFontFamilies({'family': 'x'}), throwsStateError);
    });
  });
}

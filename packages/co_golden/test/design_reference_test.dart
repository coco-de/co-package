import 'dart:convert';
import 'dart:io';

import 'package:co_golden/co_golden.dart';
import 'package:co_golden/src/design_comparison_capture.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:path/path.dart' as p;

final _output = Directory.systemTemp.createTempSync('co_golden_design_');
const _tiny = GoldenDevice(name: 'tiny', logicalSize: Size(2, 2));
const _red = Color(0xffff0000);

image.Image _redImage({int width = 2, int height = 2}) {
  final png = image.Image(width: width, height: height, numChannels: 4);
  image.fill(png, color: image.ColorRgba8(255, 0, 0, 255));
  return png;
}

File _png(String name, image.Image pixels) {
  final file = File(p.join(_output.path, name));
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(image.encodePng(pixels));
  return file;
}

GoldenMatrix<Color> _matrix({
  List<GoldenTheme<Color>> themes = const [
    GoldenTheme(name: 'light', data: _red),
  ],
  GoldenMatrixMode mode = GoldenMatrixMode.capture,
}) => GoldenMatrix<Color>(
  suite: 'design',
  coverage: GoldenCoverage(
    devices: const [_tiny],
    themes: themes,
    locales: const [Locale('en')],
  ),
  environment: GoldenMatrixEnvironment(
    mode: mode,
    outputDirectory: _output.path,
  ),
  app: (variant, child) =>
      Directionality(textDirection: TextDirection.ltr, child: child),
);

List<Map<String, Object?>> _results(String scenario) {
  final json =
      jsonDecode(
            File(
              p.join(
                _output.path,
                GoldenScenarioReport.manifestPath('design', scenario),
              ),
            ).readAsStringSync(),
          )
          as Map<String, Object?>;
  expect(json['schemaVersion'], 1);
  return (json['results']! as List<Object?>).cast<Map<String, Object?>>();
}

void main() {
  tearDownAll(() => _output.deleteSync(recursive: true));
  final original = _png('exports/exact.png', _redImage());
  final different = _png(
    'exports/different.png',
    _redImage()..setPixelRgba(1, 0, 0, 0, 255, 255),
  );
  final mismatch = _png('exports/small.png', _redImage(width: 1));
  var resolverCalls = 0;
  _matrix(
    themes: const [
      GoldenTheme(name: 'light', data: _red),
      GoldenTheme(name: 'dark', data: _red, brightness: Brightness.dark),
    ],
  ).scenario(
    'associated',
    build: (_) => const ColoredBox(color: _red),
    designReference: (variant) {
      resolverCalls++;
      return variant.theme.name == 'light'
          ? GoldenDesignReference(
              imagePath: original.path,
              label: 'Figma login',
              sourceUrl: 'https://www.figma.com/design/example?node-id=1-2',
            )
          : null;
    },
  );
  _matrix().scenario(
    'different',
    build: (_) => const ColoredBox(color: _red),
    designReference: (_) => GoldenDesignReference(imagePath: different.path),
  );
  _matrix().scenario(
    'geometry',
    build: (_) => const ColoredBox(color: _red),
    designReference: (_) => GoldenDesignReference(imagePath: mismatch.path),
  );
  _matrix().scenario('without', build: (_) => const ColoredBox(color: _red));
  _matrix(mode: GoldenMatrixMode.skip).scenario(
    'skipped',
    build: (_) => const SizedBox(),
    designReference: (_) => throw StateError('Must not resolve in skip mode.'),
  );

  test(
    'capture associates only the resolved variant and snapshots PNG bytes',
    () {
      final results = _results('associated');
      expect(resolverCalls, 2);
      expect(results, hasLength(2));
      final matching =
          results.first['designComparison']! as Map<String, Object?>;
      expect(matching, {
        'reference': 'references/design/associated/tiny__light__en.png',
        'label': 'Figma login',
        'sourceUrl': 'https://www.figma.com/design/example?node-id=1-2',
        'status': 'matched',
        'referenceWidth': 2,
        'referenceHeight': 2,
        'renderWidth': 2,
        'renderHeight': 2,
        'diff': 'differences/design/associated/tiny__light__en.png',
        'differentPixels': 0,
        'totalPixels': 4,
        'differenceRatio': 0.0,
      });
      final snapshot = File(
        p.join(_output.path, matching['reference']! as String),
      );
      final originalBytes = original.readAsBytesSync();
      expect(snapshot.readAsBytesSync(), originalBytes);
      original.writeAsBytesSync(image.encodePng(_redImage(width: 1)));
      expect(snapshot.readAsBytesSync(), originalBytes);
      expect(results.last.containsKey('designComparison'), isFalse);
      expect(
        File(
          p.join(
            _output.path,
            'references/design/associated/tiny__dark__en.png',
          ),
        ).existsSync(),
        isFalse,
      );
      expect(
        File(p.join(_output.path, matching['diff']! as String)).existsSync(),
        isTrue,
      );
    },
  );

  test(
    'different and size mismatch captures pass without design acceptance',
    () {
      final result = _results('different').single;
      final comparison = result['designComparison']! as Map<String, Object?>;
      expect(result['status'], 'passed');
      expect(comparison['status'], 'different');
      expect(comparison['differentPixels'], 1);
      expect(comparison['totalPixels'], 4);
      expect(comparison['differenceRatio'], 0.25);
      final diff = image.decodePng(
        File(
          p.join(_output.path, comparison['diff']! as String),
        ).readAsBytesSync(),
      )!;
      final changed = diff.getPixel(1, 0);
      expect([changed.r, changed.g, changed.b, changed.a], [255, 0, 255, 255]);
      final geometryResult = _results('geometry').single;
      final geometry =
          geometryResult['designComparison']! as Map<String, Object?>;
      expect(geometryResult['status'], 'passed');
      expect(geometry['status'], 'sizeMismatch');
      expect(geometry['referenceWidth'], 1);
      expect(geometry['referenceHeight'], 2);
      expect(geometry['renderWidth'], 2);
      expect(geometry['renderHeight'], 2);
      for (final field in [
        'diff',
        'differentPixels',
        'totalPixels',
        'differenceRatio',
      ]) {
        expect(geometry[field], isNull, reason: field);
      }
      expect(
        Directory(
          p.join(_output.path, 'differences/design/geometry'),
        ).existsSync(),
        isFalse,
      );
    },
  );

  test('old manifests and scenarios without references stay unchanged', () {
    expect(_results('without').single.containsKey('designComparison'), isFalse);
    expect(
      Directory(p.join(_output.path, 'references/design/without')).existsSync(),
      isFalse,
    );
    expect(
      Directory(p.join(_output.path, 'references/design/skipped')).existsSync(),
      isFalse,
    );
    expect(
      File(p.join(_output.path, 'runs/design/skipped.json')).existsSync(),
      isFalse,
    );
  });

  group('exact decoded RGBA', () {
    GoldenDesignComparison compare(image.Image reference, image.Image render) {
      final input = _png('unit/reference.png', reference);
      _png('unit/render.png', render);
      return captureDesignComparison(
        design: GoldenDesignReference(imagePath: input.path),
        outputDirectory: _output.path,
        renderPath: 'unit/render.png',
        suite: 'unit',
        scenario: 'rgba',
        fileStem: 'tiny',
      );
    }

    test('counts alpha-only changes and makes them visible', () {
      final reference = _redImage()..setPixelRgba(0, 0, 255, 0, 0, 254);
      final result = compare(reference, _redImage());
      expect(result.differentPixels, 1);
      expect(result.differenceRatio, 0.25);
      final diff = image.decodePng(
        File(p.join(_output.path, result.diff!)).readAsBytesSync(),
      )!;
      expect(diff.getPixel(0, 0).g, 0);
      expect(diff.getPixel(0, 0).a, 255);
    });

    test('includes differing RGB channels under fully transparent pixels', () {
      final reference = _redImage()..setPixelRgba(0, 0, 255, 0, 0, 0);
      final render = _redImage()..setPixelRgba(0, 0, 0, 0, 0, 0);
      expect(compare(reference, render).differentPixels, 1);
    });

    test('retains 16-bit precision and handles equal normalized channels', () {
      final reference = image.Image(
        width: 2,
        height: 2,
        format: image.Format.uint16,
        numChannels: 4,
      );
      for (final pixel in reference) {
        pixel.setRgba(65535, 0, 0, 65535);
      }
      expect(
        compare(reference, _redImage()).status,
        GoldenDesignComparisonStatus.matched,
      );
      reference.setPixelRgba(0, 0, 65534, 0, 0, 65535);
      expect(compare(reference, _redImage()).differentPixels, 1);
    });
  });

  test('invalid references fail the recorded designComparison phase', () async {
    var root = Directory.current;
    while (!File(
      p.join(root.path, '.dart_tool/package_config.json'),
    ).existsSync()) {
      final parent = root.parent;
      if (parent.path == root.path) {
        throw StateError('Package configuration not found.');
      }
      root = parent;
    }
    final configFile = File(
      p.join(root.path, '.dart_tool/package_config.json'),
    );
    final config =
        jsonDecode(configFile.readAsStringSync()) as Map<String, Object?>;
    final packages = (config['packages']! as List<Object?>)
        .cast<Map<String, Object?>>();
    Directory packageRoot(String name) => Directory.fromUri(
      configFile.uri.resolve(
        packages.singleWhere((package) => package['name'] == name)['rootUri']!
            as String,
      ),
    );
    final flutter = File(
      p.normalize(
        p.join(
          packageRoot('flutter').path,
          '..',
          '..',
          'bin',
          Platform.isWindows ? 'flutter.bat' : 'flutter',
        ),
      ),
    );
    final package = packageRoot('co_golden');
    final invalidOutput = Directory(p.join(_output.path, 'invalid'));
    final result = await Process.run(
      flutter.path,
      ['test', '--no-pub', 'test/fixtures/design_reference_failure.dart'],
      workingDirectory: package.path,
      environment: {'CO_GOLDEN_FAILURE_OUTPUT': invalidOutput.path},
    );
    expect(result.exitCode, 1, reason: '${result.stdout}\n${result.stderr}');
    for (final scenario in ['missing', 'invalid', 'resolver']) {
      final manifest =
          jsonDecode(
                File(
                  p.join(
                    invalidOutput.path,
                    'runs/design-failure/$scenario.json',
                  ),
                ).readAsStringSync(),
              )
              as Map<String, Object?>;
      final entry =
          (manifest['results']! as List<Object?>).single!
              as Map<String, Object?>;
      expect(entry['status'], 'failed');
      expect(entry['failurePhase'], 'designComparison');
      expect(entry['errors'], isNotEmpty);
      expect(
        File(
          p.join(invalidOutput.path, entry['image']! as String),
        ).existsSync(),
        isTrue,
      );
      expect(entry.containsKey('designComparison'), isFalse);
    }
  }, timeout: const Timeout(Duration(minutes: 2)));
}

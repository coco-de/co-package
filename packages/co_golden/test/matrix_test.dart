import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:co_golden/co_golden.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

final Directory _output = Directory.systemTemp.createTempSync('co_golden_');

GoldenMatrix<ThemeData> _matrix({
  required String suite,
  required GoldenMatrixMode mode,
  List<GoldenDevice> devices = const [
    GoldenDevice.phoneCompact,
    GoldenDevice.desktop,
  ],
  bool failOnErrors = true,
}) => GoldenMatrix<ThemeData>(
  suite: suite,
  environment: GoldenMatrixEnvironment(
    mode: mode,
    outputDirectory: _output.path,
  ),
  failOnErrors: failOnErrors,
  coverage: GoldenCoverage<ThemeData>(
    devices: devices,
    themes: [
      GoldenTheme(name: 'light', data: ThemeData.light()),
      GoldenTheme(
        name: 'dark',
        data: ThemeData.dark(),
        brightness: Brightness.dark,
      ),
    ],
    locales: const [Locale('en')],
  ),
  // Theme objects resolve their platform when they are created, before the
  // matrix overrides it — the app builder applies the variant's platform.
  app: (variant, child) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: variant.theme.data.copyWith(platform: variant.platform),
    locale: variant.locale,
    home: child,
  ),
);

Map<String, Object?> _manifest(String suite, String scenario) =>
    jsonDecode(
          File(
            p.join(
              _output.path,
              GoldenScenarioReport.manifestPath(suite, scenario),
            ),
          ).readAsStringSync(),
        )
        as Map<String, Object?>;

List<Map<String, Object?>> _results(Map<String, Object?> manifest) => [
  for (final result in manifest['results']! as List<Object?>)
    result! as Map<String, Object?>,
];

(int, int) _pngSize(File file) {
  final header = ByteData.sublistView(file.readAsBytesSync(), 16, 24);
  return (header.getUint32(0), header.getUint32(4));
}

void main() {
  tearDownAll(() => _output.deleteSync(recursive: true));

  final observed = <String>[];
  _matrix(suite: 'demo', mode: GoldenMatrixMode.capture).scenario(
    'card',
    description: 'A card on every device',
    build: (variant) => Scaffold(
      body: Center(
        child: Builder(
          builder: (context) {
            final media = MediaQuery.of(context);
            observed.add(
              '${variant.fileStem} ${media.size.width.toInt()} '
              '${media.devicePixelRatio} ${Theme.of(context).platform.name}',
            );
            return const Card(
              child: Padding(padding: EdgeInsets.all(16), child: Text('Hi')),
            );
          },
        ),
      ),
    ),
  );

  group('capture', () {
    test('writes one PNG per variant at the device pixel ratio', () {
      final sizes = {
        'phone-compact__light__en': (640, 1136),
        'phone-compact__dark__en': (640, 1136),
        'desktop__light__en': (2560, 1600),
        'desktop__dark__en': (2560, 1600),
      };
      for (final MapEntry(key: stem, value: size) in sizes.entries) {
        final file = File(
          p.join(_output.path, 'images', 'demo', 'card', '$stem.png'),
        );
        expect(file.existsSync(), isTrue, reason: stem);
        expect(_pngSize(file), size, reason: stem);
      }
    });

    test('applies the device to the view and the platform', () {
      expect(
        observed.toSet(),
        containsAll(<String>{
          'phone-compact__light__en 320 2.0 iOS',
          'desktop__dark__en 1280 2.0 macOS',
        }),
      );
    });

    test('writes a manifest with the plan and every result', () {
      final manifest = _manifest('demo', 'card');
      final results = _results(manifest);

      expect(manifest['schema'], goldenRunSchema);
      expect(manifest['schemaVersion'], goldenRunSchemaVersion);
      expect(manifest['suite'], 'demo');
      expect(manifest['description'], 'A card on every device');
      expect(manifest['mode'], 'capture');
      expect(manifest['plan'], {
        'combinations': 4,
        'excluded': 0,
        'selected': 4,
        'axes': {
          'devices': ['phone-compact', 'desktop'],
          'themes': ['light', 'dark'],
          'locales': ['en'],
          'textScales': [1.0],
        },
      });
      expect(results, hasLength(4));
      expect(results.map((result) => result['status']).toSet(), {'passed'});
      expect(
        results.first['image'],
        'images/demo/card/phone-compact__light__en.png',
      );
      final variant = results.first['variant']! as Map<String, Object?>;
      expect(variant['theme'], 'light');
      expect(variant['locale'], 'en');
      expect(variant['platform'], 'iOS');
    });
  });

  _matrix(
    suite: 'overflow',
    mode: GoldenMatrixMode.capture,
    devices: const [GoldenDevice.phoneCompact],
    failOnErrors: false,
  ).scenario(
    'wide-row',
    build: (_) => const Scaffold(
      body: Row(
        children: [
          SizedBox(
            width: 400,
            height: 40,
            child: ColoredBox(color: Color(0xFF1565C0)),
          ),
        ],
      ),
    ),
  );

  group('diagnostics', () {
    test('records an overflow as a failure and still captures', () {
      final results = _results(_manifest('overflow', 'wide-row'));

      expect(results, hasLength(2));
      for (final result in results) {
        expect(result['status'], 'failed');
        expect(result['overflowCount'], greaterThanOrEqualTo(1));
        expect(result['errors'], isNotEmpty);
        final image = File(p.join(_output.path, result['image']! as String));
        expect(image.existsSync(), isTrue);
      }
    });
  });

  final skipped = _matrix(suite: 'skipped', mode: GoldenMatrixMode.skip)
    ..scenario('never', build: (_) => const SizedBox());
  Object? duplicate;
  try {
    skipped.scenario('never', build: (_) => const SizedBox());
  } on ArgumentError catch (error) {
    duplicate = error;
  }

  group('registration', () {
    test('skip mode writes nothing', () {
      expect(
        Directory(p.join(_output.path, 'images', 'skipped')).existsSync(),
        isFalse,
      );
      expect(
        Directory(p.join(_output.path, 'runs', 'skipped')).existsSync(),
        isFalse,
      );
    });

    test('rejects a duplicate scenario', () {
      expect(duplicate, isA<ArgumentError>());
    });

    test('rejects an invalid suite name', () {
      expect(
        () => _matrix(suite: 'Bad Suite', mode: GoldenMatrixMode.skip),
        throwsArgumentError,
      );
    });
  });

  final baselines = Directory(p.join(_output.path, 'baselines'))
    ..createSync(recursive: true);
  late GoldenFileComparator previousComparator;
  void useBaselines({required bool update}) {
    previousComparator = goldenFileComparator;
    goldenFileComparator = LocalFileComparator(
      Uri.file(p.join(baselines.path, 'matrix_test.dart')),
    );
    autoUpdateGoldenFiles = update;
  }

  void restoreComparator() {
    autoUpdateGoldenFiles = false;
    goldenFileComparator = previousComparator;
  }

  Widget box(GoldenVariant<ThemeData> variant) =>
      const ColoredBox(color: Color(0xFF2E7D32), child: SizedBox.expand());

  group('compare mode with --update-goldens', () {
    setUpAll(() => useBaselines(update: true));
    tearDownAll(restoreComparator);
    _matrix(
      suite: 'compare',
      mode: GoldenMatrixMode.compare,
      devices: const [GoldenDevice.phoneCompact],
    ).scenario('box', build: box);
  });

  group('compare mode against the baselines', () {
    setUpAll(() => useBaselines(update: false));
    tearDownAll(restoreComparator);
    _matrix(
      suite: 'compare',
      mode: GoldenMatrixMode.compare,
      devices: const [GoldenDevice.phoneCompact],
    ).scenario('box', build: box);

    test('baselines live next to the test file', () {
      final file = File(
        p.join(
          baselines.path,
          'goldens',
          'compare',
          'box',
          'phone-compact__light__en.png',
        ),
      );
      expect(file.existsSync(), isTrue);
      expect(_pngSize(file), (640, 1136));
    });
  });
}

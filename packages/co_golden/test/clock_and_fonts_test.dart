import 'dart:io';

import 'package:clock/clock.dart';
import 'package:co_golden/co_golden.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final Directory _output = Directory.systemTemp.createTempSync('co_golden_');

GoldenMatrix<ThemeData> _matrix({DateTime? clock}) => GoldenMatrix<ThemeData>(
  suite: 'clock',
  environment: GoldenMatrixEnvironment(
    mode: GoldenMatrixMode.capture,
    outputDirectory: _output.path,
  ),
  clock: clock,
  coverage: GoldenCoverage<ThemeData>(
    devices: const [GoldenDevice.phone],
    themes: [GoldenTheme(name: 'light', data: ThemeData.light())],
    locales: const [Locale('en')],
  ),
  app: (variant, child) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: variant.theme.data,
    home: child,
  ),
);

void main() {
  tearDownAll(() => _output.deleteSync(recursive: true));

  final seen = <String, DateTime>{};
  final matrix = _matrix(clock: DateTime.utc(2026, 9, 30, 10, 30));
  Widget stamp(String key) => Builder(
    builder: (context) {
      final now = clock.now();
      seen[key] = now;
      return Text(now.toIso8601String());
    },
  );
  matrix
    ..scenario('fixed', build: (_) => stamp('fixed'))
    ..scenario(
      'override',
      clock: DateTime.utc(2027, 1, 1),
      build: (_) => stamp('override'),
    );

  test('variants read the injected clock', () {
    expect(seen['fixed'], DateTime.utc(2026, 9, 30, 10, 30));
    expect(seen['override'], DateTime.utc(2027, 1, 1));
  });

  testWidgets('loadGoldenFontFiles reports missing files', (tester) async {
    await expectLater(
      loadGoldenFontFiles({
        'Missing': ['test/fonts/does-not-exist.otf'],
      }),
      throwsStateError,
    );
  });
}

// Invoked explicitly by design_reference_test.dart in a child test runner.
// These expected-failure scenarios must not be discovered by ordinary tests.
import 'dart:io';

import 'package:co_golden/co_golden.dart';
import 'package:flutter/widgets.dart';

void main() {
  final output = Platform.environment['CO_GOLDEN_FAILURE_OUTPUT']!;
  final invalid = File('$output/not-a-png.txt');
  invalid.parent.createSync(recursive: true);
  invalid.writeAsStringSync('not a PNG');
  final matrix = GoldenMatrix<int>(
    suite: 'design-failure',
    environment: GoldenMatrixEnvironment(
      mode: GoldenMatrixMode.capture,
      outputDirectory: output,
    ),
    coverage: const GoldenCoverage(
      devices: [GoldenDevice(name: 'tiny', logicalSize: Size(2, 2))],
      themes: [GoldenTheme(name: 'light', data: 0)],
      locales: [Locale('en')],
    ),
    app: (variant, child) =>
        Directionality(textDirection: TextDirection.ltr, child: child),
  );
  matrix
    ..scenario(
      'missing',
      build: (_) => const ColoredBox(color: Color(0xffff0000)),
      designReference: (_) =>
          GoldenDesignReference(imagePath: '$output/missing.png'),
    )
    ..scenario(
      'invalid',
      build: (_) => const ColoredBox(color: Color(0xffff0000)),
      designReference: (_) => GoldenDesignReference(imagePath: invalid.path),
    )
    ..scenario(
      'resolver',
      build: (_) => const ColoredBox(color: Color(0xffff0000)),
      designReference: (_) => throw StateError('Invalid reference resolver'),
    );
}

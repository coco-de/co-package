// Run by design_analysis_test.dart in a subprocess: with failOnMismatch, a
// design mismatch fails the variant and the manifest records the verdict; an
// unreadable design specification fails the designAnalysis phase.
import 'dart:io';

import 'package:co_golden/co_golden.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;

void main() {
  final output = Platform.environment['CO_GOLDEN_GATE_OUTPUT']!;
  final matrix = GoldenMatrix<Color>(
    suite: 'gate',
    coverage: const GoldenCoverage(
      devices: [GoldenDevice(name: 'tiny', logicalSize: Size(40, 30))],
      themes: [GoldenTheme(name: 'light', data: Color(0xffffffff))],
      locales: [Locale('en')],
    ),
    environment: GoldenMatrixEnvironment(
      mode: GoldenMatrixMode.capture,
      outputDirectory: output,
    ),
    app: (variant, child) =>
        Directionality(textDirection: TextDirection.ltr, child: child),
    designAnalysis: const GoldenDesignAnalysis(failOnMismatch: true),
  );
  matrix.scenario(
    'design',
    build: (_) => const ColoredBox(color: Color(0xff1e5ac8)),
  );
  matrix.scenario(
    'screen',
    build: (_) => const ColoredBox(color: Color(0xffc82828)),
    designReference: (variant) => GoldenDesignReference(
      imagePath: p.join(
        output,
        'images',
        'gate',
        'design',
        '${variant.fileStem}.png',
      ),
    ),
  );
  matrix.scenario(
    'spec-missing',
    build: (_) => const ColoredBox(color: Color(0xff1e5ac8)),
    designReference: (variant) => GoldenDesignReference(
      imagePath: p.join(
        output,
        'images',
        'gate',
        'design',
        '${variant.fileStem}.png',
      ),
      specPath: p.join(output, 'missing.design.json'),
    ),
  );
}

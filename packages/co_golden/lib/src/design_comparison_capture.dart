import 'dart:io';

import 'package:image/image.dart' as image;
import 'package:path/path.dart' as p;

import 'design_comparison.dart';
import 'design_reference.dart';

/// Synchronous because widget tests run in a fake-async zone. Exported from this
/// internal library only so the exact pixel behavior can be tested directly.
GoldenDesignComparison captureDesignComparison({
  required GoldenDesignReference design,
  required String outputDirectory,
  required String renderPath,
  required String suite,
  required String scenario,
  required String fileStem,
}) => captureDesign(
  design: design,
  outputDirectory: outputDirectory,
  renderPath: renderPath,
  suite: suite,
  scenario: scenario,
  fileStem: fileStem,
).comparison;

/// The exact comparison together with the decoded images and original design
/// bytes, which the design analysis reuses.
typedef GoldenCapturedDesign = ({
  GoldenDesignComparison comparison,
  image.Image reference,
  image.Image render,
  List<int> referenceBytes,
});

/// Snapshots the design, compares it exactly with the render, and returns the
/// decoded images. See [captureDesignComparison].
GoldenCapturedDesign captureDesign({
  required GoldenDesignReference design,
  required String outputDirectory,
  required String renderPath,
  required String suite,
  required String scenario,
  required String fileStem,
}) {
  if (design.imagePath.trim().isEmpty ||
      RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*://').hasMatch(design.imagePath)) {
    throw ArgumentError.value(design.imagePath, 'imagePath', 'must be local');
  }
  if (design.label.trim().isEmpty) {
    throw ArgumentError.value(design.label, 'label', 'must not be empty');
  }
  final sourceUrl = design.sourceUrl;
  final specPath = design.specPath;
  if (specPath != null &&
      (specPath.trim().isEmpty ||
          RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*://').hasMatch(specPath))) {
    throw ArgumentError.value(specPath, 'specPath', 'must be local');
  }
  if (sourceUrl != null) {
    final uri = Uri.tryParse(sourceUrl);
    if (uri == null ||
        !{'http', 'https'}.contains(uri.scheme) ||
        uri.host.isEmpty) {
      throw ArgumentError.value(sourceUrl, 'sourceUrl', 'must be HTTP(S)');
    }
  }
  // Read once: the manifest always refers to these exact original bytes, even
  // if an external export replaces the source while the matrix is running.
  final referenceBytes = File(design.imagePath).readAsBytesSync();
  final reference = image.decodePng(referenceBytes);
  if (reference == null) {
    throw FormatException('Design reference is not a PNG: ${design.imagePath}');
  }
  if (reference.numFrames != 1) {
    throw const FormatException('Design reference must be a single-frame PNG.');
  }
  final render = image.decodePng(
    File(p.join(outputDirectory, renderPath)).readAsBytesSync(),
  );
  if (render == null || render.numFrames != 1) {
    throw const FormatException('Captured render must be a single-frame PNG.');
  }
  final relative = p.posix.join('references', suite, scenario, '$fileStem.png');
  final referenceFile = File(p.join(outputDirectory, relative));
  referenceFile.parent.createSync(recursive: true);
  referenceFile.writeAsBytesSync(referenceBytes, flush: true);
  if (reference.width != render.width || reference.height != render.height) {
    return (
      comparison: GoldenDesignComparison(
        reference: relative,
        label: design.label,
        sourceUrl: sourceUrl,
        status: GoldenDesignComparisonStatus.sizeMismatch,
        referenceWidth: reference.width,
        referenceHeight: reference.height,
        renderWidth: render.width,
        renderHeight: render.height,
      ),
      reference: reference,
      render: render,
      referenceBytes: referenceBytes,
    );
  }
  final diff = image.Image(width: render.width, height: render.height);
  var differentPixels = 0;
  for (final actual in render) {
    final expected = reference.getPixel(actual.x, actual.y);
    // Normalized channels preserve palette/gray/16-bit PNG equivalence without
    // rounding a design channel to the render's 8-bit precision. Alpha and RGB
    // under full transparency count too: this is exact RGBA, not compositing.
    final changed =
        actual.rNormalized != expected.rNormalized ||
        actual.gNormalized != expected.gNormalized ||
        actual.bNormalized != expected.bNormalized ||
        actual.aNormalized != expected.aNormalized;
    if (changed) {
      differentPixels++;
      diff.setPixelRgb(actual.x, actual.y, 255, 0, 255);
    } else {
      // Keep context subdued against white; alpha-only changes remain visible
      // as opaque magenta instead of disappearing in a transparent diff.
      final gray =
          (actual.rNormalized + actual.gNormalized + actual.bNormalized) / 3;
      final luminance = gray * actual.aNormalized + 1 - actual.aNormalized;
      final shade = (191 + luminance * 64).round();
      diff.setPixelRgb(actual.x, actual.y, shade, shade, shade);
    }
  }
  final diffPath = p.posix.join(
    'differences',
    suite,
    scenario,
    '$fileStem.png',
  );
  final diffFile = File(p.join(outputDirectory, diffPath));
  diffFile.parent.createSync(recursive: true);
  diffFile.writeAsBytesSync(image.encodePng(diff), flush: true);
  final totalPixels = render.width * render.height;
  return (
    comparison: GoldenDesignComparison(
      reference: relative,
      label: design.label,
      sourceUrl: sourceUrl,
      status: differentPixels == 0
          ? GoldenDesignComparisonStatus.matched
          : GoldenDesignComparisonStatus.different,
      referenceWidth: reference.width,
      referenceHeight: reference.height,
      renderWidth: render.width,
      renderHeight: render.height,
      diff: diffPath,
      differentPixels: differentPixels,
      totalPixels: totalPixels,
      differenceRatio: differentPixels / totalPixels,
    ),
    reference: reference,
    render: render,
    referenceBytes: referenceBytes,
  );
}

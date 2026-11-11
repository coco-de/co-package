import 'dart:math' as math;
import 'package:co_golden/src/design/geometry.dart';
import 'package:co_golden/src/design/ink_raster_evidence.dart';
import 'package:co_golden/src/design/pixel_diff.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;

image.Image glyph(
  String space, {
  int foreground = 0x5620ba,
  bool extra = false,
}) {
  const bg = 0xe7d8ff;
  final result = image.Image(width: 24, height: 28, numChannels: 4);
  double linear(int c) {
    final v = c / 255;
    return (v <= .04045 ? v / 12.92 : math.pow((v + .055) / 1.055, 2.4))
        .toDouble();
  }

  int blend(int a, int b, double alpha, bool useLinear) {
    if (!useLinear) return (a * alpha + b * (1 - alpha)).round();
    final v = linear(a) * alpha + linear(b) * (1 - alpha);
    return (255 *
            (v <= .0031308 ? v * 12.92 : 1.055 * math.pow(v, 1 / 2.4) - .055))
        .round();
  }

  for (var y = 0; y < 28; y++) {
    for (var x = 0; x < 24; x++) {
      final inside = y >= 5 && y <= 20;
      final solid =
          inside && (x == 5 || x == 11 || y == 12 && x >= 5 && x <= 11);
      final edge = inside && (x == 4 || x == 6 || x == 10 || x == 12);
      final alpha = solid || extra && x >= 19 && x <= 21 && inside
          ? 1.0
          : edge
          ? .35
          : 0.0;
      final useLinear = space == 'linear' || space == 'mixed' && y.isEven;
      final channels = [
        for (final shift in [16, 8, 0])
          blend(foreground >> shift & 255, bg >> shift & 255, alpha, useLinear),
      ];
      result.setPixelRgba(x, y, channels[0], channels[1], channels[2], 255);
    }
  }
  return result;
}

GoldenInkRasterEvidence? evidence(image.Image actual) =>
    GoldenInkRasterEvidence.compare(
      rect: const GoldenRect(0, 0, 24, 28),
      foregroundColor: 0xff5620ba,
      reference: GoldenRgbImage.fromImage(glyph('linear')),
      actual: GoldenRgbImage.fromImage(actual),
      logicalWidth: 24,
      horizontalRadius: 2,
      verticalRadius: 1,
    );

void main() {
  test('same colored glyph has evidence across the two sRGB blend spaces', () {
    expect(evidence(glyph('encoded')), isNotNull);
  });
  test('does not choose a different blend space for each pixel', () {
    expect(evidence(glyph('mixed')), isNull);
  });
  test('wrong foreground is still rejected', () {
    expect(evidence(glyph('encoded', foreground: 0x008833)), isNull);
  });
  test('additional ink is still rejected', () {
    expect(evidence(glyph('encoded', extra: true)), isNull);
  });
}

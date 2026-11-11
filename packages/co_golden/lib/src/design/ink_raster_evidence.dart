import 'dart:math' as math;
import 'dart:typed_data';

import 'geometry.dart';
import 'color.dart';
import 'pixel_diff.dart';

/// Verified bidirectional coverage of the same solid painted shape.
/// Callers must first verify content, style, color, size and opacity.
final class GoldenInkRasterEvidence {
  const GoldenInkRasterEvidence._(this.coverage, this.massRatio);

  /// Smaller bidirectional supported ink-mass fraction, excluding faint noise.
  final double coverage;

  /// Rendered ink mass divided by the reference ink mass.
  final double massRatio;

  /// Measures shape support without changing raw differences or their verdict.
  static GoldenInkRasterEvidence? compare({
    required GoldenRect rect,
    required int foregroundColor,
    required GoldenRgbImage reference,
    required GoldenRgbImage actual,
    required double logicalWidth,
    required double horizontalRadius,
    required double verticalRadius,
    double minMassRatio = 0.75,
    double maxMassRatio = 1.34,
    double backgroundDeltaE = 0,
  }) {
    final scale = reference.width / logicalWidth;
    if (reference.width != actual.width ||
        reference.height != actual.height ||
        logicalWidth <= 0 ||
        foregroundColor >> 24 != 255) {
      return null;
    }
    final bounds = rect.inflate(horizontalRadius, verticalRadius);
    final x0 = (bounds.left * scale).floor().clamp(0, reference.width);
    final y0 = (bounds.top * scale).floor().clamp(0, reference.height);
    final x1 = (bounds.right * scale).ceil().clamp(0, reference.width);
    final y1 = (bounds.bottom * scale).ceil().clamp(0, reference.height);
    final w = x1 - x0;
    final h = y1 - y0;
    if (w <= 0 || h <= 0) return null;
    int pixel(GoldenRgbImage img, int x, int y) {
      final at = (y * img.width + x) * 3;
      return img.rgb[at] << 16 | img.rgb[at + 1] << 8 | img.rgb[at + 2];
    }

    (int, int) mode(GoldenRgbImage img) {
      final histogram = <int, int>{};
      for (var y = y0; y < y1; y++) {
        for (var x = x0; x < x1; x++) {
          final c = pixel(img, x, y);
          histogram[c] = (histogram[c] ?? 0) + 1;
        }
      }
      final best = histogram.entries.reduce(
        (a, b) => a.value >= b.value ? a : b,
      );
      return (best.key, best.value);
    }

    final bg = mode(reference);
    final otherBg = mode(actual);
    if (math.min(bg.$2, otherBg.$2) < w * h / 4 ||
        (bg.$1 != otherBg.$1 &&
            GoldenColorMath.ciede2000(
                  GoldenColorMath.rgbToLab(bg.$1),
                  GoldenColorMath.rgbToLab(otherBg.$1),
                ) >
                backgroundDeltaE)) {
      return null;
    }
    final fg = foregroundColor & 0xffffff;
    double channel(int value, bool linear) {
      if (!linear) return value.toDouble();
      final v = value / 255;
      return (255 *
              (v <= 0.04045 ? v / 12.92 : math.pow((v + .055) / 1.055, 2.4)))
          .toDouble();
    }

    double encoded(double value, bool linear) {
      if (!linear) return value;
      final v = value.clamp(0, 255) / 255;
      return 255 *
          (v <= 0.0031308 ? v * 12.92 : 1.055 * math.pow(v, 1 / 2.4) - .055);
    }

    (Uint8List, double, int, int)? ink(
      GoldenRgbImage img,
      int bgColor,
      bool linear,
    ) {
      final background = [
        channel(bgColor >> 16 & 255, linear),
        channel(bgColor >> 8 & 255, linear),
        channel(bgColor & 255, linear),
      ];
      final vector = [
        channel(fg >> 16 & 255, linear) - background[0],
        channel(fg >> 8 & 255, linear) - background[1],
        channel(fg & 255, linear) - background[2],
      ];
      final norm = vector.fold<double>(0, (sum, v) => sum + v * v);
      if (norm < 1200) return null;
      final mask = Uint8List(w * h);
      var mass = 0.0;
      var count = 0;
      var inkPixels = 0;
      var foreign = 0;
      for (var y = y0; y < y1; y++) {
        for (var x = x0; x < x1; x++) {
          final rgb = pixel(img, x, y);
          final channels = [rgb >> 16 & 255, rgb >> 8 & 255, rgb & 255];
          var alpha = 0.0;
          for (var c = 0; c < 3; c++) {
            alpha +=
                (channel(channels[c], linear) - background[c]) *
                vector[c] /
                norm;
          }
          var residual = 0.0;
          for (var c = 0; c < 3; c++) {
            residual = math.max(
              residual,
              (channels[c] - encoded(background[c] + alpha * vector[c], linear))
                  .abs(),
            );
          }
          if (alpha < -0.02 || alpha > 1.02 || residual > 2) foreign++;
          alpha = alpha.clamp(0, 1);
          mass += alpha;
          if (alpha > 0.1) {
            final weight = (alpha * 255).round();
            mask[(y - y0) * w + x - x0] = weight;
            count += weight;
            inkPixels++;
          }
        }
      }
      if (inkPixels < 4) return null;
      return (mask, mass, count, foreign);
    }

    (Uint8List, double, int, int)? bestInk(GoldenRgbImage img, int bgColor) {
      // Choose one interpolation space for the entire glyph, never one per
      // pixel. Both encoded-sRGB and linear-sRGB alpha blending are used by
      // renderers. The original 2 RGB palette residual still applies.
      final candidates = [
        ink(img, bgColor, false),
        ink(img, bgColor, true),
      ].whereType<(Uint8List, double, int, int)>().toList();
      if (candidates.isEmpty) return null;
      var best = candidates.first;
      for (final candidate in candidates.skip(1)) {
        if (candidate.$4 < best.$4) best = candidate;
      }
      return best.$4 <= w * h * .005 ? best : null;
    }

    final a = bestInk(reference, bg.$1);
    final b = bestInk(actual, otherBg.$1);
    if (a == null || b == null || a.$2 == 0) return null;
    final massRatio = b.$2 / a.$2;
    if (massRatio < minMassRatio || massRatio > maxMassRatio) return null;
    final rx = (horizontalRadius * scale).ceil();
    final ry = (verticalRadius * scale).ceil();
    double support(Uint8List from, Uint8List to, int count) {
      var supported = 0;
      for (var y = 0; y < h; y++) {
        for (var x = 0; x < w; x++) {
          if (from[y * w + x] == 0) continue;
          var found = false;
          for (
            var yy = math.max(0, y - ry);
            yy <= math.min(h - 1, y + ry) && !found;
            yy++
          ) {
            for (
              var xx = math.max(0, x - rx);
              xx <= math.min(w - 1, x + rx);
              xx++
            ) {
              if (to[yy * w + xx] != 0) {
                found = true;
                break;
              }
            }
          }
          if (found) supported += from[y * w + x];
        }
      }
      return supported / count;
    }

    final coverage = math.min(
      support(a.$1, b.$1, a.$3),
      support(b.$1, a.$1, b.$3),
    );
    return coverage >= 0.995
        ? GoldenInkRasterEvidence._(coverage, massRatio)
        : null;
  }
}

import 'dart:math' as math;

/// Color math shared by the tolerant pixel comparison and the structural
/// design comparison.
///
/// The formulas follow `figma_compare.py` of the `visual-verify` skill, so a
/// design difference measured here and one measured by that script use the
/// same CIEDE2000 numbers.
abstract final class GoldenColorMath {
  static final List<double> _linear = List.unmodifiable([
    for (var c = 0; c < 256; c++)
      c / 255 <= 0.04045
          ? (c / 255) / 12.92
          : math.pow(((c / 255) + 0.055) / 1.055, 2.4).toDouble(),
  ]);

  static const double _epsilon = (6 / 29) * (6 / 29) * (6 / 29);

  static double _f(double t) => t > _epsilon
      ? math.pow(t, 1 / 3).toDouble()
      : t / (3 * (6 / 29) * (6 / 29)) + 4 / 29;

  /// CIE L*a*b* (D65) of a packed `0xRRGGBB` color.
  static (double, double, double) rgbToLab(int rgb) {
    final r = _linear[(rgb >> 16) & 255];
    final g = _linear[(rgb >> 8) & 255];
    final b = _linear[rgb & 255];
    final x = (0.4124564 * r + 0.3575761 * g + 0.1804375 * b) / 0.95047;
    final y = 0.2126729 * r + 0.7151522 * g + 0.0721750 * b;
    final z = (0.0193339 * r + 0.1191920 * g + 0.9503041 * b) / 1.08883;
    final fx = _f(x);
    final fy = _f(y);
    final fz = _f(z);
    return (116 * fy - 16, 500 * (fx - fy), 200 * (fy - fz));
  }

  static double _degrees(double radians) => radians * 180 / math.pi;
  static double _radians(double degrees) => degrees * math.pi / 180;
  static double _hypot(double a, double b) => math.sqrt(a * a + b * b);
  static double _mod360(double value) {
    final result = value % 360;
    return result < 0 ? result + 360 : result;
  }

  /// CIEDE2000 color difference (Sharma, kL = kC = kH = 1).
  static double ciede2000(
    (double, double, double) lab1,
    (double, double, double) lab2,
  ) {
    final (l1, a1, b1) = lab1;
    final (l2, a2, b2) = lab2;
    final c1 = _hypot(a1, b1);
    final c2 = _hypot(a2, b2);
    final cBar7 = math.pow((c1 + c2) / 2, 7).toDouble();
    final g = 0.5 * (1 - math.sqrt(cBar7 / (cBar7 + math.pow(25, 7))));
    final a1p = (1 + g) * a1;
    final a2p = (1 + g) * a2;
    final c1p = _hypot(a1p, b1);
    final c2p = _hypot(a2p, b2);
    final h1p = (b1 == 0 && a1p == 0)
        ? 0.0
        : _mod360(_degrees(math.atan2(b1, a1p)));
    final h2p = (b2 == 0 && a2p == 0)
        ? 0.0
        : _mod360(_degrees(math.atan2(b2, a2p)));
    final dlp = l2 - l1;
    final dcp = c2p - c1p;
    var dhp = 0.0;
    if (c1p * c2p != 0) {
      dhp = h2p - h1p;
      if (dhp > 180) {
        dhp -= 360;
      } else if (dhp < -180) {
        dhp += 360;
      }
    }
    final dhpBig = 2 * math.sqrt(c1p * c2p) * math.sin(_radians(dhp / 2));
    final lBarP = (l1 + l2) / 2;
    final cBarP = (c1p + c2p) / 2;
    final double hBarP;
    if (c1p * c2p == 0) {
      hBarP = h1p + h2p;
    } else if ((h1p - h2p).abs() <= 180) {
      hBarP = (h1p + h2p) / 2;
    } else if (h1p + h2p < 360) {
      hBarP = (h1p + h2p + 360) / 2;
    } else {
      hBarP = (h1p + h2p - 360) / 2;
    }
    final t =
        1 -
        0.17 * math.cos(_radians(hBarP - 30)) +
        0.24 * math.cos(_radians(2 * hBarP)) +
        0.32 * math.cos(_radians(3 * hBarP + 6)) -
        0.20 * math.cos(_radians(4 * hBarP - 63));
    final dTheta = 30 * math.exp(-math.pow((hBarP - 275) / 25, 2));
    final cBarP7 = math.pow(cBarP, 7).toDouble();
    final rc = 2 * math.sqrt(cBarP7 / (cBarP7 + math.pow(25, 7)));
    final sl =
        1 +
        (0.015 * math.pow(lBarP - 50, 2)) /
            math.sqrt(20 + math.pow(lBarP - 50, 2));
    final sc = 1 + 0.045 * cBarP;
    final sh = 1 + 0.015 * cBarP * t;
    final rt = -math.sin(_radians(2 * dTheta)) * rc;
    final dl = dlp / sl;
    final dc = dcp / sc;
    final dh = dhpBig / sh;
    return math.sqrt(dl * dl + dc * dc + dh * dh + rt * dc * dh);
  }

  /// CIEDE2000 between two packed `0xRRGGBB` colors.
  static double deltaE(int rgb1, int rgb2) =>
      rgb1 == rgb2 ? 0 : ciede2000(rgbToLab(rgb1), rgbToLab(rgb2));

  /// Perceived brightness used by the anti-aliasing check (pixelmatch).
  static double luma(int rgb) =>
      0.29889531 * ((rgb >> 16) & 255) +
      0.58662247 * ((rgb >> 8) & 255) +
      0.11448223 * (rgb & 255);

  /// `#RRGGBB` of a packed color.
  static String hex(int rgb) =>
      '#${(rgb & 0xffffff).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  /// `#RRGGBBAA` of a packed `0xAARRGGBB` color, or `#RRGGBB` when opaque.
  static String hexArgb(int argb) {
    final alpha = (argb >> 24) & 255;
    final rgb = hex(argb);
    return alpha == 255
        ? rgb
        : '$rgb${alpha.toRadixString(16).padLeft(2, '0').toUpperCase()}';
  }

  /// Parses `#RGB`, `#RRGGBB`, or `#RRGGBBAA` into `0xAARRGGBB`.
  static int? parseHex(String value) {
    var text = value.trim();
    if (text.startsWith('#')) text = text.substring(1);
    if (text.length == 3) {
      text = text.split('').map((c) => '$c$c').join();
    }
    if (text.length == 6) text = '${text}ff';
    if (text.length != 8) return null;
    final parsed = int.tryParse(text, radix: 16);
    if (parsed == null) return null;
    final rgb = parsed >> 8;
    final alpha = parsed & 255;
    return (alpha << 24) | rgb;
  }

  /// Composites a packed `0xAARRGGBB` color over an opaque [backdrop]
  /// `0xRRGGBB` with the rounding of `figma_compare.py`.
  static int over(int argb, int backdrop) {
    final a = (argb >> 24) & 255;
    if (a == 255) return argb & 0xffffff;
    int channel(int shift) {
      final c = (argb >> shift) & 255;
      final bg = (backdrop >> shift) & 255;
      return (c * a + bg * (255 - a) + 127) ~/ 255;
    }

    return (channel(16) << 16) | (channel(8) << 8) | channel(0);
  }
}

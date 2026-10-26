// The anti-aliased pixel check (_antialiased, _manySiblings) is adapted from
// pixelmatch (https://github.com/mapbox/pixelmatch), which implements
// V. Vysniauskas, "Anti-aliased Pixel and Intensity Slope Detector" (2009).
// See THIRD_PARTY_LICENSES at the repository root.
//
// ISC License
//
// Copyright (c) 2025, Mapbox
//
// Permission to use, copy, modify, and/or distribute this software for any
// purpose with or without fee is hereby granted, provided that the above
// copyright notice and this permission notice appear in all copies.
//
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
// WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
// MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
// SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
// WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION
// OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN
// CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as image;

import 'color.dart';
import 'geometry.dart';
import 'tolerance.dart';

/// Neutral backdrop for transparent pixels, as in `figma_compare.py`.
const int goldenPixelBackdrop = 0x808080;

const double _cellLogical = 4;

/// Pixel states of a tolerant comparison.
abstract final class GoldenPixelState {
  /// Equal within tolerance.
  static const int same = 0;

  /// Different beyond tolerance.
  static const int different = 1;

  /// Anti-aliased edge pixel; not counted.
  static const int antialiased = 2;

  /// Masked; not compared.
  static const int masked = 3;
}

/// Why a tolerant pixel comparison could not decide.
final class GoldenPixelUndetermined implements Exception {
  /// Creates the reason.
  const GoldenPixelUndetermined(this.reason, this.detail);

  /// Machine-readable reason: `size-mismatch` or `over-masked`.
  final String reason;

  /// Human explanation.
  final String detail;

  @override
  String toString() => 'GoldenPixelUndetermined($reason: $detail)';
}

/// Opaque RGB pixels: transparent pixels are composited over
/// [goldenPixelBackdrop], exactly like `figma_compare.py`.
final class GoldenRgbImage {
  GoldenRgbImage._(this.width, this.height, this.rgb, this.transparentPixels);

  /// Converts a decoded image.
  factory GoldenRgbImage.fromImage(image.Image source) {
    final converted =
        source.format == image.Format.uint8 &&
            source.numChannels == 4 &&
            !source.hasPalette
        ? source
        : source.convert(format: image.Format.uint8, numChannels: 4);
    final width = converted.width;
    final height = converted.height;
    final bytes = converted.getBytes(order: image.ChannelOrder.rgba);
    final rgb = Uint8List(width * height * 3);
    var clear = 0;
    for (var i = 0, o = 0; o < rgb.length; i += 4, o += 3) {
      final a = bytes[i + 3];
      var r = bytes[i];
      var g = bytes[i + 1];
      var b = bytes[i + 2];
      if (a != 255) {
        clear++;
        r = (r * a + 128 * (255 - a) + 127) ~/ 255;
        g = (g * a + 128 * (255 - a) + 127) ~/ 255;
        b = (b * a + 128 * (255 - a) + 127) ~/ 255;
      }
      rgb[o] = r;
      rgb[o + 1] = g;
      rgb[o + 2] = b;
    }
    return GoldenRgbImage._(width, height, rgb, clear);
  }

  /// Width in pixels.
  final int width;

  /// Height in pixels.
  final int height;

  /// Row-major RGB bytes.
  final Uint8List rgb;

  /// Pixels that were not fully opaque before compositing.
  final int transparentPixels;

  /// Packed `0xRRGGBB` at ([x], [y]).
  int pixel(int x, int y) {
    final i = (y * width + x) * 3;
    return (rgb[i] << 16) | (rgb[i + 1] << 8) | rgb[i + 2];
  }

  /// Box average by the integer factor [k] — never interpolated.
  GoldenRgbImage downscale(int k) {
    if (width % k != 0 || height % k != 0) {
      throw GoldenPixelUndetermined(
        'size-mismatch',
        '$width×$height is not divisible by $k',
      );
    }
    final nw = width ~/ k;
    final nh = height ~/ k;
    final kk = k * k;
    final out = Uint8List(nw * nh * 3);
    for (var oy = 0; oy < nh; oy++) {
      for (var ox = 0; ox < nw; ox++) {
        var sr = 0;
        var sg = 0;
        var sb = 0;
        for (var dy = 0; dy < k; dy++) {
          final base = ((oy * k + dy) * width + ox * k) * 3;
          for (var dx = 0; dx < k; dx++) {
            final i = base + 3 * dx;
            sr += rgb[i];
            sg += rgb[i + 1];
            sb += rgb[i + 2];
          }
        }
        final o = (oy * nw + ox) * 3;
        out[o] = (sr + kk ~/ 2) ~/ kk;
        out[o + 1] = (sg + kk ~/ 2) ~/ kk;
        out[o + 2] = (sb + kk ~/ 2) ~/ kk;
      }
    }
    return GoldenRgbImage._(nw, nh, out, 0);
  }
}

/// A connected group of differing pixels.
final class GoldenPixelRegion {
  /// Creates a region.
  const GoldenPixelRegion({
    required this.bounds,
    required this.pixels,
    required this.logicalPixels,
    required this.referenceColor,
    required this.renderColor,
    required this.meanDeltaE,
  });

  /// Tight bounds of the differing pixels in logical pixels.
  final GoldenRect bounds;

  /// Differing pixels at the compared resolution.
  final int pixels;

  /// [pixels] in logical px².
  final double logicalPixels;

  /// Mean design color of the differing pixels, `0xRRGGBB`.
  final int referenceColor;

  /// Mean implementation color of the differing pixels, `0xRRGGBB`.
  final int renderColor;

  /// Mean CIEDE2000 of the differing pixels.
  final double meanDeltaE;
}

/// Result of a tolerant pixel comparison.
final class GoldenPixelDiff {
  GoldenPixelDiff._({
    required this.width,
    required this.height,
    required this.scale,
    required this.state,
    required this.differentPixels,
    required this.antialiasedPixels,
    required this.maskedPixels,
    required this.regions,
    required this.notes,
    required this.transparentReferencePixels,
    required this.transparentRenderPixels,
    required this.textBoxCount,
  });

  /// Compared width in pixels (the design export's width).
  final int width;

  /// Compared height in pixels.
  final int height;

  /// Compared pixels per logical pixel.
  final double scale;

  /// [GoldenPixelState] of every pixel.
  final Uint8List state;

  /// Pixels that differ beyond tolerance.
  final int differentPixels;

  /// Anti-aliased pixels left out of the count.
  final int antialiasedPixels;

  /// Pixels inside masks.
  final int maskedPixels;

  /// Regions, largest first.
  final List<GoldenPixelRegion> regions;

  /// Notes such as a box-average downscale of the render.
  final List<String> notes;

  /// Non-opaque pixels of the design export.
  final int transparentReferencePixels;

  /// Non-opaque pixels of the render.
  final int transparentRenderPixels;

  /// Number of text boxes that used the text tolerances.
  final int textBoxCount;

  /// Pixels that were compared.
  int get comparablePixels => width * height - maskedPixels;

  /// Differing fraction of the comparable pixels.
  double get ratio =>
      comparablePixels == 0 ? 1 : differentPixels / comparablePixels;

  /// Largest region in logical px².
  double get largestRegion =>
      regions.fold(0, (largest, r) => math.max(largest, r.logicalPixels));

  /// Masked fraction of the frame.
  double get maskedRatio =>
      width * height == 0 ? 0 : maskedPixels / (width * height);

  /// Whether the result is within [tolerance]'s budget.
  bool withinBudget(GoldenDesignTolerance tolerance) =>
      ratio <= tolerance.budgetRatio && largestRegion <= tolerance.budgetRegion;

  /// Same-size map: red differences, yellow anti-aliasing, blue masks, and
  /// the design in faint gray for context.
  image.Image diffMap(GoldenRgbImage reference) {
    final out = image.Image(width: width, height: height);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final s = state[y * width + x];
        if (s == GoldenPixelState.different) {
          out.setPixelRgb(x, y, 230, 20, 20);
        } else if (s == GoldenPixelState.antialiased) {
          out.setPixelRgb(x, y, 240, 190, 0);
        } else {
          final lum = GoldenColorMath.luma(reference.pixel(x, y)).toInt();
          final v = 255 - (255 - lum) ~/ 4;
          if (s == GoldenPixelState.same) {
            out.setPixelRgb(x, y, v, v, v);
          } else {
            out.setPixelRgb(
              x,
              y,
              (v + 80) ~/ 2,
              (v + 120) ~/ 2,
              (v + 255) ~/ 2,
            );
          }
        }
      }
    }
    return out;
  }
}

/// Compares a design export with a render at the export's resolution.
///
/// [logicalWidth] is the logical width of the frame both images show. A render
/// that is an exact integer multiple (≥ 2) of the export is box-averaged down;
/// any other size difference throws [GoldenPixelUndetermined]. [masks] and
/// [textBoxes] are logical rectangles. A pixel differs when (1) its CIEDE2000
/// exceeds the tolerance, (2) no matching color exists within the positional
/// radius in the other image, in both directions, and (3) it is not an
/// anti-aliased edge — the rules of `figma_compare.py`.
GoldenPixelDiff compareDesignPixels({
  required GoldenRgbImage reference,
  required GoldenRgbImage render,
  required double logicalWidth,
  required GoldenDesignTolerance tolerance,
  List<GoldenRect> masks = const [],
  List<GoldenRect> textBoxes = const [],
}) {
  final notes = <String>[];
  var compared = render;
  if (render.width != reference.width || render.height != reference.height) {
    final k = reference.width == 0 ? 0 : render.width ~/ reference.width;
    if (k >= 2 &&
        render.width == reference.width * k &&
        render.height == reference.height * k) {
      compared = render.downscale(k);
      notes.add('렌더를 1/$k 로 상자 평균했다');
    } else {
      throw GoldenPixelUndetermined(
        'size-mismatch',
        '구현 ${render.width}×${render.height} ≠ 디자인 '
            '${reference.width}×${reference.height} — 같은 배율로 내보낸다',
      );
    }
  }
  final width = reference.width;
  final height = reference.height;
  final scale = width / logicalWidth;
  final total = width * height;
  final mask = _maskBits(width, height, scale, masks);
  var masked = 0;
  for (final bit in mask) {
    masked += bit;
  }
  if (total > 0 && masked / total > tolerance.maxMaskRatio) {
    throw GoldenPixelUndetermined(
      'over-masked',
      '가린 넓이 ${(masked / total * 100).toStringAsFixed(1)}% > 상한 '
          '${(tolerance.maxMaskRatio * 100).toStringAsFixed(0)}% — 가리지 말고 비교한다',
    );
  }
  final textMask = textBoxes.isEmpty
      ? null
      : _maskBits(
          width,
          height,
          scale,
          textBoxes,
          padX: tolerance.textPixel,
          padY: tolerance.pixel,
        );
  final comparator = _Comparator(
    reference.rgb,
    compared.rgb,
    width,
    height,
    scale,
    tolerance,
    textMask,
  );
  final (state, diff, aa) = comparator.run(mask);
  return GoldenPixelDiff._(
    width: width,
    height: height,
    scale: scale,
    state: state,
    differentPixels: diff,
    antialiasedPixels: aa,
    maskedPixels: masked,
    regions: comparator.regions(state),
    notes: notes,
    transparentReferencePixels: reference.transparentPixels,
    transparentRenderPixels: render.transparentPixels,
    textBoxCount: textBoxes.length,
  );
}

Uint8List _maskBits(
  int width,
  int height,
  double scale,
  List<GoldenRect> rects, {
  double padX = 0,
  double padY = 0,
}) {
  final mask = Uint8List(width * height);
  for (final rect in rects) {
    final x0 = math.max(0, ((rect.left - padX) * scale).floor());
    final y0 = math.max(0, ((rect.top - padY) * scale).floor());
    final x1 = math.min(width, ((rect.right + padX) * scale).ceil());
    final y1 = math.min(height, ((rect.bottom + padY) * scale).ceil());
    for (var y = y0; y < y1; y++) {
      if (x1 > x0) mask.fillRange(y * width + x0, y * width + x1, 1);
    }
  }
  return mask;
}

final class _Comparator {
  _Comparator(
    this.a,
    this.b,
    this.w,
    this.h,
    this.scale,
    GoldenDesignTolerance tolerance,
    this.textMask,
  ) : t = tolerance.colorDeltaE,
      r = math.max(0, (tolerance.pixel * scale - 1e-9).ceil()),
      rxText = math.max(
        math.max(0, (tolerance.pixel * scale - 1e-9).ceil()),
        (tolerance.textPixel * scale - 1e-9).ceil(),
      ),
      tText = math.max(tolerance.colorDeltaE, tolerance.textDeltaE),
      antialias = tolerance.antialias;

  final Uint8List a;
  final Uint8List b;
  final int w;
  final int h;
  final double scale;
  final double t;
  final int r;
  final int rxText;
  final double tText;
  final bool antialias;
  final Uint8List? textMask;
  final Map<int, (double, double, double)> _lab = {};
  final Map<int, double> _de = {};

  double de(int c1, int c2) {
    if (c1 == c2) return 0;
    final key = c1 < c2 ? (c1 << 24) | c2 : (c2 << 24) | c1;
    return _de[key] ??= GoldenColorMath.ciede2000(
      _lab[c1] ??= GoldenColorMath.rgbToLab(c1),
      _lab[c2] ??= GoldenColorMath.rgbToLab(c2),
    );
  }

  int px(Uint8List img, int x, int y) {
    final i = (y * w + x) * 3;
    return (img[i] << 16) | (img[i + 1] << 8) | img[i + 2];
  }

  bool _near(int c, Uint8List img, int x, int y, int rx, int ry, double t) {
    if (x < rx || y < ry || x >= w - rx || y >= h - ry) {
      // Outside the frame is unknown: an element touching the edge may be
      // shorter or longer by the tolerance, so the edge band is not counted.
      return true;
    }
    for (var yy = y - ry; yy <= y + ry; yy++) {
      final base = yy * w;
      for (var xx = x - rx; xx <= x + rx; xx++) {
        final i = (base + xx) * 3;
        final q = (img[i] << 16) | (img[i + 1] << 8) | img[i + 2];
        if (q == c || de(c, q) <= t) return true;
      }
    }
    return false;
  }

  bool _manySiblings(Uint8List img, int x, int y) {
    final c = px(img, x, y);
    var zeroes = (x == 0 || x == w - 1 || y == 0 || y == h - 1) ? 1 : 0;
    for (var yy = math.max(0, y - 1); yy < math.min(h, y + 2); yy++) {
      for (var xx = math.max(0, x - 1); xx < math.min(w, x + 2); xx++) {
        if ((xx != x || yy != y) && px(img, xx, yy) == c) {
          zeroes++;
          if (zeroes > 2) return true;
        }
      }
    }
    return false;
  }

  bool _antialiased(Uint8List img, int x, int y, Uint8List other) {
    final center = GoldenColorMath.luma(px(img, x, y));
    var zeroes = (x == 0 || x == w - 1 || y == 0 || y == h - 1) ? 1 : 0;
    var lo = 0.0;
    var hi = 0.0;
    int? loX;
    int? loY;
    int? hiX;
    int? hiY;
    for (var yy = math.max(0, y - 1); yy < math.min(h, y + 2); yy++) {
      for (var xx = math.max(0, x - 1); xx < math.min(w, x + 2); xx++) {
        if (xx == x && yy == y) continue;
        final delta = center - GoldenColorMath.luma(px(img, xx, yy));
        if (delta == 0) {
          zeroes++;
          if (zeroes > 2) return false;
        } else if (delta < lo) {
          lo = delta;
          loX = xx;
          loY = yy;
        } else if (delta > hi) {
          hi = delta;
          hiX = xx;
          hiY = yy;
        }
      }
    }
    if (loX == null || hiX == null) return false;
    return (_manySiblings(img, loX, loY!) && _manySiblings(other, loX, loY)) ||
        (_manySiblings(img, hiX, hiY!) && _manySiblings(other, hiX, hiY));
  }

  (Uint8List, int, int) run(Uint8List mask) {
    final state = Uint8List(w * h);
    var diff = 0;
    var aa = 0;
    final row = w * 3;
    for (var y = 0; y < h; y++) {
      final o = y * row;
      var sameRow = true;
      for (var i = o; i < o + row; i++) {
        if (a[i] != b[i]) {
          sameRow = false;
          break;
        }
      }
      if (sameRow) {
        for (var x = 0; x < w; x++) {
          if (mask[y * w + x] != 0) state[y * w + x] = GoldenPixelState.masked;
        }
        continue;
      }
      for (var x = 0; x < w; x++) {
        final p = y * w + x;
        if (mask[p] != 0) {
          state[p] = GoldenPixelState.masked;
          continue;
        }
        final i = o + 3 * x;
        final ca = (a[i] << 16) | (a[i + 1] << 8) | a[i + 2];
        final cb = (b[i] << 16) | (b[i + 1] << 8) | b[i + 2];
        final inText = textMask != null && textMask![p] != 0;
        final tt = inText ? tText : t;
        if (ca == cb || de(ca, cb) <= tt) continue;
        final rx = inText ? rxText : r;
        if ((rx != 0 || r != 0) &&
            _near(ca, b, x, y, rx, r, tt) &&
            _near(cb, a, x, y, rx, r, tt)) {
          continue;
        }
        if (antialias &&
            (_antialiased(a, x, y, b) || _antialiased(b, x, y, a))) {
          state[p] = GoldenPixelState.antialiased;
          aa++;
          continue;
        }
        state[p] = GoldenPixelState.different;
        diff++;
      }
    }
    return (state, diff, aa);
  }

  List<GoldenPixelRegion> regions(Uint8List state) {
    final cs = math.max(1, (_cellLogical * scale).round());
    final gw = (w + cs - 1) ~/ cs;
    final gh = (h + cs - 1) ~/ cs;
    final cells = <int, _Cell>{};
    for (var p = 0; p < state.length; p++) {
      if (state[p] != GoldenPixelState.different) continue;
      final y = p ~/ w;
      final x = p % w;
      final key = (y ~/ cs) * gw + (x ~/ cs);
      final cell = cells[key] ??= _Cell(x, y);
      final ca = px(a, x, y);
      final cb = px(b, x, y);
      cell.add(x, y, ca, cb, de(ca, cb));
    }
    final seen = <int>{};
    final regions = <GoldenPixelRegion>[];
    final keys = cells.keys.toList()..sort();
    for (final start in keys) {
      if (!seen.add(start)) continue;
      final stack = [start];
      final members = <int>[];
      while (stack.isNotEmpty) {
        final k = stack.removeLast();
        members.add(k);
        final cy = k ~/ gw;
        final cx = k % gw;
        for (var dy = -1; dy <= 1; dy++) {
          for (var dx = -1; dx <= 1; dx++) {
            final ny = cy + dy;
            final nx = cx + dx;
            if (ny < 0 || ny >= gh || nx < 0 || nx >= gw) continue;
            final nk = ny * gw + nx;
            if (cells.containsKey(nk) && seen.add(nk)) stack.add(nk);
          }
        }
      }
      final total = _Cell(0, 0)..count = 0;
      int? x0;
      int? y0;
      var x1 = 0;
      var y1 = 0;
      for (final k in members) {
        final cell = cells[k]!;
        total.merge(cell);
        x0 = x0 == null ? cell.minX : math.min(x0, cell.minX);
        y0 = y0 == null ? cell.minY : math.min(y0, cell.minY);
        x1 = math.max(x1, cell.maxX + 1);
        y1 = math.max(y1, cell.maxY + 1);
      }
      final n = total.count;
      int mean(int sum) => (sum / n).round();
      regions.add(
        GoldenPixelRegion(
          bounds: GoldenRect(
            goldenRound(x0! / scale, 1),
            goldenRound(y0! / scale, 1),
            goldenRound((x1 - x0) / scale, 1),
            goldenRound((y1 - y0) / scale, 1),
          ),
          pixels: n,
          logicalPixels: goldenRound(n / (scale * scale)),
          referenceColor:
              (mean(total.ar) << 16) | (mean(total.ag) << 8) | mean(total.ab),
          renderColor:
              (mean(total.br) << 16) | (mean(total.bg) << 8) | mean(total.bb),
          meanDeltaE: goldenRound(total.deltaE / n),
        ),
      );
    }
    regions.sort((x, y) {
      final byPixels = y.pixels.compareTo(x.pixels);
      if (byPixels != 0) return byPixels;
      final byTop = x.bounds.top.compareTo(y.bounds.top);
      return byTop != 0 ? byTop : x.bounds.left.compareTo(y.bounds.left);
    });
    return regions;
  }
}

final class _Cell {
  _Cell(this.minX, this.minY) : maxX = minX, maxY = minY;

  int count = 0;
  int ar = 0;
  int ag = 0;
  int ab = 0;
  int br = 0;
  int bg = 0;
  int bb = 0;
  double deltaE = 0;
  int minX;
  int minY;
  int maxX;
  int maxY;

  void add(int x, int y, int ca, int cb, double de) {
    if (x < minX) minX = x;
    if (x > maxX) maxX = x;
    maxY = y;
    count++;
    ar += (ca >> 16) & 255;
    ag += (ca >> 8) & 255;
    ab += ca & 255;
    br += (cb >> 16) & 255;
    bg += (cb >> 8) & 255;
    bb += cb & 255;
    deltaE += de;
  }

  void merge(_Cell other) {
    count += other.count;
    ar += other.ar;
    ag += other.ag;
    ab += other.ab;
    br += other.br;
    bg += other.bg;
    bb += other.bb;
    deltaE += other.deltaE;
  }
}

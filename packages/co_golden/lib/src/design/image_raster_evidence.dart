import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as image;
import 'package:path/path.dart' as p;

import 'color.dart';
import 'package_map.dart';
import 'pixel_diff.dart';
import 'render_node.dart';
import 'spec.dart';
import 'tolerance.dart';

/// Source-verified texture sampling evidence, never an acceptance override.
final class GoldenImageRasterEvidence {
  const GoldenImageRasterEvidence._(this.coverage, this.meanDeltaE);

  /// Fraction of low-frequency samples within the existing color tolerance.
  final double coverage;

  /// Mean CIEDE2000 distance after a 3x3 low-pass comparison.
  final double meanDeltaE;

  /// Requires identical source bytes and verified fit, alignment, clipping,
  /// size, opacity, decoding and transforms before considering sampling noise.
  static GoldenImageRasterEvidence? compare({
    required GoldenDesignNode design,
    required GoldenRenderNode render,
    required Uint8List sourceBytes,
    required GoldenRgbImage reference,
    required GoldenRgbImage actual,
    required double logicalWidth,
    required GoldenDesignTolerance tolerance,
  }) {
    final paint = design.fills.where((f) => f.type == 'IMAGE').firstOrNull;
    final digest = paint?.sourceDigest;
    final meta = render.imagePaint;
    final expectedRadii = design.cornerRadii;
    final actualRadii = meta['clipRadius'];
    final alignment = meta['alignment'];
    final visible = design.inkRect ?? design.rect;
    if (digest == null ||
        paint?.imageFit == null ||
        render.kind != GoldenRenderKind.image ||
        reference.width != actual.width ||
        reference.height != actual.height ||
        logicalWidth <= 0 ||
        design.opacity != 1 ||
        render.opacity != 1 ||
        meta['paintOpacity'] != 1 ||
        meta['verifiedGeometry'] != true ||
        meta['tinted'] != false ||
        meta['mirrored'] != false ||
        meta['repeat'] != 'noRepeat' ||
        meta['fit'] != paint!.imageFit ||
        alignment is! List ||
        alignment.length != 2 ||
        alignment.any((v) => v is! num || v.abs() > 0.000001) ||
        expectedRadii == null ||
        actualRadii is! List ||
        actualRadii.length != 4 ||
        (design.rect.left - render.rect.left).abs() > tolerance.position ||
        (design.rect.top - render.rect.top).abs() > tolerance.position ||
        (design.rect.width - render.rect.width).abs() > tolerance.size ||
        (design.rect.height - render.rect.height).abs() > tolerance.size ||
        (visible.left - render.visibleRect.left).abs() > tolerance.position ||
        (visible.top - render.visibleRect.top).abs() > tolerance.position ||
        (visible.width - render.visibleRect.width).abs() > tolerance.size ||
        (visible.height - render.visibleRect.height).abs() > tolerance.size) {
      return null;
    }
    for (var i = 0; i < 4; i++) {
      if (actualRadii[i] is! num ||
          (expectedRadii[i] - (actualRadii[i] as num)).abs() >
              tolerance.radius) {
        return null;
      }
    }
    final actualDigest = digest.startsWith('sha256:')
        ? 'sha256:${sha256.convert(sourceBytes)}'
        : digest.startsWith('sha1:')
        ? 'sha1:${sha1.convert(sourceBytes)}'
        : null;
    if (actualDigest != digest) return null;
    final decoded = image.decodeImage(sourceBytes);
    if (decoded == null ||
        decoded.width != meta['decodedWidth'] ||
        decoded.height != meta['decodedHeight']) {
      return null;
    }
    final radius = math.min(
      expectedRadii.reduce(math.max),
      math.min(design.rect.width, design.rect.height) / 2,
    );
    final padding = (radius * (1 - math.sqrt(0.5))).ceil() + 1;
    final scale = reference.width / logicalWidth;
    final rect = visible.intersect(render.visibleRect);
    if (rect == null) return null;
    final x0 = ((rect.left + padding) * scale).ceil().clamp(
      1,
      reference.width - 1,
    );
    final y0 = ((rect.top + padding) * scale).ceil().clamp(
      1,
      reference.height - 1,
    );
    final x1 = ((rect.right - padding) * scale).floor().clamp(
      1,
      reference.width - 1,
    );
    final y1 = ((rect.bottom - padding) * scale).floor().clamp(
      1,
      reference.height - 1,
    );
    if ((x1 - x0) * (y1 - y0) < 16 || x1 <= x0 || y1 <= y0) return null;
    int lowPass(GoldenRgbImage img, int x, int y) {
      final sums = [0, 0, 0];
      for (var dy = -1; dy <= 1; dy++) {
        for (var dx = -1; dx <= 1; dx++) {
          final at = ((y + dy) * img.width + x + dx) * 3;
          for (var c = 0; c < 3; c++) {
            sums[c] += img.rgb[at + c];
          }
        }
      }
      return (sums[0] / 9).round() << 16 |
          (sums[1] / 9).round() << 8 |
          (sums[2] / 9).round();
    }

    var outliers = 0;
    var count = 0;
    var sum = 0.0;
    for (var y = y0; y < y1; y++) {
      for (var x = x0; x < x1; x++) {
        final a = lowPass(reference, x, y), b = lowPass(actual, x, y);
        final delta = a == b
            ? 0.0
            : GoldenColorMath.ciede2000(
                GoldenColorMath.rgbToLab(a),
                GoldenColorMath.rgbToLab(b),
              );
        if (delta > tolerance.colorDeltaE) outliers++;
        sum += delta;
        count++;
      }
    }
    final coverage = 1 - outliers / count;
    final mean = sum / count;
    return coverage >= 0.995 && mean <= math.min(1, tolerance.colorDeltaE / 3)
        ? GoldenImageRasterEvidence._(coverage, mean)
        : null;
  }
}

/// Resolves only an observed asset key within its owning package's directory.
/// Network, memory and path-traversal descriptions provide no byte evidence.
Uint8List? goldenAssetImageBytes(
  String? description,
  GoldenPackageMap packages,
) {
  if (description == null || !description.startsWith('asset:')) return null;
  var key = description.substring(6);
  if (p.isAbsolute(key) || key.split('/').any((s) => s == '..' || s.isEmpty)) {
    return null;
  }
  var root = packages.workingDirectory;
  if (key.startsWith('packages/')) {
    final parts = key.split('/');
    if (parts.length < 3) return null;
    final package = packages.byName(parts[1]);
    if (package == null) return null;
    root = package.root;
    key = parts.skip(2).join('/');
  }
  final file = File(p.normalize(p.join(root, key)));
  if (!p.isWithin(root, file.path) || !file.existsSync()) return null;
  try {
    return file.readAsBytesSync();
  } on FileSystemException {
    return null;
  }
}

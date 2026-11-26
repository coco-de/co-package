import 'dart:typed_data';

/// Pixels ready to be embedded in a PDF: an 8-bit RGB plane and, when the
/// picture is not fully opaque, an 8-bit soft mask (alpha) plane.
///
/// Draw it with `NotePdfPage.drawImage`; drawing the same instance again reuses
/// the embedded data. Not mutable after construction.
class NotePdfImage {
  NotePdfImage._(this.width, this.height, this.rgb, this.softMask);

  /// Splits straight (not premultiplied) [rgba] pixels, row by row from the
  /// top, such as `ui.Image.toByteData(format:
  /// ui.ImageByteFormat.rawStraightRgba)`.
  ///
  /// Throws [ArgumentError] when a size is not positive or [rgba] does not hold
  /// exactly `width * height * 4` bytes.
  factory NotePdfImage.fromRgba(
    Uint8List rgba, {
    required int width,
    required int height,
  }) {
    if (width <= 0 || height <= 0) {
      throw ArgumentError('an image needs a positive size: ${width}x$height');
    }
    final pixels = width * height;
    if (rgba.length != pixels * 4) {
      throw ArgumentError(
        'expected ${pixels * 4} RGBA bytes, got ${rgba.length}',
      );
    }
    final rgb = Uint8List(pixels * 3);
    final alpha = Uint8List(pixels);
    var opaque = true;
    for (var pixel = 0; pixel < pixels; pixel++) {
      final source = pixel * 4;
      final target = pixel * 3;
      rgb[target] = rgba[source];
      rgb[target + 1] = rgba[source + 1];
      rgb[target + 2] = rgba[source + 2];
      alpha[pixel] = rgba[source + 3];
      opaque = opaque && rgba[source + 3] == 255;
    }

    return NotePdfImage._(width, height, rgb, opaque ? null : alpha);
  }

  /// Width in pixels.
  final int width;

  /// Height in pixels.
  final int height;

  /// `width * height * 3` bytes, rows from the top.
  final Uint8List rgb;

  /// `width * height` alpha bytes, or `null` when every pixel is opaque.
  final Uint8List? softMask;

  /// Whether the picture needs a soft mask.
  bool get hasAlpha => softMask != null;

  /// Whether no pixel is visible at all.
  bool get isFullyTransparent {
    final mask = softMask;

    return mask != null && mask.every((value) => value == 0);
  }
}

// Internal to the PDF exporter: turns painted regions and decoded images into
// PDF image planes. Not exported from the module barrel.
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:open_note/src/note/io/pdf/note_pdf_image.dart';

/// A painted piece of a page and the exact page rectangle it covers.
typedef NotePdfRaster = ({NotePdfImage image, ui.Rect rect});

/// Rasterises page regions at a fixed pixel density.
class NotePdfRasterizer {
  /// A rasteriser producing [scale] pixels per page unit, downscaling decoded
  /// images to at most [maxImageDimension] pixels on their longer side.
  NotePdfRasterizer({required this.scale, required this.maxImageDimension});

  /// The longest edge of a painted raster.
  static const int maxRasterDimension = 8192;

  /// Pixels per page unit.
  final double scale;

  /// The longest edge of an embedded decoded image.
  final int maxImageDimension;

  final Map<ui.Image, Future<NotePdfImage>> _converted = Map.identity();

  /// Paints [paint] (page coordinates) and keeps [region], snapped outwards to
  /// whole pixels. `null` when the region is empty or nothing visible was
  /// painted.
  Future<NotePdfRaster?> rasterize(
    ui.Rect region,
    void Function(ui.Canvas canvas) paint,
  ) async {
    if (region.width <= 0 || region.height <= 0) return null;
    final density = math.min(
      scale,
      maxRasterDimension / math.max(region.width, region.height),
    );
    final left = (region.left * density).floor();
    final top = (region.top * density).floor();
    final width = math.max(1, (region.right * density - 1e-6).ceil() - left);
    final height = math.max(1, (region.bottom * density - 1e-6).ceil() - top);
    final rect = ui.Rect.fromLTWH(
      left / density,
      top / density,
      width / density,
      height / density,
    );
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder)
      ..scale(density)
      ..translate(-rect.left, -rect.top)
      ..clipRect(rect);
    paint(canvas);
    final picture = recorder.endRecording();
    try {
      final image = await picture.toImage(width, height);
      try {
        final pixels = await _planes(image);

        return pixels.isFullyTransparent ? null : (image: pixels, rect: rect);
      } finally {
        image.dispose();
      }
    } finally {
      picture.dispose();
    }
  }

  /// The planes of a decoded [image], converted once per instance.
  Future<NotePdfImage> convert(ui.Image image) =>
      _converted.putIfAbsent(image, () => _downscaledPlanes(image));

  Future<NotePdfImage> _downscaledPlanes(ui.Image image) async {
    final longest = math.max(image.width, image.height);
    if (longest <= maxImageDimension) return _planes(image);
    final factor = maxImageDimension / longest;
    final width = math.max(1, (image.width * factor).round());
    final height = math.max(1, (image.height * factor).round());
    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder).drawImageRect(
      image,
      ui.Rect.fromLTWH(0, 0, image.width * 1.0, image.height * 1.0),
      ui.Rect.fromLTWH(0, 0, width * 1.0, height * 1.0),
      ui.Paint()..filterQuality = ui.FilterQuality.medium,
    );
    final picture = recorder.endRecording();
    try {
      final smaller = await picture.toImage(width, height);
      try {
        return await _planes(smaller);
      } finally {
        smaller.dispose();
      }
    } finally {
      picture.dispose();
    }
  }

  static Future<NotePdfImage> _planes(ui.Image image) async {
    final data = await image.toByteData(
      format: ui.ImageByteFormat.rawStraightRgba,
    );
    if (data == null) throw StateError('the engine could not read an image');

    return NotePdfImage.fromRgba(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      width: image.width,
      height: image.height,
    );
  }
}

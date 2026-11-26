// Internal to the importers: image sniffing, decoding and encoding through
// `dart:ui`. Not exported from the module barrel.
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:open_note/src/note/io/import/note_import_exception.dart';

/// The image formats the importers accept.
enum NoteImageFormat {
  /// Portable Network Graphics.
  png,

  /// JPEG.
  jpeg,
}

/// The format of [bytes] by its signature, or `null`.
NoteImageFormat? noteSniffImageFormat(Uint8List bytes) {
  bool startsWith(List<int> signature) {
    if (bytes.length < signature.length) return false;
    for (var i = 0; i < signature.length; i++) {
      if (bytes[i] != signature[i]) return false;
    }

    return true;
  }

  if (startsWith(const [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])) {
    return NoteImageFormat.png;
  }

  return startsWith(const [0xFF, 0xD8, 0xFF]) ? NoteImageFormat.jpeg : null;
}

/// The pixel size stored in the header of [bytes].
Future<ui.Size> noteReadImageSize(Uint8List bytes) =>
    _withDescriptor(bytes, (descriptor) async {
      return ui.Size(descriptor.width * 1.0, descriptor.height * 1.0);
    });

/// Decodes the first frame of [bytes], scaled down so that its longer side is
/// at most [maxDimension]. The caller disposes the image.
Future<({ui.Image image, bool downscaled})> noteDecodeImage(
  Uint8List bytes, {
  required int maxDimension,
}) => _withDescriptor(bytes, (descriptor) async {
  final width = descriptor.width;
  final height = descriptor.height;
  final tooLarge = width > maxDimension || height > maxDimension;
  // Only the longer side is given so the codec keeps the aspect ratio.
  final codec = await descriptor.instantiateCodec(
    targetWidth: tooLarge && width >= height ? maxDimension : null,
    targetHeight: tooLarge && width < height ? maxDimension : null,
  );
  try {
    final frame = await codec.getNextFrame();

    return (image: frame.image, downscaled: tooLarge);
  } finally {
    codec.dispose();
  }
});

/// [image] encoded as PNG.
Future<Uint8List> noteEncodePng(ui.Image image) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  if (data == null) {
    throw const NoteImportException('the picture could not be encoded as PNG');
  }

  return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
}

/// The straight-alpha RGBA pixels of [image].
Future<Uint8List> noteStraightRgba(ui.Image image) async {
  final data = await image.toByteData(
    format: ui.ImageByteFormat.rawStraightRgba,
  );
  if (data == null) {
    throw const NoteImportException('the picture pixels could not be read');
  }

  return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
}

/// An image from straight-alpha RGBA pixels (the engine wants them
/// premultiplied). The caller disposes it.
Future<ui.Image> noteImageFromRgba(
  Uint8List rgba, {
  required int width,
  required int height,
}) async {
  final premultiplied = Uint8List(rgba.length);
  for (var i = 0; i < rgba.length; i += 4) {
    final alpha = rgba[i + 3];
    for (var channel = 0; channel < 3; channel++) {
      premultiplied[i + channel] = (rgba[i + channel] * alpha + 127) ~/ 255;
    }
    premultiplied[i + 3] = alpha;
  }
  final buffer = await ui.ImmutableBuffer.fromUint8List(premultiplied);
  final descriptor = ui.ImageDescriptor.raw(
    buffer,
    width: width,
    height: height,
    pixelFormat: ui.PixelFormat.rgba8888,
  );
  try {
    final codec = await descriptor.instantiateCodec();
    try {
      return (await codec.getNextFrame()).image;
    } finally {
      codec.dispose();
    }
  } finally {
    descriptor.dispose();
    buffer.dispose();
  }
}

/// Runs [use] with the header of [bytes], turning engine decoding errors into
/// [NoteImportException].
Future<T> _withDescriptor<T>(
  Uint8List bytes,
  Future<T> Function(ui.ImageDescriptor descriptor) use,
) async {
  ui.ImmutableBuffer? buffer;
  ui.ImageDescriptor? descriptor;
  try {
    buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    descriptor = await ui.ImageDescriptor.encoded(buffer);

    return await use(descriptor);
  } on Exception catch (error) {
    if (error is NoteImportException) rethrow;
    throw NoteImportException('the picture could not be decoded', cause: error);
  } finally {
    descriptor?.dispose();
    buffer?.dispose();
  }
}

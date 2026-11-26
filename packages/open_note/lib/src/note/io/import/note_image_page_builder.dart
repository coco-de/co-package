// Internal to the importers: turns an encoded picture into a note page. Not
// exported from the module barrel.
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/io/import/note_image_codec.dart';
import 'package:open_note/src/note/io/import/note_import_exception.dart';
import 'package:open_note/src/note/io/import/note_imported_page.dart';
import 'package:open_note/src/note/io/import/note_scan_filter.dart';

/// A page [pageWidth] points wide whose height follows the aspect ratio of the
/// picture in [bytes] (PNG or JPEG, called [name] in errors), with the
/// picture, filtered by [filter], as its PNG background. Pictures longer than
/// [maxPixelDimension] pixels are scaled down.
///
/// An unchanged PNG keeps its original bytes.
Future<NoteImportedPage> noteImagePage(
  Uint8List bytes, {
  required String name,
  required double pageWidth,
  required int maxPixelDimension,
  NoteScanFilter filter = NoteScanFilter.none,
}) async {
  final format = noteSniffImageFormat(bytes);
  if (format == null) {
    throw NoteImportException('"$name" is not a PNG or JPEG picture');
  }
  final decoded = await noteDecodeImage(bytes, maxDimension: maxPixelDimension);
  final image = decoded.image;
  try {
    final size = NotePageSize(
      pageWidth,
      pageWidth * image.height / image.width,
    );
    final unchanged =
        format == NoteImageFormat.png && !decoded.downscaled && filter.isNone;

    return NoteImportedPage(
      size: size,
      backgroundPng: unchanged ? bytes : await _encode(image, filter),
    );
  } finally {
    image.dispose();
  }
}

Future<Uint8List> _encode(ui.Image image, NoteScanFilter filter) async {
  if (filter.isNone) return noteEncodePng(image);
  final filtered = await noteImageFromRgba(
    filter.apply(await noteStraightRgba(image)),
    width: image.width,
    height: image.height,
  );
  try {
    return await noteEncodePng(filtered);
  } finally {
    filtered.dispose();
  }
}

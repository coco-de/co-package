import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/io/import/note_image_codec.dart';
import 'package:open_note/src/note/io/import/note_pdf_page_renderer.dart';

/// A [NotePdfPageRenderer] for tests and the example app: it "renders" [pages]
/// plain grey pages of [pageSize] whatever the bytes are, and records the
/// requests.
class FakeNotePdfPageRenderer implements NotePdfPageRenderer {
  /// A fake document of [pages] pages. With [reportPageSize] false the rendered
  /// pages carry no size; with [failure] every call throws it.
  FakeNotePdfPageRenderer({
    this.pages = 3,
    this.pageSize = NotePageSize.a4,
    this.reportPageSize = true,
    this.failure,
  });

  /// Number of pages of the fake document.
  final int pages;

  /// Size of every page.
  final NotePageSize pageSize;

  /// Whether rendered pages report [pageSize].
  final bool reportPageSize;

  /// Thrown by every call when set.
  final Exception? failure;

  /// The page indices rendered, in call order.
  final List<int> renderedPages = [];

  /// The pixel widths requested, in call order.
  final List<int> requestedWidths = [];

  @override
  Future<int> pageCount(Uint8List bytes) async {
    final error = failure;
    if (error != null) throw error;

    return pages;
  }

  @override
  Future<NotePdfRenderedPage> renderPage(
    Uint8List bytes,
    int index, {
    required int targetWidth,
  }) async {
    final error = failure;
    if (error != null) throw error;
    RangeError.checkValueInInterval(index, 0, pages - 1, 'index');
    renderedPages.add(index);
    requestedWidths.add(targetWidth);
    final height = (targetWidth * pageSize.height / pageSize.width).round();

    return NotePdfRenderedPage(
      png: await _picture(targetWidth, height < 1 ? 1 : height, index),
      pageSize: reportPageSize ? pageSize : null,
    );
  }

  static Future<Uint8List> _picture(int width, int height, int index) async {
    final recorder = ui.PictureRecorder();
    final shade = 255 - (index % 8) * 16;
    ui.Canvas(recorder).drawRect(
      ui.Rect.fromLTWH(0, 0, width * 1.0, height * 1.0),
      ui.Paint()..color = ui.Color.fromARGB(255, shade, shade, shade),
    );
    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);
    picture.dispose();
    try {
      return await noteEncodePng(image);
    } finally {
      image.dispose();
    }
  }
}

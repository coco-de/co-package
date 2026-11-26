import 'dart:typed_data';

import 'package:open_note/src/note/io/pdf/note_pdf_page_composer.dart';
import 'package:open_note/src/note/io/pdf/note_pdf_rasterizer.dart';
import 'package:open_note/src/note/io/pdf/note_pdf_writer.dart';
import 'package:open_note/src/note/io/pdf/note_pdf_deflate.dart';
import 'package:open_note/src/note/io/render/note_page_render_input.dart';

/// Exports pages as a PDF.
///
/// One PDF page per input, sized in points like the note page. Handwriting
/// stays **vector** (filled outlines for pens, stroked paths for pencil, marker
/// and uniform pens, vector shapes; see `NoteStrokeVectorizer`), each
/// translucent layer composited as one group. The paper, text boxes and note
/// objects are embedded as images rendered at `rasterScale` pixels per point;
/// image drawables embed their decoded pixels (downscaled above
/// `maxImageDimension`), once however often they appear. Text is therefore not
/// selectable in the exported file.
abstract final class NotePdfExporter {
  /// The default density of rasterised parts (144 dpi).
  static const double defaultRasterScale = 2;

  /// The PDF bytes of [pages].
  ///
  /// With [includeBackground] false the paper is left out. [rasterScale] is
  /// clamped to 0.25–8. [onPageExported] reports progress as
  /// `(done, total)`. Every image a page uses must be decoded in its
  /// `images` map, otherwise a placeholder box is exported.
  ///
  /// Throws [ArgumentError] when [pages] is empty.
  static Future<Uint8List> export(
    List<NotePageRenderInput> pages, {
    bool includeBackground = true,
    double rasterScale = defaultRasterScale,
    int maxImageDimension = 2048,
    String? title,
    NotePdfCompressor compressor = notePdfDeflate,
    void Function(int done, int total)? onPageExported,
  }) async {
    if (pages.isEmpty) {
      throw ArgumentError.value(pages, 'pages', 'must not be empty');
    }
    final writer = NotePdfWriter(compressor: compressor, title: title);
    final rasterizer = NotePdfRasterizer(
      scale: rasterScale.isFinite
          ? rasterScale.clamp(0.25, 8.0)
          : defaultRasterScale,
      maxImageDimension: maxImageDimension < 1 ? 1 : maxImageDimension,
    );
    for (var index = 0; index < pages.length; index++) {
      final input = pages[index];
      final page = writer.addPage(input.size.width, input.size.height);
      await NotePdfPageComposer(
        page,
        input,
        rasterizer,
      ).compose(includeBackground: includeBackground);
      onPageExported?.call(index + 1, pages.length);
    }

    return writer.save();
  }
}

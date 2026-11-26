import 'package:flutter/foundation.dart';
import 'package:open_note/src/note/core/core.dart';

/// A PDF page drawn by a [NotePdfPageRenderer]. Transient, no JSON form.
@immutable
class NotePdfRenderedPage {
  /// A page picture [png], optionally with the real page size.
  const NotePdfRenderedPage({required this.png, this.pageSize});

  /// The page picture, PNG encoded.
  final Uint8List png;

  /// The page size in points, when the renderer knows it. Without it the
  /// importer derives a size from the picture's aspect ratio.
  final NotePageSize? pageSize;

  @override
  bool operator ==(Object other) =>
      other is NotePdfRenderedPage &&
      other.pageSize == pageSize &&
      listEquals(other.png, png);

  @override
  int get hashCode => Object.hash(png.length, pageSize);
}

/// The PDF rasteriser the host plugs in (the package ships none), for example
/// one built on a platform PDF library.
abstract interface class NotePdfPageRenderer {
  /// The number of pages of the PDF [bytes].
  Future<int> pageCount(Uint8List bytes);

  /// Page [index] (0-based) drawn [targetWidth] pixels wide.
  Future<NotePdfRenderedPage> renderPage(
    Uint8List bytes,
    int index, {
    required int targetWidth,
  });
}

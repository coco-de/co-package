import 'package:open_note/src/note/io/import/note_import_source.dart';

/// The document scanner the host plugs in (camera capture, edge detection,
/// perspective correction). The package ships none.
abstract interface class NoteDocumentScanner {
  /// The scanned pages as PNG or JPEG pictures, in order.
  ///
  /// With [source] the scanner processes that picture; without it, it captures
  /// pages itself (camera). An interactive camera scanner may ignore [source].
  /// A cancelled scan returns an empty list.
  Future<List<NoteImportSource>> scan({NoteImportSource? source});
}

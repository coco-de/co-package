import 'dart:typed_data';

import 'package:open_note/src/note/tools/note_font_descriptor.dart';

/// Where downloadable fonts come from. The host implements it (a server, an
/// asset bundle, ...); `MemoryNoteFontSource` serves tests and examples.
abstract interface class NoteFontSource {
  /// The fonts whose family or name contains [query], ignoring case; every
  /// font when [query] is `null` or blank.
  Future<List<NoteFontDescriptor>> list({String? query});

  /// The font file of the font [id]. Throws `NoteFontException` when there is
  /// no such font.
  Future<Uint8List> download(String id);
}

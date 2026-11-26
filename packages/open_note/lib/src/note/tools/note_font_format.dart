import 'dart:typed_data';

/// The font containers the font manager accepts, told apart by file header.
enum NoteFontFormat {
  /// TrueType outlines (`.ttf`): sfnt version `0x00010000` or `true`.
  ttf,

  /// OpenType with CFF outlines (`.otf`): sfnt version `OTTO`.
  otf;

  static const int _headerLength = 12;
  static const int _tableRecordLength = 16;

  /// The file extension without the dot. Persisted, so it never changes.
  String get fileExtension => name;

  /// The format of [bytes], or `null` when they do not start with a complete
  /// TTF/OTF table directory: too short, an unknown version (font collections
  /// and WOFF are not accepted), no tables, or a directory running past the
  /// end. Only the header is checked, not the tables themselves.
  static NoteFontFormat? detect(Uint8List bytes) {
    if (bytes.length < _headerLength) return null;
    final data = ByteData.sublistView(bytes);
    final format = switch (data.getUint32(0)) {
      0x00010000 || 0x74727565 => NoteFontFormat.ttf,
      0x4F54544F => NoteFontFormat.otf,
      _ => null,
    };
    final tables = data.getUint16(4);
    final needed = _headerLength + tables * _tableRecordLength;

    return tables > 0 && bytes.length >= needed ? format : null;
  }
}

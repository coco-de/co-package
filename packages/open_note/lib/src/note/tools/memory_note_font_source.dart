import 'dart:typed_data';

import 'package:open_note/src/note/tools/note_font_descriptor.dart';
import 'package:open_note/src/note/tools/note_font_exception.dart';
import 'package:open_note/src/note/tools/note_font_source.dart';

/// A [NoteFontSource] holding its fonts in memory, for tests and examples.
class MemoryNoteFontSource implements NoteFontSource {
  final Map<String, ({NoteFontDescriptor descriptor, Uint8List bytes})> _fonts =
      {};

  /// Adds a font, replacing any font with the same id. The bytes are copied.
  void add(NoteFontDescriptor descriptor, Uint8List bytes) {
    _fonts[descriptor.id] = (
      descriptor: descriptor,
      bytes: Uint8List.fromList(bytes),
    );
  }

  /// Fonts in the order their ids were first added.
  @override
  Future<List<NoteFontDescriptor>> list({String? query}) async {
    final needle = query?.trim().toLowerCase() ?? '';

    return [
      for (final font in _fonts.values)
        if (_matches(font.descriptor, needle)) font.descriptor,
    ];
  }

  @override
  Future<Uint8List> download(String id) async {
    final font = _fonts[id];
    if (font == null) throw NoteFontException('unknown font id: "$id"');

    return Uint8List.fromList(font.bytes);
  }

  static bool _matches(NoteFontDescriptor descriptor, String needle) =>
      needle.isEmpty ||
      descriptor.family.toLowerCase().contains(needle) ||
      descriptor.name.toLowerCase().contains(needle);
}

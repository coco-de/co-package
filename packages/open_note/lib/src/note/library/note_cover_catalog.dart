import 'dart:ui' show Color;

import 'package:open_note/src/note/library/note_cover.dart';
import 'package:open_note/src/note/library/note_cover_design.dart';

/// The cover designs built into the package.
///
/// The ids in [builtIn] are persisted in [NoteCover.builtinId]; they never
/// change meaning.
abstract final class NoteCoverCatalog {
  /// The ids of the built-in covers, in the order a picker should show them.
  static const List<String> builtIn = [
    'ocean',
    'forest',
    'sunset',
    'plum',
    'charcoal',
    'sand',
    'rose',
    'sky',
    'mint',
    'lemon',
    'kraft',
    'midnight',
    'coral',
    'lavender',
  ];

  /// The design used for new notes and for unknown ids.
  static const String defaultId = 'ocean';

  /// The look of an image cover before (or when) its picture is unavailable.
  static const NoteCoverDesign imagePlaceholder = NoteCoverDesign(
    background: Color(0xFFE0E0E0),
    accent: Color(0xFFCFCFCF),
    pattern: NoteCoverPattern.diagonal,
  );

  static const Map<String, NoteCoverDesign> _designs = {
    'ocean': NoteCoverDesign(
      background: Color(0xFF1E5F8C),
      accent: Color(0xFF4F93BD),
      pattern: NoteCoverPattern.band,
    ),
    'forest': NoteCoverDesign(
      background: Color(0xFF2E6B4A),
      accent: Color(0xFF58936F),
      pattern: NoteCoverPattern.stripes,
    ),
    'sunset': NoteCoverDesign(
      background: Color(0xFFD1633A),
      accent: Color(0xFFF2A65A),
      pattern: NoteCoverPattern.split,
    ),
    'plum': NoteCoverDesign(
      background: Color(0xFF5E3A77),
      accent: Color(0xFF8C63A8),
      pattern: NoteCoverPattern.dots,
    ),
    'charcoal': NoteCoverDesign(
      background: Color(0xFF37474F),
      accent: Color(0xFFECEFF1),
      pattern: NoteCoverPattern.label,
    ),
    'sand': NoteCoverDesign(
      background: Color(0xFFD9C3A0),
      accent: Color(0xFFBFA478),
      pattern: NoteCoverPattern.grid,
    ),
    'rose': NoteCoverDesign(
      background: Color(0xFFC4546B),
      accent: Color(0xFFE08B9C),
      pattern: NoteCoverPattern.diagonal,
    ),
    'sky': NoteCoverDesign(
      background: Color(0xFF6FB1E8),
      accent: Color(0xFFD3EBFF),
      pattern: NoteCoverPattern.plain,
    ),
    'mint': NoteCoverDesign(
      background: Color(0xFF7BCBB0),
      accent: Color(0xFFD9F3EA),
      pattern: NoteCoverPattern.dots,
    ),
    'lemon': NoteCoverDesign(
      background: Color(0xFFE9C64A),
      accent: Color(0xFFFFF1B8),
      pattern: NoteCoverPattern.band,
    ),
    'kraft': NoteCoverDesign(
      background: Color(0xFFA9825A),
      accent: Color(0xFFF2E7D5),
      pattern: NoteCoverPattern.label,
    ),
    'midnight': NoteCoverDesign(
      background: Color(0xFF17203A),
      accent: Color(0xFF3A4A75),
      pattern: NoteCoverPattern.grid,
    ),
    'coral': NoteCoverDesign(
      background: Color(0xFFE8775F),
      accent: Color(0xFFF6A894),
      pattern: NoteCoverPattern.stripes,
    ),
    'lavender': NoteCoverDesign(
      background: Color(0xFF8F8CD6),
      accent: Color(0xFFC3C1EF),
      pattern: NoteCoverPattern.split,
    ),
  };

  /// Whether [id] names a built-in cover.
  static bool contains(String? id) => _designs.containsKey(id);

  /// The design of the built-in cover [id]; unknown ids (and `null`) use
  /// [defaultId].
  static NoteCoverDesign designOf(String? id) =>
      _designs[id] ?? _designs[defaultId]!;

  /// The design [cover] is drawn with. An image cover resolves to
  /// [imagePlaceholder].
  static NoteCoverDesign resolve(NoteCover cover) => switch (cover.kind) {
    NoteCoverKind.builtin => designOf(cover.builtinId),
    NoteCoverKind.color => NoteCoverDesign.solid(
      cover.color ?? designOf(null).background,
    ),
    NoteCoverKind.image => imagePlaceholder,
  };
}

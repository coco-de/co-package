import 'dart:ui';

import 'package:open_note/src/core/utils/ink_group_info.dart';
import 'package:open_note/src/module/text/text_painter.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/document/note_page.dart';
import 'package:open_note/src/note/nav/note_page_text_extractor.dart';
import 'package:open_note/src/note/objects/note_sticky_object.dart';
import 'package:open_note/src/note/table/note_table_object.dart';

/// The typed text of a page, for search: the text boxes of the visible layers,
/// then sticky notes and table cells. Handwriting needs a
/// `NoteHandwritingIndexer`.
List<String> notePageTexts(NotePage page) => [
  for (final content in page.layers)
    if (content.layer.visible)
      ...NotePageTextExtractor.fromScribble(content.scribble),
  for (final object in page.objects) ..._objectTexts(object),
];

/// The area holding the ink, pictures, text and objects of the visible layers
/// of [page], in page coordinates; null for an empty page.
Rect? notePageContentBounds(NotePage page) {
  Rect? bounds;
  void include(Rect rect) => bounds = bounds?.expandToInclude(rect) ?? rect;
  for (final content in page.layers) {
    if (!content.layer.visible) continue;
    final scribble = content.scribble;
    for (final stroke in scribble.strokes) {
      // The lasso outline is a selection gesture, not content.
      if (stroke.ink == InkModes.lasso) continue;
      for (final point in stroke.points) {
        include(Offset(point.x, point.y) & Size.zero);
      }
    }
    for (final text in scribble.textDrawables) {
      if (!text.hidden) include(TextDrawablePainter.getTextBounds(text));
    }
    for (final image in scribble.imageDrawables) {
      if (!image.hidden) {
        include(Rect.fromLTWH(image.x, image.y, image.width, image.height));
      }
    }
  }
  for (final object in page.objects) {
    include(object.bounds);
  }

  return bounds?.intersect(Offset.zero & page.size.toSize());
}

Iterable<String> _objectTexts(NoteObject object) sync* {
  final texts = switch (object) {
    NoteStickyObject(:final text) => [text],
    NoteTableObject(:final cells) => [for (final cell in cells) cell.text],
    _ => const <String>[],
  };
  for (final text in texts) {
    final trimmed = text.trim();
    if (trimmed.isNotEmpty) yield trimmed;
  }
}

import 'package:flutter/foundation.dart';
import 'package:open_note/src/data/model/protobuf/scribble.pb.dart';

/// Pulls the typed text of a page out of its ink, for the search index.
abstract final class NotePageTextExtractor {
  static const double _fallbackFontSize = 16;

  /// The non-blank texts of the visible text boxes of [scribble] (trimmed), in
  /// reading order: top to bottom, then left to right.
  ///
  /// Boxes whose tops differ by at most half the font size of the topmost box of
  /// a line count as one line and are read left to right. Hidden boxes (the
  /// engine hides a box while it is edited) are skipped; rotation is ignored.
  static List<String> fromScribble(Scribble scribble) {
    final drawables = [
      for (final drawable in scribble.textDrawables)
        if (!drawable.hidden && drawable.text.trim().isNotEmpty) drawable,
    ];
    mergeSort<TextDrawable>(drawables, compare: _topThenLeft);
    final texts = <String>[];
    var start = 0;
    while (start < drawables.length) {
      final end = _lineEnd(drawables, start);
      final line = drawables.sublist(start, end);
      mergeSort<TextDrawable>(line, compare: (a, b) => a.x.compareTo(b.x));
      texts.addAll(line.map((drawable) => drawable.text.trim()));
      start = end;
    }

    return texts;
  }

  static int _lineEnd(List<TextDrawable> sorted, int start) {
    final first = sorted[start];
    final size = first.fontSize > 0 ? first.fontSize : _fallbackFontSize;
    final bottom = first.y + size / 2;
    var end = start + 1;
    while (end < sorted.length && sorted[end].y <= bottom) {
      end++;
    }

    return end;
  }

  static int _topThenLeft(TextDrawable a, TextDrawable b) {
    final vertical = a.y.compareTo(b.y);

    return vertical != 0 ? vertical : a.x.compareTo(b.x);
  }
}

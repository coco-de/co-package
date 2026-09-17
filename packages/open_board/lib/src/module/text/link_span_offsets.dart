import 'dart:math' as math;

import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';

/// Describes a single contiguous text edit derived by diffing two strings:
/// the half-open range `[start, oldEnd)` of the old text that was replaced,
/// and [newLength] = the number of characters that replaced it.
///
/// Offsets are UTF-16 code units, matching `String.length`, `String.substring`
/// and `TextSelection` so link spans stay aligned with the editor.
class TextEditDelta {
  const TextEditDelta({
    required this.start,
    required this.oldEnd,
    required this.newLength,
  });

  /// Inclusive start of the replaced range (== common-prefix length).
  final int start;

  /// Exclusive end of the replaced range in the old text.
  final int oldEnd;

  /// Number of characters inserted in place of `[start, oldEnd)`.
  final int newLength;
}

/// Computes the minimal single-range [TextEditDelta] transforming [oldText]
/// into [newText] by trimming the common prefix and suffix.
///
/// This collapses any edit (insert / delete / replace) into one replaced
/// range, which is sufficient to re-anchor link spans for ordinary typing.
TextEditDelta computeTextEditDelta(String oldText, String newText) {
  final maxPrefix = math.min(oldText.length, newText.length);
  var start = 0;
  while (start < maxPrefix &&
      oldText.codeUnitAt(start) == newText.codeUnitAt(start)) {
    start++;
  }

  var oldEnd = oldText.length;
  var newEnd = newText.length;
  while (oldEnd > start &&
      newEnd > start &&
      oldText.codeUnitAt(oldEnd - 1) == newText.codeUnitAt(newEnd - 1)) {
    oldEnd--;
    newEnd--;
  }

  return TextEditDelta(start: start, oldEnd: oldEnd, newLength: newEnd - start);
}

/// Re-anchors [spans] after the edit described by [delta].
///
/// Behavior:
/// - spans entirely before the edit are unchanged;
/// - spans entirely after the edit shift by the net length change;
/// - the part of a span that falls inside the replaced range is removed
///   (a span fully inside the replaced range is dropped).
///
/// Returns a fresh list of newly-built [TextLinkSpan]s (inputs untouched).
List<TextLinkSpan> shiftLinkSpans(
  Iterable<TextLinkSpan> spans,
  TextEditDelta delta,
) {
  final replaceStart = delta.start;
  final replaceEnd = delta.oldEnd;
  final shift = delta.newLength - (replaceEnd - replaceStart);

  final result = <TextLinkSpan>[];
  for (final span in spans) {
    final newStart = _mapOffset(span.start, replaceStart, replaceEnd, shift);
    final newEnd = _mapOffset(span.end, replaceStart, replaceEnd, shift);
    if (newEnd > newStart) {
      result.add(
        TextLinkSpan()
          ..start = newStart
          ..end = newEnd
          ..url = span.url,
      );
    }
  }
  return result;
}

/// Maps a single offset through a replacement of `[replaceStart, replaceEnd)`
/// whose net length change is [shift]. Offsets inside the replaced range
/// collapse to [replaceStart].
int _mapOffset(int offset, int replaceStart, int replaceEnd, int shift) {
  if (offset <= replaceStart) return offset;
  if (offset >= replaceEnd) return offset + shift;
  return replaceStart;
}

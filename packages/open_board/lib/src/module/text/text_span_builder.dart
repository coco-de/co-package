import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_board/src/module/text/text_drawable_extensions.dart';

/// Default visual style for an inline hyperlink span: blue + underline.
///
/// Matches the host (kobic) link affordance agreed for the external-link
/// feature (kobic #7162).
const Color kTextLinkColor = Color(0xFF1A73E8);

/// Builds the [TextSpan] tree for [drawable].
///
/// When [TextDrawable.linkSpans] is empty this returns a single-style span
/// identical to the legacy behavior. Otherwise it splits [TextDrawable.text]
/// into runs and paints link ranges with [linkColor] + underline.
///
/// This is the single source of truth for text→span conversion so the
/// painter, hit-test measurement, and the inline editor preview stay
/// consistent (no drift between layers).
TextSpan buildLinkAwareTextSpan(
  TextDrawable drawable, {
  Color linkColor = kTextLinkColor,
}) {
  final base = drawable.style;
  final text = drawable.text;
  final spans = sanitizeLinkSpans(drawable.linkSpans, text.length);
  if (spans.isEmpty) {
    return TextSpan(text: text, style: base);
  }

  final linkStyle = base.copyWith(
    color: linkColor,
    decoration: .underline,
  );

  final children = <TextSpan>[];
  var cursor = 0;
  for (final span in spans) {
    if (span.start > cursor) {
      children.add(TextSpan(text: text.substring(cursor, span.start)));
    }
    children.add(
      TextSpan(text: text.substring(span.start, span.end), style: linkStyle),
    );
    cursor = span.end;
  }
  if (cursor < text.length) {
    children.add(TextSpan(text: text.substring(cursor)));
  }

  return TextSpan(style: base, children: children);
}

/// Normalizes [linkSpans] against a text of [textLength]: clamps offsets into
/// range, drops empty/invalid/url-less spans, sorts by start, and drops any
/// span overlapping an earlier (kept) one.
///
/// Used both by the renderer and by the editor commit path so persisted spans
/// are always well-formed.
List<TextLinkSpan> sanitizeLinkSpans(
  Iterable<TextLinkSpan> linkSpans,
  int textLength,
) {
  final sorted = linkSpans.toList()..sort((a, b) => a.start.compareTo(b.start));

  final result = <TextLinkSpan>[];
  var lastEnd = 0;
  for (final span in sorted) {
    final start = math.max(0, math.min(span.start, textLength));
    final end = math.max(0, math.min(span.end, textLength));
    if (end <= start) continue; // empty / inverted
    if (span.url.isEmpty) continue; // not a usable link
    if (start < lastEnd) continue; // overlaps an earlier kept span

    result.add(
      TextLinkSpan()
        ..start = start
        ..end = end
        ..url = span.url,
    );
    lastEnd = end;
  }
  return result;
}

/// Returns the link span covering the half-open character [offset]
/// (`start <= offset < end`), or `null` when [offset] is not inside any link.
TextLinkSpan? linkSpanAtOffset(TextDrawable drawable, int offset) {
  for (final span in drawable.linkSpans) {
    if (span.url.isEmpty) continue;
    if (offset >= span.start && offset < span.end) {
      return span;
    }
  }
  return null;
}

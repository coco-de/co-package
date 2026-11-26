import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:open_note/src/note/style/note_contour.dart';
import 'package:open_note/src/note/style/note_shape_paths.dart';

/// One group of edges, both as an exact [path] and as polyline [contours] (for
/// hit testing, ink conversion or decorated strokes).
@immutable
class NoteShapePart {
  const NoteShapePart(this.path, this.contours);

  /// A group with no edge.
  factory NoteShapePart.empty() => NoteShapePart(Path(), const []);

  /// The exact curves.
  final Path path;

  /// The same edges as polylines.
  final List<NoteContour> contours;
}

/// Everything needed to draw a shape, with the arrowheads kept apart from the
/// shaft so they can be drawn solid.
@immutable
class NoteShapeDrawing {
  const NoteShapeDrawing({
    required this.outline,
    this.inner,
    this.hidden,
    this.heads,
    this.fillHeads = false,
  });

  /// The silhouette, or the shaft of a linear shape.
  final NoteShapePart outline;

  /// Visible interior edges, or `null`.
  final NoteShapePart? inner;

  /// Hidden edges (drawn dashed), or `null`.
  final NoteShapePart? hidden;

  /// Arrowheads, or `null`. Always drawn solid.
  final NoteShapePart? heads;

  /// Whether [heads] are filled (`triangle`, `dot`) instead of only stroked.
  final bool fillHeads;

  /// The public [NoteShapePaths] form; heads are merged into the outline.
  NoteShapePaths toPaths() {
    final tips = heads;

    return NoteShapePaths(
      outline: tips == null
          ? outline.path
          : (Path()
              ..addPath(outline.path, Offset.zero)
              ..addPath(tips.path, Offset.zero)),
      inner: inner?.path,
      hidden: hidden?.path,
    );
  }
}

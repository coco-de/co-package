import 'dart:ui';

import 'package:flutter/foundation.dart';

/// The paths of one shape.
@immutable
class NoteShapePaths {
  const NoteShapePaths({required this.outline, this.inner, this.hidden});

  /// The silhouette (closed for closed shapes; a line for linear ones). Fill
  /// this path to colour a shape. Arrow kinds include their heads.
  final Path outline;

  /// Visible edges inside the silhouette (3-D kinds), or `null`.
  final Path? inner;

  /// Edges behind the shape, to be drawn dashed (3-D kinds), or `null`.
  final Path? hidden;
}

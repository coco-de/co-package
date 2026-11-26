import 'package:flutter/foundation.dart';
import 'package:open_note/src/data/model/protobuf/scribble.pb.dart';

/// One ink layer of a page to be drawn: its [scribble] plus the layer's
/// visibility and opacity.
///
/// A transient render request, not a persisted model (the document layer owns
/// the stored form of a layer), so it has no JSON form. Equality compares the
/// scribble by value.
@immutable
class NotePageRenderLayer {
  /// A layer drawing [scribble] at [opacity], skipped when not [visible].
  const NotePageRenderLayer({
    required this.scribble,
    this.opacity = 1,
    this.visible = true,
  });

  /// The layer's ink: strokes, image drawables and text drawables in page
  /// coordinates.
  final Scribble scribble;

  /// 0 (invisible) to 1 (opaque); the layer is composited as one group.
  /// Values outside the range are clamped, a non-finite value paints as 1.
  final double opacity;

  /// A hidden layer is not drawn at all.
  final bool visible;

  /// [opacity] clamped to 0–1.
  double get effectiveOpacity => opacity.isFinite ? opacity.clamp(0.0, 1.0) : 1;

  /// Whether painting this layer can draw anything.
  bool get isPaintable => visible && effectiveOpacity > 0;

  /// A copy with the given fields replaced.
  NotePageRenderLayer copyWith({
    Scribble? scribble,
    double? opacity,
    bool? visible,
  }) => NotePageRenderLayer(
    scribble: scribble ?? this.scribble,
    opacity: opacity ?? this.opacity,
    visible: visible ?? this.visible,
  );

  @override
  bool operator ==(Object other) =>
      other is NotePageRenderLayer &&
      other.opacity == opacity &&
      other.visible == visible &&
      other.scribble == scribble;

  @override
  int get hashCode => Object.hash(scribble, opacity, visible);
}

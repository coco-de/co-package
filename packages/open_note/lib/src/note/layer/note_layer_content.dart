import 'package:open_note/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_note/src/note/layer/note_layer.dart';

/// One layer together with its ink — the unit a page persists. The [scribble]
/// is treated as immutable: build a new one instead of mutating it.
class NoteLayerContent {
  NoteLayerContent({required this.layer, Scribble? scribble})
    : scribble = scribble ?? Scribble();

  final NoteLayer layer;
  final Scribble scribble;

  /// Whether the layer holds no stroke, text or image.
  bool get isEmpty =>
      scribble.strokes.isEmpty &&
      scribble.textDrawables.isEmpty &&
      scribble.imageDrawables.isEmpty;

  NoteLayerContent copyWith({NoteLayer? layer, Scribble? scribble}) =>
      NoteLayerContent(
        layer: layer ?? this.layer,
        scribble: scribble ?? this.scribble,
      );
}

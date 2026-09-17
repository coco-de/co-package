import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';

/// Immutable CRUD manager for [ImageDrawable]s on a [Scribble].
///
/// Mirrors the contract of `TextDrawableManager`: every operation returns a
/// fresh [Scribble] instance with the requested mutation applied, leaving the
/// input scribble untouched. The manager itself holds no state, so the same
/// instance can be reused across pages and undo/redo stacks.
class ImageDrawableManager {
  const ImageDrawableManager();

  /// Append [imageDrawable] to the scribble.
  Scribble add(Scribble scribble, ImageDrawable imageDrawable) {
    final next = [...scribble.imageDrawables, imageDrawable];
    return _applyToScribble(scribble, next);
  }

  /// Replace the drawable identified by [id] with [updated]. Returns the same
  /// scribble unchanged when no matching drawable exists.
  Scribble update(Scribble scribble, String id, ImageDrawable updated) {
    final current = scribble.imageDrawables;
    if (current.every((d) => d.id != id)) return scribble;
    final next = current
        .map((d) => d.id == id ? updated : d)
        .toList(growable: false);
    return _applyToScribble(scribble, next);
  }

  /// Remove the drawable identified by [id]. Returns the same scribble
  /// unchanged when no matching drawable exists.
  Scribble remove(Scribble scribble, String id) {
    final current = scribble.imageDrawables;
    if (current.every((d) => d.id != id)) return scribble;
    final next = current.where((d) => d.id != id).toList(growable: false);
    return _applyToScribble(scribble, next);
  }

  /// Snapshot of all image drawables on [scribble].
  List<ImageDrawable> getAll(Scribble scribble) {
    return List<ImageDrawable>.unmodifiable(scribble.imageDrawables);
  }

  /// Find a drawable by id. Returns `null` when absent.
  ImageDrawable? findById(Scribble scribble, String id) {
    for (final drawable in scribble.imageDrawables) {
      if (drawable.id == id) return drawable;
    }
    return null;
  }

  Scribble _applyToScribble(Scribble scribble, List<ImageDrawable> drawables) {
    return Scribble(
      x: scribble.x,
      y: scribble.y,
      width: scribble.width,
      height: scribble.height,
      strokes: scribble.strokes,
      textDrawables: scribble.textDrawables,
      imageDrawables: drawables,
      createdAt: scribble.createdAt,
      updatedAt: DateTime.now().toIso8601String(),
      version: scribble.version,
    );
  }
}

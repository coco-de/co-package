import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/study/overlay/note_mask_fill.dart';
import 'package:open_note/src/note/study/overlay/note_mask_object.dart';
import 'package:open_note/src/note/study/overlay/note_tape_object.dart';

/// How many covers (masks and tapes) there are and how many are lifted.
typedef NoteMaskCounts = ({int total, int revealed});

/// Bulk operations on the covers of a page, as pure functions over an object
/// list. A *cover* is a [NoteMaskObject] or a [NoteTapeObject]; every other
/// object passes through untouched.
///
/// Each function returns a new list in the same order. Objects that do not
/// change are the very same instances, so an object controller sees them as
/// unchanged. These are study actions rather than editing gestures, so they
/// apply to locked covers too.
abstract final class NoteMaskOps {
  /// Lifts every cover.
  static List<NoteObject> revealAll(List<NoteObject> objects) =>
      _map(objects, (cover) => _withRevealed(cover, true));

  /// Puts every cover back.
  static List<NoteObject> hideAll(List<NoteObject> objects) =>
      _map(objects, (cover) => _withRevealed(cover, false));

  /// Removes every cover.
  static List<NoteObject> clearAll(List<NoteObject> objects) => [
    for (final object in objects)
      if (!isCover(object)) object,
  ];

  /// Gives every cover [fill] and/or the fill opacity [opacity] (clamped to
  /// 0–1; a non-finite value is ignored). The object's own `opacity` is kept.
  static List<NoteObject> restyleAll(
    List<NoteObject> objects, {
    NoteMaskFill? fill,
    double? opacity,
  }) {
    final fade = (opacity?.isFinite ?? false) ? opacity!.clamp(0.0, 1.0) : null;

    return _map(objects, (cover) => _restyled(cover, fill, fade));
  }

  /// The number of covers and of lifted covers.
  static NoteMaskCounts counts(Iterable<NoteObject> objects) {
    final covers = objects.where(isCover);

    return (total: covers.length, revealed: covers.where(isRevealed).length);
  }

  /// The masks every page of the note must show
  /// ([NoteMaskScope.document]), in order.
  static List<NoteMaskObject> documentMasks(Iterable<NoteObject> objects) => [
    for (final object in objects)
      if (object is NoteMaskObject && object.scope == NoteMaskScope.document)
        object,
  ];

  /// Whether [object] is a mask or a tape.
  static bool isCover(NoteObject object) =>
      object is NoteMaskObject || object is NoteTapeObject;

  /// Whether [object] is a lifted cover (`false` for other objects).
  static bool isRevealed(NoteObject object) => switch (object) {
    NoteMaskObject(:final revealed) => revealed,
    NoteTapeObject(:final revealed) => revealed,
    _ => false,
  };

  static List<NoteObject> _map(
    List<NoteObject> objects,
    NoteObject Function(NoteObject cover) change,
  ) => [
    for (final object in objects) isCover(object) ? change(object) : object,
  ];

  static NoteObject _withRevealed(NoteObject cover, bool revealed) {
    if (isRevealed(cover) == revealed) return cover;

    return switch (cover) {
      NoteMaskObject() => cover.copyWith(revealed: revealed),
      NoteTapeObject() => cover.copyWith(revealed: revealed),
      _ => cover,
    };
  }

  static NoteObject _restyled(
    NoteObject cover,
    NoteMaskFill? fill,
    double? opacity,
  ) {
    final restyled = switch (cover) {
      NoteMaskObject() => cover.copyWith(fill: fill, fillOpacity: opacity),
      NoteTapeObject() => cover.copyWith(fill: fill, fillOpacity: opacity),
      _ => cover,
    };

    return restyled == cover ? cover : restyled;
  }
}

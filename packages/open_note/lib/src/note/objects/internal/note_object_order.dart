import 'package:open_note/src/note/core/note_object.dart';

/// Pure restacking of objects. In every list index 0 is the bottom; each
/// function returns a new list and keeps the relative order inside the moved
/// group and inside the rest.
abstract final class NoteObjectOrder {
  /// The objects in [ids] moved above every other object.
  static List<NoteObject> toFront(List<NoteObject> objects, Set<String> ids) =>
      [
        ...objects.where((object) => !ids.contains(object.id)),
        ...objects.where((object) => ids.contains(object.id)),
      ];

  /// The objects in [ids] moved below every other object.
  static List<NoteObject> toBack(List<NoteObject> objects, Set<String> ids) => [
    ...objects.where((object) => ids.contains(object.id)),
    ...objects.where((object) => !ids.contains(object.id)),
  ];

  /// Every object in [ids] moved one step up, past the next object that is not
  /// in [ids].
  static List<NoteObject> forward(List<NoteObject> objects, Set<String> ids) {
    final next = List.of(objects);
    // From the top down, so a block of chosen objects moves up together.
    for (var index = next.length - 2; index >= 0; index--) {
      if (ids.contains(next[index].id) && !ids.contains(next[index + 1].id)) {
        _swap(next, index, index + 1);
      }
    }

    return next;
  }

  /// Every object in [ids] moved one step down, past the previous object that
  /// is not in [ids].
  static List<NoteObject> backward(List<NoteObject> objects, Set<String> ids) {
    final next = List.of(objects);
    for (var index = 1; index < next.length; index++) {
      if (ids.contains(next[index].id) && !ids.contains(next[index - 1].id)) {
        _swap(next, index, index - 1);
      }
    }

    return next;
  }

  static void _swap(List<NoteObject> list, int a, int b) {
    final held = list[a];
    list[a] = list[b];
    list[b] = held;
  }
}

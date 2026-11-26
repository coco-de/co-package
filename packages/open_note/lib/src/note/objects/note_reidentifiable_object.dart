import 'package:open_note/src/note/core/note_object.dart';

/// A [NoteObject] that can be copied under a new id without a
/// [NoteObjectRegistry].
///
/// [NoteObject.withBase] cannot change the id, so duplicating needs either
/// this interface or a registry that can re-decode the object with a new id.
/// Every kind shipped by the `objects` module implements it.
abstract interface class NoteReidentifiableObject {
  /// A copy of this object with [id]; every other field is kept.
  NoteObject withId(String id);
}

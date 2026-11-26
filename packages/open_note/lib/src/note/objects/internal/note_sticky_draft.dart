import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/core/note_object.dart';
import 'package:open_note/src/note/objects/note_object_controller.dart';
import 'package:open_note/src/note/objects/note_sticky_object.dart';

/// The unsaved text of one sticky-note editing session.
class NoteStickyDraft {
  /// The field's text.
  final TextEditingController text;

  /// The field's focus.
  final FocusNode focusNode;

  /// The object text the field was last in step with.
  String _base;

  NotePendingEditRegistration? _registration;

  /// Starts a session on the note's current [text].
  NoteStickyDraft(String text)
    : _base = text,
      text = TextEditingController.fromValue(_atEnd(text)),
      focusNode = FocusNode(debugLabel: 'NoteStickyView');

  /// Lets [controller] commit this input; without one, only [commit] does.
  ///
  /// A note the controller still holds undecoded (loaded before its kind was
  /// registered) is also left to [commit], which writes the decoded note the
  /// widget shows.
  void attach(NoteObjectController? controller, String objectId) {
    _registration?.cancel();
    _registration = controller?.find(objectId) is NoteStickyObject
        ? controller?.registerPendingEdit(objectId, apply)
        : null;
  }

  /// The edited copy of [current], or `null` when there is nothing to commit —
  /// including when the object's text was changed from outside since the field
  /// last saw it, because the outside change wins.
  ///
  /// The caller must apply the returned copy: the field then counts as in step
  /// with it, so an undo right after (before any rebuild) still reaches the
  /// field.
  NoteObject? apply(NoteObject current) {
    if (current is! NoteStickyObject) return null;
    final typed = text.text;
    if (typed == current.text || current.text != _base) return null;
    _base = typed;

    return current.copyWith(text: typed);
  }

  /// Keeps the field in step with the object's [objectText] after a rebuild.
  void sync(String objectText) {
    if (objectText == _base) return;
    _base = objectText;
    if (objectText != text.text) text.value = _atEnd(objectText);
  }

  /// Commits through the controller when it knows this session, otherwise
  /// through [onChanged] applied to [fallback]. A controller that dropped the
  /// session (it was disposed or reloaded) gets nothing.
  void commit(NoteObject fallback, ValueChanged<NoteObject>? onChanged) {
    final registration = _registration;
    if (registration != null) {
      registration.commit();

      return;
    }
    final next = apply(fallback);
    if (next != null) onChanged?.call(next);
  }

  /// Releases the field's resources.
  void dispose() {
    _registration?.cancel();
    _registration = null;
    text.dispose();
    focusNode.dispose();
  }

  static TextEditingValue _atEnd(String text) => TextEditingValue(
    text: text,
    selection: TextSelection.collapsed(offset: text.length),
  );
}

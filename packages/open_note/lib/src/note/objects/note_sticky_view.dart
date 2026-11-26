import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/core/note_object.dart';
import 'package:open_note/src/note/core/note_text_field.dart';
import 'package:open_note/src/note/objects/internal/note_sticky_draft.dart';
import 'package:open_note/src/note/objects/note_object_controller.dart';
import 'package:open_note/src/note/objects/note_object_layer_scope.dart';
import 'package:open_note/src/note/objects/note_objects_strings.dart';
import 'package:open_note/src/note/objects/note_sticky_object.dart';

/// Draws a [NoteStickyObject] filling its constraints.
///
/// While `scope.editing` is set it shows a text field instead of the text. The
/// typed text is committed through `scope.onChanged` (or the enclosing layer's
/// controller) when the field loses focus, when editing ends and when the
/// widget is removed — never on every keystroke, so one editing session is one
/// undo step. If the object's text changes from outside while editing (an
/// undo, say), the field takes the new text and the unsaved typing is
/// discarded.
///
/// The text ignores the device's text-scale setting: it is page content.
class NoteStickyView extends StatefulWidget {
  const NoteStickyView({
    required this.object,
    required this.scope,
    super.key,
    this.strings = const NoteObjectsStrings(),
  });

  /// The note to draw.
  final NoteStickyObject object;

  /// How the layer shows it.
  final NoteObjectViewScope scope;

  /// Provides the hint of an empty note.
  final NoteObjectsStrings strings;

  @override
  State<NoteStickyView> createState() => _NoteStickyViewState();
}

class _NoteStickyViewState extends State<NoteStickyView> {
  NoteStickyDraft? _draft;
  NoteObjectController? _controller;

  @override
  void initState() {
    super.initState();
    if (widget.scope.editing) _startEditing();
  }

  void _startEditing() {
    final draft = NoteStickyDraft(widget.object.text);
    _draft = draft;
    // Focus once the field exists; autofocus alone loses to a focused node.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && identical(_draft, draft)) draft.focusNode.requestFocus();
    });
  }

  /// Commits after this frame: it may not change the controller while the tree
  /// is being built or torn down.
  void _finishEditing(NoteObjectViewScope previousScope) {
    final draft = _draft;
    if (draft == null) return;
    _draft = null;
    final latest = widget.object;
    final onChanged = widget.scope.onChanged ?? previousScope.onChanged;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      draft
        ..commit(latest, onChanged)
        ..dispose();
    });
  }

  void _commitNow() => _draft?.commit(widget.object, widget.scope.onChanged);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller = NoteObjectLayerScope.maybeControllerOf(context);
    _draft?.attach(_controller, widget.object.id);
  }

  @override
  void didUpdateWidget(NoteStickyView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final draft = _draft;
    if (widget.scope.editing && draft == null) {
      _startEditing();
      _draft?.attach(_controller, widget.object.id);
    } else if (!widget.scope.editing && draft != null) {
      _finishEditing(oldWidget.scope);
    } else {
      draft?.sync(widget.object.text);
    }
  }

  @override
  void dispose() {
    if (_draft != null) _finishEditing(widget.scope);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final object = widget.object;
    final draft = widget.scope.editing ? _draft : null;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: object.paperColor,
        borderRadius: const BorderRadius.all(
          Radius.circular(NoteStickyObject.cornerRadius),
        ),
        boxShadow: object.shadow ? const [NoteStickyObject.paperShadow] : null,
      ),
      child: ClipRect(
        child: draft == null
            ? _StickyText(object: object)
            : _StickyEditor(
                object: object,
                draft: draft,
                hint: widget.strings.stickyHint,
                onSubmitted: _commitNow,
              ),
      ),
    );
  }
}

class _StickyText extends StatelessWidget {
  const _StickyText({required this.object});

  final NoteStickyObject object;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(NoteStickyObject.textPadding),
    child: Text(
      object.text,
      style: object.textStyle,
      textAlign: TextAlign.start,
      textScaler: TextScaler.noScaling,
    ),
  );
}

class _StickyEditor extends StatelessWidget {
  const _StickyEditor({
    required this.object,
    required this.draft,
    required this.hint,
    required this.onSubmitted,
  });

  final NoteStickyObject object;
  final NoteStickyDraft draft;
  final String hint;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    final style = object.textStyle;

    return MediaQuery.withNoTextScaling(
      // A tap anywhere on the paper, not only on a line of text, focuses.
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: draft.focusNode.requestFocus,
        child: SingleChildScrollView(
          child: NoteTextField(
            controller: draft.text,
            focusNode: draft.focusNode,
            autofocus: true,
            maxLines: null,
            submitOnBlur: true,
            onSubmitted: (_) => onSubmitted(),
            style: style,
            hintText: hint,
            hintStyle: style.copyWith(
              color: object.textColor.withValues(alpha: 0.4),
            ),
            cursorColor: object.textColor,
            padding: const EdgeInsets.all(NoteStickyObject.textPadding),
            decoration: null,
          ),
        ),
      ),
    );
  }
}

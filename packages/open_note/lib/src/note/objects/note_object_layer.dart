import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/core/note_link_target.dart';
import 'package:open_note/src/note/core/note_object.dart';
import 'package:open_note/src/note/objects/internal/note_object_hit_region.dart';
import 'package:open_note/src/note/objects/internal/note_object_layer_gestures.dart';
import 'package:open_note/src/note/objects/internal/note_object_overlay.dart';
import 'package:open_note/src/note/objects/note_object_controller.dart';
import 'package:open_note/src/note/objects/note_object_geometry.dart';
import 'package:open_note/src/note/objects/note_object_layer_scope.dart';
import 'package:open_note/src/note/objects/note_objects_strings.dart';

/// Draws the objects of a [NoteObjectController] over a page, bottom first,
/// each positioned, rotated and faded, using the widgets of a
/// [NoteObjectRegistry]. It talks to objects only through the [NoteObject]
/// contract.
///
/// The layer is [size] in page units (give it tight constraints of that size;
/// the host scales and pans it). Pointers reach it only where an object is (or,
/// in edit mode, a grip); everywhere else they fall through to what is beneath.
/// Objects reaching past the page are drawn past it and can only be touched on
/// the page — clip it if the page should hide them.
///
/// **view** — each object's widget gets `interactive: true` and reacts itself.
///
/// **edit** —
/// - a tap selects the topmost object under it; Shift-tap adds or removes one;
///   a tap on empty space deselects (without taking the tap from what is
///   beneath);
/// - dragging an object moves the selection (an unselected object is selected
///   first); the middle of the moved group stays on the page; one drag is one
///   undo step, and a cancelled pointer puts things back;
/// - a single unlocked selection has eight resize grips (resizing follows the
///   rotation and keeps the opposite side still; at least 12 units) and a
///   rotation grip above it (below or beside it when it would leave the page);
///   a multi-selection can only be moved;
/// - a double tap starts inline editing: that object's widget gets
///   `editing: true` and `interactive: true`. Pointers its widget takes go to
///   it; others (on grips, or on objects that ignore them) work as usual.
///   Editing ends when something else is selected or the selection clears;
/// - locked objects show a lock mark and cannot be moved, resized or rotated
///   (dragging one is left to ancestors); they can be selected and edited.
///
/// **passThrough** — ignores every pointer.
///
/// Leaving edit mode or replacing the controller ends editing after the frame.
/// Removing the layer from the tree does not: call
/// [NoteObjectController.endEditing] when the user leaves a page.
class NoteObjectLayer extends StatefulWidget {
  const NoteObjectLayer({
    required this.controller,
    required this.registry,
    required this.size,
    super.key,
    this.mode = NoteObjectLayerMode.view,
    this.onLinkActivated,
    this.selectionColor = const Color(0xFF2962FF),
    this.lockColor = const Color(0xCC424242),
    this.handleSize = 12,
    this.strings = const NoteObjectsStrings(),
  }) : assert(handleSize > 0, 'handleSize must be positive');

  /// The objects and selection.
  final NoteObjectController controller;

  /// Builds the widget of each kind.
  final NoteObjectRegistry registry;

  /// The page size in page units.
  final Size size;

  /// How pointers are used.
  final NoteObjectLayerMode mode;

  /// Called when the user follows a link on an object (in view mode).
  final ValueChanged<NoteLinkTarget>? onLinkActivated;

  /// Colour of the selection outline and grips.
  final Color selectionColor;

  /// Colour of the badge behind the (white) lock mark.
  final Color lockColor;

  /// Diameter of the drawn grips in page units. A grip can be touched within
  /// this radius, and at least within 16.
  final double handleSize;

  /// Accessibility labels.
  final NoteObjectsStrings strings;

  @override
  State<NoteObjectLayer> createState() => _NoteObjectLayerState();
}

class _NoteObjectLayerState extends State<NoteObjectLayer> {
  late final NoteObjectLayerGestures _gestures = NoteObjectLayerGestures(
    () => widget,
  );

  bool _isTarget(Offset position) => widget.mode == NoteObjectLayerMode.edit
      ? _gestures.isTarget(position)
      : widget.controller.objectAt(position) != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _gestures.recognizer.gestureSettings = MediaQuery.maybeGestureSettingsOf(
      context,
    );
  }

  @override
  void didUpdateWidget(NoteObjectLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final previous = oldWidget.controller;
    final leftEditing =
        oldWidget.mode == NoteObjectLayerMode.edit &&
        widget.mode != NoteObjectLayerMode.edit;
    if (leftEditing || previous != widget.controller) {
      _gestures.interrupt();
      // Not during the build: ending may commit input and notify.
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => previous.endEditing(),
      );
    }
  }

  @override
  void dispose() {
    _gestures.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => NoteObjectLayerScope(
    controller: widget.controller,
    child: SizedBox.fromSize(
      size: widget.size,
      child: IgnorePointer(
        ignoring: widget.mode == NoteObjectLayerMode.passThrough,
        // Translucent: it watches taps on empty space without taking them.
        child: Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: _gestures.pointerDown,
          onPointerMove: _gestures.pointerMove,
          onPointerUp: _gestures.pointerUp,
          onPointerCancel: _gestures.pointerCancel,
          child: NoteObjectHitRegion(
            isTarget: _isTarget,
            claimsTargets: widget.mode == NoteObjectLayerMode.edit,
            // New object widgets for another controller, so an editor of the
            // old content commits to the old controller.
            child: KeyedSubtree(
              key: ObjectKey(widget.controller),
              child: ListenableBuilder(
                listenable: widget.controller,
                builder: (context, _) =>
                    _NoteObjectStack(layer: widget, gestures: _gestures),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _NoteObjectStack extends StatelessWidget {
  const _NoteObjectStack({required this.layer, required this.gestures});

  final NoteObjectLayer layer;
  final NoteObjectLayerGestures gestures;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    clipBehavior: Clip.none,
    children: [
      for (final object in layer.controller.objects)
        _NoteObjectSlot(
          key: ValueKey('note-object-${object.id}'),
          object: object,
          layer: layer,
          gestures: gestures,
        ),
      if (layer.mode == NoteObjectLayerMode.edit)
        IgnorePointer(
          key: const ValueKey('note-object-overlay'),
          child: NoteObjectOverlay(
            controller: layer.controller,
            pageSize: layer.size,
            handleSize: layer.handleSize,
            color: layer.selectionColor,
            lockColor: layer.lockColor,
            strings: layer.strings,
          ),
        ),
    ],
  );
}

/// One object, placed, turned and faded.
class _NoteObjectSlot extends StatelessWidget {
  const _NoteObjectSlot({
    required this.object,
    required this.layer,
    required this.gestures,
    super.key,
  });

  final NoteObject object;
  final NoteObjectLayer layer;
  final NoteObjectLayerGestures gestures;

  NoteObjectViewScope _scope() {
    final controller = layer.controller;
    final id = object.id;
    final editMode = layer.mode == NoteObjectLayerMode.edit;
    final editing = editMode && controller.editingId == id;

    return NoteObjectViewScope(
      selected: editMode && controller.selectedIds.contains(id),
      editing: editing,
      interactive: editing || layer.mode == NoteObjectLayerMode.view,
      onChanged: controller.update,
      onLinkActivated: layer.mode == NoteObjectLayerMode.passThrough
          ? null
          : layer.onLinkActivated,
      onRequestEdit: editMode ? () => controller.beginEditing(id) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scope = _scope();
    final editMode = layer.mode == NoteObjectLayerMode.edit;

    return Positioned.fromRect(
      rect: NoteObjectGeometry.normalizeRect(object.bounds),
      child: Transform.rotate(
        angle: object.rotation,
        child: Opacity(
          opacity: object.opacity.clamp(0.0, 1.0),
          child: Semantics(
            container: true,
            label: layer.strings.nameOf(object.kind),
            selected: editMode ? scope.selected : null,
            onTap: editMode ? () => layer.controller.select(object.id) : null,
            // Marks the pointers an edited object's widget takes, which the
            // layer then leaves to it.
            child: Listener(
              onPointerDown: scope.editing
                  ? (event) => gestures.claim(event.pointer)
                  : null,
              // In edit mode only an edited object reacts by itself. The
              // others still absorb the pointer, so a covered editor does not
              // take a touch meant for the object above it.
              child: AbsorbPointer(
                absorbing: editMode && !scope.editing,
                child: layer.registry.buildView(context, object, scope),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// What a [NoteObjectLayer] does with pointers.
enum NoteObjectLayerMode {
  /// Reading: objects react to taps themselves (masks reveal, links open) and
  /// there is no selection.
  view,

  /// Arranging: a tap selects, a drag moves, grips resize and rotate, a
  /// double tap edits.
  edit,

  /// Every pointer passes through, so the user can draw over the objects.
  passThrough,
}

import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/objects/note_object_controller.dart';

/// Gives the widgets a [NoteObjectLayer] builds access to its controller.
///
/// An inline editor of a custom object kind can use it to hand its unsaved
/// input to [NoteObjectController.registerPendingEdit], so the input is
/// committed as its own undo step before the editing session ends. Widgets
/// built outside a layer find nothing and must commit through
/// `NoteObjectViewScope.onChanged` alone.
class NoteObjectLayerScope extends InheritedWidget {
  const NoteObjectLayerScope({
    required this.controller,
    required super.child,
    super.key,
  });

  /// The controller of the nearest enclosing layer, or `null` outside one.
  /// The caller rebuilds when the layer gets another controller.
  static NoteObjectController? maybeControllerOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<NoteObjectLayerScope>()
          ?.controller;

  /// The controller of the enclosing layer.
  final NoteObjectController controller;

  @override
  bool updateShouldNotify(NoteObjectLayerScope oldWidget) =>
      controller != oldWidget.controller;
}

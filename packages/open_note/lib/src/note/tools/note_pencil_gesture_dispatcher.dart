import 'package:open_note/src/note/tools/note_pencil_gesture.dart';
import 'package:open_note/src/note/tools/note_pencil_gesture_map.dart';
import 'package:open_note/src/note/tools/note_tool_actions.dart';

/// Turns stylus gestures into editor actions. The host forwards the platform
/// gesture (for example a `UIPencilInteraction` callback) to [dispatch].
class NotePencilGestureDispatcher {
  /// Which action each gesture runs; assign a new one when settings change.
  NotePencilGestureMap map;

  /// The editor the actions run on.
  final NoteToolActions actions;

  /// Creates a dispatcher that runs the actions of [map] on [actions].
  NotePencilGestureDispatcher(this.map, this.actions);

  /// Runs the action mapped to [gesture] and returns it. Nothing is called for
  /// [NotePencilAction.none].
  NotePencilAction dispatch(NotePencilGesture gesture) {
    final action = map.actionFor(gesture);
    switch (action) {
      case NotePencilAction.none:
        break;
      case NotePencilAction.switchPreviousTool:
        actions.previousTool();
      case NotePencilAction.toggleEraser:
        actions.toggleEraser();
      case NotePencilAction.undo:
        actions.undo();
      case NotePencilAction.redo:
        actions.redo();
      case NotePencilAction.showToolPalette:
        actions.showToolPalette();
      case NotePencilAction.cyclePreset:
        actions.cyclePreset();
    }

    return action;
  }
}

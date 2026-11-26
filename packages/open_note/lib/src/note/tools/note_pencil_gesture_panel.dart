import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/tools/internal/note_tools_button.dart';
import 'package:open_note/src/note/tools/note_pencil_gesture.dart';
import 'package:open_note/src/note/tools/note_pencil_gesture_map.dart';
import 'package:open_note/src/note/tools/note_tools_strings.dart';
import 'package:open_note/src/note/tools/note_tools_style.dart';

/// Chooses what Apple Pencil double tap and squeeze do (iPadOS reports
/// squeeze only for Pencil Pro). Your app passes the gestures to
/// `NoteToolController.dispatcher`.
class NotePencilGesturePanel extends StatelessWidget {
  const NotePencilGesturePanel({
    required this.map,
    required this.onChanged,
    this.strings = const NoteToolsStrings(),
    this.style = const NoteToolsStyle(),
    super.key,
  });

  /// The button choosing [action] for [gesture].
  static Key optionKey(NotePencilGesture gesture, NotePencilAction action) =>
      ValueKey<String>('note-pencil-${gesture.name}-${action.name}');

  final NotePencilGestureMap map;
  final ValueChanged<NotePencilGestureMap> onChanged;
  final NoteToolsStrings strings;
  final NoteToolsStyle style;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    explicitChildNodes: true,
    label: strings.pencilGestures,
    child: SingleChildScrollView(
      padding: EdgeInsets.all(style.spacing),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final gesture in NotePencilGesture.values) ...[
            if (gesture != NotePencilGesture.values.first)
              SizedBox(height: style.spacing),
            Text(switch (gesture) {
              NotePencilGesture.doubleTap => strings.pencilDoubleTap,
              NotePencilGesture.squeeze => strings.pencilSqueeze,
            }, style: style.labelStyle),
            SizedBox(height: style.spacing / 2),
            Wrap(
              spacing: style.spacing / 2,
              runSpacing: style.spacing / 2,
              children: [
                for (final action in NotePencilAction.values)
                  NoteToolsButton(
                    key: optionKey(gesture, action),
                    label: strings.pencilActionName(action),
                    semanticLabel: strings.pencilActionName(action),
                    selected: map.actionFor(gesture) == action,
                    onPressed: () => onChanged(map.withAction(gesture, action)),
                    style: style,
                  ),
              ],
            ),
          ],
        ],
      ),
    ),
  );
}

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/study/overlay/note_floating_window.dart';
import 'package:open_note/src/note/study/overlay/note_floating_window_controller.dart';
import 'package:open_note/src/note/study/overlay/note_floating_window_style.dart';
import 'package:open_note/src/note/study/overlay/note_overlay_button.dart';
import 'package:open_note/src/note/study/overlay/note_overlay_glyph.dart';
import 'package:open_note/src/note/study/overlay/note_study_overlay_strings.dart';

/// The title bar of a floating window: a drag area with the title, then the
/// pin, minimize and close buttons. Internal to `study/overlay`.
class NoteFloatingWindowTitleBar extends StatelessWidget {
  /// Creates the bar of [window].
  const NoteFloatingWindowTitleBar({
    required this.window,
    required this.controller,
    required this.focused,
    required this.style,
    required this.strings,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    super.key,
  });

  /// The window.
  final NoteFloatingWindow window;

  /// Receives the button actions.
  final NoteFloatingWindowController controller;

  /// Whether the window has focus.
  final bool focused;

  /// Colours and metrics.
  final NoteFloatingWindowStyle style;

  /// Button labels.
  final NoteStudyOverlayStrings strings;

  /// A drag of the title began.
  final VoidCallback onDragStart;

  /// The drag moved by `delta`.
  final ValueChanged<Offset> onDragUpdate;

  /// The drag ended or was cancelled.
  final VoidCallback onDragEnd;

  String get _id => window.id;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: focused ? style.focusedTitleBarColor : style.titleBarColor,
    child: SizedBox(
      height: style.titleBarHeight,
      child: Row(
        children: [
          Expanded(child: _dragArea()),
          _button(
            'pin',
            window.pinned ? strings.unpinWindow : strings.pinWindow,
            window.pinned
                ? NoteOverlayGlyphKind.pinned
                : NoteOverlayGlyphKind.pin,
            () => controller.togglePin(_id),
          ),
          _button(
            'minimize',
            window.minimized ? strings.restoreWindow : strings.minimizeWindow,
            window.minimized
                ? NoteOverlayGlyphKind.restore
                : NoteOverlayGlyphKind.minimize,
            () => controller.toggleMinimize(_id),
          ),
          _button(
            'close',
            strings.closeWindow,
            NoteOverlayGlyphKind.close,
            () => controller.close(_id),
          ),
        ],
      ),
    ),
  );

  Widget _dragArea() => Semantics(
    header: true,
    label: '${window.spec.title}. ${strings.moveWindow}',
    excludeSemantics: true,
    child: MouseRegion(
      cursor: SystemMouseCursors.move,
      child: GestureDetector(
        key: ValueKey('note-floating-title-$_id'),
        behavior: HitTestBehavior.opaque,
        dragStartBehavior: DragStartBehavior.down,
        onPanStart: (_) => onDragStart(),
        onPanUpdate: (details) => onDragUpdate(details.delta),
        onPanEnd: (_) => onDragEnd(),
        onPanCancel: onDragEnd,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              window.spec.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style.titleStyle,
            ),
          ),
        ),
      ),
    ),
  );

  Widget _button(
    String action,
    String label,
    NoteOverlayGlyphKind glyph,
    VoidCallback onPressed,
  ) => NoteOverlayButton(
    key: ValueKey('note-floating-$action-$_id'),
    label: label,
    onPressed: onPressed,
    minWidth: style.buttonExtent,
    height: style.titleBarHeight,
    child: NoteOverlayGlyph(glyph, color: style.iconColor, size: 14),
  );
}

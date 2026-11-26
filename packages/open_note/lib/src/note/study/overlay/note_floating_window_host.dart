import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/study/overlay/note_floating_window_controller.dart';
import 'package:open_note/src/note/study/overlay/note_floating_window_frame.dart';
import 'package:open_note/src/note/study/overlay/note_floating_window_style.dart';
import 'package:open_note/src/note/study/overlay/note_study_overlay_strings.dart';

/// A [Stack] that draws the windows of a [NoteFloatingWindowController] over
/// an optional [child].
///
/// Place it wherever the windows may float, with bounded constraints. Each
/// window has a title bar to drag it by, pin, minimize and close buttons and
/// (when resizable) a corner to resize it. Windows are always drawn inside the
/// host: one that would stick out (say, after the screen turned) is shown moved
/// in, without forgetting where it was put. Without a [child], presses beside
/// the windows pass through to what lies under the host.
class NoteFloatingWindowHost extends StatelessWidget {
  /// Hosts the windows of [controller].
  const NoteFloatingWindowHost({
    required this.controller,
    this.child,
    this.style = const NoteFloatingWindowStyle(),
    this.strings = const NoteStudyOverlayStrings(),
    super.key,
  });

  /// The windows.
  final NoteFloatingWindowController controller;

  /// Content filling the host beneath the windows.
  final Widget? child;

  /// Colours and metrics of the windows.
  final NoteFloatingWindowStyle style;

  /// Accessibility labels.
  final NoteStudyOverlayStrings strings;

  @override
  Widget build(BuildContext context) {
    final content = child;

    return LayoutBuilder(
      builder: (context, constraints) => ListenableBuilder(
        listenable: controller,
        builder: (context, _) => Stack(
          children: [
            if (content != null)
              Positioned.fill(
                key: const ValueKey('note-floating-content'),
                child: content,
              ),
            for (final window in controller.windows)
              NoteFloatingWindowFrame(
                key: ValueKey('note-floating-frame-${window.id}'),
                window: window,
                controller: controller,
                hostSize: constraints.biggest,
                focused: controller.focusedId == window.id,
                style: style,
                strings: strings,
              ),
          ],
        ),
      ),
    );
  }
}

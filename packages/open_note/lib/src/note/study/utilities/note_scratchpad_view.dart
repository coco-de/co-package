import 'package:flutter/widgets.dart';
import 'package:open_note/src/module/state/scribble.state.dart';
import 'package:open_note/src/module/widgets/scribble_widget.dart';
import 'package:open_note/src/module/widgets/simple_scribble_widget.dart';
import 'package:open_note/src/note/study/utilities/internal/note_utility_button.dart';
import 'package:open_note/src/note/study/utilities/note_scratchpad_controller.dart';
import 'package:open_note/src/note/study/utilities/note_study_utilities_strings.dart';
import 'package:open_note/src/note/study/utilities/note_study_utilities_style.dart';

/// A small drawing surface on the controller's coloured, translucent sheet,
/// built on the engine's [SimpleScribbleWidget].
///
/// The surface is [size] logical pixels and stroke coordinates are in that
/// space: when the view is given less room, the surface is scaled down rather
/// than cropped. A header offers clearing (and closing when [onClose] is set).
class NoteScratchpadView extends StatelessWidget {
  /// A drawing surface of [size] on [controller]'s sheet.
  const NoteScratchpadView({
    required this.controller,
    super.key,
    this.size = const Size(320, 240),
    this.showHeader = true,
    this.onClose,
    this.strings = const NoteStudyUtilitiesStrings(),
    this.style = const NoteStudyUtilitiesStyle(),
  });

  /// The sheet and its ink.
  final NoteScratchpadController controller;

  /// Logical size of the drawing surface.
  final Size size;

  /// Whether the title, clear and close buttons are shown.
  final bool showHeader;

  /// Shows a close button that calls this.
  final VoidCallback? onClose;

  /// Labels and messages.
  final NoteStudyUtilitiesStrings strings;

  /// Colors and sizes.
  final NoteStudyUtilitiesStyle style;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size.width,
    child: ListenableBuilder(
      listenable: controller,
      // Built once, so the engine widget is not rebuilt by sheet changes.
      child: _ScratchpadSurface(view: this),
      builder: (context, surface) => DecoratedBox(
        decoration: BoxDecoration(
          color: controller.color.withValues(alpha: controller.opacity),
          border: Border.all(color: style.border),
          borderRadius: BorderRadius.circular(style.cornerRadius),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showHeader) _ScratchpadHeader(view: this),
            surface!,
          ],
        ),
      ),
    ),
  );
}

class _ScratchpadHeader extends StatelessWidget {
  const _ScratchpadHeader({required this.view});

  final NoteScratchpadView view;

  @override
  Widget build(BuildContext context) {
    final strings = view.strings;
    final style = view.style;
    final close = view.onClose;

    return Padding(
      padding: EdgeInsets.all(style.spacing / 2),
      child: Row(
        children: [
          SizedBox(width: style.spacing / 2),
          Expanded(
            child: Text(
              strings.scratchpad,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style.text(),
            ),
          ),
          NoteUtilityButton(
            key: const ValueKey('scratchpad-clear'),
            text: strings.clear,
            semanticLabel: strings.clear,
            style: style,
            onPressed: view.controller.isEmpty ? null : view.controller.clear,
          ),
          if (close != null) ...[
            SizedBox(width: style.spacing / 2),
            NoteUtilityButton(
              key: const ValueKey('scratchpad-close'),
              text: strings.close,
              semanticLabel: strings.close,
              style: style,
              onPressed: close,
            ),
          ],
        ],
      ),
    );
  }
}

class _ScratchpadSurface extends StatelessWidget {
  const _ScratchpadSurface({required this.view});

  final NoteScratchpadView view;

  @override
  Widget build(BuildContext context) => Semantics(
    label: view.strings.scratchpadSurface,
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: SizedBox.fromSize(
        size: view.size,
        child: ClipRect(
          child: SimpleScribbleWidget(
            controller: view.controller.scribbleController,
            contentLogicalSize: view.size,
            panDirection: PanDirection.none,
            maxScale: 0,
            allowedPointersMode: ScribblePointerMode.all,
            child: SizedBox.fromSize(size: view.size),
          ),
        ),
      ),
    ),
  );
}

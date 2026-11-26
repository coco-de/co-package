import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/study/overlay/note_mask_cover_view.dart';
import 'package:open_note/src/note/study/overlay/note_mask_fill_image.dart';
import 'package:open_note/src/note/study/overlay/note_mask_style.dart';
import 'package:open_note/src/note/study/overlay/note_study_overlay_strings.dart';
import 'package:open_note/src/note/study/overlay/note_tape_object.dart';

/// Shows a [NoteTapeObject] filling its constraints (the object's bounds, laid
/// out by the hosting layer, which also applies rotation and opacity).
///
/// A tap on the tape peels it off or sticks it back by committing
/// `tape.copyWith(revealed: !tape.revealed)` through
/// [NoteObjectViewScope.onChanged]. Nothing happens, and the tape takes no
/// gesture, when the scope is not [NoteObjectViewScope.interactive] or has no
/// `onChanged`. Taps beside a straight tape fall through.
class NoteTapeView extends StatelessWidget {
  /// Shows [tape].
  const NoteTapeView({
    required this.tape,
    this.scope = const NoteObjectViewScope(),
    this.strings = const NoteStudyOverlayStrings(),
    this.style = const NoteMaskStyle(),
    this.imageResolver,
    super.key,
  });

  /// The tape to show.
  final NoteTapeObject tape;

  /// Interactivity and the change callback.
  final NoteObjectViewScope scope;

  /// Accessibility labels.
  final NoteStudyOverlayStrings strings;

  /// Outline, pattern and hit-test metrics.
  final NoteMaskStyle style;

  /// Resolves image fills.
  final NoteMaskImageResolver? imageResolver;

  @override
  Widget build(BuildContext context) {
    final onChanged = scope.interactive ? scope.onChanged : null;

    return NoteMaskCoverView(
      geometryFor: (area) =>
          tape.geometryIn(area, cornerRadius: style.cornerRadius),
      fill: tape.fill,
      fillOpacity: tape.fillOpacity,
      revealed: tape.revealed,
      fallbackSize: tape.bounds.size,
      semanticLabel: tape.revealed ? strings.hideTape : strings.revealTape,
      onToggle: onChanged == null
          ? null
          : () => onChanged(tape.copyWith(revealed: !tape.revealed)),
      style: style,
      imageResolver: imageResolver,
    );
  }
}

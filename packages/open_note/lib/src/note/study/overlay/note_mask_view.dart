import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/study/overlay/note_mask_cover_view.dart';
import 'package:open_note/src/note/study/overlay/note_mask_fill_image.dart';
import 'package:open_note/src/note/study/overlay/note_mask_object.dart';
import 'package:open_note/src/note/study/overlay/note_mask_style.dart';
import 'package:open_note/src/note/study/overlay/note_study_overlay_strings.dart';

/// Shows a [NoteMaskObject] filling its constraints (the object's bounds, laid
/// out by the hosting layer, which also applies rotation and opacity).
///
/// A tap on the mask commits `mask.copyWith(revealed: !mask.revealed)` through
/// [NoteObjectViewScope.onChanged]. Nothing happens, and the mask takes no
/// gesture, when the scope is not [NoteObjectViewScope.interactive] or has no
/// `onChanged`. Taps beside a stroke mask fall through.
class NoteMaskView extends StatelessWidget {
  /// Shows [mask].
  const NoteMaskView({
    required this.mask,
    this.scope = const NoteObjectViewScope(),
    this.strings = const NoteStudyOverlayStrings(),
    this.style = const NoteMaskStyle(),
    this.imageResolver,
    super.key,
  });

  /// The mask to show.
  final NoteMaskObject mask;

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
          mask.geometryIn(area, cornerRadius: style.cornerRadius),
      fill: mask.fill,
      fillOpacity: mask.fillOpacity,
      revealed: mask.revealed,
      fallbackSize: mask.bounds.size,
      semanticLabel: mask.revealed ? strings.hideMask : strings.revealMask,
      onToggle: onChanged == null
          ? null
          : () => onChanged(mask.copyWith(revealed: !mask.revealed)),
      style: style,
      imageResolver: imageResolver,
    );
  }
}

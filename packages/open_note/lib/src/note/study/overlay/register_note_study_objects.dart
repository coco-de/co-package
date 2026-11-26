import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/study/overlay/note_mask_fill_image.dart';
import 'package:open_note/src/note/study/overlay/note_mask_object.dart';
import 'package:open_note/src/note/study/overlay/note_mask_style.dart';
import 'package:open_note/src/note/study/overlay/note_mask_view.dart';
import 'package:open_note/src/note/study/overlay/note_study_overlay_strings.dart';
import 'package:open_note/src/note/study/overlay/note_tape_object.dart';
import 'package:open_note/src/note/study/overlay/note_tape_view.dart';

/// Registers the study object kinds, `mask` and `tape`, with [registry].
///
/// [strings] and [style] apply to the widgets built by the registry (export
/// through `paintToCanvas` uses the default style); [imageResolver] loads
/// image fills on screen.
void registerNoteStudyObjects(
  NoteObjectRegistry registry, {
  NoteStudyOverlayStrings strings = const NoteStudyOverlayStrings(),
  NoteMaskStyle style = const NoteMaskStyle(),
  NoteMaskImageResolver? imageResolver,
}) {
  registry
    ..register(
      NoteMaskObject.kindName,
      decoder: NoteMaskObject.fromPayload,
      builder: (context, object, scope) => object is NoteMaskObject
          ? NoteMaskView(
              mask: object,
              scope: scope,
              strings: strings,
              style: style,
              imageResolver: imageResolver,
            )
          : const SizedBox.shrink(),
    )
    ..register(
      NoteTapeObject.kindName,
      decoder: NoteTapeObject.fromPayload,
      builder: (context, object, scope) => object is NoteTapeObject
          ? NoteTapeView(
              tape: object,
              scope: scope,
              strings: strings,
              style: style,
              imageResolver: imageResolver,
            )
          : const SizedBox.shrink(),
    );
}

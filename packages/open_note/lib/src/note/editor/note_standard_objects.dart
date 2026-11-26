import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/objects/objects.dart';
import 'package:open_note/src/note/study/overlay/overlay.dart';
import 'package:open_note/src/note/table/table.dart';

/// A registry with every object kind the package ships: sticky notes, arrows,
/// link areas, stickers, tables, cover masks and tape.
///
/// Build one and share it between the editor, the document repository and
/// export. Give the editor the same [tableSelection], so its table toolbar acts
/// on the cells selected in the table views.
NoteObjectRegistry standardNoteObjectRegistry({
  NoteTableSelectionController? tableSelection,
  NoteObjectsStrings objectStrings = const NoteObjectsStrings(),
  NoteStickerImageResolver? stickerImageResolver,
  NoteTableStrings tableStrings = const NoteTableStrings(),
  NoteTableViewStyle tableStyle = const NoteTableViewStyle(),
  NoteStudyOverlayStrings studyStrings = const NoteStudyOverlayStrings(),
  NoteMaskStyle maskStyle = const NoteMaskStyle(),
  NoteMaskImageResolver? maskImageResolver,
}) {
  final registry = NoteObjectRegistry();
  registerNoteObjects(
    registry,
    strings: objectStrings,
    imageProviderResolver: stickerImageResolver,
  );
  registerNoteTableObject(
    registry,
    selectionController: tableSelection,
    strings: tableStrings,
    viewStyle: tableStyle,
  );
  registerNoteStudyObjects(
    registry,
    strings: studyStrings,
    style: maskStyle,
    imageResolver: maskImageResolver,
  );

  return registry;
}

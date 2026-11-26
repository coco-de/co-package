import 'package:open_note/src/note/core/note_json.dart';
import 'package:open_note/src/note/core/note_object.dart';
import 'package:open_note/src/note/objects/note_arrow_object.dart';
import 'package:open_note/src/note/objects/note_arrow_view.dart';
import 'package:open_note/src/note/objects/note_link_object.dart';
import 'package:open_note/src/note/objects/note_link_view.dart';
import 'package:open_note/src/note/objects/note_objects_strings.dart';
import 'package:open_note/src/note/objects/note_sticker_object.dart';
import 'package:open_note/src/note/objects/note_sticker_view.dart';
import 'package:open_note/src/note/objects/note_sticky_object.dart';
import 'package:open_note/src/note/objects/note_sticky_view.dart';

/// Registers the sticky note, arrow, link and sticker kinds in [registry].
///
/// [strings] is used by the widgets, and [imageProviderResolver] turns sticker
/// sources into images (by default the engine's `resolveImageSource`).
void registerNoteObjects(
  NoteObjectRegistry registry, {
  NoteObjectsStrings strings = const NoteObjectsStrings(),
  NoteStickerImageResolver? imageProviderResolver,
}) {
  registry
    ..register(
      NoteStickyObject.kindName,
      decoder: NoteStickyObject.decode,
      builder: (context, object, scope) => NoteStickyView(
        object: _typed(object, NoteStickyObject.decode),
        scope: scope,
        strings: strings,
      ),
    )
    ..register(
      NoteArrowObject.kindName,
      decoder: NoteArrowObject.decode,
      builder: (context, object, scope) =>
          NoteArrowView(object: _typed(object, NoteArrowObject.decode)),
    )
    ..register(
      NoteLinkObject.kindName,
      decoder: NoteLinkObject.decode,
      builder: (context, object, scope) => NoteLinkView(
        object: _typed(object, NoteLinkObject.decode),
        scope: scope,
      ),
    )
    ..register(
      NoteStickerObject.kindName,
      decoder: NoteStickerObject.decode,
      builder: (context, object, scope) => NoteStickerView(
        object: _typed(object, NoteStickerObject.decode),
        imageProviderResolver: imageProviderResolver,
      ),
    );
}

/// [object] as a `T`. An object decoded before its kind was registered is
/// still a [NoteUnknownObject]; it is decoded now from its raw JSON.
T _typed<T extends NoteObject>(
  NoteObject object,
  T Function(NoteObjectBase base, JsonMap payload) decode,
) => object is T
    ? object
    : decode(
        NoteObjectBase(
          id: object.id,
          bounds: object.bounds,
          rotation: object.rotation,
          opacity: object.opacity,
          locked: object.locked,
        ),
        object.payloadToJson(),
      );

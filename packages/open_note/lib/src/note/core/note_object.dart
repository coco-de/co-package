import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/core/note_json.dart';
import 'package:open_note/src/note/core/note_link_target.dart';

/// A note-level object laid over a page in page coordinates: sticky notes,
/// tables, masks, tape, link hotspots, stickers…
///
/// Objects are *not* ink. They live beside the page's layers, are persisted
/// with the page as JSON, and are drawn by widgets registered in a
/// [NoteObjectRegistry]. Every object is an immutable value; an edit produces a
/// copy.
///
/// Implementing a kind: extend [NoteObject], give it a unique [kind], write
/// `payloadToJson`, and register a decoder plus a widget builder with
/// [NoteObjectRegistry.register].
@immutable
abstract class NoteObject {
  const NoteObject({
    required this.id,
    required this.bounds,
    this.rotation = 0,
    this.opacity = 1,
    this.locked = false,
  });

  /// Stable identifier, unique within a page.
  final String id;

  /// Axis-aligned bounds *before* [rotation], in page logical coordinates.
  final Rect bounds;

  /// Clockwise rotation in radians about `bounds.center`.
  final double rotation;

  /// 0 (transparent) to 1 (opaque).
  final double opacity;

  /// A locked object cannot be moved, resized, rotated or deleted by gestures.
  final bool locked;

  /// Unique key of this kind, e.g. `sticky`. Persisted, so never rename it.
  String get kind;

  /// A copy with the shared fields replaced; every other field is kept.
  NoteObject withBase({
    Rect? bounds,
    double? rotation,
    double? opacity,
    bool? locked,
  });

  /// Kind-specific fields only (the shared fields are written by [toJson]).
  JsonMap payloadToJson();

  /// Paints this object onto [canvas] in page coordinates. Used by export and
  /// region capture where widgets are not available. The canvas is already
  /// translated/rotated/faded for [bounds], [rotation] and [opacity]; draw in
  /// the unrotated `bounds` rectangle. Painting is synchronous, so any image
  /// must already be decoded and reachable through [context]. Default: draws
  /// nothing.
  void paintToCanvas(ui.Canvas canvas, NoteObjectPaintContext context) {}

  /// The link this object activates when tapped, if any.
  NoteLinkTarget? get linkTarget => null;

  /// Persisted form: `{kind, id, bounds, rotation, opacity, locked, payload}`.
  JsonMap toJson() => {
    'kind': kind,
    'id': id,
    'bounds': NoteJson.rectToJson(bounds),
    'rotation': rotation,
    'opacity': opacity,
    'locked': locked,
    'payload': payloadToJson(),
  };
}

/// The shared fields of a decoded object, handed to a [NoteObjectDecoder].
@immutable
class NoteObjectBase {
  const NoteObjectBase({
    required this.id,
    required this.bounds,
    required this.rotation,
    required this.opacity,
    required this.locked,
  });

  final String id;
  final Rect bounds;
  final double rotation;
  final double opacity;
  final bool locked;
}

/// Rebuilds one object kind from its [base] fields and kind-specific [payload].
typedef NoteObjectDecoder =
    NoteObject Function(NoteObjectBase base, JsonMap payload);

/// Resolves the decoded image for a source string (a sticker's file path or
/// URL), or `null` when it has not been loaded.
typedef NoteImageLookup = ui.Image? Function(String source);

/// What [NoteObject.paintToCanvas] may use besides the canvas.
@immutable
class NoteObjectPaintContext {
  const NoteObjectPaintContext({this.imageLookup});

  /// An empty context: no image is available.
  static const NoteObjectPaintContext empty = NoteObjectPaintContext();

  /// Looks up an already-decoded image by source string.
  final NoteImageLookup? imageLookup;

  /// The decoded image for [source], or `null`.
  ui.Image? imageFor(String source) => imageLookup?.call(source);
}

/// What a widget needs to know to draw and edit one object.
@immutable
class NoteObjectViewScope {
  const NoteObjectViewScope({
    this.selected = false,
    this.editing = false,
    this.interactive = true,
    this.onChanged,
    this.onLinkActivated,
    this.onRequestEdit,
  });

  /// Whether the object is currently selected in its layer.
  final bool selected;

  /// Whether the object is in an inline editing session (a sticky note shows
  /// its text field, a table shows a cell editor).
  final bool editing;

  /// Whether taps and edits reach the object (false in read-only views).
  final bool interactive;

  /// Commits a changed copy of the object (for example a mask toggling its
  /// revealed state, or a sticky note's edited text). The hosting layer records
  /// it in the undo history.
  final ValueChanged<NoteObject>? onChanged;

  /// Called when the user activates a link on the object.
  final ValueChanged<NoteLinkTarget>? onLinkActivated;

  /// Asks the host to start an editing session for the object (for example to
  /// open a text field over a sticky note).
  final VoidCallback? onRequestEdit;
}

/// Builds the widget that draws [object]. The widget is laid out inside
/// `object.bounds` and rotated/faded by the hosting layer, so it should fill
/// its constraints.
typedef NoteObjectWidgetBuilder =
    Widget Function(
      BuildContext context,
      NoteObject object,
      NoteObjectViewScope scope,
    );

/// An object whose kind is not registered (written by a newer version or by a
/// host plugin that is not installed). It keeps the raw JSON so saving the page
/// does not destroy it.
@immutable
class NoteUnknownObject extends NoteObject {
  const NoteUnknownObject({
    required super.id,
    required super.bounds,
    required this.unknownKind,
    required this.payload,
    super.rotation,
    super.opacity,
    super.locked,
  });

  /// The `kind` string found in the document.
  final String unknownKind;

  /// The untouched kind-specific JSON.
  final JsonMap payload;

  @override
  String get kind => unknownKind;

  @override
  NoteUnknownObject withBase({
    Rect? bounds,
    double? rotation,
    double? opacity,
    bool? locked,
  }) => NoteUnknownObject(
    id: id,
    bounds: bounds ?? this.bounds,
    unknownKind: unknownKind,
    payload: payload,
    rotation: rotation ?? this.rotation,
    opacity: opacity ?? this.opacity,
    locked: locked ?? this.locked,
  );

  @override
  JsonMap payloadToJson() => payload;
}

/// Maps `kind` strings to decoders and widget builders.
///
/// The registry is an ordinary object (not a global): a host builds one with
/// the kinds it wants — `NoteObjectRegistry.standard()` registers every kind
/// the package ships — and passes it to the layer and the page repository.
class NoteObjectRegistry {
  NoteObjectRegistry();

  final Map<String, NoteObjectDecoder> _decoders = {};
  final Map<String, NoteObjectWidgetBuilder> _builders = {};

  /// Registered kinds.
  Iterable<String> get kinds => _decoders.keys;

  /// Registers [kind]. A second registration replaces the first (hosts use
  /// this to override a built-in kind).
  void register(
    String kind, {
    required NoteObjectDecoder decoder,
    required NoteObjectWidgetBuilder builder,
  }) {
    _decoders[kind] = decoder;
    _builders[kind] = builder;
  }

  /// Whether [kind] is registered.
  bool isRegistered(String kind) => _decoders.containsKey(kind);

  /// Rebuilds an object from its [toJson] form. Unknown kinds come back as a
  /// [NoteUnknownObject] so no data is lost; a document that is not an object
  /// at all yields `null`.
  NoteObject? decode(Object? value) {
    final json = NoteJson.asMap(value);
    if (json == null) return null;
    final kind = NoteJson.string(json, 'kind');
    final id = NoteJson.string(json, 'id');
    if (kind.isEmpty || id.isEmpty) return null;
    final base = NoteObjectBase(
      id: id,
      bounds: NoteJson.rect(json, 'bounds'),
      rotation: NoteJson.number(json, 'rotation'),
      opacity: NoteJson.number(json, 'opacity', 1).clamp(0.0, 1.0),
      locked: NoteJson.boolean(json, 'locked'),
    );
    final payload = NoteJson.map(json, 'payload');
    final decoder = _decoders[kind];
    if (decoder == null) {
      return NoteUnknownObject(
        id: base.id,
        bounds: base.bounds,
        unknownKind: kind,
        payload: payload,
        rotation: base.rotation,
        opacity: base.opacity,
        locked: base.locked,
      );
    }

    return decoder(base, payload);
  }

  /// Decodes a list of objects, dropping malformed entries.
  List<NoteObject> decodeAll(Iterable<Object?> values) => [
    for (final value in values)
      if (decode(value) case final NoteObject object) object,
  ];

  /// Builds the widget for [object]. A kind without a builder (including
  /// [NoteUnknownObject]) renders as a labelled placeholder.
  Widget buildView(
    BuildContext context,
    NoteObject object,
    NoteObjectViewScope scope,
  ) {
    final builder = _builders[object.kind];
    if (builder == null) return _UnknownObjectView(kind: object.kind);

    return builder(context, object, scope);
  }
}

class _UnknownObjectView extends StatelessWidget {
  const _UnknownObjectView({required this.kind});

  final String kind;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      border: Border.all(color: const Color(0xFF9E9E9E)),
      color: const Color(0x14000000),
    ),
    child: Center(
      child: Text(
        kind,
        textDirection: TextDirection.ltr,
        style: const TextStyle(color: Color(0xFF616161), fontSize: 11),
      ),
    ),
  );
}

import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/core/note_json.dart';
import 'package:open_note/src/note/core/note_link_target.dart';
import 'package:open_note/src/note/core/note_object.dart';
import 'package:open_note/src/note/objects/internal/note_link_painting.dart';
import 'package:open_note/src/note/objects/note_object_geometry.dart';
import 'package:open_note/src/note/objects/note_reidentifiable_object.dart';

/// A tappable area that follows a link, placed over text or a drawing.
///
/// JSON payload (the `payload` of [NoteObject.toJson]):
///
/// ```text
/// {"target": String,       // the NoteLinkTarget wire form, e.g. "page:3"
///  "appearance": "hidden"|"outline"|"underline",
///  "color": int}           // 32-bit ARGB of the frame or underline
/// ```
///
/// [NoteLinkObject.decode] never throws: a missing, mistyped or unknown value
/// takes its default. A target that does not parse is kept as it is; tapping it
/// does nothing.
@immutable
class NoteLinkObject extends NoteObject implements NoteReidentifiableObject {
  /// The `kind` of link hotspots.
  static const String kindName = 'link';

  /// Link blue.
  static const Color defaultColor = Color(0xFF2962FF);

  /// The link's wire form (see [NoteLinkTarget]).
  final String target;

  /// How the area looks.
  final NoteLinkAppearance appearance;

  /// Colour of the frame or underline.
  final Color color;

  const NoteLinkObject({
    required super.id,
    required super.bounds,
    this.target = '',
    this.appearance = NoteLinkAppearance.outline,
    this.color = defaultColor,
    super.rotation,
    super.opacity,
    super.locked,
  });

  /// Rebuilds a link hotspot from its [base] fields and [payload].
  factory NoteLinkObject.decode(NoteObjectBase base, JsonMap payload) =>
      NoteLinkObject(
        id: base.id,
        bounds: NoteObjectGeometry.normalizeRect(base.bounds),
        rotation: base.rotation,
        opacity: base.opacity,
        locked: base.locked,
        target: NoteJson.string(payload, 'target'),
        appearance: NoteJson.enumByName(
          NoteLinkAppearance.values,
          payload['appearance'],
          NoteLinkAppearance.outline,
        ),
        color: NoteJson.color(payload, 'color', defaultColor),
      );

  @override
  String get kind => kindName;

  /// The parsed [target], or `null` when it is blank or malformed.
  @override
  NoteLinkTarget? get linkTarget => NoteLinkTarget.parse(target);

  @override
  int get hashCode => Object.hash(
    id,
    bounds,
    rotation,
    opacity,
    locked,
    target,
    appearance,
    color,
  );

  /// A copy with the given fields replaced; the [id] is kept.
  NoteLinkObject copyWith({
    Rect? bounds,
    double? rotation,
    double? opacity,
    bool? locked,
    String? target,
    NoteLinkAppearance? appearance,
    Color? color,
  }) => NoteLinkObject(
    id: id,
    bounds: bounds ?? this.bounds,
    rotation: rotation ?? this.rotation,
    opacity: opacity ?? this.opacity,
    locked: locked ?? this.locked,
    target: target ?? this.target,
    appearance: appearance ?? this.appearance,
    color: color ?? this.color,
  );

  @override
  NoteLinkObject withBase({
    Rect? bounds,
    double? rotation,
    double? opacity,
    bool? locked,
  }) => copyWith(
    bounds: bounds,
    rotation: rotation,
    opacity: opacity,
    locked: locked,
  );

  @override
  NoteLinkObject withId(String id) => NoteLinkObject(
    id: id,
    bounds: bounds,
    rotation: rotation,
    opacity: opacity,
    locked: locked,
    target: target,
    appearance: appearance,
    color: color,
  );

  @override
  JsonMap payloadToJson() => {
    'target': target,
    'appearance': appearance.name,
    'color': NoteJson.colorToJson(color),
  };

  @override
  void paintToCanvas(ui.Canvas canvas, NoteObjectPaintContext context) =>
      NoteLinkPainting.paint(canvas, bounds, appearance, color);

  @override
  bool operator ==(Object other) =>
      other is NoteLinkObject &&
      other.runtimeType == runtimeType &&
      other.id == id &&
      other.bounds == bounds &&
      other.rotation == rotation &&
      other.opacity == opacity &&
      other.locked == locked &&
      other.target == target &&
      other.appearance == appearance &&
      other.color == color;

  @override
  String toString() => 'NoteLinkObject($id, $bounds, $target)';
}

/// How a [NoteLinkObject] looks. The names are persisted.
enum NoteLinkAppearance {
  /// Invisible: only the tappable area (edit mode still outlines it).
  hidden,

  /// A thin rounded frame around the area.
  outline,

  /// A line along the bottom of the area.
  underline,
}

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/study/overlay/note_mask_cover_painter.dart';
import 'package:open_note/src/note/study/overlay/note_mask_fill.dart';
import 'package:open_note/src/note/study/overlay/note_mask_geometry.dart';
import 'package:open_note/src/note/study/overlay/note_mask_object.dart';
import 'package:open_note/src/note/study/overlay/note_mask_style.dart';

/// The outline of a [NoteTapeObject]. The `name`s are persisted.
enum NoteTapeShape {
  /// A straight strip with flat ends from [NoteTapeObject.start] to
  /// [NoteTapeObject.end].
  straight,

  /// A rectangle covering the whole `bounds`.
  rect,
}

/// A strip of cover-up tape: it hides part of a page until a tap peels it off,
/// and a second tap sticks it back (see `NoteTapeView`).
///
/// A [NoteTapeShape.rect] tape covers [bounds]. A [NoteTapeShape.straight] tape
/// is [thickness] page units wide from [start] to [end], which are
/// **fractions (0–1) of the centre-line box** — [bounds] shrunk by half the
/// thickness on every side — so moving or resizing [bounds] moves and
/// stretches the tape, which never leaves [bounds] (a box thinner than the
/// tape draws it thinner). Build one from page points with
/// [NoteTapeObject.straight] and read them back with [pageStart]/[pageEnd].
///
/// A [locked] tape can still be peeled and stuck back.
///
/// JSON payload: `{"shape": "straight"|"rect", "start": {"x", "y"}, "end":
/// {"x", "y"}, "thickness": 2–120, "fill": NoteMaskFill, "fillOpacity": 0–1,
/// "revealed": bool}`. Reading never fails: values are clamped, unknown names
/// fall back to `rect`, and a straight tape without both ends becomes a `rect`
/// tape.
@immutable
class NoteTapeObject extends NoteObject {
  /// Creates a tape. [thickness], [fillOpacity], [start] and [end] are clamped
  /// into range.
  NoteTapeObject({
    required super.id,
    required super.bounds,
    this.shape = NoteTapeShape.rect,
    Offset start = defaultStart,
    Offset end = defaultEnd,
    double thickness = defaultThickness,
    this.fill = defaultFill,
    double fillOpacity = 1,
    this.revealed = false,
    super.rotation,
    super.opacity,
    super.locked,
  }) : start = NoteMaskGeometry.clampFraction(start),
       end = NoteMaskGeometry.clampFraction(end),
       thickness = _clampThickness(thickness),
       fillOpacity = fillOpacity.clamp(0.0, 1.0);

  /// A straight tape from [pageStart] to [pageEnd] (page coordinates). Its
  /// [bounds] are the two points' bounding box grown by half the thickness.
  factory NoteTapeObject.straight({
    required String id,
    required Offset pageStart,
    required Offset pageEnd,
    double thickness = defaultThickness,
    NoteMaskFill fill = defaultFill,
    double fillOpacity = 1,
  }) {
    final width = _clampThickness(thickness);
    final bounds = Rect.fromPoints(pageStart, pageEnd).inflate(width / 2);
    final box = NoteMaskGeometry.centerLineBox(bounds, width);

    return NoteTapeObject(
      id: id,
      bounds: bounds,
      shape: NoteTapeShape.straight,
      start: NoteMaskGeometry.toFraction(pageStart, box),
      end: NoteMaskGeometry.toFraction(pageEnd, box),
      thickness: width,
      fill: fill,
      fillOpacity: fillOpacity,
    );
  }

  /// Rebuilds a tape from [payloadToJson] output (the registry decoder).
  factory NoteTapeObject.fromPayload(NoteObjectBase base, JsonMap payload) {
    final start = NoteMaskGeometry.fractionFromJson(payload['start']);
    final end = NoteMaskGeometry.fractionFromJson(payload['end']);
    final shape = NoteJson.enumByName(
      NoteTapeShape.values,
      payload['shape'],
      NoteTapeShape.rect,
    );
    final hasEnds = start != null && end != null;

    return NoteTapeObject(
      id: base.id,
      bounds: base.bounds,
      rotation: base.rotation,
      opacity: base.opacity,
      locked: base.locked,
      shape: hasEnds ? shape : NoteTapeShape.rect,
      start: start ?? defaultStart,
      end: end ?? defaultEnd,
      thickness: NoteJson.number(payload, 'thickness', defaultThickness),
      fill: NoteMaskFill.fromJson(payload['fill'], defaultFill),
      fillOpacity: NoteJson.number(payload, 'fillOpacity', 1),
      revealed: NoteJson.boolean(payload, 'revealed'),
    );
  }

  /// The persisted object kind.
  static const String kindName = 'tape';

  /// Default width of a straight tape, page units. The range is that of
  /// [NoteMaskObject.minThickness] to [NoteMaskObject.maxThickness].
  static const double defaultThickness = 22;

  /// Default left end of the centre line.
  static const Offset defaultStart = Offset(0, 0.5);

  /// Default right end of the centre line.
  static const Offset defaultEnd = Offset(1, 0.5);

  /// Default look: soft striped masking tape.
  static const NoteMaskFill defaultFill = NoteMaskFill.stripes(
    color: Color(0xFFFFCC80),
  );

  /// Whether the tape is a straight strip or a rectangle.
  final NoteTapeShape shape;

  /// First end of a straight tape, as a fraction of the centre-line box.
  final Offset start;

  /// Second end of a straight tape, as a fraction of the centre-line box.
  final Offset end;

  /// Width of a straight tape in page units.
  final double thickness;

  /// Colour and pattern.
  final NoteMaskFill fill;

  /// Opacity of the fill, 0 to 1.
  final double fillOpacity;

  /// Whether the tape is peeled off (only a faint outline shows).
  final bool revealed;

  static double _clampThickness(double thickness) => thickness.isFinite
      ? thickness.clamp(
          NoteMaskObject.minThickness,
          NoteMaskObject.maxThickness,
        )
      : defaultThickness;

  @override
  String get kind => kindName;

  /// The image the fill needs decoded, if any.
  String? get imageSource => fill.imageSource;

  /// [start] in page coordinates, ignoring [rotation].
  Offset get pageStart => NoteMaskGeometry.fromFraction(start, _pageBox);

  /// [end] in page coordinates, ignoring [rotation].
  Offset get pageEnd => NoteMaskGeometry.fromFraction(end, _pageBox);

  Rect get _pageBox => NoteMaskGeometry.centerLineBox(
    bounds,
    math.min(thickness, bounds.shortestSide),
  );

  /// The covered shape when the tape is laid out in [area] (`bounds` for
  /// export, the widget's local rectangle on screen).
  NoteMaskGeometry geometryIn(
    Rect area, {
    double cornerRadius = NoteMaskStyle.defaultCornerRadius,
  }) {
    if (shape == NoteTapeShape.rect) {
      return NoteMaskRectGeometry(area, cornerRadius: cornerRadius);
    }
    final width = math.min(thickness, area.shortestSide);
    final box = NoteMaskGeometry.centerLineBox(area, width);

    return NoteMaskQuadGeometry.strip(
      NoteMaskGeometry.fromFraction(start, box),
      NoteMaskGeometry.fromFraction(end, box),
      width,
    );
  }

  /// A copy with the given fields replaced.
  NoteTapeObject copyWith({
    String? id,
    Rect? bounds,
    double? rotation,
    double? opacity,
    bool? locked,
    NoteTapeShape? shape,
    Offset? start,
    Offset? end,
    double? thickness,
    NoteMaskFill? fill,
    double? fillOpacity,
    bool? revealed,
  }) => NoteTapeObject(
    id: id ?? this.id,
    bounds: bounds ?? this.bounds,
    rotation: rotation ?? this.rotation,
    opacity: opacity ?? this.opacity,
    locked: locked ?? this.locked,
    shape: shape ?? this.shape,
    start: start ?? this.start,
    end: end ?? this.end,
    thickness: thickness ?? this.thickness,
    fill: fill ?? this.fill,
    fillOpacity: fillOpacity ?? this.fillOpacity,
    revealed: revealed ?? this.revealed,
  );

  @override
  NoteTapeObject withBase({
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
  JsonMap payloadToJson() => {
    'shape': shape.name,
    'start': NoteJson.offsetToJson(start),
    'end': NoteJson.offsetToJson(end),
    'thickness': thickness,
    'fill': fill.toJson(),
    'fillOpacity': fillOpacity,
    'revealed': revealed,
  };

  /// Paints the tape as it looks on screen (a peeled tape exports as its faint
  /// outline). An image fill needs the picture in [context].
  @override
  void paintToCanvas(ui.Canvas canvas, NoteObjectPaintContext context) {
    final source = imageSource;
    NoteMaskCoverPainter.paintCover(
      canvas,
      geometry: geometryIn(bounds),
      fill: fill,
      fillOpacity: fillOpacity,
      revealed: revealed,
      image: source == null ? null : context.imageFor(source),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is NoteTapeObject &&
      other.id == id &&
      other.bounds == bounds &&
      other.rotation == rotation &&
      other.opacity == opacity &&
      other.locked == locked &&
      other.shape == shape &&
      other.start == start &&
      other.end == end &&
      other.thickness == thickness &&
      other.fill == fill &&
      other.fillOpacity == fillOpacity &&
      other.revealed == revealed;

  @override
  int get hashCode => Object.hash(
    id,
    bounds,
    rotation,
    opacity,
    locked,
    shape,
    start,
    end,
    thickness,
    fill,
    fillOpacity,
    revealed,
  );

  @override
  String toString() =>
      'NoteTapeObject($id, ${shape.name}, revealed: $revealed, $bounds)';
}

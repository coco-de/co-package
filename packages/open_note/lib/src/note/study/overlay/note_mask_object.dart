import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/study/overlay/note_mask_cover_painter.dart';
import 'package:open_note/src/note/study/overlay/note_mask_fill.dart';
import 'package:open_note/src/note/study/overlay/note_mask_geometry.dart';
import 'package:open_note/src/note/study/overlay/note_mask_style.dart';

/// The outline of a [NoteMaskObject]. The `name`s are persisted.
enum NoteMaskShape {
  /// Covers the whole `bounds` rectangle.
  rect,

  /// A thick freehand stroke along [NoteMaskObject.points].
  stroke,
}

/// Which pages show a [NoteMaskObject]. The `name`s are persisted.
enum NoteMaskScope {
  /// Only the page that holds the mask.
  page,

  /// Every page of the note: the host's document layer repeats it.
  document,
}

/// A cover-up mask for memorising: it hides part of a page until a tap lifts
/// it, and a second tap covers it again (see `NoteMaskView`).
///
/// [bounds] and [rotation] place the mask on the page. A [NoteMaskShape.rect]
/// mask covers all of [bounds]. A [NoteMaskShape.stroke] mask is a round-capped
/// line, [thickness] page units wide, through [points]. The points are
/// **fractions (0–1) of the centre-line box** — [bounds] shrunk by half the
/// thickness on every side — so moving or resizing [bounds] moves and
/// stretches the stroke, which never leaves [bounds] (a box thinner than the
/// stroke draws it thinner). Build one from page points with
/// [NoteMaskObject.stroke] and read them back with [pagePoints].
///
/// [fillOpacity] fades the fill only; the inherited [opacity] fades the whole
/// object. A [locked] mask can still be revealed and covered.
///
/// JSON payload: `{"shape": "rect"|"stroke", "points": [{"x": 0–1, "y":
/// 0–1}], "thickness": 2–120, "fill": NoteMaskFill, "fillOpacity": 0–1,
/// "revealed": bool, "scope": "page"|"document"}`. Reading never fails: values
/// are clamped, bad points are skipped, unknown names fall back to `rect` /
/// `page`, and a stroke without any valid point becomes a `rect` mask, so it
/// still hides what it hid.
@immutable
class NoteMaskObject extends NoteObject {
  /// Creates a mask. [thickness] and [fillOpacity] are clamped into range and
  /// [points] into 0–1; the list is copied.
  NoteMaskObject({
    required super.id,
    required super.bounds,
    this.shape = NoteMaskShape.rect,
    List<Offset> points = const [],
    double thickness = defaultThickness,
    this.fill = const NoteMaskFill(),
    double fillOpacity = 1,
    this.revealed = false,
    this.scope = NoteMaskScope.page,
    super.rotation,
    super.opacity,
    super.locked,
  }) : points = List.unmodifiable(points.map(NoteMaskGeometry.clampFraction)),
       thickness = clampThickness(thickness),
       fillOpacity = fillOpacity.clamp(0.0, 1.0);

  /// A stroke mask through [pagePoints] (page coordinates, at least one). Its
  /// [bounds] are the points' bounding box grown by half the thickness.
  ///
  /// Throws an [ArgumentError] when [pagePoints] is empty.
  factory NoteMaskObject.stroke({
    required String id,
    required List<Offset> pagePoints,
    double thickness = defaultThickness,
    NoteMaskFill fill = const NoteMaskFill(),
    double fillOpacity = 1,
    NoteMaskScope scope = NoteMaskScope.page,
  }) {
    if (pagePoints.isEmpty) {
      throw ArgumentError.value(pagePoints, 'pagePoints', 'must not be empty');
    }
    final width = clampThickness(thickness);
    final line = NoteMaskGeometry.boundsOf(pagePoints);
    final bounds = line.inflate(width / 2);
    final box = NoteMaskGeometry.centerLineBox(bounds, width);

    return NoteMaskObject(
      id: id,
      bounds: bounds,
      shape: NoteMaskShape.stroke,
      points: [
        for (final point in pagePoints) NoteMaskGeometry.toFraction(point, box),
      ],
      thickness: width,
      fill: fill,
      fillOpacity: fillOpacity,
      scope: scope,
    );
  }

  /// Rebuilds a mask from [payloadToJson] output (the registry decoder).
  factory NoteMaskObject.fromPayload(NoteObjectBase base, JsonMap payload) {
    final points = [
      for (final entry in NoteJson.list(payload, 'points'))
        if (NoteMaskGeometry.fractionFromJson(entry) case final Offset point)
          point,
    ];
    final shape = NoteJson.enumByName(
      NoteMaskShape.values,
      payload['shape'],
      NoteMaskShape.rect,
    );

    return NoteMaskObject(
      id: base.id,
      bounds: base.bounds,
      rotation: base.rotation,
      opacity: base.opacity,
      locked: base.locked,
      shape: points.isEmpty ? NoteMaskShape.rect : shape,
      points: points,
      thickness: NoteJson.number(payload, 'thickness', defaultThickness),
      fill: NoteMaskFill.fromJson(payload['fill']),
      fillOpacity: NoteJson.number(payload, 'fillOpacity', 1),
      revealed: NoteJson.boolean(payload, 'revealed'),
      scope: NoteJson.enumByName(
        NoteMaskScope.values,
        payload['scope'],
        NoteMaskScope.page,
      ),
    );
  }

  /// The persisted object kind.
  static const String kindName = 'mask';

  /// Narrowest stroke, page units.
  static const double minThickness = 2;

  /// Widest stroke, page units.
  static const double maxThickness = 120;

  /// Default stroke width, page units.
  static const double defaultThickness = 24;

  /// Whether the mask is a rectangle or a stroke.
  final NoteMaskShape shape;

  /// Stroke centre line as fractions of the centre-line box (unmodifiable;
  /// ignored by rectangular masks).
  final List<Offset> points;

  /// Stroke width in page units, [minThickness] to [maxThickness].
  final double thickness;

  /// How the hidden mask is painted.
  final NoteMaskFill fill;

  /// Opacity of the fill, 0 to 1.
  final double fillOpacity;

  /// Whether the mask is lifted (only a faint outline shows).
  final bool revealed;

  /// Whether only this page or every page shows the mask.
  final NoteMaskScope scope;

  /// [thickness] limited to the allowed range (non-finite → the default).
  static double clampThickness(double thickness) => thickness.isFinite
      ? thickness.clamp(minThickness, maxThickness)
      : defaultThickness;

  @override
  String get kind => kindName;

  /// The image the fill needs decoded, if any.
  String? get imageSource => fill.imageSource;

  /// [points] in page coordinates, ignoring [rotation].
  List<Offset> get pagePoints {
    final width = math.min(thickness, bounds.shortestSide);
    final box = NoteMaskGeometry.centerLineBox(bounds, width);

    return [
      for (final point in points) NoteMaskGeometry.fromFraction(point, box),
    ];
  }

  /// The covered shape when the mask is laid out in [area] (`bounds` for
  /// export, the widget's local rectangle on screen).
  NoteMaskGeometry geometryIn(
    Rect area, {
    double cornerRadius = NoteMaskStyle.defaultCornerRadius,
  }) {
    if (shape == NoteMaskShape.rect || points.isEmpty) {
      return NoteMaskRectGeometry(area, cornerRadius: cornerRadius);
    }
    final width = math.min(thickness, area.shortestSide);
    final box = NoteMaskGeometry.centerLineBox(area, width);

    return NoteMaskStrokeGeometry([
      for (final point in points) NoteMaskGeometry.fromFraction(point, box),
    ], width);
  }

  /// A copy with the given fields replaced.
  NoteMaskObject copyWith({
    String? id,
    Rect? bounds,
    double? rotation,
    double? opacity,
    bool? locked,
    NoteMaskShape? shape,
    List<Offset>? points,
    double? thickness,
    NoteMaskFill? fill,
    double? fillOpacity,
    bool? revealed,
    NoteMaskScope? scope,
  }) => NoteMaskObject(
    id: id ?? this.id,
    bounds: bounds ?? this.bounds,
    rotation: rotation ?? this.rotation,
    opacity: opacity ?? this.opacity,
    locked: locked ?? this.locked,
    shape: shape ?? this.shape,
    points: points ?? this.points,
    thickness: thickness ?? this.thickness,
    fill: fill ?? this.fill,
    fillOpacity: fillOpacity ?? this.fillOpacity,
    revealed: revealed ?? this.revealed,
    scope: scope ?? this.scope,
  );

  @override
  NoteMaskObject withBase({
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
    'points': [for (final point in points) NoteJson.offsetToJson(point)],
    'thickness': thickness,
    'fill': fill.toJson(),
    'fillOpacity': fillOpacity,
    'revealed': revealed,
    'scope': scope.name,
  };

  /// Paints the mask as it looks on screen (a revealed mask exports as its
  /// faint outline). An image fill needs the picture in [context].
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
      other is NoteMaskObject &&
      other.id == id &&
      other.bounds == bounds &&
      other.rotation == rotation &&
      other.opacity == opacity &&
      other.locked == locked &&
      other.shape == shape &&
      listEquals(other.points, points) &&
      other.thickness == thickness &&
      other.fill == fill &&
      other.fillOpacity == fillOpacity &&
      other.revealed == revealed &&
      other.scope == scope;

  @override
  int get hashCode => Object.hash(
    id,
    bounds,
    rotation,
    opacity,
    locked,
    shape,
    Object.hashAll(points),
    thickness,
    fill,
    fillOpacity,
    revealed,
    scope,
  );

  @override
  String toString() =>
      'NoteMaskObject($id, ${shape.name}, revealed: $revealed, $bounds)';
}

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/core/note_json.dart';
import 'package:open_note/src/note/core/note_object.dart';
import 'package:open_note/src/note/objects/internal/note_arrow_painting.dart';
import 'package:open_note/src/note/objects/note_object_geometry.dart';
import 'package:open_note/src/note/objects/note_reidentifiable_object.dart';

/// An arrow from [start] to [end], straight or bent through [bend] into a
/// curve (a quadratic Bézier whose middle passes through [bend]).
///
/// [start], [end] and [bend] are fractions of [bounds] (`(0, 0)` is its top left,
/// `(1, 1)` its bottom right), so moving, resizing and rotating the object
/// through its bounds carries the arrow along. [width] is in page units.
///
/// JSON payload (the `payload` of [NoteObject.toJson]):
///
/// ```text
/// {"start": {"x": num, "y": num},  // fractions, clamped to 0–1
///  "end": {"x": num, "y": num},    // fractions, clamped to 0–1
///  "color": int,                   // 32-bit ARGB
///  "width": num,                   // clamped to 0.5–64
///  "headStyle": "none"|"triangle"|"open",
///  "tailStyle": "none"|"triangle"|"open",
///  "dashed": bool,
///  "bend": {"x": num, "y": num}}   // optional; absent is straight
/// ```
///
/// [NoteArrowObject.decode] never throws: a missing, mistyped or unknown value
/// takes its default.
@immutable
class NoteArrowObject extends NoteObject implements NoteReidentifiableObject {
  /// The `kind` of arrows.
  static const String kindName = 'arrow';

  /// The default [start]: the middle of the left side.
  static const Offset defaultStart = Offset(0, 0.5);

  /// The default [end]: the middle of the right side.
  static const Offset defaultEnd = Offset(1, 0.5);

  /// Near-black.
  static const Color defaultColor = Color(0xFF212121);

  /// The default [width].
  static const double defaultWidth = 3;

  /// The thinnest line drawn.
  static const double minWidth = 0.5;

  /// The thickest line drawn.
  static const double maxWidth = 64;

  /// Where the line begins, as a fraction of [bounds].
  final Offset start;

  /// Where the line ends (the head), as a fraction of [bounds].
  final Offset end;

  /// Colour of the line and both caps.
  final Color color;

  /// Line width in page units; drawn clamped to [minWidth]–[maxWidth].
  final double width;

  /// The cap at [end].
  final NoteArrowCap headStyle;

  /// The cap at [start].
  final NoteArrowCap tailStyle;

  /// Whether the line is dashed.
  final bool dashed;

  /// Where the middle of a curved line passes, as a fraction of [bounds];
  /// null keeps the line straight.
  final Offset? bend;

  const NoteArrowObject({
    required super.id,
    required super.bounds,
    this.start = defaultStart,
    this.end = defaultEnd,
    this.color = defaultColor,
    this.width = defaultWidth,
    this.headStyle = NoteArrowCap.triangle,
    this.tailStyle = NoteArrowCap.none,
    this.dashed = false,
    this.bend,
    super.rotation,
    super.opacity,
    super.locked,
  });

  /// An arrow from page point [from] to page point [to], curved so that its
  /// middle passes through [through] when given. Its bounds enclose the line,
  /// each side at least [NoteObjectGeometry.minimumSize].
  factory NoteArrowObject.fromPoints({
    required String id,
    required Offset from,
    required Offset to,
    Color color = defaultColor,
    double width = defaultWidth,
    NoteArrowCap headStyle = NoteArrowCap.triangle,
    NoteArrowCap tailStyle = NoteArrowCap.none,
    bool dashed = false,
    Offset? through,
  }) {
    final bounds = NoteObjectGeometry.normalizeRect(
      _enclose(from, through, to),
      minimum: NoteObjectGeometry.minimumSize,
    );
    Offset fractionOf(Offset point) => _clampFraction(
      Offset(
        (point.dx - bounds.left) / bounds.width,
        (point.dy - bounds.top) / bounds.height,
      ),
    );

    return NoteArrowObject(
      id: id,
      bounds: bounds,
      start: fractionOf(from),
      end: fractionOf(to),
      bend: through == null ? null : fractionOf(through),
      color: color,
      width: width,
      headStyle: headStyle,
      tailStyle: tailStyle,
      dashed: dashed,
    );
  }

  /// Rebuilds an arrow from its [base] fields and [payload].
  factory NoteArrowObject.decode(NoteObjectBase base, JsonMap payload) =>
      NoteArrowObject(
        id: base.id,
        bounds: NoteObjectGeometry.normalizeRect(base.bounds),
        rotation: base.rotation,
        opacity: base.opacity,
        locked: base.locked,
        start: _clampFraction(NoteJson.offset(payload, 'start', defaultStart)),
        end: _clampFraction(NoteJson.offset(payload, 'end', defaultEnd)),
        color: NoteJson.color(payload, 'color', defaultColor),
        width: NoteJson.number(
          payload,
          'width',
          defaultWidth,
        ).clamp(minWidth, maxWidth),
        headStyle: NoteJson.enumByName(
          NoteArrowCap.values,
          payload['headStyle'],
          NoteArrowCap.triangle,
        ),
        tailStyle: NoteJson.enumByName(
          NoteArrowCap.values,
          payload['tailStyle'],
          NoteArrowCap.none,
        ),
        dashed: NoteJson.boolean(payload, 'dashed'),
        bend: payload['bend'] is Map
            ? _clampFraction(NoteJson.offset(payload, 'bend', _middle))
            : null,
      );

  /// [start] as a point on the page before [rotation].
  Offset get startPoint => NoteArrowPainting.pointIn(bounds, start);

  /// [end] as a point on the page before [rotation].
  Offset get endPoint => NoteArrowPainting.pointIn(bounds, end);

  /// Where the middle of the line is, before [rotation]: [bend], or halfway
  /// between the ends of a straight line.
  Offset get bendPoint => bend == null
      ? Offset.lerp(startPoint, endPoint, 0.5)!
      : NoteArrowPainting.pointIn(bounds, bend!);

  /// This arrow curved so that its middle passes through [point] (page
  /// coordinates before [rotation]). The bounds fit the new curve and the
  /// ends stay where they are on screen.
  NoteArrowObject bentThrough(Offset point) {
    final from = startPoint;
    final to = endPoint;
    final fitted = NoteObjectGeometry.normalizeRect(
      _enclose(from, point, to),
      minimum: NoteObjectGeometry.minimumSize,
    );
    // The object turns about its center: moving the center of a turned object
    // would move its ends, so shift the new bounds to make up for it.
    final moved = fitted.center - bounds.center;
    final shift = NoteObjectGeometry.rotateVector(moved, rotation) - moved;
    Offset fractionOf(Offset at) => _clampFraction(
      Offset(
        (at.dx - fitted.left) / fitted.width,
        (at.dy - fitted.top) / fitted.height,
      ),
    );

    return copyWith(
      bounds: fitted.shift(shift),
      start: fractionOf(from),
      end: fractionOf(to),
      bend: fractionOf(point),
    );
  }

  /// This arrow without its curve.
  NoteArrowObject straightened() => copyWith(straighten: true);

  /// The line width actually drawn.
  double get effectiveWidth => width.isNaN
      ? defaultWidth
      : math.min(maxWidth, math.max(minWidth, width));

  @override
  String get kind => kindName;

  @override
  int get hashCode => Object.hash(
    id,
    bounds,
    rotation,
    opacity,
    locked,
    start,
    end,
    color,
    width,
    headStyle,
    tailStyle,
    dashed,
    bend,
  );

  /// A copy with the given fields replaced; the [id] is kept. [straighten]
  /// removes [bend].
  NoteArrowObject copyWith({
    Rect? bounds,
    double? rotation,
    double? opacity,
    bool? locked,
    Offset? start,
    Offset? end,
    Color? color,
    double? width,
    NoteArrowCap? headStyle,
    NoteArrowCap? tailStyle,
    bool? dashed,
    Offset? bend,
    bool straighten = false,
  }) => NoteArrowObject(
    id: id,
    bounds: bounds ?? this.bounds,
    rotation: rotation ?? this.rotation,
    opacity: opacity ?? this.opacity,
    locked: locked ?? this.locked,
    start: start ?? this.start,
    end: end ?? this.end,
    color: color ?? this.color,
    width: width ?? this.width,
    headStyle: headStyle ?? this.headStyle,
    tailStyle: tailStyle ?? this.tailStyle,
    dashed: dashed ?? this.dashed,
    bend: straighten ? null : bend ?? this.bend,
  );

  @override
  NoteArrowObject withBase({
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
  NoteArrowObject withId(String id) => NoteArrowObject(
    id: id,
    bounds: bounds,
    rotation: rotation,
    opacity: opacity,
    locked: locked,
    start: start,
    end: end,
    color: color,
    width: width,
    headStyle: headStyle,
    tailStyle: tailStyle,
    dashed: dashed,
    bend: bend,
  );

  @override
  JsonMap payloadToJson() => {
    'start': NoteJson.offsetToJson(start),
    'end': NoteJson.offsetToJson(end),
    'color': NoteJson.colorToJson(color),
    'width': width,
    'headStyle': headStyle.name,
    'tailStyle': tailStyle.name,
    'dashed': dashed,
    if (bend != null) 'bend': NoteJson.offsetToJson(bend!),
  };

  @override
  void paintToCanvas(ui.Canvas canvas, NoteObjectPaintContext context) =>
      NoteArrowPainting.paint(canvas, bounds, this);

  @override
  bool operator ==(Object other) =>
      other is NoteArrowObject &&
      other.runtimeType == runtimeType &&
      other.id == id &&
      other.bounds == bounds &&
      other.rotation == rotation &&
      other.opacity == opacity &&
      other.locked == locked &&
      other.start == start &&
      other.end == end &&
      other.color == color &&
      other.width == width &&
      other.headStyle == headStyle &&
      other.tailStyle == tailStyle &&
      other.dashed == dashed &&
      other.bend == bend;

  @override
  String toString() => 'NoteArrowObject($id, $bounds, $start → $end)';

  static const Offset _middle = Offset(0.5, 0.5);

  static Rect _enclose(Offset from, Offset? through, Offset to) =>
      through == null
      ? Rect.fromPoints(from, to)
      : NoteArrowPainting.curveBounds(
          from,
          NoteArrowPainting.controlFor(from, through, to),
          to,
        );

  static Offset _clampFraction(Offset fraction) => Offset(
    fraction.dx.isNaN ? 0.0 : fraction.dx.clamp(0.0, 1.0),
    fraction.dy.isNaN ? 0.0 : fraction.dy.clamp(0.0, 1.0),
  );
}

/// What is drawn at one end of a [NoteArrowObject]. The names are persisted.
enum NoteArrowCap {
  /// Nothing: the line simply ends.
  none,

  /// A filled triangular head.
  triangle,

  /// An open chevron made of two strokes.
  open,
}

import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/view/note_ruler_unit.dart';
import 'package:open_note/src/note/view/note_view_notifier.dart';

/// One of the two long edges of the ruler, named in its own frame: with
/// angle 0, [top] is the edge with the smaller y.
enum NoteRulerEdge {
  /// The edge with the smaller y at angle 0.
  top,

  /// The edge with the larger y at angle 0.
  bottom,
}

/// Position, direction and snapping of the on-page ruler.
///
/// Coordinates and lengths are page units; [angle] is in radians, clockwise
/// (y grows downward) from the positive x axis, kept in `(-π, π]`. The ruler is
/// a [length] × [width] bar centred on [center].
///
/// JSON: `{center: {x, y}, angle, length, width, visible, unit}`, where `unit`
/// is the [NoteRulerUnit.code].
class NoteRulerController extends NoteViewNotifier {
  /// Creates the controller; [length] and [width] are clamped to their ranges
  /// and non-finite values replaced by the defaults.
  NoteRulerController({
    Offset center = const Offset(300, 300),
    double angle = 0,
    double length = defaultLength,
    double width = defaultWidth,
    bool visible = false,
    NoteRulerUnit unit = NoteRulerUnit.cm,
  }) : _center = _isFinite(center) ? center : const Offset(300, 300),
       _angle = angle.isFinite ? normalizeAngle(angle) : 0,
       _length = length.isFinite
           ? length.clamp(minLength, maxLength)
           : defaultLength,
       width = width.isFinite ? width.clamp(minWidth, maxWidth) : defaultWidth,
       _visible = visible,
       _unit = unit;

  /// Reads [toJson]; bad values get the defaults.
  factory NoteRulerController.fromJson(Object? value) {
    final map = NoteJson.asMap(value) ?? <String, Object?>{};

    return NoteRulerController(
      center: NoteJson.offset(map, 'center', const Offset(300, 300)),
      angle: NoteJson.number(map, 'angle'),
      length: NoteJson.number(map, 'length', defaultLength),
      width: NoteJson.number(map, 'width', defaultWidth),
      visible: NoteJson.boolean(map, 'visible'),
      unit: NoteRulerUnit.fromCode(map['unit']),
    );
  }

  /// Default [length].
  static const double defaultLength = 360;

  /// Shortest ruler.
  static const double minLength = 60;

  /// Longest ruler.
  static const double maxLength = 5000;

  /// Default [width].
  static const double defaultWidth = 56;

  /// Narrowest ruler body.
  static const double minWidth = 20;

  /// Widest ruler body.
  static const double maxWidth = 200;

  /// Default snapping distance of [snap].
  static const double defaultSnapThreshold = 12;

  static const double _epsilon = 1e-6;

  /// Thickness of the ruler body.
  final double width;

  Offset _center;
  double _angle;
  double _length;
  bool _visible;
  NoteRulerUnit _unit;

  /// [radians] brought into `(-π, π]`.
  static double normalizeAngle(double radians) {
    const turn = 2 * math.pi;
    final wrapped = radians % turn;

    return wrapped > math.pi ? wrapped - turn : wrapped;
  }

  /// Middle of the ruler.
  Offset get center => _center;

  /// Direction of the ruler's long axis, in radians.
  double get angle => _angle;

  /// Length of the long edges.
  double get length => _length;

  /// Whether the ruler is shown; a hidden ruler does not snap.
  bool get visible => _visible;

  /// Unit of the ticks and the length label.
  NoteRulerUnit get unit => _unit;

  /// Unit vector along the ruler (toward its "end").
  Offset get direction => Offset(math.cos(_angle), math.sin(_angle));

  /// Unit vector from the centre toward the bottom edge.
  Offset get normal => Offset(-math.sin(_angle), math.cos(_angle));

  /// [length] formatted in [unit], without the unit name.
  String get lengthText => _unit.format(_length);

  /// The line angle in degrees, 0 up to (not including) 180, clockwise.
  double get degrees => (_angle * 180 / math.pi) % 180;

  /// Moves the centre.
  void setCenter(Offset center) {
    if (isDisposed || !_isFinite(center) || center == _center) return;
    _center = center;
    notifyChanged();
  }

  /// Translates the ruler.
  void moveBy(Offset delta) => setCenter(_center + delta);

  /// Rotates the ruler to [radians] (wrapped into `(-π, π]`).
  void setAngle(double radians) {
    if (isDisposed || !radians.isFinite) return;
    final next = normalizeAngle(radians);
    if ((next - _angle).abs() < 1e-12) return;
    _angle = next;
    notifyChanged();
  }

  /// Rotates by [radians].
  void rotateBy(double radians) => setAngle(_angle + radians);

  /// Sets the length (clamped).
  void setLength(double length) {
    if (isDisposed || !length.isFinite) return;
    final next = length.clamp(minLength, maxLength);
    if (next == _length) return;
    _length = next;
    notifyChanged();
  }

  /// Shows or hides the ruler.
  void setVisible(bool visible) {
    if (isDisposed || visible == _visible) return;
    _visible = visible;
    notifyChanged();
  }

  /// Flips [visible].
  void toggle() => setVisible(!_visible);

  /// Changes the unit of the ticks and label.
  void setUnit(NoteRulerUnit unit) {
    if (isDisposed || unit == _unit) return;
    _unit = unit;
    notifyChanged();
  }

  /// The two ends of [edge], start first (along [direction]).
  (Offset, Offset) edgeSegment(NoteRulerEdge edge) {
    final middle = _center + normal * _across(edge);
    final half = direction * (_length / 2);

    return (middle - half, middle + half);
  }

  /// The edge within [threshold] of [point], or `null`: when the ruler is
  /// hidden, the point is past either end or too far from both edges. When both
  /// edges are equally near, [NoteRulerEdge.top] wins. Use it at the start of a
  /// stroke, then [projectOnto] that edge for the rest of the stroke.
  NoteRulerEdge? edgeNear(
    Offset point, {
    double threshold = defaultSnapThreshold,
  }) {
    if (!_visible || !_isFinite(point)) return null;
    final relative = point - _center;
    final along = _dot(relative, direction);
    if (along.abs() > _length / 2 + _epsilon) return null;
    final across = _dot(relative, normal);
    final top = (across - _across(NoteRulerEdge.top)).abs();
    final bottom = (across - _across(NoteRulerEdge.bottom)).abs();
    final nearest = top <= bottom + _epsilon
        ? NoteRulerEdge.top
        : NoteRulerEdge.bottom;

    return math.min(top, bottom) <= threshold + _epsilon ? nearest : null;
  }

  /// [point] projected onto the line of [edge]; with [clampToLength] it also
  /// stays between the ruler's ends.
  Offset projectOnto(
    NoteRulerEdge edge,
    Offset point, {
    bool clampToLength = true,
  }) {
    var along = _dot(point - _center, direction);
    if (clampToLength) along = along.clamp(-_length / 2, _length / 2);

    return _center + direction * along + normal * _across(edge);
  }

  /// [point] pulled onto the nearest ruler edge when that edge is within
  /// [threshold] (see [edgeNear]); otherwise [point] itself.
  Offset snap(Offset point, {double threshold = defaultSnapThreshold}) {
    final edge = edgeNear(point, threshold: threshold);

    return edge == null ? point : projectOnto(edge, point);
  }

  /// The persisted form (see the class comment).
  JsonMap toJson() => {
    'center': NoteJson.offsetToJson(_center),
    'angle': _angle,
    'length': _length,
    'width': width,
    'visible': _visible,
    'unit': _unit.code,
  };

  double _across(NoteRulerEdge edge) =>
      edge == NoteRulerEdge.top ? -width / 2 : width / 2;

  static double _dot(Offset a, Offset b) => a.dx * b.dx + a.dy * b.dy;

  static bool _isFinite(Offset offset) =>
      offset.dx.isFinite && offset.dy.isFinite;
}

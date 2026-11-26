import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui';

import 'package:open_note/src/note/io/pdf/note_vector_segment.dart';

/// A path whose segments can be read back (a `dart:ui` [Path] cannot), so it
/// can be written to a PDF as well as painted. Built like a [Path]; quadratic
/// curves are stored as the equivalent cubic.
///
/// Every segment except a move needs a current point: calling [lineTo],
/// [cubicTo], [quadraticTo] or [close] on an empty path throws [StateError].
class NoteVectorPath {
  /// An empty path.
  NoteVectorPath();

  /// The Bezier handle length of a quarter circle of radius 1.
  static const double _circleHandle = 0.5522847498307936;

  final List<NoteVectorSegment> _segments = [];
  Offset? _current;
  Offset? _start;

  /// The steps, in drawing order.
  List<NoteVectorSegment> get segments => UnmodifiableListView(_segments);

  /// Whether nothing has been added.
  bool get isEmpty => _segments.isEmpty;

  /// Starts a new subpath at [point].
  void moveTo(Offset point) {
    _segments.add(NoteVectorMove(point));
    _current = point;
    _start = point;
  }

  /// A straight line to [point].
  void lineTo(Offset point) {
    _requireCurrent();
    _segments.add(NoteVectorLine(point));
    _current = point;
  }

  /// A cubic Bezier to [point].
  void cubicTo(Offset control1, Offset control2, Offset point) {
    _requireCurrent();
    _segments.add(NoteVectorCubic(control1, control2, point));
    _current = point;
  }

  /// A quadratic Bezier to [point], stored as the exactly equivalent cubic.
  void quadraticTo(Offset control, Offset point) {
    final from = _requireCurrent();
    cubicTo(
      from + (control - from) * (2 / 3),
      point + (control - point) * (2 / 3),
      point,
    );
  }

  /// Closes the current subpath.
  void close() {
    _requireCurrent();
    _segments.add(const NoteVectorClose());
    _current = _start;
  }

  /// A closed rectangle.
  void addRect(Rect rect) {
    moveTo(rect.topLeft);
    lineTo(rect.topRight);
    lineTo(rect.bottomRight);
    lineTo(rect.bottomLeft);
    close();
  }

  /// A closed ellipse inscribed in [rect], turned by [rotation] radians about
  /// the rect's centre (four cubic Beziers).
  void addOval(Rect rect, {double rotation = 0}) {
    final center = rect.center;
    final cos = math.cos(rotation);
    final sin = math.sin(rotation);
    final rx = rect.width / 2;
    final ry = rect.height / 2;
    Offset at(double x, double y) => Offset(
      center.dx + x * rx * cos - y * ry * sin,
      center.dy + x * rx * sin + y * ry * cos,
    );
    const k = _circleHandle;
    moveTo(at(1, 0));
    cubicTo(at(1, k), at(k, 1), at(0, 1));
    cubicTo(at(-k, 1), at(-1, k), at(-1, 0));
    cubicTo(at(-1, -k), at(-k, -1), at(0, -1));
    cubicTo(at(k, -1), at(1, -k), at(1, 0));
    close();
  }

  /// The same shape as a paintable [Path] (non-zero fill rule).
  Path toPath() {
    final path = Path();
    for (final segment in _segments) {
      switch (segment) {
        case NoteVectorMove(:final point):
          path.moveTo(point.dx, point.dy);
        case NoteVectorLine(:final point):
          path.lineTo(point.dx, point.dy);
        case NoteVectorCubic(:final control1, :final control2, :final point):
          path.cubicTo(
            control1.dx,
            control1.dy,
            control2.dx,
            control2.dy,
            point.dx,
            point.dy,
          );
        case NoteVectorClose():
          path.close();
      }
    }

    return path;
  }

  Offset _requireCurrent() {
    final current = _current;
    if (current == null) throw StateError('the path has no current point');

    return current;
  }
}

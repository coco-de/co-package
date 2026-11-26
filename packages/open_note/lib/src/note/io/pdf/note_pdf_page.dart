part of 'note_pdf_writer.dart';

/// The drawing surface of one PDF page. Create it with
/// `NotePdfWriter.addPage`.
///
/// Coordinates are page coordinates, like the rest of the note layer: PDF
/// points, origin at the top left, y down (the writer flips them for PDF).
///
/// PDF's rules are enforced with [StateError]: graphics state may not change
/// while a path is being built, every [save] needs a [restore] and every
/// [beginGroup] an [endGroup] before the document is saved.
class NotePdfPage {
  NotePdfPage._(this.width, this.height, this._resources);

  /// Width in points.
  final double width;

  /// Height in points.
  final double height;

  final _Resources _resources;
  final List<_PdfScope> _scopes = [_PdfScope(1)];

  _PdfScope get _scope => _scopes.last;

  /// The page's own content stream.
  _ContentStream get _content => _scopes.first.content;

  /// Whether every [save] and [beginGroup] is closed and no path is pending.
  bool get _isComplete =>
      _scopes.length == 1 && _scope.saved.isEmpty && !_scope.hasPath;

  /// Saves the graphics state (`q`).
  void save() {
    _state('q');
    _scope.saved.add(_scope.alpha);
  }

  /// Restores the last [save] (`Q`).
  void restore() {
    if (_scope.saved.isEmpty) throw StateError('restore without save');
    _state('Q');
    _scope.alpha = _scope.saved.removeLast();
  }

  /// Concatenates the matrix `[a b c d e f]` (`cm`).
  void transform(double a, double b, double c, double d, double e, double f) =>
      _state('${notePdfNumbers([a, b, c, d, e, f])} cm');

  /// Moves the origin by [dx], [dy].
  void translate(double dx, double dy) => transform(1, 0, 0, 1, dx, dy);

  /// Scales by [sx] and [sy].
  void scale(double sx, double sy) => transform(sx, 0, 0, sy, 0, 0);

  /// Turns by [radians], clockwise on the page as `Canvas.rotate` does, about
  /// [center] (default: the origin).
  void rotate(double radians, [Offset center = Offset.zero]) {
    final cos = math.cos(radians);
    final sin = math.sin(radians);
    transform(
      cos,
      sin,
      -sin,
      cos,
      center.dx - cos * center.dx + sin * center.dy,
      center.dy - sin * center.dx - cos * center.dy,
    );
  }

  /// Sets the fill colour; alpha is ignored (use [setOpacity]).
  void setFillColor(Color color) => _state('${_rgb(color)} rg');

  /// Sets the line colour; alpha is ignored (use [setOpacity]).
  void setStrokeColor(Color color) => _state('${_rgb(color)} RG');

  /// Sets fill and/or line alpha (0–1) through an `ExtGState`; an omitted value
  /// keeps the current one.
  void setOpacity({double? fill, double? stroke}) {
    _requireNoPath();
    final _Alpha alpha = (
      fill: _unit(fill ?? _scope.alpha.fill),
      stroke: _unit(stroke ?? _scope.alpha.stroke),
    );
    final index = _resources.graphicsState(alpha);
    _scope.content.graphicsStates.add(index);
    _scope.content.add('/GS${index + 1} gs');
    _scope.alpha = alpha;
  }

  /// Sets the line width (0 is a hairline).
  void setLineWidth(double value) =>
      _state('${notePdfNumber(math.max(0, value))} w');

  /// Sets the line end style.
  void setLineCap(StrokeCap cap) {
    final code = switch (cap) {
      StrokeCap.butt => 0,
      StrokeCap.round => 1,
      StrokeCap.square => 2,
    };
    _state('$code J');
  }

  /// Sets the corner style.
  void setLineJoin(StrokeJoin join) {
    final code = switch (join) {
      StrokeJoin.miter => 0,
      StrokeJoin.round => 1,
      StrokeJoin.bevel => 2,
    };
    _state('$code j');
  }

  /// Sets a dash pattern (on and off lengths) starting at [phase]; an empty
  /// [pattern] means solid. Throws [ArgumentError] for negative lengths or a
  /// pattern of only zeros.
  void setDashPattern(List<double> pattern, [double phase = 0]) {
    final negative = pattern.any((length) => length < 0 || !length.isFinite);
    final allZero =
        pattern.isNotEmpty && pattern.every((length) => length == 0);
    if (negative || allZero) {
      throw ArgumentError.value(pattern, 'pattern', 'is not a dash pattern');
    }
    _state('[${notePdfNumbers(pattern)}] ${notePdfNumber(phase)} d');
  }

  /// Starts a subpath at [point] (`m`).
  void moveTo(Offset point) {
    _scope.content.add('${_xy(point)} m');
    _scope.hasPath = true;
    _scope.current = point;
    _scope.start = point;
  }

  /// Line to [point] (`l`).
  void lineTo(Offset point) {
    _requireCurrent();
    _scope.content.add('${_xy(point)} l');
    _scope.current = point;
  }

  /// Cubic Bezier to [point] (`c`).
  void curveTo(Offset control1, Offset control2, Offset point) {
    _requireCurrent();
    _scope.content.add('${_xy(control1)} ${_xy(control2)} ${_xy(point)} c');
    _scope.current = point;
  }

  /// Quadratic Bezier to [point], written as the equivalent cubic.
  void quadraticTo(Offset control, Offset point) {
    final from = _requireCurrent();
    curveTo(
      from + (control - from) * (2 / 3),
      point + (control - point) * (2 / 3),
      point,
    );
  }

  /// Closes the subpath (`h`).
  void closePath() {
    _requireCurrent();
    _scope.content.add('h');
    _scope.current = _scope.start;
  }

  /// Adds a closed rectangle (`re`).
  void rectangle(Rect rect) {
    _scope.content.add(
      '${notePdfNumbers([rect.left, rect.top, rect.width, rect.height])} re',
    );
    _scope.hasPath = true;
    _scope.current = rect.topLeft;
    _scope.start = rect.topLeft;
  }

  /// Adds a closed ellipse inscribed in [rect], turned by [rotation] radians.
  void ellipse(Rect rect, {double rotation = 0}) =>
      addPath(NoteVectorPath()..addOval(rect, rotation: rotation));

  /// Adds every segment of [path] to the current path.
  void addPath(NoteVectorPath path) {
    for (final segment in path.segments) {
      switch (segment) {
        case NoteVectorMove(:final point):
          moveTo(point);
        case NoteVectorLine(:final point):
          lineTo(point);
        case NoteVectorCubic(:final control1, :final control2, :final point):
          curveTo(control1, control2, point);
        case NoteVectorClose():
          closePath();
      }
    }
  }

  /// Fills the path (`f`, or `f*` with the even-odd rule). Nothing happens
  /// without a path, as for [stroke] and [fillAndStroke].
  void fill({bool evenOdd = false}) => _finishPath(evenOdd ? 'f*' : 'f');

  /// Strokes the path (`S`).
  void stroke() => _finishPath('S');

  /// Fills, then strokes the path (`B` or `B*`).
  void fillAndStroke({bool evenOdd = false}) =>
      _finishPath(evenOdd ? 'B*' : 'B');

  /// Clips later drawing to the path until the enclosing [restore] (`W n`).
  /// Throws [StateError] without a path.
  void clip({bool evenOdd = false}) {
    _requireCurrent();
    _finishPath(evenOdd ? 'W* n' : 'W n');
  }

  /// Draws [image] filling [destination]. A destination without a positive,
  /// finite area draws nothing.
  void drawImage(NotePdfImage image, Rect destination) {
    final area = destination.width * destination.height;
    if (!area.isFinite || destination.width <= 0 || destination.height <= 0) {
      return;
    }
    final index = _resources.image(image);
    _scope.content.images.add(index);
    save();
    // An image fills the unit square with its first row at y = 1; flip it
    // into this y-down coordinate system.
    transform(
      destination.width,
      0,
      0,
      -destination.height,
      destination.left,
      destination.bottom,
    );
    _scope.content.add('/Im${index + 1} Do');
    restore();
  }

  /// Starts a transparency group: what is drawn until [endGroup] is composited
  /// as one object at [opacity] (like `Canvas.saveLayer`), so overlapping
  /// strokes do not darken each other. The group covers the page rectangle in
  /// the current coordinates, so start it outside rotations.
  void beginGroup({double opacity = 1}) {
    _requireNoPath();
    _scopes.add(_PdfScope(_unit(opacity)));
  }

  /// Ends the group started by [beginGroup] and draws it.
  void endGroup() {
    if (_scopes.length == 1) throw StateError('endGroup without beginGroup');
    if (_scope.saved.isNotEmpty || _scope.hasPath) {
      throw StateError('close every save and path inside the group first');
    }
    final group = _scopes.removeLast();
    final index = _resources.group(_Group(group.content, width, height));
    _scope.content.groups.add(index);
    save();
    if (group.opacity < 1) {
      setOpacity(fill: group.opacity, stroke: group.opacity);
    }
    _scope.content.add('/Fm${index + 1} Do');
    restore();
  }

  void _state(String operator) {
    _requireNoPath();
    _scope.content.add(operator);
  }

  void _requireNoPath() {
    if (_scope.hasPath) {
      throw StateError('paint or clip the current path first');
    }
  }

  Offset _requireCurrent() {
    final current = _scope.current;
    if (current == null) throw StateError('there is no current point');

    return current;
  }

  void _finishPath(String operator) {
    if (!_scope.hasPath) return;
    _scope.content.add(operator);
    _scope.hasPath = false;
    _scope.current = null;
  }

  static double _unit(double value) {
    if (!value.isFinite) return 1;

    return (value.clamp(0.0, 1.0) * 10000).round() / 10000;
  }

  static String _rgb(Color color) =>
      notePdfNumbers([color.r, color.g, color.b]);

  static String _xy(Offset point) => notePdfNumbers([point.dx, point.dy]);
}

/// State of one content stream being built (the page or an open group).
class _PdfScope {
  _PdfScope(this.opacity);

  /// The opacity a group is drawn with (1 for the page itself).
  final double opacity;

  final _ContentStream content = _ContentStream();
  final List<_Alpha> saved = [];
  _Alpha alpha = (fill: 1, stroke: 1);
  bool hasPath = false;
  Offset? current;
  Offset? start;
}

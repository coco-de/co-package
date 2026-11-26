import 'dart:ui';

import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/view/note_view_notifier.dart';

/// Position, power and size of the movable magnifier lens.
///
/// JSON: `{center: {x, y}, zoom, diameter, visible}`.
class NoteMagnifierController extends NoteViewNotifier {
  /// Creates the controller; [zoom] and [diameter] are clamped to their ranges
  /// and non-finite values replaced by the defaults.
  NoteMagnifierController({
    Offset center = const Offset(200, 200),
    double zoom = defaultZoom,
    double diameter = defaultDiameter,
    bool visible = false,
  }) : _center = _isFinite(center) ? center : const Offset(200, 200),
       _zoom = zoom.isFinite ? zoom.clamp(minZoom, maxZoom) : defaultZoom,
       _diameter = diameter.isFinite
           ? diameter.clamp(minDiameter, maxDiameter)
           : defaultDiameter,
       _visible = visible;

  /// Reads [toJson]; bad values get the defaults.
  factory NoteMagnifierController.fromJson(Object? value) {
    final map = NoteJson.asMap(value) ?? <String, Object?>{};

    return NoteMagnifierController(
      center: NoteJson.offset(map, 'center', const Offset(200, 200)),
      zoom: NoteJson.number(map, 'zoom', defaultZoom),
      diameter: NoteJson.number(map, 'diameter', defaultDiameter),
      visible: NoteJson.boolean(map, 'visible'),
    );
  }

  /// Weakest magnification.
  static const double minZoom = 1.5;

  /// Strongest magnification.
  static const double maxZoom = 6;

  /// Magnification of a new lens.
  static const double defaultZoom = 2;

  /// Smallest lens diameter, in logical pixels of the overlay.
  static const double minDiameter = 80;

  /// Largest lens diameter.
  static const double maxDiameter = 400;

  /// Diameter of a new lens.
  static const double defaultDiameter = 160;

  Offset _center;
  double _zoom;
  double _diameter;
  bool _visible;

  /// Middle of the lens, in the coordinates of the overlay that hosts it; the
  /// lens magnifies what is directly under this point.
  Offset get center => _center;

  /// Magnification factor.
  double get zoom => _zoom;

  /// Lens diameter.
  double get diameter => _diameter;

  /// Whether the lens is shown.
  bool get visible => _visible;

  /// Moves the lens centre.
  void setCenter(Offset center) {
    if (isDisposed || !_isFinite(center) || center == _center) return;
    _center = center;
    notifyChanged();
  }

  /// Translates the lens.
  void moveBy(Offset delta) => setCenter(_center + delta);

  /// Sets the magnification (clamped).
  void setZoom(double zoom) {
    if (isDisposed || !zoom.isFinite) return;
    final next = zoom.clamp(minZoom, maxZoom);
    if (next == _zoom) return;
    _zoom = next;
    notifyChanged();
  }

  /// Sets the lens size (clamped).
  void setDiameter(double diameter) {
    if (isDisposed || !diameter.isFinite) return;
    final next = diameter.clamp(minDiameter, maxDiameter);
    if (next == _diameter) return;
    _diameter = next;
    notifyChanged();
  }

  /// Shows or hides the lens.
  void setVisible(bool visible) {
    if (isDisposed || visible == _visible) return;
    _visible = visible;
    notifyChanged();
  }

  /// Flips [visible].
  void toggle() => setVisible(!_visible);

  /// The persisted form (see the class comment).
  JsonMap toJson() => {
    'center': NoteJson.offsetToJson(_center),
    'zoom': _zoom,
    'diameter': _diameter,
    'visible': _visible,
  };

  static bool _isFinite(Offset offset) =>
      offset.dx.isFinite && offset.dy.isFinite;
}

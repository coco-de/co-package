import 'dart:math' as math;
import 'dart:ui';

import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/study/overlay/note_mask_fill.dart';
import 'package:open_note/src/note/study/overlay/note_mask_geometry.dart';
import 'package:open_note/src/note/study/overlay/note_mask_object.dart';

/// One drag of the cover-up pen: feed it the pen's page points and take the
/// finished [NoteMaskObject] out with [finish].
///
/// With [NoteMaskShape.rect] the mask is the bounding box of the points; with
/// [NoteMaskShape.stroke] it follows the pen at [thickness]. A drag whose
/// points span less than [minSize] in *both* directions is an accidental tap
/// and makes no mask; otherwise a rectangle narrower than [minSize] in one
/// direction is widened to it around its centre.
class NoteMaskPenSession {
  /// A session that makes masks with the given look. Ids come from [idFactory]
  /// (default: random UUIDs).
  NoteMaskPenSession({
    this.shape = NoteMaskShape.rect,
    this.thickness = NoteMaskObject.defaultThickness,
    this.fill = const NoteMaskFill(),
    this.fillOpacity = 1,
    this.scope = NoteMaskScope.page,
    this.minSize = defaultMinSize,
    NoteIdFactory? idFactory,
  }) : assert(minSize >= 0, 'minSize must not be negative'),
       _idFactory = idFactory ?? generateNoteId;

  /// Default [minSize], page units.
  static const double defaultMinSize = 8;

  /// Id of the object [preview] returns.
  static const String previewId = 'mask-preview';

  /// Points closer than this to the previous one are dropped.
  static const double _spacing = 0.5;

  /// The shape of the masks.
  final NoteMaskShape shape;

  /// Stroke width of [NoteMaskShape.stroke] masks.
  final double thickness;

  /// Fill of the masks.
  final NoteMaskFill fill;

  /// Fill opacity of the masks.
  final double fillOpacity;

  /// Which pages the masks cover.
  final NoteMaskScope scope;

  /// Smallest mask, page units (see the class comment).
  final double minSize;

  final NoteIdFactory _idFactory;
  final List<Offset> _points = [];

  /// The points collected so far (unmodifiable).
  List<Offset> get points => List.unmodifiable(_points);

  /// Whether no point has been added since the last [finish] or [cancel].
  bool get isEmpty => _points.isEmpty;

  /// Adds the next pen position. Non-finite points and points that barely moved
  /// are ignored.
  void add(Offset point) {
    if (!point.isFinite) return;
    if (_points.isNotEmpty && (point - _points.last).distance < _spacing) {
      return;
    }
    _points.add(point);
  }

  /// The mask the points would make now, with the id [previewId], for drawing
  /// while the pen is down. `null` while the drag is still too small.
  NoteMaskObject? preview() => _build(() => previewId);

  /// Ends the drag: returns the mask (or `null` when too small) and starts
  /// over. An id is only taken when a mask is made.
  NoteMaskObject? finish() {
    final mask = _build(_idFactory);
    _points.clear();

    return mask;
  }

  /// Throws the drag away.
  void cancel() => _points.clear();

  NoteMaskObject? _build(NoteIdFactory id) {
    if (_points.isEmpty) return null;
    final line = NoteMaskGeometry.boundsOf(_points);
    if (line.width < minSize && line.height < minSize) return null;

    return shape == NoteMaskShape.stroke ? _stroke(id) : _rectangle(line, id);
  }

  NoteMaskObject _stroke(NoteIdFactory id) => NoteMaskObject.stroke(
    id: id(),
    pagePoints: _points,
    thickness: thickness,
    fill: fill,
    fillOpacity: fillOpacity,
    scope: scope,
  );

  NoteMaskObject? _rectangle(Rect line, NoteIdFactory id) {
    final width = math.max(line.width, minSize);
    final height = math.max(line.height, minSize);
    if (width <= 0 || height <= 0) return null;

    return NoteMaskObject(
      id: id(),
      bounds: Rect.fromCenter(
        center: line.center,
        width: width,
        height: height,
      ),
      fill: fill,
      fillOpacity: fillOpacity,
      scope: scope,
    );
  }
}

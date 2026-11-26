import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/view/note_view_notifier.dart';
import 'package:open_note/src/note/view/note_zoom_math.dart';

/// The user's favourite zoom levels: at most [maxLevels] factors between
/// [minZoom] and [maxZoom] (1 = 100 %), kept sorted. Two factors closer than
/// [tolerance] count as the same one.
///
/// JSON: `{levels: [number]}`.
class NoteZoomPresets extends NoteViewNotifier {
  /// Creates the list from [levels]: values are clamped, duplicates and
  /// non-finite ones skipped, and only the first [maxLevels] are kept.
  NoteZoomPresets([Iterable<double> levels = const []]) {
    for (final level in levels) {
      if (_levels.length == maxLevels || !level.isFinite) continue;
      _insert(NoteZoomMath.clampZoom(level, min: minZoom, max: maxZoom));
    }
  }

  /// Restores [toJson]; anything that is not a number is skipped.
  factory NoteZoomPresets.fromJson(Object? value) {
    final map = NoteJson.asMap(value) ?? <String, Object?>{};

    return NoteZoomPresets([
      for (final entry in NoteJson.list(map, 'levels'))
        if (entry is num) entry.toDouble(),
    ]);
  }

  /// Smallest storable zoom factor.
  static const double minZoom = NoteZoomMath.minZoom;

  /// Largest storable zoom factor.
  static const double maxZoom = NoteZoomMath.maxZoom;

  /// Most favourites the list holds.
  static const int maxLevels = 8;

  /// Factors closer than this are equal (half a percentage point).
  static const double tolerance = 0.005;

  final List<double> _levels = [];

  /// The favourites, ascending.
  List<double> get levels => List.unmodifiable(_levels);

  /// Whether no further favourite can be added.
  bool get isFull => _levels.length >= maxLevels;

  /// Whether [zoom] (clamped to the range) is a favourite.
  bool contains(double zoom) => _indexOf(zoom) >= 0;

  /// Adds [zoom] (clamped) or removes it when it is already a favourite.
  /// Returns whether it is a favourite afterwards; `false` also when the list
  /// is full or [zoom] is not finite (nothing changes then).
  bool toggle(double zoom) {
    if (isDisposed || !zoom.isFinite) return false;
    final index = _indexOf(zoom);
    if (index >= 0) {
      _levels.removeAt(index);
      notifyChanged();

      return false;
    }
    if (isFull) return false;
    _insert(NoteZoomMath.clampZoom(zoom, min: minZoom, max: maxZoom));
    notifyChanged();

    return true;
  }

  /// The first favourite above [zoom], wrapping to the smallest one — the next
  /// step of a "cycle favourites" button; `null` without favourites.
  double? nextAfter(double zoom) {
    for (final level in _levels) {
      if (level > zoom + tolerance) return level;
    }

    return _levels.firstOrNull;
  }

  /// The persisted form `{levels}`.
  JsonMap toJson() => {'levels': List<double>.of(_levels)};

  int _indexOf(double zoom) {
    if (!zoom.isFinite) return -1;
    final wanted = NoteZoomMath.clampZoom(zoom, min: minZoom, max: maxZoom);

    return _levels.indexWhere((level) => (level - wanted).abs() < tolerance);
  }

  void _insert(double level) {
    if (_indexOf(level) >= 0) return;
    _levels
      ..add(level)
      ..sort();
  }

  @override
  String toString() => 'NoteZoomPresets($_levels)';
}

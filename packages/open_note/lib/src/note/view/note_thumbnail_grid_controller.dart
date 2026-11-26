import 'package:flutter/foundation.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/view/note_view_notifier.dart';

/// State of the page thumbnail grid: column count, pinch accumulation, sidebar
/// visibility and the multi-selection of pages.
///
/// JSON: `{columns, sidebarVisible}` (the selection is not persisted).
class NoteThumbnailGridController extends NoteViewNotifier {
  /// Creates the controller; [columns] is clamped to [minColumns]–[maxColumns]
  /// and a [pinchStep] that is not a finite number above 1 becomes
  /// [defaultPinchStep].
  NoteThumbnailGridController({
    int columns = defaultColumns,
    bool sidebarVisible = false,
    double pinchStep = defaultPinchStep,
  }) : _columns = columns.clamp(minColumns, maxColumns),
       _sidebarVisible = sidebarVisible,
       pinchStep = pinchStep.isFinite && pinchStep > 1
           ? pinchStep
           : defaultPinchStep;

  /// Restores [toJson]; missing or malformed values get the defaults.
  factory NoteThumbnailGridController.fromJson(Object? value) {
    final map = NoteJson.asMap(value) ?? <String, Object?>{};

    return NoteThumbnailGridController(
      columns: NoteJson.integer(map, 'columns', defaultColumns),
      sidebarVisible: NoteJson.boolean(map, 'sidebarVisible'),
    );
  }

  /// Fewest columns (largest thumbnails).
  static const int minColumns = 1;

  /// Most columns (smallest thumbnails).
  static const int maxColumns = 6;

  /// Columns of a new grid.
  static const int defaultColumns = 3;

  /// Default [pinchStep].
  static const double defaultPinchStep = 1.25;

  static const double _tolerance = 1e-9;

  /// Cumulative pinch factor that changes the column count by one. A pinch must
  /// spread to [pinchStep] times (or close to `1 / pinchStep`) of the distance
  /// at which the last step happened, so small wobbles around a threshold never
  /// flip the layout back and forth.
  final double pinchStep;

  int _columns;
  bool _sidebarVisible;
  bool _selectionMode = false;
  final Set<int> _selection = {};
  double _accumulated = 1;

  /// Number of thumbnails per row.
  int get columns => _columns;

  /// Whether the host should show the thumbnail sidebar.
  bool get sidebarVisible => _sidebarVisible;

  /// Pinch factor collected since the last column step (1 right after a step).
  double get pinchProgress => _accumulated;

  /// Whether taps toggle the selection instead of opening a page.
  bool get selectionMode => _selectionMode;

  /// Selected 0-based page indexes.
  Set<int> get selection => Set.unmodifiable(_selection);

  /// Whether page [index] is selected.
  bool isSelected(int index) => _selection.contains(index);

  /// Sets the column count (clamped).
  void setColumns(int columns) {
    if (isDisposed) return;
    final next = columns.clamp(minColumns, maxColumns);
    if (next == _columns) return;
    _columns = next;
    notifyChanged();
  }

  /// Starts a new pinch gesture: forgets the factor collected by the last one.
  void beginPinch() => _accumulated = 1;

  /// Feeds an incremental pinch [factor] (the ratio of the finger distance to
  /// the previous one). Spreading the fingers (above 1) removes columns, making
  /// thumbnails larger; pinching (below 1) adds columns. At a limit the
  /// collected factor is discarded so the opposite direction reacts at once.
  /// Non-finite or non-positive factors are ignored.
  void scaleBy(double factor) {
    if (isDisposed || !factor.isFinite || factor <= 0) return;
    _accumulated *= factor;
    var next = _columns;
    while (_accumulated >= pinchStep * (1 - _tolerance)) {
      if (next == minColumns) {
        _accumulated = 1;
        break;
      }
      next--;
      _accumulated /= pinchStep;
    }
    while (_accumulated <= (1 / pinchStep) * (1 + _tolerance)) {
      if (next == maxColumns) {
        _accumulated = 1;
        break;
      }
      next++;
      _accumulated *= pinchStep;
    }
    setColumns(next);
  }

  /// Shows or hides the sidebar.
  void setSidebarVisible(bool visible) {
    if (isDisposed || visible == _sidebarVisible) return;
    _sidebarVisible = visible;
    notifyChanged();
  }

  /// Flips [sidebarVisible].
  void toggleSidebar() => setSidebarVisible(!_sidebarVisible);

  /// Enters or leaves selection mode; leaving clears the selection.
  void setSelectionMode(bool enabled) {
    if (isDisposed || enabled == _selectionMode) return;
    _selectionMode = enabled;
    if (!enabled) _selection.clear();
    notifyChanged();
  }

  /// Selects or deselects page [index] (negative indexes are ignored) and
  /// enters selection mode.
  void toggleSelect(int index) {
    if (isDisposed || index < 0) return;
    _selectionMode = true;
    if (!_selection.remove(index)) _selection.add(index);
    notifyChanged();
  }

  /// Selects pages `0 … pageCount - 1` and enters selection mode.
  void selectAll(int pageCount) {
    if (isDisposed || pageCount <= 0) return;
    final all = {for (var i = 0; i < pageCount; i++) i};
    if (_selectionMode && setEquals(all, _selection)) return;
    _selectionMode = true;
    _selection
      ..clear()
      ..addAll(all);
    notifyChanged();
  }

  /// Deselects every page, keeping selection mode.
  void clearSelection() {
    if (isDisposed || _selection.isEmpty) return;
    _selection.clear();
    notifyChanged();
  }

  /// Drops selected indexes that no longer exist after the note shrank to
  /// [pageCount] pages. Page indexes shift when pages are removed in the
  /// middle; clear the selection after such an edit instead.
  void retainPages(int pageCount) {
    if (isDisposed) return;
    final before = _selection.length;
    _selection.removeWhere((index) => index >= pageCount);
    if (_selection.length != before) notifyChanged();
  }

  /// The persisted form `{columns, sidebarVisible}`.
  JsonMap toJson() => {'columns': _columns, 'sidebarVisible': _sidebarVisible};
}

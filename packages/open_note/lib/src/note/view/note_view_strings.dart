import 'package:open_note/src/note/view/note_ruler_unit.dart';

/// User-visible text of the view widgets, in English by default. Pass a
/// translated instance as the `strings:` argument of each widget.
class NoteViewStrings {
  /// English text unless overridden.
  const NoteViewStrings({
    this.resizeDivider = 'Resize panes',
    this.dropLeft = 'Open on the left',
    this.dropRight = 'Open on the right',
    this.dropTop = 'Open on top',
    this.dropBottom = 'Open at the bottom',
    this.currentPage = 'Current page',
    this.ruler = 'Ruler',
    this.rotateRuler = 'Rotate ruler',
    this.magnifier = 'Magnifier',
    this.zoomIn = 'Zoom in',
    this.zoomOut = 'Zoom out',
    this.closeMagnifier = 'Close magnifier',
    this.closeTab = 'Close tab',
    this.untitled = 'Untitled',
    this.pageLabel = _pageLabel,
    this.zoomLabel = _zoomLabel,
    this.rulerLabel = _rulerLabel,
  });

  /// Accessibility label of a pane divider.
  final String resizeDivider;

  /// Label of the left drop zone.
  final String dropLeft;

  /// Label of the right drop zone.
  final String dropRight;

  /// Label of the top drop zone.
  final String dropTop;

  /// Label of the bottom drop zone.
  final String dropBottom;

  /// Accessibility value of the thumbnail of the current page.
  final String currentPage;

  /// Accessibility label of the ruler.
  final String ruler;

  /// Accessibility label of the ruler's rotation handle.
  final String rotateRuler;

  /// Accessibility label of the magnifier lens.
  final String magnifier;

  /// Tooltip of the magnifier's plus button.
  final String zoomIn;

  /// Tooltip of the magnifier's minus button.
  final String zoomOut;

  /// Tooltip of the magnifier's close button.
  final String closeMagnifier;

  /// Accessibility label prefix of a tab's close button.
  final String closeTab;

  /// Shown for a tab whose title is empty.
  final String untitled;

  /// Label of a page thumbnail, given the 1-based page number.
  final String Function(int pageNumber) pageLabel;

  /// Label of a magnification factor such as 2.5.
  final String Function(double zoom) zoomLabel;

  /// Text of the ruler's label, given the formatted length, its unit and the
  /// line angle in whole degrees (0–179, clockwise).
  final String Function(String length, NoteRulerUnit unit, int degrees)
  rulerLabel;

  static String _pageLabel(int pageNumber) => 'Page $pageNumber';

  static String _zoomLabel(double zoom) => '${zoom.toStringAsFixed(1)}×';

  static String _rulerLabel(String length, NoteRulerUnit unit, int degrees) =>
      '$length ${unit.code} · $degrees°';
}

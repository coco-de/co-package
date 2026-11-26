import 'package:flutter/widgets.dart';

/// The colours and sizes of the library widgets.
@immutable
class NoteLibraryStyle {
  /// Creates a style. Sizes are logical pixels.
  const NoteLibraryStyle({
    this.backgroundColor = const Color(0xFFFAFAFA),
    this.textColor = const Color(0xFF212121),
    this.secondaryTextColor = const Color(0xFF757575),
    this.accentColor = const Color(0xFF2962FF),
    this.selectionColor = const Color(0x1F2962FF),
    this.dividerColor = const Color(0xFFE0E0E0),
    this.spacing = 16,
    this.drawerTileWidth = 132,
    this.drawerCoverAspectRatio = 0.75,
    this.listRowHeight = 64,
    this.coverCornerRadius = 6,
    this.titleFontSize = 13,
    this.captionFontSize = 11,
  }) : assert(spacing >= 0, 'spacing must not be negative'),
       assert(drawerTileWidth > 0, 'drawerTileWidth must be positive'),
       assert(
         drawerCoverAspectRatio > 0,
         'drawerCoverAspectRatio must be positive',
       );

  /// The background of the view and the sidebar.
  final Color backgroundColor;

  /// Titles and folder names.
  final Color textColor;

  /// Dates, counts and headings.
  final Color secondaryTextColor;

  /// Selection marks, pins and the selected tile's frame.
  final Color accentColor;

  /// The background of a selected row.
  final Color selectionColor;

  /// The line between list rows.
  final Color dividerColor;

  /// The padding around sections and the gap between drawer tiles.
  final double spacing;

  /// The width a drawer tile aims for at zoom 1. Tiles stretch to fill a row,
  /// so the actual width is at least this times the zoom.
  final double drawerTileWidth;

  /// Width divided by height of the area a drawer tile keeps for the cover; a
  /// cover is fitted inside it.
  final double drawerCoverAspectRatio;

  /// The least height of a list row.
  final double listRowHeight;

  /// The corner radius of covers.
  final double coverCornerRadius;

  /// The size of titles.
  final double titleFontSize;

  /// The size of captions such as dates.
  final double captionFontSize;

  static const double _lineHeight = 1.3;

  /// The gap between a drawer cover and its title.
  static const double captionGap = 6;

  /// The text style of titles.
  TextStyle get titleStyle => TextStyle(
    color: textColor,
    fontSize: titleFontSize,
    fontWeight: FontWeight.w600,
    height: _lineHeight,
  );

  /// The text style of captions.
  TextStyle get captionStyle => TextStyle(
    color: secondaryTextColor,
    fontSize: captionFontSize,
    height: _lineHeight,
  );

  /// The height a drawer tile needs under its cover for the title and date.
  double drawerCaptionHeight(TextScaler textScaler) =>
      captionGap +
      textScaler.scale(titleFontSize) * _lineHeight +
      textScaler.scale(captionFontSize) * _lineHeight +
      2;

  /// A copy with some fields replaced.
  NoteLibraryStyle copyWith({
    Color? backgroundColor,
    Color? textColor,
    Color? secondaryTextColor,
    Color? accentColor,
    Color? selectionColor,
    Color? dividerColor,
    double? spacing,
    double? drawerTileWidth,
    double? drawerCoverAspectRatio,
    double? listRowHeight,
    double? coverCornerRadius,
    double? titleFontSize,
    double? captionFontSize,
  }) => NoteLibraryStyle(
    backgroundColor: backgroundColor ?? this.backgroundColor,
    textColor: textColor ?? this.textColor,
    secondaryTextColor: secondaryTextColor ?? this.secondaryTextColor,
    accentColor: accentColor ?? this.accentColor,
    selectionColor: selectionColor ?? this.selectionColor,
    dividerColor: dividerColor ?? this.dividerColor,
    spacing: spacing ?? this.spacing,
    drawerTileWidth: drawerTileWidth ?? this.drawerTileWidth,
    drawerCoverAspectRatio:
        drawerCoverAspectRatio ?? this.drawerCoverAspectRatio,
    listRowHeight: listRowHeight ?? this.listRowHeight,
    coverCornerRadius: coverCornerRadius ?? this.coverCornerRadius,
    titleFontSize: titleFontSize ?? this.titleFontSize,
    captionFontSize: captionFontSize ?? this.captionFontSize,
  );

  @override
  bool operator ==(Object other) =>
      other is NoteLibraryStyle &&
      other.backgroundColor == backgroundColor &&
      other.textColor == textColor &&
      other.secondaryTextColor == secondaryTextColor &&
      other.accentColor == accentColor &&
      other.selectionColor == selectionColor &&
      other.dividerColor == dividerColor &&
      other.spacing == spacing &&
      other.drawerTileWidth == drawerTileWidth &&
      other.drawerCoverAspectRatio == drawerCoverAspectRatio &&
      other.listRowHeight == listRowHeight &&
      other.coverCornerRadius == coverCornerRadius &&
      other.titleFontSize == titleFontSize &&
      other.captionFontSize == captionFontSize;

  @override
  int get hashCode => Object.hash(
    backgroundColor,
    textColor,
    secondaryTextColor,
    accentColor,
    selectionColor,
    dividerColor,
    spacing,
    drawerTileWidth,
    drawerCoverAspectRatio,
    listRowHeight,
    coverCornerRadius,
    titleFontSize,
    captionFontSize,
  );
}

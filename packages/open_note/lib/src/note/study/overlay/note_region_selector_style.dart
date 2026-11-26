import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// Colours and metrics of `NoteRegionSelector`, in page units (the host scales
/// the page together with the selector).
@immutable
class NoteRegionSelectorStyle {
  /// Creates a style; every value has a usable default.
  const NoteRegionSelectorStyle({
    this.scrimColor = const Color(0x52000000),
    this.accentColor = const Color(0xFF2962FF),
    this.borderWidth = 1.5,
    this.handleColor = const Color(0xFFFFFFFF),
    this.handleRadius = 6,
    this.handleHitRadius = 20,
    this.toolbarColor = const Color(0xFFFFFFFF),
    this.toolbarIconColor = const Color(0xFF212121),
    this.buttonExtent = 40,
    this.toolbarGap = 8,
  });

  /// Dims the page outside the selection.
  final Color scrimColor;

  /// Selection border, handle rings and the confirm button.
  final Color accentColor;

  /// Width of the selection border.
  final double borderWidth;

  /// Fill of the handles.
  final Color handleColor;

  /// Drawn radius of a handle.
  final double handleRadius;

  /// How close to a handle a drag must start to resize.
  final double handleHitRadius;

  /// Background of the confirm/cancel bar.
  final Color toolbarColor;

  /// Colour of the cancel icon.
  final Color toolbarIconColor;

  /// Size of one toolbar button.
  final double buttonExtent;

  /// Space between the selection and the toolbar.
  final double toolbarGap;

  @override
  bool operator ==(Object other) =>
      other is NoteRegionSelectorStyle &&
      other.scrimColor == scrimColor &&
      other.accentColor == accentColor &&
      other.borderWidth == borderWidth &&
      other.handleColor == handleColor &&
      other.handleRadius == handleRadius &&
      other.handleHitRadius == handleHitRadius &&
      other.toolbarColor == toolbarColor &&
      other.toolbarIconColor == toolbarIconColor &&
      other.buttonExtent == buttonExtent &&
      other.toolbarGap == toolbarGap;

  @override
  int get hashCode => Object.hash(
    scrimColor,
    accentColor,
    borderWidth,
    handleColor,
    handleRadius,
    handleHitRadius,
    toolbarColor,
    toolbarIconColor,
    buttonExtent,
    toolbarGap,
  );
}

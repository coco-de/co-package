import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// Colours and metrics of the windows drawn by `NoteFloatingWindowHost`.
@immutable
class NoteFloatingWindowStyle {
  /// Creates a style; every value has a usable default.
  const NoteFloatingWindowStyle({
    this.backgroundColor = const Color(0xFFFFFFFF),
    this.titleBarColor = const Color(0xFFF5F5F5),
    this.focusedTitleBarColor = const Color(0xFFE8EEFF),
    this.titleStyle = const TextStyle(
      color: Color(0xFF212121),
      fontSize: 13,
      fontWeight: FontWeight.w600,
    ),
    this.iconColor = const Color(0xFF424242),
    this.borderColor = const Color(0xFFBDBDBD),
    this.focusedBorderColor = const Color(0xFF2962FF),
    this.cornerRadius = 10,
    this.titleBarHeight = 36,
    this.buttonExtent = 30,
    this.resizeHandleExtent = 22,
    this.shadows = const [
      BoxShadow(color: Color(0x40000000), blurRadius: 16, offset: Offset(0, 6)),
    ],
  }) : assert(titleBarHeight > 0, 'titleBarHeight must be positive');

  /// Behind the window body.
  final Color backgroundColor;

  /// Title bar of windows without focus.
  final Color titleBarColor;

  /// Title bar of the focused window.
  final Color focusedTitleBarColor;

  /// The title text.
  final TextStyle titleStyle;

  /// Title bar and resize icons.
  final Color iconColor;

  /// Border of windows without focus.
  final Color borderColor;

  /// Border of the focused window.
  final Color focusedBorderColor;

  /// Corner radius of the windows.
  final double cornerRadius;

  /// Height of the title bar; a minimized window is this tall.
  final double titleBarHeight;

  /// Width of each title bar button.
  final double buttonExtent;

  /// Size of the resize corner.
  final double resizeHandleExtent;

  /// Drop shadow.
  final List<BoxShadow> shadows;

  @override
  bool operator ==(Object other) =>
      other is NoteFloatingWindowStyle &&
      other.backgroundColor == backgroundColor &&
      other.titleBarColor == titleBarColor &&
      other.focusedTitleBarColor == focusedTitleBarColor &&
      other.titleStyle == titleStyle &&
      other.iconColor == iconColor &&
      other.borderColor == borderColor &&
      other.focusedBorderColor == focusedBorderColor &&
      other.cornerRadius == cornerRadius &&
      other.titleBarHeight == titleBarHeight &&
      other.buttonExtent == buttonExtent &&
      other.resizeHandleExtent == resizeHandleExtent &&
      listEquals(other.shadows, shadows);

  @override
  int get hashCode => Object.hash(
    backgroundColor,
    titleBarColor,
    focusedTitleBarColor,
    titleStyle,
    iconColor,
    borderColor,
    focusedBorderColor,
    cornerRadius,
    titleBarHeight,
    buttonExtent,
    resizeHandleExtent,
    Object.hashAll(shadows),
  );
}

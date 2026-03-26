// 🐦 Flutter imports:
import 'package:flutter/material.dart' hide showDialog;

// 🌎 Project imports:
import 'package:open_board/src/core/extentions/debouncer.dart';

final class DebouncerButton extends StatefulWidget {
  const DebouncerButton({
    super.key,
    this.child,
    this.onTap,
    this.color,
    this.highlightColor,
    this.splashColor,
    this.hoverColor,
    this.borderRadius,
    this.height,
    this.margin = EdgeInsets.zero,
    this.padding = EdgeInsets.zero,
    this.enabled = true,
    this.tooltip,
  });

  final Widget? child;
  final Function? onTap;
  final Color? color;
  final Color? highlightColor;
  final Color? splashColor;
  final Color? hoverColor;
  final BorderRadius? borderRadius;
  final double? height;
  final EdgeInsets margin;
  final EdgeInsets padding;
  final bool enabled;
  final String? tooltip;

  @override
  DebouncerButtonState createState() => DebouncerButtonState();
}

final class DebouncerButtonState extends State<DebouncerButton> {
  bool? isTapped;
  late Debouncer _debouncer;

  @override
  void initState() {
    _debouncer = Debouncer();
    super.initState();
    isTapped = false;
  }

  @override
  Widget build(BuildContext context) {
    final splashColor = widget.enabled
        ? (widget.splashColor ?? ThemeData.light().splashColor)
        : null;
    final highlightColor = widget.enabled
        ? (widget.highlightColor ?? ThemeData.light().highlightColor)
        : null;
    final hoverColor = widget.enabled
        ? (widget.hoverColor ?? ThemeData.light().hoverColor)
        : null;

    final child = InkWell(
      onTap: widget.enabled
          ? () {
              _debouncer.run(() {
                if (widget.onTap == null) return;
                widget.onTap!();
              });
            }
          : null,
      splashColor: splashColor,
      highlightColor: highlightColor,
      hoverColor: hoverColor,
    );
    return Padding(
      padding: widget.margin,
      child: ClipRRect(
        borderRadius: widget.borderRadius ?? .circular(6),
        child: Stack(
          children: [
            Container(
              padding: widget.padding,
              height: widget.height,
              child: widget.child,
            ),
            Positioned.fill(
              child: Material(
                color: widget.color ?? Colors.transparent,
                child: widget.tooltip != null
                    ? Tooltip(message: widget.tooltip, child: child)
                    : child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

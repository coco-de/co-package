import 'package:flutter/widgets.dart';

/// The screen edge a piece of chrome leaves through when it is hidden.
enum NoteChromeEdge {
  /// Up and out, as a top toolbar.
  top,

  /// Down and out, as a bottom toolbar.
  bottom,

  /// Out to the left, as a left panel.
  left,

  /// Out to the right, as a right panel.
  right,
}

/// Animates a toolbar or panel away toward an [edge] and back.
///
/// Hidden chrome ignores pointers, takes no focus and is left out of the
/// accessibility tree, but keeps its state. With [collapse] (the default) its
/// space shrinks too, so the content next to it grows.
class NoteChromeVisibility extends StatefulWidget {
  /// Wraps [child] so it can leave and return through [edge].
  const NoteChromeVisibility({
    required this.hidden,
    required this.child,
    super.key,
    this.edge = NoteChromeEdge.top,
    this.duration = defaultDuration,
    this.curve = Curves.easeInOut,
    this.collapse = true,
  });

  /// Default animation length.
  static const Duration defaultDuration = Duration(milliseconds: 220);

  /// Whether the chrome is away (usually `NoteFullScreenController
  /// .chromeHidden`). The first build shows the final state without animating.
  final bool hidden;

  /// The toolbar or panel.
  final Widget child;

  /// The edge it leaves through.
  final NoteChromeEdge edge;

  /// Length of the animation.
  final Duration duration;

  /// Easing of the animation.
  final Curve curve;

  /// Whether the layout space shrinks while leaving; without it the chrome
  /// slides and fades but keeps its room.
  final bool collapse;

  @override
  State<NoteChromeVisibility> createState() => _NoteChromeVisibilityState();
}

class _NoteChromeVisibilityState extends State<NoteChromeVisibility>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      value: widget.hidden ? 0 : 1,
    );
  }

  @override
  void didUpdateWidget(NoteChromeVisibility oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.duration = widget.duration;
    if (oldWidget.hidden != widget.hidden) {
      if (widget.hidden) {
        _controller.reverse();
      } else {
        _controller.forward();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: IgnorePointer(
        ignoring: widget.hidden,
        child: ExcludeSemantics(
          excluding: widget.hidden,
          child: ExcludeFocus(excluding: widget.hidden, child: widget.child),
        ),
      ),
      builder: (context, child) =>
          _buildAt(widget.curve.transform(_controller.value), child!),
    );
  }

  Widget _buildAt(double shown, Widget child) {
    final away = _controller.isDismissed;
    final faded = Opacity(opacity: shown.clamp(0.0, 1.0), child: child);
    if (!widget.collapse) {
      return FractionalTranslation(
        translation: _offset(1 - shown),
        child: faded,
      );
    }
    final vertical =
        widget.edge == NoteChromeEdge.top ||
        widget.edge == NoteChromeEdge.bottom;

    return Offstage(
      offstage: away,
      child: ClipRect(
        child: Align(
          alignment: _anchor,
          widthFactor: vertical ? 1 : shown.clamp(0.0, 1.0),
          heightFactor: vertical ? shown.clamp(0.0, 1.0) : 1,
          child: faded,
        ),
      ),
    );
  }

  /// The side of the child that stays inside the shrinking box, so the rest
  /// slides out through [NoteChromeVisibility.edge].
  Alignment get _anchor => switch (widget.edge) {
    NoteChromeEdge.top => Alignment.bottomCenter,
    NoteChromeEdge.bottom => Alignment.topCenter,
    NoteChromeEdge.left => Alignment.centerRight,
    NoteChromeEdge.right => Alignment.centerLeft,
  };

  Offset _offset(double amount) => switch (widget.edge) {
    NoteChromeEdge.top => Offset(0, -amount),
    NoteChromeEdge.bottom => Offset(0, amount),
    NoteChromeEdge.left => Offset(-amount, 0),
    NoteChromeEdge.right => Offset(amount, 0),
  };
}

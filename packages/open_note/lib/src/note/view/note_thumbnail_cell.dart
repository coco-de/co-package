import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/view/note_view_strings.dart';
import 'package:open_note/src/note/view/note_view_style.dart';

/// One entry of a `NoteThumbnailGrid`: a framed page preview, its number, the
/// ring of the current page and, while selecting, a check mark.
class NoteThumbnailCell extends StatelessWidget {
  /// A thumbnail of page [pageNumber] around the preview [child].
  const NoteThumbnailCell({
    required this.pageNumber,
    required this.child,
    required this.onTap,
    super.key,
    this.onLongPress,
    this.current = false,
    this.selected = false,
    this.selecting = false,
    this.showNumber = true,
    this.style = const NoteViewStyle(),
    this.strings = const NoteViewStrings(),
  });

  /// Height reserved under the frame for the page number.
  static const double labelExtent = 22;

  /// 1-based page number.
  final int pageNumber;

  /// The page preview.
  final Widget child;

  /// The cell was tapped.
  final VoidCallback onTap;

  /// The cell was long-pressed; `null` disables the gesture.
  final VoidCallback? onLongPress;

  /// Whether this is the page shown elsewhere (it gets a ring).
  final bool current;

  /// Whether the page is selected.
  final bool selected;

  /// Whether the grid is in selection mode (a mark is shown on every cell).
  final bool selecting;

  /// Whether the page number is printed under the frame.
  final bool showNumber;

  /// Colours; see [NoteViewStyle].
  final NoteViewStyle style;

  /// Visible and accessibility text.
  final NoteViewStrings strings;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label: strings.pageLabel(pageNumber),
      value: current ? strings.currentPage : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onLongPress: onLongPress,
        child: Column(
          children: [
            Expanded(child: _buildFrame()),
            if (showNumber)
              SizedBox(
                height: labelExtent,
                child: Center(
                  child: ExcludeSemantics(
                    child: Text(
                      '$pageNumber',
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 12,
                        color: current
                            ? style.accentColor
                            : style.mutedTextColor,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFrame() {
    final highlighted = current || selected;

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: style.surfaceColor,
            border: Border.all(color: style.borderColor),
          ),
          child: Padding(
            padding: const EdgeInsets.all(1),
            child: ClipRect(child: child),
          ),
        ),
        if (highlighted)
          IgnorePointer(
            child: DecoratedBox(
              key: ValueKey<String>(
                current ? 'note-thumbnail-current' : 'note-thumbnail-selected',
              ),
              decoration: BoxDecoration(
                border: Border.all(
                  color: style.accentColor,
                  width: current ? 3 : 2,
                ),
              ),
            ),
          ),
        if (selecting)
          Positioned(
            top: 4,
            right: 4,
            child: SizedBox.square(
              dimension: 20,
              child: CustomPaint(
                painter: _CheckMarkPainter(
                  checked: selected,
                  color: style.accentColor,
                  idle: style.surfaceColor,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CheckMarkPainter extends CustomPainter {
  const _CheckMarkPainter({
    required this.checked,
    required this.color,
    required this.idle,
  });

  final bool checked;
  final Color color;
  final Color idle;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 1;
    canvas
      ..drawCircle(center, radius, Paint()..color = checked ? color : idle)
      ..drawCircle(
        center,
        radius,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    if (!checked) return;
    final tick = Path()
      ..moveTo(size.width * 0.28, size.height * 0.52)
      ..lineTo(size.width * 0.44, size.height * 0.68)
      ..lineTo(size.width * 0.74, size.height * 0.36);
    canvas.drawPath(
      tick,
      Paint()
        ..color = const Color(0xFFFFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_CheckMarkPainter old) =>
      old.checked != checked || old.color != color || old.idle != idle;
}

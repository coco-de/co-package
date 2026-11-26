import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/nav/note_excerpt.dart';
import 'package:open_note/src/note/nav/note_excerpt_flash_controller.dart';
import 'package:open_note/src/note/nav/note_excerpts.dart';

/// Paints the fading highlight of a flashed excerpt over one page.
///
/// Place it over the page with tight constraints equal to the page size: it draws
/// in page coordinates (the excerpt rect is a fraction of the page). It shows
/// nothing while the flash is idle or belongs to another page, and never takes
/// pointer events.
class NoteExcerptFlashOverlay extends StatelessWidget {
  /// Creates the overlay of the page [pageId].
  const NoteExcerptFlashOverlay({
    required this.controller,
    required this.excerpts,
    required this.pageId,
    super.key,
    this.color = const Color(0xFFFFC107),
    this.fillOpacity = 0.35,
    this.borderWidth = 2,
    this.cornerRadius = 4,
  });

  /// The flash to draw.
  final NoteExcerptFlashController controller;

  /// Where the flashed excerpt is looked up.
  final NoteExcerpts excerpts;

  /// The page this overlay covers.
  final String pageId;

  /// Highlight colour for excerpts without a colour of their own.
  final Color color;

  /// Fill alpha (`0`–`1`) at the start of the flash; the border starts opaque.
  final double fillOpacity;

  /// Border width in page units; `0` draws no border.
  final double borderWidth;

  /// Corner radius of the highlight in page units.
  final double cornerRadius;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: ListenableBuilder(
      listenable: Listenable.merge([controller, excerpts]),
      builder: (context, _) {
        final id = controller.excerptId;
        final excerpt = id == null ? null : excerpts.byId(id);
        if (excerpt == null || excerpt.pageId != pageId) {
          return const SizedBox.expand();
        }

        return CustomPaint(
          size: Size.infinite,
          painter: _NoteFlashPainter(
            excerpt: excerpt,
            color: excerpt.color ?? color,
            progress: controller.progress,
            fillOpacity: fillOpacity,
            borderWidth: borderWidth,
            cornerRadius: cornerRadius,
          ),
        );
      },
    ),
  );
}

class _NoteFlashPainter extends CustomPainter {
  const _NoteFlashPainter({
    required this.excerpt,
    required this.color,
    required this.progress,
    required this.fillOpacity,
    required this.borderWidth,
    required this.cornerRadius,
  });

  final NoteExcerpt excerpt;
  final Color color;
  final double progress;
  final double fillOpacity;
  final double borderWidth;
  final double cornerRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final shape = RRect.fromRectAndRadius(
      excerpt.rectIn(size),
      Radius.circular(cornerRadius),
    );
    final alpha = color.a * progress;
    canvas.drawRRect(
      shape,
      Paint()..color = color.withValues(alpha: alpha * fillOpacity),
    );
    if (borderWidth <= 0) return;
    canvas.drawRRect(
      shape,
      Paint()
        ..color = color.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth,
    );
  }

  @override
  bool shouldRepaint(_NoteFlashPainter old) =>
      old.excerpt != excerpt ||
      old.color != color ||
      old.progress != progress ||
      old.fillOpacity != fillOpacity ||
      old.borderWidth != borderWidth ||
      old.cornerRadius != cornerRadius;
}

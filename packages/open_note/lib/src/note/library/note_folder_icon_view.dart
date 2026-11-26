import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/library/internal/note_folder_glyphs.dart';

/// A small line glyph for a folder icon key (see `NoteFolderIcons.keys`).
/// Unknown keys draw the plain folder.
class NoteFolderIconView extends StatelessWidget {
  /// Creates a glyph of [size] logical pixels square.
  const NoteFolderIconView({
    required this.iconKey,
    super.key,
    this.size = 20,
    this.color = const Color(0xFF424242),
    this.semanticLabel,
  });

  /// Which icon to draw.
  final String iconKey;

  /// The width and height in logical pixels.
  final double size;

  /// The stroke colour.
  final Color color;

  /// The accessibility label; without it the icon is decorative.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => Semantics(
    label: semanticLabel,
    image: semanticLabel != null,
    child: SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _NoteFolderIconPainter(iconKey, color)),
    ),
  );
}

class _NoteFolderIconPainter extends CustomPainter {
  const _NoteFolderIconPainter(this.iconKey, this.color);

  final String iconKey;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final side = math.min(size.width, size.height);
    canvas
      ..save()
      ..translate((size.width - side) / 2, (size.height - side) / 2)
      ..scale(side / NoteFolderGlyphs.designSize)
      ..drawPath(
        NoteFolderGlyphs.pathFor(iconKey),
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.7
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_NoteFolderIconPainter oldDelegate) =>
      oldDelegate.iconKey != iconKey || oldDelegate.color != color;
}

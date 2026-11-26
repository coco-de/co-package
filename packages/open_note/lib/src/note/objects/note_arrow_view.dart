import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/objects/internal/note_arrow_painting.dart';
import 'package:open_note/src/note/objects/note_arrow_object.dart';

/// Draws a [NoteArrowObject] filling its constraints. An arrow has nothing to
/// tap, so it lets every pointer through (in edit mode the layer handles
/// selection and dragging).
class NoteArrowView extends StatelessWidget {
  const NoteArrowView({required this.object, super.key});

  /// The arrow to draw.
  final NoteArrowObject object;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: CustomPaint(
      painter: _NoteArrowViewPainter(object),
      child: const SizedBox.expand(),
    ),
  );
}

class _NoteArrowViewPainter extends CustomPainter {
  final NoteArrowObject object;

  const _NoteArrowViewPainter(this.object);

  @override
  void paint(Canvas canvas, Size size) =>
      NoteArrowPainting.paint(canvas, Offset.zero & size, object);

  @override
  bool shouldRepaint(_NoteArrowViewPainter oldDelegate) =>
      oldDelegate.object != object;
}

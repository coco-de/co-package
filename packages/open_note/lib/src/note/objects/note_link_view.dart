import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/core/note_object.dart';
import 'package:open_note/src/note/objects/internal/note_link_painting.dart';
import 'package:open_note/src/note/objects/note_link_object.dart';

/// Draws a [NoteLinkObject] filling its constraints and follows the link when
/// tapped.
///
/// It reacts only in use: `scope.interactive` with neither selection nor
/// editing, and a target that parses. Then a tap calls
/// `scope.onLinkActivated` with the parsed target; otherwise pointers pass
/// through.
class NoteLinkView extends StatelessWidget {
  const NoteLinkView({required this.object, required this.scope, super.key});

  /// The hotspot to draw.
  final NoteLinkObject object;

  /// How the layer shows it.
  final NoteObjectViewScope scope;

  void _activate() {
    final target = object.linkTarget;
    if (target != null) scope.onLinkActivated?.call(target);
  }

  @override
  Widget build(BuildContext context) {
    final active =
        scope.interactive &&
        !scope.editing &&
        !scope.selected &&
        object.linkTarget != null;

    return IgnorePointer(
      ignoring: !active,
      child: Semantics(
        link: true,
        value: object.target,
        child: MouseRegion(
          cursor: active ? SystemMouseCursors.click : MouseCursor.defer,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: active ? _activate : null,
            child: CustomPaint(
              painter: _NoteLinkViewPainter(object.appearance, object.color),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
  }
}

class _NoteLinkViewPainter extends CustomPainter {
  final NoteLinkAppearance appearance;

  final Color color;
  const _NoteLinkViewPainter(this.appearance, this.color);

  @override
  void paint(Canvas canvas, Size size) =>
      NoteLinkPainting.paint(canvas, Offset.zero & size, appearance, color);

  @override
  bool shouldRepaint(_NoteLinkViewPainter oldDelegate) =>
      oldDelegate.appearance != appearance || oldDelegate.color != color;
}

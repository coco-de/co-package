import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/nav/note_nav_style.dart';

/// A text button in the accent colour ("Edit" / "Done"). Not exported by the
/// barrel.
class NoteNavTextButton extends StatelessWidget {
  const NoteNavTextButton({
    required this.label,
    required this.onPressed,
    required this.style,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;
  final NoteNavStyle style;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    child: MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Text(
            label,
            style: style.textStyle.copyWith(
              color: style.accentColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    ),
  );
}

import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/nav/note_nav_style.dart';

/// A centred placeholder message ("No results"). Not exported by the barrel.
class NoteNavMessage extends StatelessWidget {
  const NoteNavMessage({required this.message, required this.style, super.key});

  final String message;
  final NoteNavStyle style;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        message,
        style: style.secondaryTextStyle,
        textAlign: TextAlign.center,
      ),
    ),
  );
}

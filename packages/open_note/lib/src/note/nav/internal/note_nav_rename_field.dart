import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/core/note_text_field.dart';
import 'package:open_note/src/note/nav/note_nav_style.dart';

/// The inline title editor of a panel row. It takes the focus when it appears
/// and commits on the keyboard's done action or when it loses focus. Not
/// exported by the barrel.
///
/// The owner keeps the typed text (from [onChanged]), so it survives a row that
/// is scrolled away and can be committed when the edit mode ends.
class NoteNavRenameField extends StatefulWidget {
  const NoteNavRenameField({
    required this.initialText,
    required this.hintText,
    required this.onChanged,
    required this.onCommit,
    required this.style,
    super.key,
  });

  final String initialText;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback onCommit;
  final NoteNavStyle style;

  @override
  State<NoteNavRenameField> createState() => _NoteNavRenameFieldState();
}

class _NoteNavRenameFieldState extends State<NoteNavRenameField> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(_takeFocus);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _takeFocus(Duration _) {
    if (mounted) _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) => NoteTextField(
    initialText: widget.initialText,
    focusNode: _focusNode,
    hintText: widget.hintText,
    submitOnBlur: true,
    onChanged: widget.onChanged,
    onSubmitted: (_) => widget.onCommit(),
    style: widget.style.textStyle,
    hintStyle: widget.style.secondaryTextStyle,
    cursorColor: widget.style.accentColor,
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
  );
}

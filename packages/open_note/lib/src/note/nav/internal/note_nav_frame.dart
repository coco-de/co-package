import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/nav/note_nav_style.dart';

/// The shell shared by the list panels: a titled header with actions, optional
/// fixed content below it and a body that takes the remaining height. Not
/// exported by the barrel.
class NoteNavFrame extends StatelessWidget {
  const NoteNavFrame({
    required this.title,
    required this.body,
    required this.style,
    super.key,
    this.actions = const [],
    this.toolbar,
  });

  final String title;
  final Widget body;
  final NoteNavStyle style;
  final List<Widget> actions;

  /// Fixed content between the header and the body (search field, chips).
  final Widget? toolbar;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: style.backgroundColor,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _NoteNavHeader(title: title, actions: actions, style: style),
        if (toolbar != null)
          Padding(
            padding: style.padding.add(const EdgeInsets.only(bottom: 8)),
            child: toolbar,
          ),
        Expanded(child: body),
      ],
    ),
  );
}

class _NoteNavHeader extends StatelessWidget {
  const _NoteNavHeader({
    required this.title,
    required this.actions,
    required this.style,
  });

  final String title;
  final List<Widget> actions;
  final NoteNavStyle style;

  @override
  Widget build(BuildContext context) => Padding(
    padding: style.padding,
    child: SizedBox(
      height: style.rowHeight + 4,
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: style.titleTextStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          ...actions,
        ],
      ),
    ),
  );
}

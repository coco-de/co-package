part of 'note_folder_sidebar.dart';

/// One row of the sidebar: an optional open/close toggle, then the icon, name
/// and note count.
class _NoteFolderRow extends StatelessWidget {
  const _NoteFolderRow({
    required this.sidebar,
    required this.iconKey,
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
    super.key,
    this.depth = 0,
    this.open,
    this.toggleKey,
    this.onToggle,
    this.onLongPress,
  });

  static const double _indent = 18;
  static const double _toggleWidth = 28;
  static const double _height = 40;

  final NoteFolderSidebar sidebar;
  final String iconKey;
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final int depth;

  /// Whether the folder's subfolders are shown; `null` when it has none.
  final bool? open;
  final Key? toggleKey;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final style = sidebar.style;
    final isOpen = open;

    return ColoredBox(
      color: selected ? style.selectionColor : const Color(0x00000000),
      child: Padding(
        padding: EdgeInsetsDirectional.only(
          start: 4 + depth * _indent,
          end: 12,
        ),
        child: Row(
          children: [
            SizedBox(
              width: _toggleWidth,
              height: _height,
              child: isOpen == null
                  ? null
                  : _NoteFolderToggle(
                      key: toggleKey,
                      open: isOpen,
                      color: style.secondaryTextColor,
                      label: isOpen
                          ? sidebar.strings.collapseFolder
                          : sidebar.strings.expandFolder,
                      onTap: onToggle,
                    ),
            ),
            Expanded(child: _NoteFolderRowContent(this)),
          ],
        ),
      ),
    );
  }
}

class _NoteFolderRowContent extends StatelessWidget {
  const _NoteFolderRowContent(this.row);

  final _NoteFolderRow row;

  @override
  Widget build(BuildContext context) {
    final style = row.sidebar.style;

    return Semantics(
      container: true,
      button: true,
      selected: row.selected,
      label: '${row.label}, ${row.sidebar.strings.noteCount(row.count)}',
      onTap: row.onTap,
      onLongPress: row.onLongPress,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTap: row.onTap,
        onLongPress: row.onLongPress,
        child: SizedBox(
          height: _NoteFolderRow._height,
          child: Row(
            children: [
              NoteFolderIconView(
                iconKey: row.iconKey,
                color: row.selected ? style.accentColor : style.textColor,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  row.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: style.titleStyle.copyWith(
                    fontWeight: row.selected
                        ? FontWeight.w700
                        : FontWeight.w400,
                  ),
                ),
              ),
              Text('${row.count}', style: style.captionStyle),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoteFolderToggle extends StatelessWidget {
  const _NoteFolderToggle({
    required this.open,
    required this.color,
    required this.label,
    required this.onTap,
    super.key,
  });

  final bool open;
  final Color color;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    onTap: onTap,
    excludeSemantics: true,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      excludeFromSemantics: true,
      onTap: onTap,
      child: CustomPaint(painter: _NoteTrianglePainter(open, color)),
    ),
  );
}

class _NoteTrianglePainter extends CustomPainter {
  const _NoteTrianglePainter(this.open, this.color);

  final bool open;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final path = Path();
    if (open) {
      path.addPolygon([
        center + const Offset(-4.5, -2.5),
        center + const Offset(4.5, -2.5),
        center + const Offset(0, 3.5),
      ], true);
    } else {
      path.addPolygon([
        center + const Offset(-2.5, -4.5),
        center + const Offset(3.5, 0),
        center + const Offset(-2.5, 4.5),
      ], true);
    }
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_NoteTrianglePainter oldDelegate) =>
      oldDelegate.open != open || oldDelegate.color != color;
}

import 'package:flutter/widgets.dart';
import 'package:open_note/src/module/image/image_source_resolver.dart';
import 'package:open_note/src/note/template/note_paper_picker_controls.dart';
import 'package:open_note/src/note/template/note_paper_picker_style.dart';
import 'package:open_note/src/note/template/note_paper_picker_tile.dart';
import 'package:open_note/src/note/template/note_paper_strings.dart';
import 'package:open_note/src/note/template/note_paper_template.dart';
import 'package:open_note/src/note/template/note_paper_view.dart';

/// A grid of live paper previews with optional spacing and line width sliders
/// for the selected paper.
///
/// [onSelected] reports the paper *as configured*: it is called when a tile is
/// tapped and again on every slider change, each time with the adjusted
/// template (same id). The picker remembers adjustments per id until the host
/// passes a different template for that id.
///
/// The sliders appear only for ruled kinds. With bounded height the grid
/// scrolls and the sliders stay below it; with unbounded height (inside a
/// scroll view) the grid is as tall as its content.
class NotePaperPicker extends StatefulWidget {
  const NotePaperPicker({
    required this.templates,
    required this.onSelected,
    super.key,
    this.selectedId,
    this.showLineSpacingControl = true,
    this.showLineWidthControl = true,
    this.imageProviderResolver = resolveImageSource,
    this.style = const NotePaperPickerStyle(),
    this.strings = const NotePaperStrings(),
  });

  /// The papers to offer, usually `NotePaperCatalog.templates`. Their ids must
  /// be unique. Pass a new list to change them.
  final List<NotePaperTemplate> templates;

  /// Receives the selected paper with its current adjustments.
  final ValueChanged<NotePaperTemplate> onSelected;

  /// The initially selected id; a new value moves the selection.
  final String? selectedId;

  /// Whether the line spacing slider is offered.
  final bool showLineSpacingControl;

  /// Whether the line width slider is offered.
  final bool showLineWidthControl;

  /// Resolves the pictures of `image` papers.
  final NotePaperImageResolver imageProviderResolver;

  /// Sizes and colours.
  final NotePaperPickerStyle style;

  /// Texts.
  final NotePaperStrings strings;

  @override
  State<NotePaperPicker> createState() => _NotePaperPickerState();
}

class _NotePaperPickerState extends State<NotePaperPicker> {
  final Map<String, NotePaperTemplate> _adjusted = {};
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.selectedId;
  }

  @override
  void didUpdateWidget(NotePaperPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedId != oldWidget.selectedId) {
      _selectedId = widget.selectedId;
    }
    final before = {for (final t in oldWidget.templates) t.id: t};
    final after = {for (final t in widget.templates) t.id: t};
    _adjusted.removeWhere((id, _) => before[id] != after[id]);
  }

  NotePaperTemplate _effective(NotePaperTemplate base) =>
      _adjusted[base.id] ?? base;

  NotePaperTemplate? get _selected {
    for (final template in widget.templates) {
      if (template.id == _selectedId) return _effective(template);
    }

    return null;
  }

  void _select(NotePaperTemplate template) {
    setState(() => _selectedId = template.id);
    widget.onSelected(template);
  }

  void _adjust(NotePaperTemplate adjusted) {
    setState(() => _adjusted[adjusted.id] = adjusted);
    widget.onSelected(adjusted);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.templates.isEmpty) {
      return Center(
        child: Text(widget.strings.empty, style: widget.style.labelStyle),
      );
    }
    final selected = _selected;
    final adjustable =
        selected != null &&
        selected.kind.isRuled &&
        (widget.showLineSpacingControl || widget.showLineWidthControl);

    return LayoutBuilder(
      builder: (context, constraints) {
        final bounded = constraints.hasBoundedHeight;
        final grid = _NotePaperPickerGrid(
          templates: [for (final t in widget.templates) _effective(t)],
          selectedId: _selectedId,
          scrollable: bounded,
          picker: widget,
          onSelect: _select,
        );

        return Column(
          mainAxisSize: bounded ? MainAxisSize.max : MainAxisSize.min,
          children: [
            if (bounded) Expanded(child: grid) else grid,
            if (adjustable)
              NotePaperPickerControls(
                template: selected,
                strings: widget.strings,
                style: widget.style,
                showLineSpacing: widget.showLineSpacingControl,
                showLineWidth: widget.showLineWidthControl,
                onChanged: _adjust,
              ),
          ],
        );
      },
    );
  }
}

class _NotePaperPickerGrid extends StatelessWidget {
  const _NotePaperPickerGrid({
    required this.templates,
    required this.selectedId,
    required this.scrollable,
    required this.picker,
    required this.onSelect,
  });

  final List<NotePaperTemplate> templates;
  final String? selectedId;
  final bool scrollable;
  final NotePaperPicker picker;
  final ValueChanged<NotePaperTemplate> onSelect;

  @override
  Widget build(BuildContext context) => GridView.builder(
    shrinkWrap: !scrollable,
    physics: scrollable ? null : const NeverScrollableScrollPhysics(),
    padding: picker.style.padding,
    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: picker.style.tileExtent,
      childAspectRatio: picker.style.tileAspectRatio,
      crossAxisSpacing: picker.style.spacing,
      mainAxisSpacing: picker.style.spacing,
    ),
    itemCount: templates.length,
    itemBuilder: (context, index) {
      final template = templates[index];

      return NotePaperPickerTile(
        key: ValueKey('note-paper-tile-${template.id}'),
        template: template,
        label: picker.strings.templateName(template),
        selected: template.id == selectedId,
        style: picker.style,
        imageProviderResolver: picker.imageProviderResolver,
        onTap: () => onSelect(template),
      );
    },
  );
}

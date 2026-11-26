import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/template/note_paper_picker_style.dart';
import 'package:open_note/src/note/template/note_paper_template.dart';
import 'package:open_note/src/note/template/note_paper_view.dart';

/// One preview of the paper picker. Internal: not exported by the module
/// barrel.
class NotePaperPickerTile extends StatelessWidget {
  const NotePaperPickerTile({
    required this.template,
    required this.label,
    required this.selected,
    required this.style,
    required this.imageProviderResolver,
    required this.onTap,
    super.key,
  });

  /// The paper to preview.
  final NotePaperTemplate template;

  /// Its name, shown below the preview and announced.
  final String label;

  /// Whether the tile is framed as selected.
  final bool selected;

  /// Colours and sizes.
  final NotePaperPickerStyle style;

  /// Resolves the picture of an `image` paper.
  final NotePaperImageResolver imageProviderResolver;

  /// Called when the tile is activated.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    button: true,
    selected: selected,
    label: label,
    onTap: onTap,
    excludeSemantics: true,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      excludeFromSemantics: true,
      onTap: onTap,
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: selected ? style.selectedColor : style.borderColor,
                    width: style.selectedBorderWidth,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(style.selectedBorderWidth),
                  child: FittedBox(
                    child: NotePaperView(
                      template: template,
                      imageProviderResolver: imageProviderResolver,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: selected ? style.selectedLabelStyle : style.labelStyle,
          ),
        ],
      ),
    ),
  );
}

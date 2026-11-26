import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/tools/note_toolbar_placement.dart';
import 'package:open_note/src/note/tools/note_toolbar_layout.dart';
import 'package:open_note/src/note/tools/note_toolbar_dock_edge.dart';
import 'package:open_note/src/note/study/utilities/note_attachment_list.dart';
import 'package:open_note/src/note/study/utilities/note_attachment.dart';
import 'package:open_note/src/note/editor/internal/note_editor_toolbar.dart';
import 'package:open_note/src/note/editor/internal/note_editor_button.dart';
import 'package:open_note/src/note/editor/internal/note_editor_drawer_kind.dart';
import 'package:open_note/src/note/editor/note_editor_controller.dart';
import 'package:open_note/src/note/editor/note_editor_mode.dart';
import 'package:open_note/src/note/editor/note_editor_strings.dart';
import 'package:open_note/src/note/editor/note_editor_style.dart';
import 'package:open_note/src/note/editor/note_export.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/document/note_page_ops.dart';
import 'package:open_note/src/note/objects/note_link_object.dart';
import 'package:open_note/src/note/style/note_image_crop.dart';
import 'package:open_note/src/note/style/note_image_style.dart';
import 'package:open_note/src/note/template/note_paper_catalog.dart';
import 'package:open_note/src/note/template/note_paper_picker.dart';
import 'package:open_note/src/note/template/note_paper_template.dart';

/// The surface of a menu or settings sheet under the editor bars.
class NoteDrawerSurface extends StatelessWidget {
  const NoteDrawerSurface({
    required this.style,
    required this.child,
    super.key,
  });

  final NoteEditorStyle style;
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: style.panelColor,
      border: Border(bottom: BorderSide(color: style.dividerColor)),
    ),
    child: ConstrainedBox(
      constraints: BoxConstraints(maxHeight: style.drawerMaxHeight),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(style.spacing * 2),
        child: SizedBox(width: double.infinity, child: child),
      ),
    ),
  );
}

/// A wrapping row of buttons.
class _Buttons extends StatelessWidget {
  const _Buttons(this.style, this.children);

  final NoteEditorStyle style;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: style.spacing,
    runSpacing: style.spacing,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: children,
  );
}

Widget _button(
  NoteEditorStyle style,
  String key,
  String label,
  VoidCallback? onPressed, {
  bool selected = false,
}) => NoteEditorButton(
  key: ValueKey('note-drawer-$key'),
  label: label,
  style: style,
  onPressed: onPressed,
  selected: selected,
);

/// Page actions: add, copy, delete, turn, margins, paper, order, outline.
class NotePageMenuDrawer extends StatelessWidget {
  const NotePageMenuDrawer({
    required this.controller,
    required this.strings,
    required this.style,
    required this.onDrawer,
    required this.onClose,
    this.onImportPages,
    super.key,
  });

  static const double _marginStep = 160;
  static const List<NotePageSize> _sizes = [
    NotePageSize.a4,
    NotePageSize.a5,
    NotePageSize.letter,
    NotePageSize.square,
  ];

  /// Lets the host choose pages to bring in; null hides the action.
  final VoidCallback? onImportPages;

  final NoteEditorController controller;
  final NoteEditorStrings strings;
  final NoteEditorStyle style;
  final ValueChanged<NoteEditorDrawerKind> onDrawer;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final trash = controller.document.trashedPages;
    VoidCallback closing(VoidCallback action) => () {
      action();
      onClose();
    };
    Widget item(String key, String label, VoidCallback? onPressed) =>
        _button(style, key, label, onPressed);

    return _Buttons(style, [
      item(
        'add-before',
        strings.addBefore,
        closing(
          () => controller.addPage(position: NotePageInsertPosition.before),
        ),
      ),
      item('add-after', strings.addAfter, closing(controller.addPage)),
      item(
        'add-end',
        strings.addAtEnd,
        closing(() => controller.addPage(position: NotePageInsertPosition.end)),
      ),
      item(
        'add-landscape',
        strings.addLandscape,
        closing(
          () => controller.addPage(orientation: NotePageOrientation.landscape),
        ),
      ),
      for (final size in _sizes)
        item(
          'add-size-${size.width.round()}x${size.height.round()}',
          strings.newPageOfSize(strings.pageSizeName(size)),
          closing(() => controller.addPage(size: size)),
        ),
      if (onImportPages case final importPages?)
        item('import-pages', strings.importPages, closing(importPages)),
      _button(
        style,
        'endless',
        strings.endlessPage,
        closing(() => controller.setEndlessPage(!controller.page.autoGrows)),
        selected: controller.page.autoGrows,
      ),
      item(
        'page-tags',
        strings.pageTags,
        () => onDrawer(NoteEditorDrawerKind.pageTags),
      ),
      item(
        'duplicate-page',
        strings.duplicatePage,
        closing(controller.duplicatePage),
      ),
      item(
        'delete-page',
        strings.deletePage,
        controller.pageCount > 1 ? closing(controller.removePage) : null,
      ),
      item('rotate', strings.rotatePage, controller.rotatePage),
      item(
        'extend-right',
        strings.extendRight,
        () => controller.extendMargin(NoteMarginSide.right, _marginStep),
      ),
      item(
        'extend-bottom',
        strings.extendBottom,
        () => controller.extendMargin(NoteMarginSide.bottom, _marginStep),
      ),
      if (controller.page.margins != EdgeInsets.zero)
        item(
          'remove-margins',
          strings.removeMargins,
          () => controller.setMargins(EdgeInsets.zero),
        ),
      item(
        'paper',
        strings.changePaper,
        () => onDrawer(NoteEditorDrawerKind.paper),
      ),
      item(
        'move-earlier',
        strings.movePageEarlier,
        controller.pageIndex > 0
            ? () => controller.movePage(
                controller.pageId,
                controller.pageIndex - 1,
              )
            : null,
      ),
      item(
        'move-later',
        strings.movePageLater,
        controller.pageIndex < controller.pageCount - 1
            ? () => controller.movePage(
                controller.pageId,
                controller.pageIndex + 1,
              )
            : null,
      ),
      item(
        'add-to-outline',
        strings.addToOutline,
        closing(
          () => controller.document.outline.add(
            strings.outlineTitle(controller.pageLabel),
            controller.pageId,
          ),
        ),
      ),
      if (trash.isNotEmpty)
        item(
          'restore-page',
          strings.restoreDeleted(trash.length),
          closing(() => controller.restorePage(trash.last.page.id)),
        ),
    ]);
  }
}

/// Built-in and host papers with a live preview.
class NotePaperDrawer extends StatefulWidget {
  const NotePaperDrawer({
    required this.controller,
    required this.strings,
    required this.style,
    required this.imageProviderResolver,
    this.extraTemplates = const [],
    super.key,
  });

  final NoteEditorController controller;
  final NoteEditorStrings strings;
  final NoteEditorStyle style;
  final NoteImageProviderResolver imageProviderResolver;
  final List<NotePaperTemplate> extraTemplates;

  @override
  State<NotePaperDrawer> createState() => _NotePaperDrawerState();
}

class _NotePaperDrawerState extends State<NotePaperDrawer> {
  bool _everyPage = false;

  @override
  Widget build(BuildContext context) {
    final page = widget.controller.page;
    final templates = <String, NotePaperTemplate>{
      for (final template in [
        ...NotePaperCatalog.builtInTemplates(page.paperSize),
        for (final extra in widget.extraTemplates) extra.fitted(page.paperSize),
      ])
        template.id: template,
    };
    // The page's own paper (perhaps customised) stays selectable.
    templates[page.template.id] = page.template;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _button(
          widget.style,
          'paper-every-page',
          widget.strings.paperForAllPages,
          () => setState(() => _everyPage = !_everyPage),
          selected: _everyPage,
        ),
        NotePaperPicker(
          templates: templates.values.toList(),
          selectedId: page.template.id,
          imageProviderResolver: widget.imageProviderResolver,
          strings: widget.strings.paper,
          onSelected: (template) =>
              widget.controller.setPaper(template, allPages: _everyPage),
        ),
      ],
    );
  }
}

/// Points the selected link object at a page of this note.
class NoteLinkPagesDrawer extends StatelessWidget {
  const NoteLinkPagesDrawer({
    required this.controller,
    required this.strings,
    required this.style,
    required this.onClose,
    super.key,
  });

  final NoteEditorController controller;
  final NoteEditorStrings strings;
  final NoteEditorStyle style;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => _Buttons(style, [
    for (final pageId in controller.document.pageIds)
      _button(
        style,
        'link-page-$pageId',
        strings.pageOption(controller.document.labelOf(pageId)),
        () {
          for (final owner in [
            controller.session.objects,
            controller.session.shared,
          ]) {
            final selected = owner.selection;
            if (selected.length == 1 && selected.single is NoteLinkObject) {
              owner.update(
                (selected.single as NoteLinkObject).copyWith(
                  target: controller.pageLink(pageId),
                ),
              );
            }
          }
          onClose();
        },
      ),
  ]);
}

/// Which toolbar items show, their order and where the bar sits.
class NoteToolbarDrawer extends StatelessWidget {
  const NoteToolbarDrawer({
    required this.layout,
    required this.strings,
    required this.style,
    required this.onChanged,
    super.key,
  });

  final NoteToolbarLayout layout;
  final NoteEditorStrings strings;
  final NoteEditorStyle style;
  final ValueChanged<NoteToolbarLayout> onChanged;

  @override
  Widget build(BuildContext context) {
    final docked = layout.placement == NoteToolbarPlacement.docked;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: style.spacing,
      children: [
        _Buttons(style, [
          for (final (edge, label) in [
            (NoteToolbarDockEdge.top, strings.toolbarTop),
            (NoteToolbarDockEdge.bottom, strings.toolbarBottom),
            (NoteToolbarDockEdge.left, strings.toolbarLeft),
            (NoteToolbarDockEdge.right, strings.toolbarRight),
          ])
            _button(
              style,
              'toolbar-${edge.name}',
              label,
              () => onChanged(
                layout.copyWith(
                  placement: NoteToolbarPlacement.docked,
                  dockEdge: edge,
                ),
              ),
              selected: docked && layout.dockEdge == edge,
            ),
          _button(
            style,
            'toolbar-floating',
            strings.toolbarFloating,
            () => onChanged(
              layout.copyWith(placement: NoteToolbarPlacement.floating),
            ),
            selected: !docked,
          ),
        ]),
        for (final (index, item) in layout.items.indexed)
          _Buttons(style, [
            SizedBox(
              width: 150,
              child: NoteEditorButton(
                key: ValueKey('note-drawer-toolbar-show-${item.id}'),
                label: NoteEditorToolbar.labelOf(item.id, strings),
                semanticLabel:
                    '${item.visible ? strings.hideItem : strings.showItem} '
                    '${NoteEditorToolbar.labelOf(item.id, strings)}',
                style: style,
                selected: item.visible,
                onPressed: () =>
                    onChanged(layout.setVisible(item.id, !item.visible)),
              ),
            ),
            NoteEditorButton(
              key: ValueKey('note-drawer-toolbar-up-${item.id}'),
              label: '↑',
              semanticLabel: strings.moveUp,
              style: style,
              onPressed: index == 0
                  ? null
                  : () => onChanged(layout.moveItem(index, index - 1)),
            ),
            NoteEditorButton(
              key: ValueKey('note-drawer-toolbar-down-${item.id}'),
              label: '↓',
              semanticLabel: strings.moveDown,
              style: style,
              onPressed: index == layout.items.length - 1
                  ? null
                  : () => onChanged(layout.moveItem(index, index + 1)),
            ),
          ]),
      ],
    );
  }
}

/// The note's attached files.
class NoteAttachmentsDrawer extends StatelessWidget {
  const NoteAttachmentsDrawer({
    required this.attachments,
    required this.strings,
    required this.style,
    this.onAttach,
    this.onOpen,
    super.key,
  });

  final NoteAttachmentList attachments;
  final NoteEditorStrings strings;
  final NoteEditorStyle style;
  final VoidCallback? onAttach;
  final ValueChanged<NoteAttachment>? onOpen;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: attachments,
    builder: (context, _) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: style.spacing,
      children: [
        if (attachments.items.isEmpty)
          Text(strings.noAttachments, style: style.textStyle),
        for (final attachment in attachments.items)
          _Buttons(style, [
            Text(
              attachment.title.isEmpty ? attachment.source : attachment.title,
              style: style.textStyle,
            ),
            if (onOpen case final open?)
              _button(
                style,
                'open-attachment-${attachment.id}',
                strings.openAttachment,
                () => open(attachment),
              ),
            _button(
              style,
              'remove-attachment-${attachment.id}',
              strings.removeAttachment,
              () => attachments.remove(attachment.id),
            ),
          ]),
        if (onAttach != null)
          _button(style, 'attach', strings.attachFile, onAttach),
      ],
    ),
  );
}

/// Cuts the selected picture to a box or a free-hand outline.
class NoteImageCropDrawer extends StatefulWidget {
  const NoteImageCropDrawer({
    required this.controller,
    required this.strings,
    required this.style,
    required this.imageProviderResolver,
    required this.onClose,
    super.key,
  });

  static const double _height = 220;

  final NoteEditorController controller;
  final NoteEditorStrings strings;
  final NoteEditorStyle style;
  final NoteImageProviderResolver imageProviderResolver;
  final VoidCallback onClose;

  @override
  State<NoteImageCropDrawer> createState() => _NoteImageCropDrawerState();
}

class _NoteImageCropDrawerState extends State<NoteImageCropDrawer> {
  bool _free = false;
  Offset? _start;
  Offset? _end;
  final List<Offset> _path = [];
  Size _area = Size.zero;

  @override
  Widget build(BuildContext context) {
    final image = widget.controller.selectedImage;
    if (image == null) return const SizedBox.shrink();
    final crop = NoteImageStyle.decode(image.imageStyle).crop.bounds;
    // The whole picture's shape, from the part the page shows now.
    final aspect = (image.width / crop.width) / (image.height / crop.height);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: widget.style.spacing,
      children: [
        _Buttons(widget.style, [
          for (final (free, label) in [
            (false, widget.strings.rectangleCrop),
            (true, widget.strings.freeCrop),
          ])
            _button(
              widget.style,
              'crop-${free ? 'free' : 'box'}',
              label,
              () => setState(() {
                _free = free;
                _reset();
              }),
              selected: _free == free,
            ),
          _button(widget.style, 'crop-apply', widget.strings.applyCrop, _apply),
          _button(
            widget.style,
            'crop-cancel',
            widget.strings.cancel,
            widget.onClose,
          ),
        ]),
        SizedBox(
          height: NoteImageCropDrawer._height,
          child: Center(
            child: AspectRatio(
              aspectRatio: aspect.isFinite && aspect > 0 ? aspect : 1,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  _area = constraints.biggest;

                  return GestureDetector(
                    key: const ValueKey('note-crop-area'),
                    onPanStart: (details) => setState(() {
                      _reset();
                      _start = details.localPosition;
                      _end = details.localPosition;
                      _path.add(details.localPosition);
                    }),
                    onPanUpdate: (details) => setState(() {
                      _end = details.localPosition;
                      _path.add(details.localPosition);
                    }),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image(
                          image: widget.imageProviderResolver(image.source),
                          fit: BoxFit.fill,
                          errorBuilder: (context, error, stack) =>
                              ColoredBox(color: widget.style.dividerColor),
                        ),
                        CustomPaint(
                          painter: _CropPainter(
                            rect: _free ? null : _rect,
                            path: _free ? List.of(_path) : const [],
                            color: widget.style.accentColor,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Rect? get _rect {
    final start = _start;
    final end = _end;

    return start == null || end == null ? null : Rect.fromPoints(start, end);
  }

  void _reset() {
    _start = null;
    _end = null;
    _path.clear();
  }

  void _apply() {
    final image = widget.controller.selectedImage;
    if (image == null || _area.isEmpty) return;
    Offset fraction(Offset point) =>
        Offset(point.dx / _area.width, point.dy / _area.height);
    final NoteImageCrop crop;
    if (_free) {
      crop = NoteImageCrop.polygon(_path.map(fraction).toList());
    } else {
      final rect = _rect;
      if (rect == null) return;
      final topLeft = fraction(rect.topLeft);
      final bottomRight = fraction(rect.bottomRight);
      crop = NoteImageCrop.rect(
        topLeft.dx,
        topLeft.dy,
        bottomRight.dx,
        bottomRight.dy,
      );
    }
    if (crop == NoteImageCrop.none) return;
    widget.controller.styleSelectedImage(
      NoteImageStyle.decode(image.imageStyle).copyWith(crop: crop),
    );
    widget.onClose();
  }
}

class _CropPainter extends CustomPainter {
  const _CropPainter({required this.path, required this.color, this.rect});

  final Rect? rect;
  final List<Offset> path;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = color;
    if (rect case final rect?) canvas.drawRect(rect, stroke);
    if (path.length > 1) {
      canvas.drawPath(Path()..addPolygon(path, true), stroke);
    }
  }

  @override
  bool shouldRepaint(_CropPainter oldDelegate) =>
      oldDelegate.rect != rect || oldDelegate.path.length != path.length;
}

import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/editor/internal/note_editor_button.dart';
import 'package:open_note/src/note/editor/internal/note_editor_drawer_kind.dart';
import 'package:open_note/src/note/editor/note_editor_controller.dart';
import 'package:open_note/src/note/editor/note_editor_mode.dart';
import 'package:open_note/src/note/editor/note_editor_strings.dart';
import 'package:open_note/src/note/editor/note_editor_style.dart';
import 'package:open_note/src/note/objects/note_arrow_object.dart';
import 'package:open_note/src/note/objects/note_link_object.dart';
import 'package:open_note/src/note/objects/note_object_controller.dart';
import 'package:open_note/src/note/objects/note_sticker_object.dart';
import 'package:open_note/src/note/objects/note_sticky_object.dart';
import 'package:open_note/src/note/study/overlay/note_mask_object.dart';
import 'package:open_note/src/note/study/overlay/note_mask_pen_session.dart';
import 'package:open_note/src/note/study/overlay/note_tape_object.dart';
import 'package:open_note/src/note/table/note_table_object.dart';
import 'package:open_note/src/note/table/note_table_toolbar.dart';

/// The bar of the object, read, cover and capture modes.
class NoteObjectOptions extends StatelessWidget {
  const NoteObjectOptions({
    required this.controller,
    required this.strings,
    required this.style,
    required this.onDrawer,
    super.key,
  });

  static const List<Color> _paperColors = [
    Color(0xFFFFF59D),
    Color(0xFFFFCCBC),
    Color(0xFFC8E6C9),
    Color(0xFFBBDEFB),
    Color(0xFFE1BEE7),
  ];

  final NoteEditorController controller;
  final NoteEditorStrings strings;
  final NoteEditorStyle style;
  final ValueChanged<NoteEditorDrawerKind> onDrawer;

  /// The objects with the selection: the page's, or the every-page ones.
  NoteObjectController? get _selectionOwner {
    final session = controller.session;
    if (session.objects.selectedIds.isNotEmpty) return session.objects;

    return session.shared.selectedIds.isNotEmpty ? session.shared : null;
  }

  @override
  Widget build(BuildContext context) => switch (controller.mode) {
    NoteEditorMode.objects => _objects(),
    NoteEditorMode.maskPen => _strip(_maskPen()),
    NoteEditorMode.read => _strip([
      _button('reveal-all', strings.revealAll, () {
        controller.setMasksRevealed(true);
      }),
      _button('cover-all', strings.coverAll, () {
        controller.setMasksRevealed(false);
      }),
    ]),
    NoteEditorMode.region => _strip([
      Text(strings.regionHint, style: style.textStyle),
      _button('cancel-capture', strings.cancel, () {
        controller.mode = NoteEditorMode.draw;
      }),
    ]),
    NoteEditorMode.draw || NoteEditorMode.pdfText => const SizedBox.shrink(),
  };

  Widget _strip(List<Widget> children) =>
      NoteEditorStrip(style: style, children: children);

  Widget _objects() {
    final owner = _selectionOwner;
    final selection = owner?.selection ?? const <NoteObject>[];
    final single = selection.length == 1 ? selection.single : null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _strip([
          _button('insert-sticky', strings.stickyNote, _insertSticky),
          _button('insert-arrow', strings.arrow, _insertArrow),
          _button('insert-curve', strings.curve, _insertCurve),
          _button('insert-table', strings.tableObject, _insertTable),
          _button('insert-link', strings.linkArea, _insertLink),
          _button('insert-tape', strings.tape, _insertTape),
          _button(
            'insert-sticker',
            strings.sticker,
            () => onDrawer(NoteEditorDrawerKind.stickers),
          ),
          if (owner != null) ..._selectionActions(owner, selection),
        ]),
        if (owner != null && single != null)
          if (_specific(owner, single) case final Widget bar) bar,
      ],
    );
  }

  List<Widget> _selectionActions(
    NoteObjectController owner,
    List<NoteObject> selection,
  ) {
    final ids = {for (final object in selection) object.id};
    final locked = selection.every((object) => object.locked);

    return [
      _button('duplicate', strings.duplicate, () => owner.duplicate(ids)),
      _button('delete', strings.delete, () => owner.remove(ids)),
      _button('front', strings.bringToFront, () => owner.bringToFront(ids)),
      _button('back', strings.sendToBack, () => owner.sendToBack(ids)),
      _button(
        'lock',
        locked ? strings.unlock : strings.lock,
        () => owner.setLocked(ids, !locked),
      ),
    ];
  }

  Widget? _specific(NoteObjectController owner, NoteObject object) =>
      switch (object) {
        NoteTableObject() => Padding(
          padding: EdgeInsets.symmetric(horizontal: style.spacing),
          child: NoteTableToolbar(
            table: object,
            selectionController: controller.tableSelection,
            strings: strings.table,
            onChanged: owner.update,
          ),
        ),
        NoteStickyObject() => _strip([
          for (final color in _paperColors)
            NoteEditorSwatch(
              key: ValueKey('note-paper-${color.toARGB32()}'),
              color: color,
              label: strings.colorName(color.toARGB32()),
              style: style,
              selected: object.paperColor == color,
              onPressed: () => owner.update(object.copyWith(paperColor: color)),
            ),
        ]),
        NoteArrowObject() => _strip([
          for (final color in const [
            Color(0xFF212121),
            Color(0xFFE53935),
            Color(0xFF1E88E5),
          ])
            NoteEditorSwatch(
              key: ValueKey('note-arrow-${color.toARGB32()}'),
              color: color,
              label: strings.colorName(color.toARGB32()),
              style: style,
              selected: object.color == color,
              onPressed: () => owner.update(object.copyWith(color: color)),
            ),
          _button(
            'arrow-dashed',
            strings.dashed,
            () => owner.update(object.copyWith(dashed: !object.dashed)),
            selected: object.dashed,
          ),
          if (object.bend != null)
            _button(
              'arrow-straighten',
              strings.straighten,
              () => owner.update(object.straightened()),
            ),
        ]),
        NoteLinkObject() => _strip([
          SizedBox(
            width: 260,
            child: NoteTextField(
              key: ValueKey('note-link-target-${object.id}-${object.target}'),
              initialText: object.target,
              hintText: strings.linkHint,
              submitOnBlur: true,
              onSubmitted: (value) {
                final current = owner.find(object.id);
                if (current is NoteLinkObject &&
                    current.target != value.trim()) {
                  owner.update(current.copyWith(target: value.trim()));
                }
              },
            ),
          ),
          _button(
            'link-to-page',
            strings.linkToPage,
            () => onDrawer(NoteEditorDrawerKind.linkPages),
          ),
        ]),
        NoteStickerObject() => _strip([
          _button(
            'flip-sticker',
            '↔',
            () => owner.update(
              object.copyWith(flipHorizontal: !object.flipHorizontal),
            ),
            selected: object.flipHorizontal,
          ),
        ]),
        _ => null,
      };

  List<Widget> _maskPen() {
    final session = controller.maskPen;
    void replace({NoteMaskShape? shape, NoteMaskScope? scope}) {
      controller.maskPen = NoteMaskPenSession(
        shape: shape ?? session.shape,
        thickness: session.thickness,
        fill: session.fill,
        fillOpacity: session.fillOpacity,
        scope: scope ?? session.scope,
        minSize: session.minSize,
        idFactory: controller.newId,
      );
    }

    return [
      for (final (shape, label) in [
        (NoteMaskShape.rect, strings.maskBox),
        (NoteMaskShape.stroke, strings.maskPenShape),
      ])
        _button(
          'mask-${shape.name}',
          label,
          () => replace(shape: shape),
          selected: session.shape == shape,
        ),
      _button(
        'mask-every-page',
        strings.maskEveryPage,
        () => replace(
          scope: session.scope == NoteMaskScope.document
              ? NoteMaskScope.page
              : NoteMaskScope.document,
        ),
        selected: session.scope == NoteMaskScope.document,
      ),
      _button('reveal-all', strings.revealAll, () {
        controller.setMasksRevealed(true);
      }),
      _button('cover-all', strings.coverAll, () {
        controller.setMasksRevealed(false);
      }),
      _button('remove-covers', strings.removeCovers, controller.clearMasks),
    ];
  }

  void _insertSticky() => controller.addObject(
    NoteStickyObject(
      id: controller.newId(),
      bounds: controller.placement(const Size(180, 150)),
    ),
  );

  void _insertArrow() {
    final center = controller.placement(const Size(1, 1)).center;
    controller.addObject(
      NoteArrowObject.fromPoints(
        id: controller.newId(),
        from: center - const Offset(80, 0),
        to: center + const Offset(80, 0),
      ),
    );
  }

  /// A line without heads, already bent a little so the grip is easy to find.
  void _insertCurve() {
    final center = controller.placement(const Size(1, 1)).center;
    controller.addObject(
      NoteArrowObject.fromPoints(
        id: controller.newId(),
        from: center - const Offset(120, 0),
        to: center + const Offset(120, 0),
        through: center - const Offset(0, 50),
        headStyle: NoteArrowCap.none,
      ),
    );
  }

  void _insertTable() => controller.addObject(
    NoteTableObject.grid(
      id: controller.newId(),
      bounds: controller.placement(const Size(360, 150)),
    ),
  );

  void _insertLink() => controller.addObject(
    NoteLinkObject(
      id: controller.newId(),
      bounds: controller.placement(const Size(200, 44)),
    ),
  );

  void _insertTape() {
    final bounds = controller.placement(const Size(220, 36));
    controller.addObject(
      NoteTapeObject(id: controller.newId(), bounds: bounds),
    );
  }

  Widget _button(
    String key,
    String label,
    VoidCallback onPressed, {
    bool selected = false,
  }) => NoteEditorButton(
    key: ValueKey('note-object-$key'),
    label: label,
    style: style,
    onPressed: onPressed,
    selected: selected,
  );
}

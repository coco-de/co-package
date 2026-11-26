import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:open_note/src/module/text/link_hit_test.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/editor/note_editor_controller.dart';
import 'package:open_note/src/note/editor/note_editor_mode.dart';
import 'package:open_note/src/note/editor/note_editor_strings.dart';
import 'package:open_note/src/note/editor/note_page_session.dart';
import 'package:open_note/src/note/nav/note_excerpt_flash_overlay.dart';
import 'package:open_note/src/note/objects/note_arrow_object.dart';
import 'package:open_note/src/note/objects/note_object_geometry.dart';
import 'package:open_note/src/note/objects/note_object_controller.dart';
import 'package:open_note/src/note/objects/note_object_layer.dart';
import 'package:open_note/src/note/study/overlay/note_mask_object.dart';
import 'package:open_note/src/note/study/overlay/note_region_selector.dart';
import 'package:open_note/src/note/table/note_table_layout.dart';
import 'package:open_note/src/note/table/note_table_object.dart';
import 'package:open_note/src/note/table/note_table_range.dart';
import 'package:open_note/src/note/view/note_ruler.dart';

/// Everything above the ink, in page coordinates: the every-page and page
/// objects, the excerpt flash, text links in read mode, the mask pen and the
/// capture rectangle.
class NotePageOverlay extends StatefulWidget {
  const NotePageOverlay({
    required this.controller,
    required this.strings,
    required this.onRegionSelected,
    super.key,
  });

  final NoteEditorController controller;
  final NoteEditorStrings strings;
  final ValueChanged<Rect> onRegionSelected;

  @override
  State<NotePageOverlay> createState() => _NotePageOverlayState();
}

class _NotePageOverlayState extends State<NotePageOverlay> {
  NotePageSession? _session;
  Offset _lastPointer = Offset.zero;
  String? _editingId;
  Set<String> _pageSelection = const {};
  Set<String> _sharedSelection = const {};

  @override
  void initState() {
    super.initState();
    _attach(widget.controller.session);
  }

  @override
  void didUpdateWidget(NotePageOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(_session, widget.controller.session)) {
      _detach();
      _attach(widget.controller.session);
    }
  }

  @override
  void dispose() {
    _detach();
    super.dispose();
  }

  void _attach(NotePageSession session) {
    _session = session;
    _pageSelection = session.objects.selectedIds;
    _sharedSelection = session.shared.selectedIds;
    session.objects.addListener(_onObjectsChanged);
    session.shared.addListener(_onObjectsChanged);
  }

  void _detach() {
    _session?.objects.removeListener(_onObjectsChanged);
    _session?.shared.removeListener(_onObjectsChanged);
    _session = null;
  }

  /// Keeps one selection across the two object layers, and selects the tapped
  /// cell when a table starts being edited.
  void _onObjectsChanged() {
    final session = _session;
    if (session == null) return;
    final page = session.objects.selectedIds;
    final shared = session.shared.selectedIds;
    final pageGrew = !_sameIds(page, _pageSelection) && page.isNotEmpty;
    final sharedGrew = !_sameIds(shared, _sharedSelection) && shared.isNotEmpty;
    _pageSelection = page;
    _sharedSelection = shared;
    if (pageGrew && shared.isNotEmpty) session.shared.clearSelection();
    if (sharedGrew && page.isNotEmpty) session.objects.clearSelection();
    _selectTappedCell(session);
  }

  void _selectTappedCell(NotePageSession session) {
    for (final owner in [session.objects, session.shared]) {
      final id = owner.editingId;
      if (id == null) continue;
      if (id == _editingId) return;
      _editingId = id;
      _selectCell(owner, id);

      return;
    }
    _editingId = null;
  }

  void _selectCell(NoteObjectController owner, String id) {
    final table = owner.find(id);
    if (table is! NoteTableObject) return;
    final center = table.bounds.center;
    final offset = _lastPointer - center;
    final cos = math.cos(-table.rotation);
    final sin = math.sin(-table.rotation);
    final local =
        center +
        Offset(
          offset.dx * cos - offset.dy * sin,
          offset.dx * sin + offset.dy * cos,
        );
    final cell = NoteTableLayout(table, table.bounds).cellAt(local);
    widget.controller.tableSelection.select(
      id,
      table.expandToMerges(NoteTableRange.cell(cell.row, cell.column)),
    );
  }

  void _followTextLink(Offset point) {
    final layers = widget.controller.layers;
    for (final content in layers.contents.reversed) {
      if (!content.layer.visible) continue;
      final link = findLinkAtCanvasPoint(content.scribble.textDrawables, point);
      if (link != null) {
        widget.controller.followRawLink(link.url);

        return;
      }
    }
  }

  /// A grip on the middle of a lone selected line: drag it to bend the line.
  Widget? _bendGrip(NotePageSession session) {
    for (final owner in [session.objects, session.shared]) {
      final selection = owner.selection;
      if (selection.length != 1) continue;
      final line = selection.single;
      if (line is! NoteArrowObject || line.locked) return null;

      return _BendGrip(
        key: ValueKey('note-bend-${line.id}'),
        owner: owner,
        line: line,
        label: widget.strings.bendLine,
      );
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final session = controller.session;
    final size = controller.page.size.toSize();
    final mode = controller.mode;
    final layerMode = switch (mode) {
      NoteEditorMode.objects => NoteObjectLayerMode.edit,
      NoteEditorMode.read => NoteObjectLayerMode.view,
      _ => NoteObjectLayerMode.passThrough,
    };
    Widget objects(String key, NoteObjectController owner) => NoteObjectLayer(
      key: ValueKey('note-$key-objects'),
      controller: owner,
      registry: controller.document.registry,
      size: size,
      mode: layerMode,
      onLinkActivated: controller.followLink,
      strings: widget.strings.objects,
    );

    return Listener(
      onPointerDown: (event) => _lastPointer = event.localPosition,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (mode == NoteEditorMode.read)
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTapUp: (details) => _followTextLink(details.localPosition),
            ),
          IgnorePointer(
            child: NoteExcerptFlashOverlay(
              controller: controller.excerptFlash,
              excerpts: controller.document.excerpts,
              pageId: controller.pageId,
            ),
          ),
          objects('shared', session.shared),
          objects('page', session.objects),
          if (mode == NoteEditorMode.objects) ?_bendGrip(session),
          NoteRuler(controller: controller.ruler, strings: widget.strings.view),
          if (mode == NoteEditorMode.maskPen)
            _MaskPenSurface(controller: controller),
          if (mode == NoteEditorMode.pdfText)
            _PdfTextSurface(controller: controller),
          if (mode == NoteEditorMode.region)
            NoteRegionSelector(
              onRegionSelected: widget.onRegionSelected,
              onCancel: () => controller.mode = NoteEditorMode.draw,
              confirmOnRelease: true,
              strings: widget.strings.studyOverlay,
            ),
        ],
      ),
    );
  }

  static bool _sameIds(Set<String> a, Set<String> b) =>
      a.length == b.length && a.containsAll(b);
}

/// Draws a mask under the pen; it takes the pointer so the page does not pan.
class _MaskPenSurface extends StatefulWidget {
  const _MaskPenSurface({required this.controller});

  final NoteEditorController controller;

  @override
  State<_MaskPenSurface> createState() => _MaskPenSurfaceState();
}

class _MaskPenSurfaceState extends State<_MaskPenSurface> {
  int? _pointer;

  @override
  Widget build(BuildContext context) => RawGestureDetector(
    behavior: HitTestBehavior.opaque,
    gestures: {
      EagerGestureRecognizer:
          GestureRecognizerFactoryWithHandlers<EagerGestureRecognizer>(
            EagerGestureRecognizer.new,
            (_) {},
          ),
    },
    child: Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (event) {
        if (_pointer != null) return;
        _pointer = event.pointer;
        setState(() => widget.controller.maskPen.add(event.localPosition));
      },
      onPointerMove: (event) {
        if (event.pointer != _pointer) return;
        setState(() => widget.controller.maskPen.add(event.localPosition));
      },
      onPointerUp: (event) {
        if (event.pointer != _pointer) return;
        _pointer = null;
        final session = widget.controller.maskPen..add(event.localPosition);
        final mask = session.finish();
        if (mask != null) widget.controller.addMask(mask);
        setState(() {});
      },
      onPointerCancel: (event) {
        if (event.pointer != _pointer) return;
        _pointer = null;
        setState(widget.controller.maskPen.cancel);
      },
      child: CustomPaint(
        size: Size.infinite,
        painter: _MaskPreviewPainter(widget.controller.maskPen.preview()),
      ),
    ),
  );
}

class _MaskPreviewPainter extends CustomPainter {
  const _MaskPreviewPainter(this.preview);

  final NoteMaskObject? preview;

  @override
  void paint(Canvas canvas, Size size) =>
      preview?.paintToCanvas(canvas, NoteObjectPaintContext.empty);

  @override
  bool shouldRepaint(_MaskPreviewPainter oldDelegate) =>
      oldDelegate.preview != preview;
}

/// Selects PDF text under a drag (a tap picks one run) and shows the
/// selection; like the mask pen it takes the pointer so the page stays put.
class _PdfTextSurface extends StatefulWidget {
  const _PdfTextSurface({required this.controller});

  final NoteEditorController controller;

  @override
  State<_PdfTextSurface> createState() => _PdfTextSurfaceState();
}

class _PdfTextSurfaceState extends State<_PdfTextSurface> {
  int? _pointer;
  Offset _start = Offset.zero;

  @override
  Widget build(BuildContext context) => RawGestureDetector(
    key: const ValueKey('note-pdf-surface'),
    behavior: HitTestBehavior.opaque,
    gestures: {
      EagerGestureRecognizer:
          GestureRecognizerFactoryWithHandlers<EagerGestureRecognizer>(
            EagerGestureRecognizer.new,
            (_) {},
          ),
    },
    child: Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (event) {
        if (_pointer != null) return;
        _pointer = event.pointer;
        _start = event.localPosition;
        widget.controller.selectPdfText(_start, _start);
      },
      onPointerMove: (event) {
        if (event.pointer != _pointer) return;
        widget.controller.selectPdfText(_start, event.localPosition);
      },
      onPointerUp: (event) {
        if (event.pointer == _pointer) _pointer = null;
      },
      onPointerCancel: (event) {
        if (event.pointer != _pointer) return;
        _pointer = null;
        widget.controller.pdfText.clear();
      },
      child: CustomPaint(
        size: Size.infinite,
        painter: _PdfSelectionPainter(widget.controller.pdfSelectionRects),
      ),
    ),
  );
}

class _PdfSelectionPainter extends CustomPainter {
  const _PdfSelectionPainter(this.rects);

  static const Color _color = Color(0x552962FF);

  final List<Rect> rects;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = _color;
    for (final rect in rects) {
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(_PdfSelectionPainter oldDelegate) =>
      !listEquals(oldDelegate.rects, rects);
}

/// Bends [line] by dragging; one drag is one undo step.
class _BendGrip extends StatefulWidget {
  const _BendGrip({
    required this.owner,
    required this.line,
    required this.label,
    super.key,
  });

  /// In page units, like the object layer's grips.
  static const double _radius = 10;
  static const double _touchRadius = 20;

  final NoteObjectController owner;
  final NoteArrowObject line;
  final String label;

  @override
  State<_BendGrip> createState() => _BendGripState();
}

class _BendGripState extends State<_BendGrip> {
  int? _pointer;

  /// Where the dragged middle is on screen, in page units.
  Offset _target = Offset.zero;

  static Offset _screenPoint(NoteArrowObject line) =>
      line.bounds.center +
      NoteObjectGeometry.rotateVector(
        line.bendPoint - line.bounds.center,
        line.rotation,
      );

  @override
  Widget build(BuildContext context) {
    final center = _screenPoint(widget.line);

    return Stack(
      children: [
        Positioned.fromRect(
          rect: Rect.fromCircle(center: center, radius: _BendGrip._touchRadius),
          child: Semantics(
            label: widget.label,
            child: RawGestureDetector(
              behavior: HitTestBehavior.opaque,
              gestures: {
                EagerGestureRecognizer:
                    GestureRecognizerFactoryWithHandlers<
                      EagerGestureRecognizer
                    >(EagerGestureRecognizer.new, (_) {}),
              },
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: (event) {
                  if (_pointer != null) return;
                  _pointer = event.pointer;
                  _target = _screenPoint(widget.line);
                  widget.owner.beginGesture();
                },
                onPointerMove: (event) {
                  if (event.pointer != _pointer) return;
                  _target += event.localDelta;
                  _bendTo(_target);
                },
                onPointerUp: (event) {
                  if (event.pointer != _pointer) return;
                  _pointer = null;
                  widget.owner.endGesture();
                },
                onPointerCancel: (event) {
                  if (event.pointer != _pointer) return;
                  _pointer = null;
                  widget.owner.cancelGesture();
                },
                child: Center(
                  child: DecoratedBox(
                    key: const ValueKey('note-bend-grip'),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFFFFFF),
                      border: Border.all(
                        color: const Color(0xFF2962FF),
                        width: 2,
                      ),
                    ),
                    child: const SizedBox.square(
                      dimension: _BendGrip._radius * 2,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _bendTo(Offset onScreen) {
    final line = widget.owner.find(widget.line.id);
    if (line is! NoteArrowObject) return;
    final center = line.bounds.center;
    final unturned =
        center +
        NoteObjectGeometry.rotateVector(onScreen - center, -line.rotation);
    widget.owner.update(line.bentThrough(unturned));
  }
}

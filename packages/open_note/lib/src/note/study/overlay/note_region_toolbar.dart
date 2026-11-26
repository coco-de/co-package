import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/study/overlay/note_overlay_button.dart';
import 'package:open_note/src/note/study/overlay/note_overlay_glyph.dart';
import 'package:open_note/src/note/study/overlay/note_region_selector_style.dart';
import 'package:open_note/src/note/study/overlay/note_study_overlay_strings.dart';

/// The confirm/cancel bar of `NoteRegionSelector`, placed in its `Stack`: below
/// the selection, above it when there is no room below, inside it when there is
/// room in neither place, and at the top-right of the page when there is no
/// selection. Internal to `study/overlay`.
class NoteRegionToolbar extends StatelessWidget {
  /// Creates the bar; a button without a callback is left out.
  const NoteRegionToolbar({
    required this.page,
    required this.region,
    required this.style,
    required this.strings,
    this.onConfirm,
    this.onCancel,
    super.key,
  });

  static const double _inset = 4;

  /// Size of the page.
  final Size page;

  /// The selection, if any.
  final Rect? region;

  /// Colours and metrics.
  final NoteRegionSelectorStyle style;

  /// Button labels.
  final NoteStudyOverlayStrings strings;

  /// Accepts the selection.
  final VoidCallback? onConfirm;

  /// Abandons the selection.
  final VoidCallback? onCancel;

  /// Where a [bar]-sized toolbar goes for the selection [region].
  Offset placeFor(Size bar) {
    final selection = region;
    final gap = style.toolbarGap;
    if (selection == null) {
      return Offset(math.max(0.0, page.width - bar.width - gap), gap);
    }
    final rightmost = math.max(0.0, page.width - bar.width);
    final left = (selection.right - bar.width).clamp(0.0, rightmost);
    var top = selection.bottom + gap;
    if (top + bar.height > page.height) top = selection.top - gap - bar.height;
    if (top < 0) top = math.max(0.0, selection.bottom - gap - bar.height);

    return Offset(left, top);
  }

  @override
  Widget build(BuildContext context) {
    final confirm = onConfirm;
    final cancel = onCancel;
    if (confirm == null && cancel == null) return const SizedBox.shrink();
    final count = (confirm == null ? 0 : 1) + (cancel == null ? 0 : 1);
    final bar = Size(
      count * style.buttonExtent + _inset * 2,
      style.buttonExtent + _inset * 2,
    );
    final origin = placeFor(bar);

    return Positioned(
      left: origin.dx,
      top: origin.dy,
      width: bar.width,
      height: bar.height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: style.toolbarColor,
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 8)],
        ),
        child: Padding(
          padding: const EdgeInsets.all(_inset),
          child: Row(children: _buttons(confirm, cancel)),
        ),
      ),
    );
  }

  List<Widget> _buttons(VoidCallback? confirm, VoidCallback? cancel) => [
    if (confirm != null)
      NoteOverlayButton(
        key: const ValueKey('note-region-confirm'),
        label: strings.confirmRegion,
        onPressed: confirm,
        minWidth: style.buttonExtent,
        height: style.buttonExtent,
        background: style.accentColor,
        child: const NoteOverlayGlyph(
          NoteOverlayGlyphKind.check,
          color: Color(0xFFFFFFFF),
        ),
      ),
    if (cancel != null)
      NoteOverlayButton(
        key: const ValueKey('note-region-cancel'),
        label: strings.cancelRegion,
        onPressed: cancel,
        minWidth: style.buttonExtent,
        height: style.buttonExtent,
        child: NoteOverlayGlyph(
          NoteOverlayGlyphKind.close,
          color: style.toolbarIconColor,
        ),
      ),
  ];
}

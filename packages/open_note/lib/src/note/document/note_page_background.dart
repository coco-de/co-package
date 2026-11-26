import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:open_note/src/module/image/image_source_resolver.dart';
import 'package:open_note/src/note/document/note_page.dart';
import 'package:open_note/src/note/template/note_paper_kind.dart';
import 'package:open_note/src/note/template/note_paper_painter.dart';
import 'package:open_note/src/note/template/note_paper_template.dart';
import 'package:open_note/src/note/template/note_paper_view.dart';

/// The paper of a [NotePage] as a widget, sized to the page. Use it as the
/// background of the page view.
///
/// A repeating paper (blank, lined, grid, dotted, music) continues over the
/// extended margins with its ruling where it was, unless the margins have
/// their own paper. Otherwise the margins show [NotePage.marginTemplate] (a
/// plain sheet in the paper's colour for image and Cornell papers) with the
/// (possibly turned) paper over the content.
class NotePageBackground extends StatelessWidget {
  const NotePageBackground(this.page, {super.key, this.imageProviderResolver});

  final NotePage page;

  /// Resolves image papers; the engine's resolver when null.
  final NotePaperImageResolver? imageProviderResolver;

  @override
  Widget build(BuildContext context) {
    final size = page.size.toSize();
    final paper = page.template.fitted(page.paperSize);
    if (_continues(page)) {
      final sheet = _unturnedSheet(page);

      return SizedBox.fromSize(
        size: size,
        child: RotatedBox(
          quarterTurns: page.paperTurns,
          child: _paperView(paper, sheet: sheet),
        ),
      );
    }

    return SizedBox.fromSize(
      size: size,
      child: Stack(
        children: [
          if (page.margins != EdgeInsets.zero)
            Positioned.fill(child: _paperView(_marginPaper(page))),
          Positioned.fromRect(
            rect: page.contentRect,
            child: ClipRect(
              child: RotatedBox(
                quarterTurns: page.paperTurns,
                child: _paperView(paper),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _paperView(
    NotePaperTemplate template, {
    ({Size size, Rect paper})? sheet,
  }) => NotePaperView(
    template: template,
    sheetSize: sheet?.size,
    paperRect: sheet?.paper,
    imageProviderResolver: imageProviderResolver ?? resolveImageSource,
  );

  /// Paints the same paper onto [canvas] in page coordinates — for export,
  /// where widgets are not available. Image papers need their decoded picture
  /// in [images] (keyed by source).
  static void paint(
    ui.Canvas canvas,
    NotePage page, {
    Map<String, ui.Image> images = const {},
  }) {
    ui.Image? imageFor(String? source) =>
        source == null ? null : images[source];
    void paintPaper(NotePaperTemplate paper, Size size, [Rect? at]) =>
        NotePaperPainter(
          paper,
          image: imageFor(paper.imageSource),
          paperRect: at,
        ).paint(canvas, size);
    final paper = page.template.fitted(page.paperSize);
    if (_continues(page)) {
      final sheet = _unturnedSheet(page);
      canvas.save();
      _turn(canvas, page.paperTurns, page.size.toSize());
      paintPaper(paper, sheet.size, sheet.paper);
      canvas.restore();

      return;
    }
    if (page.margins != EdgeInsets.zero) {
      paintPaper(_marginPaper(page), page.size.toSize());
    }
    final content = page.contentRect;
    canvas
      ..save()
      ..translate(content.left, content.top)
      ..clipRect(Offset.zero & content.size);
    _turn(canvas, page.paperTurns, content.size);
    paintPaper(paper, page.paperSize.toSize());
    canvas.restore();
  }

  /// Maps a drawing made before [turns] clockwise quarter turns onto an area
  /// of [size].
  static void _turn(ui.Canvas canvas, int turns, Size size) {
    switch (turns) {
      case 1:
        canvas
          ..translate(size.width, 0)
          ..rotate(math.pi / 2);
      case 2:
        canvas
          ..translate(size.width, size.height)
          ..rotate(math.pi);
      case 3:
        canvas
          ..translate(0, size.height)
          ..rotate(-math.pi / 2);
    }
  }

  /// Whether the paper itself carries on over the extended margins.
  static bool _continues(NotePage page) =>
      page.margins != EdgeInsets.zero &&
      page.marginTemplate == null &&
      _repeats(page.template.kind);

  /// The whole page and the place of the paper on it, before the paper's turns.
  static ({Size size, Rect paper}) _unturnedSheet(NotePage page) {
    final size = page.paperTurns.isOdd
        ? page.size.rotated.toSize()
        : page.size.toSize();
    var margins = page.margins;
    for (var turn = 0; turn < page.paperTurns; turn++) {
      // A quarter turn back, undoing one of `NotePageOps.rotate`.
      margins = EdgeInsets.fromLTRB(
        margins.top,
        margins.right,
        margins.bottom,
        margins.left,
      );
    }

    return (size: size, paper: margins.deflateRect(Offset.zero & size));
  }

  /// Whether the ruling of [kind] repeats, so a larger sheet continues it.
  static bool _repeats(NotePaperKind kind) => switch (kind) {
    NotePaperKind.blank ||
    NotePaperKind.lined ||
    NotePaperKind.grid ||
    NotePaperKind.dotted ||
    NotePaperKind.music => true,
    NotePaperKind.cornell || NotePaperKind.image => false,
  };

  static NotePaperTemplate _marginPaper(NotePage page) {
    if (page.marginTemplate case final margin?) return margin.fitted(page.size);

    return NotePaperTemplate.blank(
      size: page.size,
    ).copyWith(backgroundColor: page.template.backgroundColor);
  }
}

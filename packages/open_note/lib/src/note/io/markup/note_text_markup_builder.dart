import 'dart:math' as math;
import 'dart:ui';

import 'package:open_note/src/core/utils/ink_group_info.dart';
import 'package:open_note/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/io/markup/note_pdf_text_run.dart';
import 'package:open_note/src/note/io/markup/note_pdf_text_selection.dart';
import 'package:open_note/src/note/io/markup/note_text_markup_kind.dart';

/// Turns selected PDF text into ordinary engine strokes, so markup can be
/// erased, undone, layered and exported like handwriting.
///
/// - highlight: a `marker` stroke along the middle of the line, as tall as the
///   text (the marker paints twice its size, so `size` is half the height);
/// - underline and strikeout: a `pen` stroke of constant width (7 % of the text
///   height, 0.75–4) along the bottom or the middle.
///
/// Each stroke has two points inset by half its painted width, so the round
/// caps end exactly at the text edges.
abstract final class NoteTextMarkupBuilder {
  /// Alpha given to an opaque highlight colour so the text stays readable.
  static const double defaultHighlightOpacity = 0.4;

  static const double _lineRatio = 0.07;
  static const double _minLineWidth = 0.75;
  static const double _maxLineWidth = 4;

  /// Strokes for the selected [runs], top to bottom.
  ///
  /// With [mergeLines] (the default) runs on the same line, separated by no more
  /// than one line height, become one continuous stroke, so word gaps are not
  /// left unmarked; otherwise each run gets its own stroke, in the given order.
  /// Runs without a positive, finite box are ignored. An opaque highlight
  /// [color] is given [highlightOpacity]; a translucent one is kept.
  static List<Stroke> build(
    List<NotePdfTextRun> runs,
    NoteTextMarkupKind kind,
    Color color, {
    NoteIdFactory idFactory = generateNoteId,
    NoteClock clock = systemNoteClock,
    double highlightOpacity = defaultHighlightOpacity,
    bool mergeLines = true,
  }) {
    final boxes = [
      for (final run in runs)
        if (_isUsable(run.rect)) run.rect,
    ];
    if (boxes.isEmpty) return [];
    final isTooOpaque = kind == NoteTextMarkupKind.highlight && color.a >= 1;
    final paint = isTooOpaque
        ? color.withValues(alpha: highlightOpacity.clamp(0.0, 1.0))
        : color;
    final createdAt = clock().toIso8601String();

    return [
      for (final box in mergeLines ? _lineSpans(boxes) : boxes)
        _stroke(box, kind, paint, idFactory(), createdAt),
    ];
  }

  static bool _isUsable(Rect rect) =>
      rect.width > 0 &&
      rect.height > 0 &&
      rect.width.isFinite &&
      rect.height.isFinite &&
      rect.topLeft.isFinite;

  static List<Rect> _lineSpans(List<Rect> boxes) {
    final sorted = [...boxes]
      ..sort((a, b) {
        final byRow = a.center.dy.compareTo(b.center.dy);

        return byRow != 0 ? byRow : a.left.compareTo(b.left);
      });
    final lines = <List<Rect>>[];
    var bounds = sorted.first;
    for (final box in sorted) {
      if (lines.isNotEmpty && NotePdfTextSelection.isSameLine(bounds, box)) {
        lines.last.add(box);
        bounds = bounds.expandToInclude(box);
      } else {
        lines.add([box]);
        bounds = box;
      }
    }

    return [for (final line in lines) ..._joinNeighbours(line)];
  }

  static List<Rect> _joinNeighbours(List<Rect> line) {
    line.sort((a, b) => a.left.compareTo(b.left));
    final joined = [line.first];
    for (final box in line.skip(1)) {
      final previous = joined.last;
      final gap = box.left - previous.right;
      if (gap <= math.max(previous.height, box.height)) {
        joined.last = previous.expandToInclude(box);
      } else {
        joined.add(box);
      }
    }

    return joined;
  }

  static Stroke _stroke(
    Rect box,
    NoteTextMarkupKind kind,
    Color color,
    String id,
    String createdAt,
  ) {
    final isHighlight = kind == NoteTextMarkupKind.highlight;
    final painted = isHighlight
        ? box.height
        : (box.height * _lineRatio).clamp(_minLineWidth, _maxLineWidth);
    final y = kind == NoteTextMarkupKind.underline
        ? box.bottom - painted / 2
        : box.center.dy;
    final inset = math.min(painted, box.width) / 2;
    final size = isHighlight ? painted / 2 : painted;

    return Stroke(
      id: id,
      ink: isHighlight ? InkModes.marker : InkModes.pen,
      color: color.toARGB32(),
      width: size,
      createdAt: createdAt,
      points: [
        Point(x: box.left + inset, y: y, p: 0.5),
        Point(x: box.right - inset, y: y, p: 0.5),
      ],
      options: StrokeOptions(
        size: size,
        thinning: 0,
        smoothing: 0.5,
        streamline: 0,
        taperStart: 0,
        taperEnd: 0,
        capStart: true,
        capEnd: true,
        simulatePressure: false,
        isComplete: true,
      ),
    );
  }
}

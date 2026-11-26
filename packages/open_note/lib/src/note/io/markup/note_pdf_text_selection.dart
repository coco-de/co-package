import 'dart:math' as math;
import 'dart:ui';

import 'package:open_note/src/note/io/markup/note_pdf_text_run.dart';

/// Selecting the text runs of a PDF page the way readers do: from one point to
/// another in reading order. All points and boxes are in PDF coordinates.
abstract final class NotePdfTextSelection {
  /// How far from any run a selection may start.
  static const double defaultReach = 24;

  /// Rows count this many times more than columns when finding the nearest
  /// run, so a point past a line's end stays on that line.
  static const double _rowWeight = 3;

  /// [runs] with a visible box, top to bottom, left to right within a line.
  static List<NotePdfTextRun> readingOrder(List<NotePdfTextRun> runs) {
    final byRow = [
      for (final run in runs)
        if (run.rect.width > 0 && run.rect.height > 0) run,
    ]..sort((a, b) => a.rect.center.dy.compareTo(b.rect.center.dy));
    final lines = <List<NotePdfTextRun>>[];
    Rect? bounds;
    for (final run in byRow) {
      final line = bounds;
      if (line != null && isSameLine(line, run.rect)) {
        lines.last.add(run);
        bounds = line.expandToInclude(run.rect);
      } else {
        lines.add([run]);
        bounds = run.rect;
      }
    }

    return [
      for (final line in lines)
        ...line..sort((a, b) => a.rect.left.compareTo(b.rect.left)),
    ];
  }

  /// Whether [box] sits on the line covering [line]: they overlap by half of
  /// the lower one.
  static bool isSameLine(Rect line, Rect box) =>
      math.min(line.bottom, box.bottom) - math.max(line.top, box.top) >=
      math.min(line.height, box.height) / 2;

  /// The part of [ordered] from the run nearest [from] to the run nearest
  /// [to], either way round; empty when nothing is within [reach] of [from].
  static List<NotePdfTextRun> between(
    List<NotePdfTextRun> ordered,
    Offset from,
    Offset to, {
    double reach = defaultReach,
  }) {
    if (ordered.isEmpty) return const [];
    final start = _nearest(ordered, from);
    if (_distance(ordered[start].rect, from, 1) > reach) return const [];
    final end = _nearest(ordered, to);

    return ordered.sublist(math.min(start, end), math.max(start, end) + 1);
  }

  /// The text of [runs] in order: a space between runs of a line, a new line
  /// between lines.
  static String textOf(List<NotePdfTextRun> runs) {
    final text = StringBuffer();
    for (final (index, run) in runs.indexed) {
      if (index > 0) {
        text.write(isSameLine(runs[index - 1].rect, run.rect) ? ' ' : '\n');
      }
      text.write(run.text.trim());
    }

    return text.toString();
  }

  static int _nearest(List<NotePdfTextRun> runs, Offset point) {
    var best = 0;
    var bestDistance = double.infinity;
    for (final (index, run) in runs.indexed) {
      final distance = _distance(run.rect, point, _rowWeight);
      if (distance < bestDistance) {
        best = index;
        bestDistance = distance;
      }
    }

    return best;
  }

  static double _distance(Rect box, Offset point, double rowWeight) {
    final dx = math.max(
      0.0,
      math.max(box.left - point.dx, point.dx - box.right),
    );
    final dy = math.max(
      0.0,
      math.max(box.top - point.dy, point.dy - box.bottom),
    );

    return Offset(dx, dy * rowWeight).distance;
  }
}

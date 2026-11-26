import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:open_note/src/note/template/note_paper_kind.dart';
import 'package:open_note/src/note/template/note_paper_template.dart';

/// Paints a [NotePaperTemplate] in page coordinates.
///
/// The ruling is laid out over the size being painted (normally
/// `template.size`; a larger page simply gets more ruling), with the template
/// margins as absolute page units. Painting is deterministic.
///
/// With a [paperRect] the painted size is a sheet that continues the paper
/// lying there: the ruling keeps the paper's places (lines, lattice and staves
/// stay under what was written) and carries on to the sheet's own margins.
///
/// The picture of an `image` paper is drawn only when its decoded [image] is
/// given (export and capture); `NotePaperView` shows it with a widget instead.
class NotePaperPainter extends CustomPainter {
  const NotePaperPainter(this.template, {this.image, this.paperRect});

  /// At most this many rules per direction are drawn (a guard against absurd
  /// page sizes).
  static const int maxLinesPerAxis = 2000;

  /// At most this many dots are drawn.
  static const int maxDots = 100000;

  static const double _dotRadiusRatio = 1.5;
  static const double _accentWidthRatio = 1.5;
  static const int _staffLines = 5;
  static const double _staffPitchSpacings = 9;
  static const double _epsilon = 1e-6;

  /// The paper to paint.
  final NotePaperTemplate template;

  /// Where the paper lies on the painted sheet when the sheet continues it;
  /// null when the paper is the whole painted area.
  final Rect? paperRect;

  /// The decoded picture of an `image` paper, or `null`.
  final ui.Image? image;

  double get _spacing => template.lineSpacing;

  @override
  void paint(Canvas canvas, Size size) {
    final page = Offset.zero & size;
    canvas.drawRect(page, Paint()..color = template.backgroundColor);
    final paper = paperRect ?? page;
    // The paper's own writing area, which places the ruling, and the area the
    // ruling covers (the same unless the sheet continues the paper).
    final area = template.margins.deflateRect(paper);
    final cover = paperRect == null ? area : template.margins.deflateRect(page);
    if (template.kind == NotePaperKind.image) {
      _paintPicture(canvas, page);
    } else if (area.width > 0 && area.height > 0) {
      _paintRuling(canvas, page, area, cover);
    }
    _paintMarginLine(canvas, size, paper);
  }

  @override
  bool shouldRepaint(NotePaperPainter oldDelegate) =>
      oldDelegate.template != template ||
      oldDelegate.image != image ||
      oldDelegate.paperRect != paperRect;

  void _paintRuling(Canvas canvas, Rect page, Rect area, Rect cover) {
    switch (template.kind) {
      case NotePaperKind.blank:
      case NotePaperKind.image:
        break;
      case NotePaperKind.lined:
        _paintRules(canvas, area, cover, cover.bottom + _epsilon);
      case NotePaperKind.grid:
        _paintGrid(canvas, area, cover);
      case NotePaperKind.dotted:
        _paintDots(canvas, area, cover);
      case NotePaperKind.cornell:
        _paintRules(canvas, area, cover, area.bottom - _epsilon);
        _paintCornellDividers(canvas, page, area);
      case NotePaperKind.music:
        _paintStaves(canvas, area, cover);
    }
  }

  Paint _rulePaint() => Paint()
    ..color = template.lineColor
    ..style = PaintingStyle.stroke
    ..strokeWidth = template.lineWidth;

  Paint _accentPaint() => Paint()
    ..color = template.accentColor
    ..style = PaintingStyle.stroke
    ..strokeWidth = template.lineWidth * _accentWidthRatio;

  /// How many whole spacings fit into [extent].
  int _fitting(double extent) =>
      math.min(maxLinesPerAxis, ((extent + _epsilon) / _spacing).floor());

  /// The steps `i` for which `origin + i * step` lies within [from]–[to], at
  /// most [limit] of them.
  (int, int) _steps(
    double origin,
    double step,
    double from,
    double to,
    int limit,
  ) {
    final first = ((from - origin - _epsilon) / step).ceil();
    final last = ((to - origin + _epsilon) / step).floor();

    return (first, math.min(last, first + limit));
  }

  /// Horizontal rules below the top of [cover] down to [limit], spaced from the
  /// top of [area].
  void _paintRules(Canvas canvas, Rect area, Rect cover, double limit) {
    final paint = _rulePaint();
    // The first rule sits one spacing below the top of the writing area.
    final first = ((cover.top - area.top) / _spacing + _epsilon).floor() + 1;
    for (var i = first; i < first + maxLinesPerAxis; i++) {
      final y = area.top + i * _spacing;
      if (y > limit) break;
      canvas.drawLine(Offset(cover.left, y), Offset(cover.right, y), paint);
    }
  }

  /// The whole cells that fit into [area], centred.
  Rect _lattice(Rect area, int columns, int rows) => Rect.fromCenter(
    center: area.center,
    width: columns * _spacing,
    height: rows * _spacing,
  );

  void _paintGrid(Canvas canvas, Rect area, Rect cover) {
    final columns = _fitting(area.width);
    final rows = _fitting(area.height);
    if (columns == 0 || rows == 0) return;
    final grid = _lattice(area, columns, rows);
    final (left, right) = _steps(
      grid.left,
      _spacing,
      cover.left,
      cover.right,
      maxLinesPerAxis,
    );
    final (top, bottom) = _steps(
      grid.top,
      _spacing,
      cover.top,
      cover.bottom,
      maxLinesPerAxis,
    );
    double x(int i) => grid.left + i * _spacing;
    double y(int j) => grid.top + j * _spacing;
    final paint = _rulePaint();
    for (var i = left; i <= right; i++) {
      canvas.drawLine(Offset(x(i), y(top)), Offset(x(i), y(bottom)), paint);
    }
    for (var j = top; j <= bottom; j++) {
      canvas.drawLine(Offset(x(left), y(j)), Offset(x(right), y(j)), paint);
    }
  }

  void _paintDots(Canvas canvas, Rect area, Rect cover) {
    final lattice = _lattice(area, _fitting(area.width), _fitting(area.height));
    final (left, right) = _steps(
      lattice.left,
      _spacing,
      cover.left,
      cover.right,
      maxLinesPerAxis,
    );
    final (top, bottom) = _steps(
      lattice.top,
      _spacing,
      cover.top,
      cover.bottom,
      maxLinesPerAxis,
    );
    final perRow = math.max(0, right - left + 1);
    final count = math.min(maxDots, perRow * math.max(0, bottom - top + 1));
    final dots = [
      for (var i = 0; i < count; i++)
        lattice.topLeft +
            Offset(
                  (left + i % perRow).toDouble(),
                  (top + i ~/ perRow).toDouble(),
                ) *
                _spacing,
    ];
    canvas.drawPoints(
      ui.PointMode.points,
      dots,
      Paint()
        ..color = template.lineColor
        ..strokeCap = StrokeCap.round
        ..strokeWidth = template.lineWidth * _dotRadiusRatio * 2,
    );
  }

  void _paintCornellDividers(Canvas canvas, Rect page, Rect area) {
    final paint = _accentPaint();
    if (template.margins.top > 0) {
      canvas.drawLine(
        Offset(page.left, area.top),
        Offset(page.right, area.top),
        paint,
      );
    }
    if (template.margins.bottom > 0) {
      canvas.drawLine(
        Offset(page.left, area.bottom),
        Offset(page.right, area.bottom),
        paint,
      );
    }
    if (template.margins.left > 0) {
      canvas.drawLine(area.topLeft, area.bottomLeft, paint);
    }
  }

  void _paintStaves(Canvas canvas, Rect area, Rect cover) {
    final staff = (_staffLines - 1) * _spacing;
    if (area.height + _epsilon < staff) return;
    final pitch = _staffPitchSpacings * _spacing;
    final fitted = math.min(
      maxLinesPerAxis ~/ _staffLines,
      ((area.height - staff + _epsilon) / pitch).floor() + 1,
    );
    final top = area.top + (area.height - (fitted - 1) * pitch - staff) / 2;
    final (first, last) = _steps(
      top,
      pitch,
      cover.top,
      cover.bottom - staff,
      maxLinesPerAxis ~/ _staffLines - 1,
    );
    final paint = _rulePaint();
    for (var i = first; i <= last; i++) {
      _paintStaff(canvas, cover, top + i * pitch, paint);
    }
  }

  void _paintStaff(Canvas canvas, Rect area, double top, Paint paint) {
    for (var line = 0; line < _staffLines; line++) {
      final y = top + line * _spacing;
      canvas.drawLine(Offset(area.left, y), Offset(area.right, y), paint);
    }
    final bottom = top + (_staffLines - 1) * _spacing;
    canvas
      ..drawLine(Offset(area.left, top), Offset(area.left, bottom), paint)
      ..drawLine(Offset(area.right, top), Offset(area.right, bottom), paint);
  }

  void _paintMarginLine(Canvas canvas, Size size, Rect paper) {
    final margin = template.margins.left;
    final x = paper.left + margin;
    if (!template.showMarginLine || margin <= 0 || x >= size.width) return;
    if (template.kind == NotePaperKind.cornell ||
        template.kind == NotePaperKind.image) {
      return;
    }
    canvas.drawLine(Offset(x, 0), Offset(x, size.height), _accentPaint());
  }

  void _paintPicture(Canvas canvas, Rect page) {
    final picture = image;
    if (picture == null || template.imageOpacity <= 0 || page.isEmpty) return;
    paintImage(
      canvas: canvas,
      rect: page,
      image: picture,
      fit: template.imageFit.boxFit,
      opacity: template.imageOpacity,
      filterQuality: FilterQuality.medium,
    );
  }
}

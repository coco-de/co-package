import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/document/note_page.dart';
import 'package:open_note/src/note/template/note_paper_image_fit.dart';

/// Where the points of an imported PDF page lie on its note page: fitted onto
/// the paper like its picture, turned with the paper and placed in the content
/// area (inside the extended margins).
class NotePdfPageMapping {
  NotePdfPageMapping(NotePage page, NotePdfOrigin origin)
    : _paper = page.paperSize,
      _turns = page.paperTurns,
      _content = page.contentRect.topLeft,
      _scale = _fit(page, origin.size) {
    _inset = Offset(
      (_paper.width - origin.size.width * _scale.dx) / 2,
      (_paper.height - origin.size.height * _scale.dy) / 2,
    );
  }

  final NotePageSize _paper;
  final int _turns;
  final Offset _content;
  final Offset _scale;
  late final Offset _inset;

  /// How much lengths grow (the mean of both directions when stretched).
  double get scale => (_scale.dx + _scale.dy) / 2;

  Offset toPage(Offset pdf) {
    final paper = _inset + pdf.scale(_scale.dx, _scale.dy);

    // A quarter turn clockwise per turn, as the paper is shown.
    return _content +
        switch (_turns) {
          1 => Offset(_paper.height - paper.dy, paper.dx),
          2 => Offset(_paper.width - paper.dx, _paper.height - paper.dy),
          3 => Offset(paper.dy, _paper.width - paper.dx),
          _ => paper,
        };
  }

  Offset toPdf(Offset page) {
    final turned = page - _content;
    final paper = switch (_turns) {
      1 => Offset(turned.dy, _paper.height - turned.dx),
      2 => Offset(_paper.width - turned.dx, _paper.height - turned.dy),
      3 => Offset(_paper.width - turned.dy, turned.dx),
      _ => turned,
    };
    final fitted = paper - _inset;

    return Offset(fitted.dx / _scale.dx, fitted.dy / _scale.dy);
  }

  Rect rectToPage(Rect pdf) =>
      Rect.fromPoints(toPage(pdf.topLeft), toPage(pdf.bottomRight));

  static Offset _fit(NotePage page, NotePageSize pdf) {
    final paper = page.paperSize;
    final across = paper.width / pdf.width;
    final down = paper.height / pdf.height;

    final both = switch (page.template.imageFit) {
      NotePaperImageFit.contain => math.min(across, down),
      NotePaperImageFit.cover => math.max(across, down),
      NotePaperImageFit.fill => null,
    };

    return both == null ? Offset(across, down) : Offset(both, both);
  }
}

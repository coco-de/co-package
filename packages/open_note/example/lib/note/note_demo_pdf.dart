import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:open_note/open_note.dart';

/// PDF 렌더러 · 글자 층 데모 — 실제 앱은 플랫폼 PDF 라이브러리를 끼운다.
/// 한 쪽짜리 "PDF" 를 즉석에서 그리고, 같은 배치에서 낱말 상자를 만들어
/// 글자를 골라 형광펜 · 밑줄을 칠 수 있게 한다.
class NoteDemoPdf implements NotePdfPageRenderer, NotePdfTextLayer {
  static const String name = 'sample.pdf';
  static const NotePageSize _size = NotePageSize(595, 842);

  static const List<(String, double)> _lines = [
    ('Conservation of energy', 26),
    ('Energy is never created or destroyed.', 16),
    ('It only changes from one form to another,', 16),
    ('so the total of an isolated system stays constant.', 16),
    ('Highlight or underline any words on this page.', 16),
  ];

  /// 줄마다 글 배치와 왼쪽 위 자리.
  late final List<(TextPainter, Offset)> _layout = () {
    var y = 72.0;

    return [
      for (final (text, fontSize) in _lines)
        () {
          final painter = TextPainter(
            text: TextSpan(
              text: text,
              style: TextStyle(
                color: const Color(0xFF1A1A1A),
                fontSize: fontSize,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout(maxWidth: _size.width - 112);
          final line = (painter, Offset(56, y));
          y += painter.height + 14;

          return line;
        }(),
    ];
  }();

  @override
  Future<int> pageCount(Uint8List bytes) async => 1;

  @override
  Future<NotePdfRenderedPage> renderPage(
    Uint8List bytes,
    int index, {
    required int targetWidth,
  }) async {
    final scale = targetWidth / _size.width;
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder)..scale(scale);
    canvas.drawRect(_size.toRect(), Paint()..color = const Color(0xFFFFFFFF));
    for (final (painter, at) in _layout) {
      painter.paint(canvas, at);
    }
    final image = await recorder.endRecording().toImage(
      targetWidth,
      (_size.height * scale).round(),
    );
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();

    return NotePdfRenderedPage(
      png: data!.buffer.asUint8List(),
      pageSize: _size,
    );
  }

  @override
  Future<List<NotePdfTextRun>> runs(int pageIndex) async => [
    for (final (painter, at) in _layout)
      for (final match in RegExp(r'\S+').allMatches(painter.plainText))
        NotePdfTextRun(
          text: match[0]!,
          rect: painter
              .getBoxesForSelection(
                TextSelection(baseOffset: match.start, extentOffset: match.end),
              )
              .map((box) => box.toRect())
              .reduce((a, b) => a.expandToInclude(b))
              .shift(at),
        ),
  ];
}

import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/template/template.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  List<Invocation> record(
    NotePaperTemplate paper, {
    ui.Image? image,
    Size? size,
  }) {
    final canvas = TestRecordingCanvas();
    NotePaperPainter(
      paper,
      image: image,
    ).paint(canvas, size ?? paper.size.toSize());

    return [for (final call in canvas.invocations) call.invocation];
  }

  // Paint stores float32 channels, so colours are compared as ARGB integers.
  bool sameColor(Color a, Color b) => a.toARGB32() == b.toARGB32();

  List<Invocation> only(List<Invocation> calls, Symbol method) => [
    for (final call in calls)
      if (call.memberName == method) call,
  ];

  List<(Offset, Offset, Paint)> linesOf(NotePaperTemplate paper) => [
    for (final call in only(record(paper), #drawLine))
      (
        call.positionalArguments[0] as Offset,
        call.positionalArguments[1] as Offset,
        call.positionalArguments[2] as Paint,
      ),
  ];

  test('the paper colour covers the page first', () {
    final paper = NotePaperTemplate.blank().copyWith(
      backgroundColor: const Color(0xFFFFF3E0),
    );
    final calls = record(paper);
    expect(calls, hasLength(1));
    expect(calls.single.memberName, #drawRect);
    expect(
      calls.single.positionalArguments.first,
      const Rect.fromLTWH(0, 0, 595, 842),
    );
    expect(
      (calls.single.positionalArguments.last as Paint).color,
      isSameColorAs(const Color(0xFFFFF3E0)),
    );
  });

  test('lined paper rules the writable area', () {
    final paper = NotePaperTemplate.lined();
    final lines = linesOf(paper);
    final area = paper.writableArea;
    expect(lines, hasLength((area.height / 28).floor()));
    expect(lines.first.$1, Offset(area.left, area.top + 28));
    expect(lines.first.$2, Offset(area.right, area.top + 28));
    expect(lines.last.$1.dy, lessThanOrEqualTo(area.bottom));
    for (final (from, to, paint) in lines) {
      expect(from.dy, to.dy);
      expect(paint.color, isSameColorAs(paper.lineColor));
      expect(paint.strokeWidth, closeTo(paper.lineWidth, 1e-6));
    }
  });

  test('spacing and width change the ruling', () {
    final tight = NotePaperTemplate.lined(lineSpacing: 14, lineWidth: 2);
    expect(
      linesOf(tight).length,
      greaterThan(linesOf(NotePaperTemplate.lined()).length),
    );
    expect(linesOf(tight).first.$3.strokeWidth, 2);
  });

  test('the margin line is an accent line at the left margin', () {
    final plain = NotePaperTemplate.lined();
    final marked = plain.copyWith(showMarginLine: true);
    final lines = linesOf(marked);
    expect(lines, hasLength(linesOf(plain).length + 1));
    expect(lines.last.$1, const Offset(40, 0));
    expect(lines.last.$2, const Offset(40, 842));
    expect(lines.last.$3.color, isSameColorAs(marked.accentColor));
    expect(
      linesOf(NotePaperTemplate.blank().copyWith(showMarginLine: true)),
      isEmpty,
      reason: 'a blank page has no left margin to mark',
    );
    expect(
      linesOf(
        NotePaperTemplate.blank().copyWith(
          showMarginLine: true,
          margins: const EdgeInsets.only(left: 72),
        ),
      ),
      hasLength(1),
    );
  });

  test('grid paper is a centred lattice of whole cells', () {
    final paper = NotePaperTemplate.grid();
    final area = paper.writableArea;
    final columns = (area.width / 24).floor();
    final rows = (area.height / 24).floor();
    final lines = linesOf(paper);
    expect(lines, hasLength(columns + 1 + rows + 1));
    final vertical = lines.where((l) => l.$1.dx == l.$2.dx).toList();
    expect(vertical, hasLength(columns + 1));
    final left = vertical.first.$1.dx;
    final right = vertical.last.$1.dx;
    expect(left - area.left, closeTo(area.right - right, 1e-6));
    expect(right - left, closeTo(columns * 24, 1e-6));
    expect(vertical.first.$2.dy - vertical.first.$1.dy, rows * 24);
  });

  test('dotted paper draws one batch of round dots', () {
    final paper = NotePaperTemplate.dotted();
    final area = paper.writableArea;
    final columns = (area.width / 24).floor();
    final rows = (area.height / 24).floor();
    final calls = record(paper);
    final points = only(calls, #drawPoints).single;
    expect(points.positionalArguments[0], ui.PointMode.points);
    final dots = points.positionalArguments[1] as List<Offset>;
    expect(dots, hasLength((columns + 1) * (rows + 1)));
    expect(dots.toSet(), hasLength(dots.length));
    final paint = points.positionalArguments[2] as Paint;
    expect(paint.strokeCap, StrokeCap.round);
    expect(paint.strokeWidth, closeTo(0.6 * 3, 1e-6));
    expect(
      dots.first.dx - area.left,
      closeTo(area.right - dots[columns].dx, 1e-6),
    );
    expect(only(calls, #drawLine), isEmpty);
  });

  test('Cornell paper has a cue column, title and summary dividers', () {
    final paper = NotePaperTemplate.cornell().copyWith(showMarginLine: true);
    final area = paper.writableArea;
    final lines = linesOf(paper);
    final accent = lines
        .where((l) => sameColor(l.$3.color, paper.accentColor))
        .toList();
    expect(accent, hasLength(3));
    expect(accent[0].$1, Offset(0, area.top));
    expect(accent[0].$2, Offset(595, area.top));
    expect(accent[1].$1, Offset(0, area.bottom));
    expect(accent[2].$1, area.topLeft);
    expect(accent[2].$2, area.bottomLeft);
    final rules = lines
        .where((l) => sameColor(l.$3.color, paper.lineColor))
        .toList();
    expect(rules, isNotEmpty);
    for (final rule in rules) {
      expect(rule.$1.dx, area.left);
      expect(rule.$2.dx, area.right);
      expect(rule.$1.dy, lessThan(area.bottom));
      expect(rule.$1.dy, greaterThan(area.top));
    }
  });

  test('music paper draws five-line staves with bar ends', () {
    final paper = NotePaperTemplate.music();
    final area = paper.writableArea;
    final lines = linesOf(paper);
    final staves = ((area.height - 40) / 90).floor() + 1;
    expect(lines, hasLength(staves * 7));
    final horizontal = lines.where((l) => l.$1.dy == l.$2.dy).toList();
    expect(horizontal, hasLength(staves * 5));
    final first = [for (final l in horizontal.take(5)) l.$1.dy];
    for (var i = 1; i < first.length; i++) {
      expect(first[i] - first[i - 1], closeTo(10, 1e-6));
    }
    // The staves are centred vertically.
    expect(
      first.first - area.top,
      closeTo(area.bottom - horizontal.last.$1.dy, 1e-6),
    );
  });

  test('a page too small for any ruling is only paper', () {
    for (final paper in NotePaperCatalog.builtInTemplates()) {
      final tiny = paper.copyWith(size: const NotePageSize(5, 5));
      expect(record(tiny).first.memberName, #drawRect, reason: paper.id);
      expect(() => record(paper, size: Size.zero), returnsNormally);
    }
    expect(
      linesOf(NotePaperTemplate.music(size: const NotePageSize(90, 90))),
      isEmpty,
    );
  });

  test('absurdly large pages stay bounded', () {
    const huge = Size(1e7, 1e7);
    expect(
      only(record(NotePaperTemplate.grid(), size: huge), #drawLine).length,
      lessThanOrEqualTo(2 * (NotePaperPainter.maxLinesPerAxis + 1)),
    );
    final dots =
        only(
              record(NotePaperTemplate.dotted(), size: huge),
              #drawPoints,
            ).single.positionalArguments[1]
            as List<Offset>;
    expect(dots, hasLength(NotePaperPainter.maxDots));
    expect(
      only(record(NotePaperTemplate.music(), size: huge), #drawLine).length,
      lessThanOrEqualTo(7 * NotePaperPainter.maxLinesPerAxis ~/ 5),
    );
  });

  test('ruling follows the painted size, not only the template size', () {
    final paper = NotePaperTemplate.lined();
    final taller = record(paper, size: const Size(595, 1200));
    expect(only(taller, #drawLine).length, greaterThan(linesOf(paper).length));
  });

  test('painting is deterministic', () {
    for (final paper in NotePaperCatalog.builtInTemplates()) {
      String dump() => record(paper)
          .map(
            (c) =>
                '${c.memberName} '
                '${c.positionalArguments.map((a) => a is Paint ? '${a.color} ${a.strokeWidth}' : '$a')}',
          )
          .join('\n');
      expect(dump(), dump(), reason: paper.id);
    }
  });

  test('shouldRepaint only for a different paper or picture', () async {
    final image = await createTestImage(width: 2, height: 2, cache: false);
    final other = image.clone();
    final paper = NotePaperTemplate.grid();
    NotePaperPainter painter(NotePaperTemplate t, [ui.Image? i]) =>
        NotePaperPainter(t, image: i);
    expect(
      painter(paper).shouldRepaint(painter(NotePaperTemplate.grid())),
      isFalse,
    );
    expect(
      painter(paper.copyWith(lineSpacing: 12)).shouldRepaint(painter(paper)),
      isTrue,
    );
    expect(painter(paper, image).shouldRepaint(painter(paper)), isTrue);
    expect(painter(paper, image).shouldRepaint(painter(paper, image)), isFalse);
    expect(painter(paper, other).shouldRepaint(painter(paper, image)), isTrue);
    other.dispose();
    image.dispose();
  });

  test('an image paper draws its decoded picture when given', () async {
    final image = await createTestImage(width: 40, height: 20, cache: false);
    addTearDown(image.dispose);
    final paper = NotePaperTemplate.image(
      id: 'i',
      imageSource: 's',
      size: const NotePageSize(200, 200),
      imageOpacity: 0.5,
    );
    expect(record(paper), hasLength(1), reason: 'plain paper without picture');
    final draw = only(record(paper, image: image), #drawImageRect).single;
    // contain: the 2:1 picture is centred in the square page.
    expect(draw.positionalArguments[2], const Rect.fromLTWH(0, 50, 200, 100));
    expect((draw.positionalArguments[3] as Paint).color.a, closeTo(0.5, 0.01));
    final cover = only(
      record(paper.copyWith(imageFit: NotePaperImageFit.cover), image: image),
      #drawImageRect,
    ).single;
    expect(cover.positionalArguments[2], const Rect.fromLTWH(0, 0, 200, 200));
    expect(cover.positionalArguments[1], const Rect.fromLTWH(10, 0, 20, 20));
    expect(
      only(
        record(paper.copyWith(imageOpacity: 0), image: image),
        #drawImageRect,
      ),
      isEmpty,
    );
    expect(
      only(record(NotePaperTemplate.grid(), image: image), #drawImageRect),
      isEmpty,
      reason: 'only image papers show pictures',
    );
  });
}

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/style/style.dart';

import 'support/path_probe.dart';

void main() {
  const ink = Color(0xFF102030);
  const fill = Color(0xFFFFEE00);
  const rect = Rect.fromLTWH(10, 10, 100, 80);

  void Function(Canvas) painter(
    NoteShapeKind kind, {
    NoteShapeStyle style = NoteShapeStyle.plain,
    Color color = ink,
    double width = 3,
    Rect box = rect,
  }) =>
      (canvas) =>
          NoteShapePainter.paint(canvas, box, kind, color, width, style);

  List<Invocation> record(void Function(Canvas) paint) {
    final canvas = TestRecordingCanvas();
    paint(canvas);

    return [for (final call in canvas.invocations) call.invocation];
  }

  int calls(void Function(Canvas) paint, Symbol method) =>
      record(paint).where((call) => call.memberName == method).length;

  test('draws the fill before the outline', () {
    expect(
      painter(NoteShapeKind.rectangle, style: NoteShapeStyle(fillColor: fill)),
      paints
        ..path(color: fill, style: PaintingStyle.fill)
        ..path(color: ink, strokeWidth: 3, style: PaintingStyle.stroke),
    );
  });

  test('fill opacity multiplies the fill alpha', () {
    final canvas = painter(
      NoteShapeKind.ellipse,
      style: NoteShapeStyle(fillColor: fill, fillOpacity: 0.5),
    );
    expect(canvas, paints..path(color: fill.withValues(alpha: 0.5)));
  });

  test('linear shapes are never filled', () {
    expect(
      calls(
        painter(NoteShapeKind.line, style: NoteShapeStyle(fillColor: fill)),
        #drawPath,
      ),
      1,
    );
  });

  test('an arrow draws its shaft, then a solid filled head', () {
    expect(
      painter(NoteShapeKind.arrow),
      paints
        ..path(color: ink, style: PaintingStyle.stroke)
        ..path(color: ink, style: PaintingStyle.fill),
    );
    expect(
      painter(
        NoteShapeKind.doubleArrow,
        style: NoteShapeStyle(headStyle: NoteShapeHeadStyle.open),
      ),
      paints
        ..path(color: ink, style: PaintingStyle.stroke)
        ..path(color: ink, style: PaintingStyle.stroke),
    );
  });

  test('arrow tips stay on the end points of a flat arrow', () {
    const flat = Rect.fromLTRB(0, 0, 200, 12);
    final heads =
        record(painter(NoteShapeKind.arrow, box: flat))
                .where((call) => call.memberName == #drawPath)
                .last
                .positionalArguments
                .first
            as Path;
    expect(
      samplePath(heads).any((p) => (p - flat.bottomRight).distance < 0.5),
      isTrue,
    );
    expect(NoteShapePainter.headLengthFor(1), 10);
    expect(NoteShapePainter.headLengthFor(4), 18);
  });

  test('3-D shapes draw outline, inner and dashed hidden edges', () {
    final cube = painter(NoteShapeKind.cube);
    expect(calls(cube, #drawPath), 3);
    final hidden =
        record(cube)
                .where((call) => call.memberName == #drawPath)
                .last
                .positionalArguments
                .first
            as Path;
    final drawing = NoteShapeGeometry.drawingFor(NoteShapeKind.cube, rect);
    // Dashes leave gaps in the hidden edges.
    expect(pathLength(hidden), lessThan(pathLength(drawing.hidden!.path)));
    expect(contourCount(hidden), greaterThan(3));
  });

  test('a translucent stroke is composited as one layer', () {
    final translucent = painter(
      NoteShapeKind.cube,
      style: NoteShapeStyle(strokeOpacity: 0.4),
    );
    expect(calls(translucent, #saveLayer), 1);
    expect(calls(translucent, #restore), 1);
    expect(translucent, paints..path(color: ink));
    expect(calls(painter(NoteShapeKind.cube), #saveLayer), 0);
    expect(
      calls(
        painter(NoteShapeKind.line, color: const Color(0x80000000)),
        #saveLayer,
      ),
      1,
    );
  });

  test('decorated line styles are applied to the outline', () {
    int strokes(NoteLineStyleKind kind) => calls(
      painter(
        NoteShapeKind.rectangle,
        style: NoteShapeStyle(lineStyle: NoteLineStyle.of(kind)),
      ),
      #drawPath,
    );
    expect(strokes(NoteLineStyleKind.solid), 1);
    expect(strokes(NoteLineStyleKind.dashed), 1);
    expect(strokes(NoteLineStyleKind.wavy), 1);
    expect(strokes(NoteLineStyleKind.zigzag), 1);
    expect(strokes(NoteLineStyleKind.double), 2);
    expect(
      painter(
        NoteShapeKind.rectangle,
        style: NoteShapeStyle(
          lineStyle: NoteLineStyle.of(NoteLineStyleKind.dotted),
        ),
      ),
      paints..path(strokeWidth: 3),
    );
  });

  test('every kind paints with every line style without throwing', () {
    for (final kind in NoteShapeKind.values) {
      for (final line in NoteLineStyleKind.values) {
        final paint = painter(
          kind,
          style: NoteShapeStyle(
            lineStyle: NoteLineStyle.of(line),
            fillColor: fill,
            cornerRadius: 6,
          ),
        );
        expect(
          record(paint).where((call) => call.memberName == #drawPath),
          isNotEmpty,
          reason: '${kind.name} ${line.name}',
        );
      }
    }
  });

  test('a zero width or invisible stroke leaves only the fill', () {
    final style = NoteShapeStyle(fillColor: fill);
    expect(
      calls(painter(NoteShapeKind.star, style: style, width: 0), #drawPath),
      1,
    );
    expect(
      calls(
        painter(
          NoteShapeKind.star,
          style: style,
          color: const Color(0x00000000),
        ),
        #drawPath,
      ),
      1,
    );
    expect(painter(NoteShapeKind.star, width: 0), paintsNothing);
  });

  test('a non-finite rectangle draws nothing', () {
    final broken = painter(
      NoteShapeKind.cube,
      box: const Rect.fromLTRB(0, double.nan, 10, 10),
      style: NoteShapeStyle(fillColor: fill, strokeOpacity: 0.5),
    );
    expect(broken, paintsNothing);
  });

  test('can be recorded into a real picture', () {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    for (final kind in NoteShapeKind.values) {
      NoteShapePainter.paint(
        canvas,
        rect,
        kind,
        const Color(0x99000000),
        2,
        NoteShapeStyle(fillColor: fill, strokeOpacity: 0.5),
      );
    }
    final picture = recorder.endRecording();
    expect(picture.approximateBytesUsed, greaterThan(0));
    picture.dispose();
  });
}

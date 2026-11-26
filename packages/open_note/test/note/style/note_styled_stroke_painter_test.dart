import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/style/style.dart';

void main() {
  const red = Color(0xFFCC0000);
  const line = [Offset.zero, Offset(100, 0)];

  test('paints each styled path as a stroke in the colour and width', () {
    expect(
      (Canvas canvas) => NoteStyledStrokePainter.paint(
        canvas,
        line,
        red,
        4,
        NoteLineStyle.of(NoteLineStyleKind.double),
      ),
      paints
        ..path(color: red, strokeWidth: 4, style: PaintingStyle.stroke)
        ..path(color: red, strokeWidth: 4, style: PaintingStyle.stroke),
    );
    expect(
      (Canvas canvas) => NoteStyledStrokePainter.paint(
        canvas,
        line,
        red,
        4,
        NoteLineStyle.solid,
      ),
      paintsExactlyCountTimes(#drawPath, 1),
    );
  });

  test('paints nothing without points or width', () {
    expect(
      (Canvas canvas) => NoteStyledStrokePainter.paint(
        canvas,
        const [],
        red,
        4,
        NoteLineStyle.solid,
      ),
      paintsNothing,
    );
    expect(
      (Canvas canvas) => NoteStyledStrokePainter.paint(
        canvas,
        line,
        red,
        0,
        NoteLineStyle.solid,
      ),
      paintsNothing,
    );
  });

  test('smooths the points unless told not to', () {
    final corner = [Offset.zero, const Offset(50, 0), const Offset(50, 50)];
    Path pathOf({required bool smooth}) {
      final canvas = TestRecordingCanvas();
      NoteStyledStrokePainter.paint(
        canvas,
        corner,
        red,
        2,
        NoteLineStyle.solid,
        smooth: smooth,
      );

      return canvas.invocations
              .singleWhere((call) => call.invocation.memberName == #drawPath)
              .invocation
              .positionalArguments
              .first
          as Path;
    }

    expect(
      pathOf(smooth: false).computeMetrics().single.length,
      closeTo(100, 1e-3),
    );
    expect(pathOf(smooth: true).computeMetrics().single.length, lessThan(100));
  });
}

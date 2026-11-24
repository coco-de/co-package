import 'dart:math' as math;

import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/open_board.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  for (final rotation in [0.0, math.pi / 4]) {
    testWidgets('should_align_border_and_handles_at_rotation_$rotation', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      const center = Offset(150, 160);
      const canvasSize = Size(350, 400);
      const expandedPadding = 12.0;
      final controller = ScribbleController(initialTool: ScribbleTool.text);
      addTearDown(controller.dispose);
      final savedText = TextDrawable(
        id: 'saved',
        text: 'apple',
        fontSize: 24,
        textAlign: 'center',
        x: center.dx,
        y: center.dy,
        rotation: rotation,
      );
      controller.scribbleNotifier.addTextDrawable(savedText);

      Future<void> pumpCanvas({double? padding}) => tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SimpleScribbleWidget(
              controller: controller,
              contentLogicalSize: canvasSize,
              textSelectionPadding: padding,
              child: SizedBox(
                width: canvasSize.width,
                height: canvasSize.height,
              ),
            ),
          ),
        ),
      );
      final textPaint = find.byWidgetPredicate(
        (widget) =>
            widget is CustomPaint && widget.painter is TextDrawablePainter,
      );
      Future<void> tapWithPen(Offset point) async {
        final gesture = await tester.startGesture(
          point,
          kind: PointerDeviceKind.stylus,
        );
        await tester.pump();
        await gesture.up();
        await tester.pumpAndSettle();
      }

      await pumpCanvas();
      await tester.pumpAndSettle();
      Offset toScreen(Offset point) =>
          tester.renderObject<RenderBox>(textPaint).localToGlobal(point);
      await tapWithPen(toScreen(center));

      final textBounds = TextDrawablePainter.getTextBounds(savedText);
      final localTextBounds = Rect.fromCenter(
        center: Offset.zero,
        width: textBounds.width,
        height: textBounds.height,
      );
      expect(textPaint, paints..rect(rect: localTextBounds.inflate(4)));

      await pumpCanvas(padding: expandedPadding);
      await tester.pumpAndSettle();
      final expectedSelection = localTextBounds.inflate(expandedPadding);
      expect(textPaint, paints..rect(rect: expectedSelection));
      expect(controller.currentScribble.textDrawables.single, savedText);

      Offset canvasPoint(Offset local) =>
          center +
          Offset(
            local.dx * math.cos(rotation) - local.dy * math.sin(rotation),
            local.dx * math.sin(rotation) + local.dy * math.cos(rotation),
          );
      final deleteHandle = canvasPoint(expectedSelection.topRight);
      final transformHandle = canvasPoint(expectedSelection.bottomLeft);
      expect(
        textPaint,
        paints
          ..circle(x: deleteHandle.dx, y: deleteHandle.dy, color: Colors.red)
          ..circle(x: deleteHandle.dx, y: deleteHandle.dy, color: Colors.white)
          ..circle(
            x: transformHandle.dx,
            y: transformHandle.dy,
            color: Colors.blue,
          ),
      );

      await tapWithPen(toScreen(deleteHandle));
      expect(controller.currentScribble.textDrawables, isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}

import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/module/scribble.notifier.dart';
import 'package:open_board/src/module/scribble_mode.notifier.dart';
import 'package:open_board/src/module/text/inline_text_editor.dart';
import 'package:open_board/src/module/text/text_interaction_manager.dart';
import 'package:open_board/src/module/widgets/scribble_widget_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_helpers.dart';

void main() {
  for (final action in ['tap', 'drag', 'cancel']) {
    testWidgets('should_${action}_selected_text_after_double_tap_timeout', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final notifier = ScribbleNotifier(scribble: createScribble());
      final mode = ScribbleModeNotifier();
      final state = ScribbleWidgetState();
      final boundaryKey = GlobalKey();
      notifier.addTextDrawable(
        createTextDrawable(
          id: 'existing',
          text: 'Existing text for editing',
          x: 200,
          y: 150,
          fontSize: 24,
        ),
      );
      late TextInteractionManager manager;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                manager = TextInteractionManager(
                  scribbleNotifier: notifier,
                  modeNotifier: mode,
                  context: context,
                  transformationController: null,
                  repaintBoundaryKey: boundaryKey,
                  widgetState: state,
                  onStateChanged: () {},
                  onTextSelected: (_) {},
                  onTextUpdated: (_) {},
                  onTextDeselected: () {},
                );
                return RepaintBoundary(
                  key: boundaryKey,
                  child: const SizedBox(width: 800, height: 600),
                );
              },
            ),
          ),
        ),
      );
      const point = Offset(200, 150);
      manager.handlePointerDown(
        const PointerDownEvent(
          pointer: 1,
          kind: PointerDeviceKind.mouse,
          position: point,
        ),
      );
      manager.handlePointerUp(
        const PointerUpEvent(
          pointer: 1,
          kind: PointerDeviceKind.mouse,
          position: point,
        ),
      );
      await tester.pump();
      expect(find.byType(InlineTextEditor), findsNothing);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 900)),
      );
      manager.handlePointerDown(
        const PointerDownEvent(
          pointer: 2,
          kind: PointerDeviceKind.mouse,
          position: point,
        ),
      );
      await tester.pump();
      expect(find.byType(InlineTextEditor), findsNothing);
      if (action == 'cancel') {
        manager.handlePointerCancel(const PointerCancelEvent(pointer: 2));
      } else {
        final end = action == 'drag' ? point + const Offset(60, 40) : point;
        if (action == 'drag') {
          manager.handlePointerMove(
            PointerMoveEvent(
              pointer: 2,
              kind: PointerDeviceKind.mouse,
              position: end,
            ),
          );
        }
        manager.handlePointerUp(
          PointerUpEvent(
            pointer: 2,
            kind: PointerDeviceKind.mouse,
            position: end,
          ),
        );
      }
      await tester.pump();
      if (action == 'tap') {
        expect(find.byType(InlineTextEditor), findsOneWidget);
        await tester.enterText(find.byType(TextField), 'Edited content');
        await tester.tapAt(const Offset(700, 500));
        await tester.pump();
        expect(
          notifier.getCurrentTextDrawables().single.text,
          'Edited content',
        );
        expect(notifier.getCurrentTextDrawables().single.id, 'existing');
      } else {
        expect(find.byType(InlineTextEditor), findsNothing);
        expect(
          notifier.getCurrentTextDrawables().single.text,
          'Existing text for editing',
        );
        expect(
          notifier.getCurrentTextDrawables().single.x,
          action == 'drag' ? 260 : 200,
        );
      }
      manager.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
      notifier.dispose();
      mode.dispose();
      state.dispose();
    });
  }
}

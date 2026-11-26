import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_note/src/module/lasso/scribble_lasso_selection.dart';
import 'package:open_note/src/module/scribble.notifier.dart';
import 'package:open_note/src/module/scribble_mode.notifier.dart';
import 'package:open_note/src/module/state/drawing_state.dart';
import 'package:open_note/src/module/widgets/scribble_widget.dart';

import '../note/support/note_test_host.dart';

/// open_note: `ScribbleWidget.lassoSelection` 이 올가미 선택을 알리고, 밖에서
/// 선택을 지울 수 있는지 실제 포인터로 검증한다.
void main() {
  const pageSize = Size(300, 400);
  const childKey = Key('page');

  late ScribbleNotifier notifier;
  late ScribbleModeNotifier modeNotifier;
  late ScribbleLassoSelection selection;
  late DrawingTool previousTool;

  setUp(() {
    previousTool = DrawingState().selectedTool.value;
    DrawingState().selectedTool.value = DrawingTool.lasso;
    notifier = ScribbleNotifier(
      scribble: Scribble(
        strokes: [
          Stroke(
            id: 'a',
            ink: 'pen',
            color: 0xFF000000,
            options: StrokeOptions(size: 4),
            points: [
              Point(x: 100, y: 100, p: 0.5),
              Point(x: 140, y: 120, p: 0.5),
            ],
          ),
        ],
      ),
    );
    modeNotifier = ScribbleModeNotifier()..setLassoSelection();
    selection = ScribbleLassoSelection();
  });

  tearDown(() {
    DrawingState().selectedTool.value = previousTool;
    notifier.dispose();
    modeNotifier.dispose();
    selection.dispose();
  });

  Future<void> pump(WidgetTester tester, {bool shown = true}) async {
    await tester.pumpWidget(
      noteTestHost(
        shown
            ? ScribbleWidget(
                notifier: notifier,
                modeNotifier: modeNotifier,
                lassoSelection: selection,
                child: SizedBox.fromSize(key: childKey, size: pageSize),
              )
            : const SizedBox(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Offset onPage(WidgetTester tester, Offset page) {
    final rect = tester.getRect(find.byKey(childKey));

    return rect.topLeft +
        Offset(
          page.dx * rect.width / pageSize.width,
          page.dy * rect.height / pageSize.height,
        );
  }

  Future<void> loop(WidgetTester tester) async {
    const corners = [
      Offset(80, 80),
      Offset(170, 80),
      Offset(170, 150),
      Offset(80, 150),
      Offset(80, 82),
    ];
    final gesture = await tester.startGesture(
      onPage(tester, corners.first),
      kind: PointerDeviceKind.stylus,
    );
    for (var i = 1; i < corners.length; i++) {
      for (var step = 1; step <= 4; step++) {
        await gesture.moveTo(
          onPage(tester, Offset.lerp(corners[i - 1], corners[i], step / 4)!),
        );
      }
    }
    await gesture.up();
    await tester.pumpAndSettle();
  }

  testWidgets('올가미로 두른 획이 알려지고, 밖에서 지울 수 있다', (tester) async {
    var notifications = 0;
    selection.addListener(() => notifications++);
    await pump(tester);

    await loop(tester);

    expect(selection.strokeIndexes, contains(0));
    expect(notifications, greaterThan(0));

    selection.clear();
    await tester.pumpAndSettle();

    expect(selection.isEmpty, isTrue);
    expect(notifier.currentScribble.strokes.map((s) => s.id), contains('a'));
  });

  testWidgets('위젯이 사라지면 선택도 비워진다 (프레임 뒤에 알림)', (tester) async {
    await pump(tester);
    await loop(tester);
    expect(selection.isEmpty, isFalse);

    await pump(tester, shown: false);

    expect(selection.isEmpty, isTrue);
    expect(tester.takeException(), isNull);
  });
}

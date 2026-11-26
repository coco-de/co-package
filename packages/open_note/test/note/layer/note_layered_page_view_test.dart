import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/module/scribble_mode.notifier.dart';
import 'package:open_note/src/module/widgets/scribble_widget.dart';
import 'package:open_note/src/note/core/note_page_size.dart';
import 'package:open_note/src/note/layer/note_layer_panel.dart';
import 'package:open_note/src/note/layer/note_layer_stack.dart';
import 'package:open_note/src/note/layer/note_layered_page_view.dart';
import 'package:open_note/src/note/layer/note_scribble_view.dart';

import '../support/note_test_host.dart';

void main() {
  const pageSize = NotePageSize(300, 400);
  late NoteLayerStack layers;
  late ScribbleModeNotifier mode;
  var ids = 0;

  setUp(() {
    ids = 0;
    layers = NoteLayerStack(idFactory: () => 'l${ids++}');
    mode = ScribbleModeNotifier()..setPen();
  });

  tearDown(() {
    layers.dispose();
    mode.dispose();
  });

  const backgroundKey = Key('paper');

  Future<void> pumpPage(
    WidgetTester tester, {
    TransformationController? controller,
  }) async {
    await tester.pumpWidget(
      noteTestHost(
        NoteLayeredPageView(
          layers: layers,
          modeNotifier: mode,
          pageSize: pageSize,
          transformationController: controller,
          background: const SizedBox.expand(key: backgroundKey),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Offset onPage(WidgetTester tester, Offset page) {
    final rect = tester.getRect(find.byKey(backgroundKey));

    return rect.topLeft +
        Offset(
          page.dx * rect.width / pageSize.width,
          page.dy * rect.height / pageSize.height,
        );
  }

  Future<void> stroke(WidgetTester tester, double y) async {
    final gesture = await tester.startGesture(
      onPage(tester, Offset(40, y)),
      kind: PointerDeviceKind.stylus,
    );
    await gesture.moveTo(onPage(tester, Offset(120, y)));
    await gesture.moveTo(onPage(tester, Offset(200, y)));
    await gesture.up();
    await tester.pumpAndSettle();
  }

  testWidgets('활성 레이어에만 그리고, 나머지는 같은 자리에 읽기 전용으로 보인다', (tester) async {
    await pumpPage(tester);
    await stroke(tester, 100);
    final first = layers.activeLayerId;
    layers.addLayer();
    await tester.pumpAndSettle();
    await stroke(tester, 200);
    final second = layers.activeLayerId;

    expect(layers.scribbleOf(first).strokes, hasLength(1));
    expect(layers.scribbleOf(second).strokes, hasLength(1));
    expect(
      layers.scribbleOf(second).strokes.single.points.first.y,
      closeTo(200, 1),
    );
    // 아래 레이어는 읽기 전용 뷰로 그려진다.
    final readOnly = tester.widget<NoteScribbleView>(
      find.byType(NoteScribbleView),
    );
    expect(readOnly.scribble.strokes.single.points.first.y, closeTo(100, 1));

    layers.undo();
    await tester.pumpAndSettle();
    expect(layers.scribbleOf(second).strokes, isEmpty);
    expect(layers.scribbleOf(first).strokes, hasLength(1));
  });

  testWidgets('위 레이어는 활성 레이어 위에 그려지고 숨기면 사라진다', (tester) async {
    await pumpPage(tester);
    final bottom = layers.activeLayerId;
    layers.addLayer();
    await tester.pumpAndSettle();
    await stroke(tester, 150);
    final top = layers.activeLayerId;
    layers.setActive(bottom);
    await tester.pumpAndSettle();

    expect(find.byType(NoteScribbleView), findsOneWidget);

    layers.setVisible(top, false);
    await tester.pumpAndSettle();
    expect(find.byType(NoteScribbleView), findsNothing);
  });

  testWidgets('잠그거나 숨긴 활성 레이어에는 그릴 수 없다', (tester) async {
    await pumpPage(tester);
    final id = layers.activeLayerId;

    layers.setLocked(id, true);
    await tester.pumpAndSettle();
    await stroke(tester, 100);
    expect(layers.scribbleOf(id).strokes, isEmpty);

    layers
      ..setLocked(id, false)
      ..setVisible(id, false);
    await tester.pumpAndSettle();
    await stroke(tester, 100);
    expect(layers.scribbleOf(id).strokes, isEmpty);
    expect(
      tester.widget<ScribbleWidget>(find.byType(ScribbleWidget)).inkOpacity,
      0,
    );
  });

  testWidgets('레이어를 바꿔도 확대 · 이동은 유지된다', (tester) async {
    final controller = TransformationController();
    addTearDown(controller.dispose);
    await pumpPage(tester, controller: controller);
    final zoomed = Matrix4.identity()
      ..translateByDouble(-40, -60, 0, 1)
      ..scaleByDouble(2, 2, 1, 1);
    controller.value = zoomed;
    await tester.pumpAndSettle();
    final before = tester.getRect(find.byKey(backgroundKey));

    layers.addLayer();
    await tester.pumpAndSettle();

    expect(controller.value, zoomed);
    expect(tester.getRect(find.byKey(backgroundKey)), before);
    // 확대 상태에서 그려도 페이지 좌표가 맞는다.
    await stroke(tester, 150);
    expect(
      layers.activeNotifier.currentScribble.strokes.single.points.first.y,
      closeTo(150, 1),
    );
  });

  testWidgets('패널의 버튼은 스택을 바꾸고 이름을 더블 탭으로 바꾼다', (tester) async {
    await tester.pumpWidget(noteTestHost(NoteLayerPanel(layers: layers)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add layer'));
    await tester.pumpAndSettle();
    expect(layers.length, 2);

    // 맨 위(활성) 행의 숨기기.
    await tester.tap(find.text('Hide').first);
    await tester.pumpAndSettle();
    expect(layers.activeLayer.visible, isFalse);

    await tester.tap(find.text('Layer 2'));
    await tester.pump(const Duration(milliseconds: 40));
    await tester.tap(find.text('Layer 2'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText), '풀이');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(layers.activeLayer.name, '풀이');

    await tester.tap(find.text('Delete').first);
    await tester.pumpAndSettle();
    expect(layers.length, 1);
    layers.undo();
    await tester.pumpAndSettle();
    expect(layers.length, 2);
  });

  testWidgets('패널의 불투명도 드래그는 한 번의 실행 취소다', (tester) async {
    await tester.pumpWidget(noteTestHost(NoteLayerPanel(layers: layers)));
    await tester.pumpAndSettle();

    final slider = tester.getRect(find.bySemanticsLabel('Opacity').first);
    await tester.dragFrom(
      Offset(slider.right - 12, slider.center.dy),
      Offset(-slider.width / 2, 0),
    );
    await tester.pumpAndSettle();

    expect(layers.activeLayer.opacity, lessThan(0.8));
    expect(layers.history.undoLength, 1);
    layers.undo();
    expect(layers.activeLayer.opacity, 1);
  });
}

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/module/scribble.notifier.dart';
import 'package:open_note/src/module/scribble_mode.notifier.dart';
import 'package:open_note/src/module/widgets/scribble_widget.dart';

import '../note/support/note_test_host.dart';

/// open_note 의 `ScribbleWidget` 슬롯(layersBelow · layersAbove · foreground)이
/// 필기와 같은 콘텐츠 좌표계에 정렬되고, 포인터 규칙을 지키는지 검증한다.
void main() {
  const pageSize = Size(300, 400);
  const childKey = Key('page');
  const belowKey = Key('below');
  const aboveKey = Key('above');
  const buttonKey = Key('object');

  late ScribbleNotifier notifier;
  late ScribbleModeNotifier modeNotifier;

  setUp(() {
    notifier = ScribbleNotifier();
    modeNotifier = ScribbleModeNotifier()..setPen();
  });

  tearDown(() {
    notifier.dispose();
    modeNotifier.dispose();
  });

  Future<void> pump(
    WidgetTester tester, {
    VoidCallback? onObjectTap,
    bool slots = true,
  }) async {
    await tester.pumpWidget(
      noteTestHost(
        ScribbleWidget(
          notifier: notifier,
          modeNotifier: modeNotifier,
          layersBelow: slots
              ? const ColoredBox(key: belowKey, color: Color(0x11FF0000))
              : null,
          layersAbove: slots
              ? const ColoredBox(key: aboveKey, color: Color(0x110000FF))
              : null,
          // 슬롯은 콘텐츠 좌표계에서 레이아웃되므로 (50,60) 에 놓인 버튼은
          // 페이지의 (50,60) 위치에 있어야 한다.
          foreground: slots
              ? Stack(
                  children: [
                    Positioned(
                      left: 50,
                      top: 60,
                      width: 80,
                      height: 40,
                      child: GestureDetector(
                        key: buttonKey,
                        behavior: HitTestBehavior.opaque,
                        onTap: onObjectTap,
                      ),
                    ),
                  ],
                )
              : null,
          child: SizedBox.fromSize(key: childKey, size: pageSize),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> stylusStroke(WidgetTester tester, Offset from, Offset to) async {
    final gesture = await tester.startGesture(
      from,
      kind: PointerDeviceKind.stylus,
    );
    await gesture.moveTo(Offset.lerp(from, to, 0.5)!);
    await gesture.moveTo(to);
    await gesture.up();
    await tester.pumpAndSettle();
  }

  /// 페이지 좌표를 화면 좌표로 — 위젯이 페이지를 화면에 맞춰 키운 배율을 반영.
  Offset onPage(WidgetTester tester, Offset page) {
    final rect = tester.getRect(find.byKey(childKey));

    return rect.topLeft +
        Offset(
          page.dx * rect.width / pageSize.width,
          page.dy * rect.height / pageSize.height,
        );
  }

  testWidgets('세 슬롯은 배경 child 와 같은 사각형에 정렬된다', (tester) async {
    await pump(tester);

    final page = tester.getRect(find.byKey(childKey));
    expect(tester.getRect(find.byKey(belowKey)), page);
    expect(tester.getRect(find.byKey(aboveKey)), page);
    final button = tester.getRect(find.byKey(buttonKey));
    expect(
      button.topLeft,
      offsetMoreOrLessEquals(onPage(tester, const Offset(50, 60))),
    );
  });

  testWidgets('빈 곳의 필기는 슬롯을 투과해 스트로크가 된다', (tester) async {
    await pump(tester);

    await stylusStroke(
      tester,
      onPage(tester, const Offset(150, 200)),
      onPage(tester, const Offset(220, 260)),
    );

    expect(notifier.currentScribble.strokes, hasLength(1));
    final first = notifier.currentScribble.strokes.single.points.first;
    expect(first.x, closeTo(150, 1));
    expect(first.y, closeTo(200, 1));
  });

  testWidgets('상호작용 오브젝트 위의 탭은 오브젝트가 받고 필기가 시작되지 않는다', (tester) async {
    var tapped = 0;
    await pump(tester, onObjectTap: () => tapped++);

    await tester.tapAt(
      onPage(tester, const Offset(90, 80)),
      kind: PointerDeviceKind.stylus,
    );
    await tester.pumpAndSettle();

    expect(tapped, 1);
    expect(notifier.currentScribble.strokes, isEmpty);
  });

  testWidgets('슬롯을 주지 않으면 종전과 같이 동작한다', (tester) async {
    await pump(tester, slots: false);

    await stylusStroke(
      tester,
      onPage(tester, const Offset(90, 80)),
      onPage(tester, const Offset(160, 90)),
    );

    expect(find.byKey(belowKey), findsNothing);
    expect(notifier.currentScribble.strokes, hasLength(1));
  });
}

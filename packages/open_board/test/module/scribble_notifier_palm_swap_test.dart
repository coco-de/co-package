  import 'package:flutter/gestures.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
  import 'package:open_board/src/module/scribble.notifier.dart';
  import 'package:open_board/src/module/scribble_mode.notifier.dart';
  import 'package:open_board/src/module/state/scribble.state.dart';

  /// kobic UB-219 2차 — 팜-먼저 스왑/고착 자가치유를 지원하는 notifier 신규
  /// API 단위 테스트.
  ///
  /// - [ScribbleNotifier.discardActiveLine]: 팜이 시작해버린 잠정 라인을
  ///   커밋 없이 폐기하고 소유권을 해제한다.
  /// - [ScribbleNotifier.releaseStalePointers]: up/cancel 유실로 잔존한
  ///   포인터 소유권을 정리한다 (그리던 내용은 보존).
  void main() {
    late ScribbleNotifier notifier;
    late ScribbleModeNotifier modeNotifier;

    PointerDownEvent touchDown(int pointer, Offset position) =>
        PointerDownEvent(
          pointer: pointer,
          kind: PointerDeviceKind.touch,
          position: position,
        );

    PointerMoveEvent touchMove(int pointer, Offset position) =>
        PointerMoveEvent(
          pointer: pointer,
          kind: PointerDeviceKind.touch,
          position: position,
        );

    setUp(() {
      notifier = ScribbleNotifier(
        scribble: Scribble(strokes: [], width: 300, height: 400),
      );
      modeNotifier = ScribbleModeNotifier()
        ..setPen()
        ..setAllowedPointersMode(ScribblePointerMode.all);
    });

    tearDown(() {
      notifier.dispose();
      modeNotifier.dispose();
    });

    group('discardActiveLine (팜-먼저 스왑)', () {
      test('should_discard_active_line_and_release_owner_without_commit', () {
        notifier.onPointerDown(touchDown(7, const Offset(10, 10)), modeNotifier.state);

        final drawing = notifier.currentState as Drawing;
        expect(drawing.activeLine, isNotNull);
        expect(drawing.activePointerIds, contains(7));
        final strokesBefore = drawing.scribble.strokes.length;

        notifier.discardActiveLine(7);

        final after = notifier.currentState as Drawing;
        expect(after.activeLine, isNull);
        expect(after.activePointerIds, isEmpty);
        // 잠정 라인은 커밋되지 않는다 (스트로크 수 불변).
        expect(after.scribble.strokes.length, strokesBefore);
      });

      test('should_allow_new_touch_down_after_discard', () {
        notifier.onPointerDown(touchDown(7, const Offset(10, 10)), modeNotifier.state);
        notifier.discardActiveLine(7);

        // 소유권이 해제됐으므로 새 터치 포인터가 곧바로 획을 시작할 수 있다
        // (onPointerDown의 touch 멀티터치 가드가 통과돼야 한다).
        notifier.onPointerDown(touchDown(8, const Offset(50, 50)), modeNotifier.state);

        final after = notifier.currentState as Drawing;
        expect(after.activeLine, isNotNull);
        expect(after.activePointerIds, [8]);
      });

      test('should_noop_when_no_active_line', () {
        final before = notifier.currentState;

        notifier.discardActiveLine(99);

        expect(notifier.currentState.activePointerIds, before.activePointerIds);
        expect((notifier.currentState as Drawing).activeLine, isNull);
      });
    });

    group('releaseStalePointers (고착 자가치유)', () {
      test('should_clear_owner_ids_and_preserve_drawn_content', () {
        notifier.onPointerDown(touchDown(7, const Offset(10, 10)), modeNotifier.state);
        notifier.onPointerUpdate(touchMove(7, const Offset(30, 30)), modeNotifier.state);
        notifier.onPointerUpdate(touchMove(7, const Offset(60, 60)), modeNotifier.state);
        // up 유실 시뮬레이션 — activePointerIds에 7이 잔존한 상태.
        expect(notifier.currentState.activePointerIds, contains(7));

        notifier.releaseStalePointers();

        final after = notifier.currentState as Drawing;
        expect(after.activePointerIds, isEmpty);
        expect(after.activeLine, isNull);
        // 그리던 내용은 폐기하지 않고 완성해 보존한다.
        expect(after.scribble.strokes, isNotEmpty);
      });

      test('should_unblock_touch_drawing_after_release', () {
        notifier.onPointerDown(touchDown(7, const Offset(10, 10)), modeNotifier.state);
        // up 유실 → 기존에는 이후 모든 touch down이 멀티터치 가드에 걸려
        // 영구 차단됐다.
        notifier.releaseStalePointers();

        notifier.onPointerDown(touchDown(8, const Offset(50, 50)), modeNotifier.state);

        expect(notifier.currentState.activePointerIds, [8]);
        expect((notifier.currentState as Drawing).activeLine, isNotNull);
      });

      test('should_noop_when_no_active_pointers', () {
        final strokesBefore = notifier.currentState.scribble.strokes.length;

        notifier.releaseStalePointers();

        expect(notifier.currentState.activePointerIds, isEmpty);
        expect(notifier.currentState.scribble.strokes.length, strokesBefore);
      });
    });
  }

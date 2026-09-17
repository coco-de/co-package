// 🐦 Flutter imports:
import 'package:flutter/gestures.dart';

// 📦 Package imports:
import 'package:flutter_test/flutter_test.dart';

// 🌎 Project imports:
import 'package:open_board/src/core/utils/ink_group_info.dart';
import 'package:open_board/src/core/utils/stroke_id.dart';
import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_board/src/module/scribble.notifier.dart';
import 'package:open_board/src/module/state/scribble.state.dart';
import 'package:open_board/src/module/state/scribble_mode.state.dart';

/// [Stroke.id] 계약 회귀 테스트.
///
/// ## 왜 "생성 직후 id 가 있다" 만 보면 안 되나
///
/// 스트로크는 창작 후 **여러 번 재구성**된다 — 포인터 이동마다, 직선화 시,
/// 도형 확정 시. 그 재구성들이 필드를 손으로 나열해 복사하고 있었기 때문에,
/// 생성 시점만 보는 테스트는 "첫 포인터 이동에서 id 가 사라지는" 결함을
/// 그대로 통과시킨다. 그래서 여기서는 **왕복 전 구간**을 지난 뒤의 id 를 본다.
void main() {
  PointerDownEvent down(double x, double y) => PointerDownEvent(
    kind: PointerDeviceKind.stylus,
    pointer: 1,
    position: Offset(x, y),
  );
  PointerMoveEvent move(double x, double y) => PointerMoveEvent(
    kind: PointerDeviceKind.stylus,
    pointer: 1,
    position: Offset(x, y),
  );
  PointerUpEvent up(double x, double y) => PointerUpEvent(
    kind: PointerDeviceKind.stylus,
    pointer: 1,
    position: Offset(x, y),
  );

  ScribbleModeState penMode() {
    final info = InkGroupInfo(selectedInk: InkModes.pen);
    info.setStrokeBox({InkModes.pen: 3.0});

    return ScribbleModeState(inkGroupInfo: info);
  }

  group('Stroke.id 발급', () {
    test('⭐ 창작 → 다수 이동 → 완료 → 와이어 왕복 전 구간에서 id 가 유지된다', () {
      final notifier = ScribbleNotifier(
        strokeIdFactory: () => 'fixed-stroke-id',
      );
      final mode = penMode();

      notifier.onPointerDown(down(10, 10), mode);
      final idAtCreation = (notifier.currentState as Drawing).activeLine!.id;
      expect(idAtCreation, 'fixed-stroke-id');

      // 포인터 이동마다 스트로크가 재구성된다 — 여기서 유실되면 100% 사라진다.
      for (var i = 1; i <= 20; i++) {
        notifier.onPointerUpdate(move(10 + i * 7.0, 10 + i * 3.0), mode);
        expect(
          (notifier.currentState as Drawing).activeLine!.id,
          idAtCreation,
          reason: '$i번째 포인터 이동에서 id 가 유실됐다',
        );
      }

      notifier.onPointerUp(up(160, 70), mode);

      final saved = notifier.currentScribble.strokes.last;
      expect(saved.id, idAtCreation, reason: '완료(finishStroke) 후 id 가 유실됐다');

      // 직렬화 왕복 — 저장·전송을 거쳐도 살아남아야 한다.
      final roundTripped = Stroke.fromBuffer(saved.writeToBuffer());
      expect(roundTripped.id, idAtCreation);
    });

    test('스트로크마다 서로 다른 id 를 받는다', () {
      final notifier = ScribbleNotifier();
      final mode = penMode();
      final ids = <String>[];

      for (var stroke = 0; stroke < 5; stroke++) {
        notifier.onPointerDown(down(10, 10.0 + stroke * 20), mode);
        notifier.onPointerUpdate(move(60, 10.0 + stroke * 20), mode);
        notifier.onPointerUp(up(60, 10.0 + stroke * 20), mode);
        ids.add(notifier.currentScribble.strokes.last.id);
      }

      expect(ids.every((id) => id.isNotEmpty), isTrue);
      expect(ids.toSet().length, ids.length, reason: 'id 가 중복 발급됐다');
    });

    test('⛔ 레거시 스트로크(id 없음)를 로드해도 즉석 발급하지 않는다', () {
      // 두 기기가 같은 레거시 `.bin` 을 각자 열면서 서로 다른 id 를 만들면,
      // 같은 스트로크가 영구히 두 벌로 갈린다. 백필은 서버 한 곳에서만 한다.
      final legacy = Stroke(points: [Point(x: 1, y: 2)], ink: InkModes.pen);
      expect(legacy.id, isEmpty);

      final notifier = ScribbleNotifier(
        scribble: Scribble(strokes: [legacy]),
      );

      expect(
        notifier.currentScribble.strokes.single.id,
        isEmpty,
        reason: '로드 시 id 를 채우면 기기마다 다른 값이 생겨 오히려 갈라진다',
      );
    });
  });

  group('generateStrokeId', () {
    test('RFC 4122 v4 형식이며 매번 다르다', () {
      final ids = List.generate(200, (_) => generateStrokeId());

      expect(ids.toSet().length, ids.length, reason: '충돌이 발생했다');
      for (final id in ids) {
        expect(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-'
            r'[0-9a-f]{12}$',
          ).hasMatch(id),
          isTrue,
          reason: '$id 가 v4 형식이 아니다 (버전/변형 비트 확인)',
        );
      }
    });

    test('⛔ 시각 기반이 아니다 — 같은 순간의 두 호출이 갈린다', () {
      // 시각 기반 발급자는 오프라인 다중 기기에서 충돌한다. 이 단언이 깨지면
      // 발급자가 시계를 쓰도록 바뀐 것이다.
      expect(generateStrokeId(), isNot(generateStrokeId()));
    });
  });
}

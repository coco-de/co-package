import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/core/utils/ink_group_info.dart';
import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_board/src/module/state/scribble.state.dart';
import 'package:open_board/src/module/state/scribble_mode.state.dart';
import 'package:open_board/src/module/stroke/stroke_processor.dart';

/// 스트로크를 재구성하는 경로가 **모든 필드를 승계하는지** 고정한다.
///
/// ## 왜 필요한가
///
/// 이 저장소는 스트로크를 바꿀 때 `Stroke(...)` 생성자에 필드를 **손으로
/// 나열해** 복사해 왔다. 그 방식은 proto 에 필드가 늘 때마다 조용히 유실을
/// 만든다 — 실제로 `segments`(8)·`confidence`(9) 가 다음 경로에서 전부
/// 떨어지고 있었다:
///
/// - `StrokeProcessor.addPointToStroke` — **포인터 이동마다** (간헐 아님)
/// - `ScribbleNotifier` 의 도형 드래그·직선화·도형 확정 5지점
/// - `ScribbleCacheManager` 양면 병합 — ink/width/color **3개만** 복사해
///   `createdAt`·`options`(두께·taper)·`shapeType` 까지 잃었고, 그 결과가
///   그대로 저장됐다
///
/// ## 이 테스트가 미래 필드까지 잡는 방식
///
/// 기대 필드를 손으로 적지 않고 **`BuilderInfo` 에서 파생**한다. proto 에 필드를
/// 더하면 이 테스트가 자동으로 그 필드까지 검사하므로, 승계를 빠뜨린 새 코드가
/// 곧바로 red 가 된다. 기대값을 하드코딩하면 그 순간 이 보호가 사라진다.
void main() {
  /// [Stroke] 의 모든 필드에 서로 구별되는 값을 채운 원본.
  ///
  /// 필드를 더했는데 여기에 값을 안 채우면 [_assertCarriedForward] 가
  /// "기본값이라 검사에서 제외됐다" 고 알려 준다 — 침묵하지 않는다.
  Stroke buildFullyPopulatedStroke() {
    return Stroke(
      points: [Point(x: 1, y: 2, p: 0.5)],
      color: 0xFF112233,
      ink: 'marker',
      createdAt: '2026-01-02T03:04:05.000Z',
      options: StrokeOptions(size: 7, thinning: 0.25, isComplete: true),
      shapeType: 'ellipse',
      width: 3.5,
      segments: [
        Segment(start: Point(x: 1, y: 2), end: Point(x: 9, y: 8)),
      ],
      confidence: 0.875,
      id: 'aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee',
    );
  }

  /// [changed] 로 지정한 태그를 뺀 **나머지 모든 필드**가 [before] 에서
  /// [after] 로 승계됐는지 단언한다.
  void assertCarriedForward(
    Stroke before,
    Stroke after, {
    required Set<int> changed,
  }) {
    final unpopulated = <String>[];
    var checked = 0;

    for (final field in before.info_.sortedByTag) {
      if (changed.contains(field.tagNumber)) continue;

      // 원본이 기본값이면 승계 여부를 구별할 수 없다 — 검사 대상이 아니라
      // **픽스처 결함**이므로 모아서 실패시킨다.
      if (!before.hasField(field.tagNumber)) {
        unpopulated.add('${field.tagNumber}:${field.name}');
        continue;
      }

      checked++;
      expect(
        after.getField(field.tagNumber).toString(),
        before.getField(field.tagNumber).toString(),
        reason:
            '필드 ${field.tagNumber}(`${field.name}`) 가 승계되지 않았다. '
            '스트로크를 재구성할 때 필드를 손으로 나열해 복사하면 새 필드가 '
            '조용히 유실된다 — `deepCopy()` 로 전 필드를 승계한 뒤 바뀌는 것만 '
            '덮어쓸 것.',
      );
    }

    expect(
      unpopulated,
      isEmpty,
      reason:
          '픽스처가 채우지 않은 필드가 있어 승계 검사에서 빠졌다: $unpopulated. '
          '`buildFullyPopulatedStroke` 에 값을 채워야 이 테스트가 그 필드를 '
          '실제로 지킨다.',
    );
    expect(checked, greaterThan(0), reason: '검사한 필드가 0개면 이 테스트는 공허하다');
  }

  group('스트로크 재구성 경로의 필드 승계', () {
    test('⭐ addPointToStroke 는 points 외 모든 필드를 승계한다', () {
      // 포인터 이동마다 도는 경로다 — 여기서 유실되면 그리는 동안 100% 사라진다.
      const processor = StrokeProcessor(pressureCurve: Curves.linear);
      final modeState = ScribbleModeState(
        inkGroupInfo: InkGroupInfo(selectedInk: InkModes.pencil),
        scaleFactor: 1.0,
      );
      final original = buildFullyPopulatedStroke();
      final state = Drawing(
        scribble: Scribble(),
        activeLine: original,
        activePointerIds: const [1],
      );

      final result = processor.addPointToStroke(
        const PointerMoveEvent(position: Offset(500, 500)),
        state,
        modeState,
      ) as Drawing;

      final next = result.activeLine!;
      expect(next.points.length, original.points.length + 1);
      // points(1) 만 바뀐다.
      assertCarriedForward(original, next, changed: {1});
    });

    test('원본은 변형되지 않는다 — 사본을 만들어야 실행취소가 성립한다', () {
      const processor = StrokeProcessor(pressureCurve: Curves.linear);
      final modeState = ScribbleModeState(
        inkGroupInfo: InkGroupInfo(selectedInk: InkModes.pencil),
        scaleFactor: 1.0,
      );
      final original = buildFullyPopulatedStroke();
      final pointCountBefore = original.points.length;

      processor.addPointToStroke(
        const PointerMoveEvent(position: Offset(500, 500)),
        Drawing(
          scribble: Scribble(),
          activeLine: original,
          activePointerIds: const [1],
        ),
        modeState,
      );

      expect(
        original.points.length,
        pointCountBefore,
        reason: '원본에 포인트가 추가되면 이전 상태 스냅샷이 함께 오염된다',
      );
    });

    test('⭐ 와이어 왕복 후에도 필드가 유지된다', () {
      // 열거 복사 결함은 직렬화 이후에야 드러나는 경우가 많다 —
      // 화면에는 points 만 그리므로 유실된 필드가 보이지 않기 때문이다.
      final original = buildFullyPopulatedStroke();

      final roundTripped = Stroke.fromBuffer(original.writeToBuffer());

      assertCarriedForward(original, roundTripped, changed: const {});
    });
  });
}

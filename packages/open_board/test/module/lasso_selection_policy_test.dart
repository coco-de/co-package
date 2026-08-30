import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_board/src/module/lasso/lasso_selection_manager.dart';
import 'package:open_board/src/module/models/scribble_selectable.dart';
import 'package:open_board/src/module/scribble.notifier.dart';

import '../helpers/protobuf_factories.dart';

/// [LassoSelectionManager.canSelectItem] 선택 후보 정책 필터 테스트
/// (kobic unibook#12445, UB-639).
///
/// 계약: 미주입(`null`) 시 기존 동작과 완전히 동일하고, 주입 시 올가미
/// 히트테스트의 **신규 진입 후보 수집**에서만 거부 항목을 제외한다.
/// 올가미 스트로크 자신(ink=='lasso')은 기존 제외가 선행되므로 콜백에
/// 아예 전달되지 않는다.
void main() {
  // 픽스처 좌표 설계:
  //   올가미 폴리곤 = (10,10)-(210,10)-(210,210)-(10,210) 사각형
  //   폴리곤 안: pen/marker/shape 스트로크 + 텍스트 t-in(100,100)
  //   폴리곤 밖: pen 스트로크(300,300 부근) + 텍스트 t-out(350,350)
  Stroke inStroke(String ink, {String shapeType = ''}) => createStroke(
    ink: ink,
    shapeType: shapeType,
    points: createPoints([
      [50, 50],
      [70, 70],
      [90, 90],
    ]),
  );

  Stroke outStroke() => createStroke(
    ink: 'pen',
    points: createPoints([
      [300, 300],
      [320, 320],
      [340, 340],
    ]),
  );

  Stroke lassoStroke() => createStroke(
    ink: 'lasso',
    points: createPoints([
      [10, 10],
      [210, 10],
      [210, 210],
      [10, 210],
    ]),
  );

  /// strokes 인덱스: 0=pen(안) 1=marker(안) 2=shape(안) 3=pen(밖) 4=lasso.
  ///
  /// ⚠️ 올가미 스트로크는 생성자 경유로 넣을 수 없다 —
  /// [ScribbleNotifier] 생성자가 `removeLassoStrokes()` 로 초기 scribble 의
  /// 올가미를 정화한다. 실사용과 동일하게 "드로잉 이후" 상태를 만들려면
  /// 생성 후 [ScribbleNotifier.setScribble] 로 주입해야 한다.
  ScribbleNotifier buildNotifier() {
    final notifier = ScribbleNotifier();
    notifier.setScribble(
      scribble: Scribble(
        width: 400,
        height: 400,
        strokes: [
          inStroke('pen'),
          inStroke('marker'),
          inStroke('shape', shapeType: 'rectangle'),
          outStroke(),
          lassoStroke(),
        ],
        textDrawables: [
          createTextDrawable(id: 't-in', x: 100, y: 100),
          createTextDrawable(id: 't-out', x: 350, y: 350),
        ],
      ),
    );
    return notifier;
  }

  LassoSelectionManager buildManager(
    ScribbleNotifier notifier, {
    CanSelectScribbleItem? canSelectItem,
  }) => LassoSelectionManager(
    scribbleNotifier: notifier,
    onStateChanged: () {},
    transformationController: TransformationController(),
    onModeChanged: null,
    canSelectItem: canSelectItem,
  );

  group('canSelectItem 미주입 (null) — 기존 동작 패리티', () {
    test('should_select_all_inside_elements_when_policy_absent', () {
      final notifier = buildNotifier();
      addTearDown(notifier.dispose);
      final manager = buildManager(notifier);

      manager.selectElementsInLassoIfNeeded();

      // 폴리곤 안 스트로크 3개(0,1,2) + 올가미 자신(4). 밖(3)은 제외.
      expect(manager.selectedStrokeIds, unorderedEquals([0, 1, 2, 4]));
      // 폴리곤 안 텍스트만 (인덱스 0 = t-in).
      expect(manager.selectedTextIds, [0]);
    });
  });

  group('스트로크 ink 필터', () {
    test('should_select_only_marker_stroke_when_policy_allows_marker_only', () {
      final notifier = buildNotifier();
      addTearDown(notifier.dispose);
      final manager = buildManager(
        notifier,
        canSelectItem: (item) => switch (item) {
          ScribbleSelectableStroke(:final ink) => ink == 'marker',
          ScribbleSelectableText() => false,
        },
      );

      manager.selectElementsInLassoIfNeeded();

      // marker(1) + 올가미 자신(4)만 — 올가미 인덱스는 선택 확정 시 항상
      // 함께 담기는 기존 동작이다(오버레이 이동 대상에 올가미 곡선 포함).
      expect(manager.selectedStrokeIds, unorderedEquals([1, 4]));
      expect(manager.selectedTextIds, isEmpty);
    });

    test('should_pass_shape_type_to_policy_for_shape_strokes', () {
      final notifier = buildNotifier();
      addTearDown(notifier.dispose);
      final seenShapeTypes = <String>[];
      final manager = buildManager(
        notifier,
        canSelectItem: (item) {
          if (item is ScribbleSelectableStroke) {
            seenShapeTypes.add(item.shapeType);
          }
          return true;
        },
      );

      manager.selectElementsInLassoIfNeeded();

      expect(seenShapeTypes, contains('rectangle'));
    });

    test('should_never_pass_lasso_stroke_to_policy', () {
      final notifier = buildNotifier();
      addTearDown(notifier.dispose);
      final seenInks = <String>[];
      final manager = buildManager(
        notifier,
        canSelectItem: (item) {
          if (item is ScribbleSelectableStroke) {
            seenInks.add(item.ink);
          }
          return true;
        },
      );

      manager.selectElementsInLassoIfNeeded();

      expect(seenInks, isNot(contains('lasso')));
    });
  });

  group('텍스트박스 필터', () {
    test('should_exclude_text_when_policy_denies_text', () {
      final notifier = buildNotifier();
      addTearDown(notifier.dispose);
      final manager = buildManager(
        notifier,
        canSelectItem: (item) => switch (item) {
          ScribbleSelectableStroke() => true,
          ScribbleSelectableText() => false,
        },
      );

      manager.selectElementsInLassoIfNeeded();

      expect(manager.selectedStrokeIds, unorderedEquals([0, 1, 2, 4]));
      expect(manager.selectedTextIds, isEmpty);
    });

    test('should_pass_text_id_to_policy', () {
      final notifier = buildNotifier();
      addTearDown(notifier.dispose);
      final seenTextIds = <String>[];
      final manager = buildManager(
        notifier,
        canSelectItem: (item) {
          if (item is ScribbleSelectableText) {
            seenTextIds.add(item.id);
          }
          return true;
        },
      );

      manager.selectElementsInLassoIfNeeded();

      expect(seenTextIds, contains('t-in'));
    });
  });

  group('전부 거부', () {
    test('should_select_nothing_when_policy_denies_all', () {
      final notifier = buildNotifier();
      addTearDown(notifier.dispose);
      final manager = buildManager(notifier, canSelectItem: (_) => false);

      manager.selectElementsInLassoIfNeeded();

      // 후보 0건이면 기존 "빈 올가미" 경로와 동일하게 선택 없이 리셋된다.
      expect(manager.selectedStrokeIds, isEmpty);
      expect(manager.selectedTextIds, isEmpty);
    });
  });

  group('필터된 선택 + 삭제 — 인덱스 계약', () {
    test('should_remove_exactly_filtered_strokes_on_delete', () {
      final notifier = buildNotifier();
      addTearDown(notifier.dispose);
      final manager = buildManager(
        notifier,
        canSelectItem: (item) => switch (item) {
          ScribbleSelectableStroke(:final ink) => ink == 'marker',
          ScribbleSelectableText() => false,
        },
      );

      manager.selectElementsInLassoIfNeeded();
      manager.removeSelectedStrokes(manager.selectedStrokeIds);

      // marker(1)와 올가미(4)만 삭제 — 선택 ID 가 전체 리스트 기준
      // 인덱스라는 계약이 필터 도입 후에도 유지됨을 고정한다.
      final remainingInks = notifier.currentState.scribble.strokes
          .map((s) => s.ink)
          .toList();
      expect(remainingInks, ['pen', 'shape', 'pen']);
      // 텍스트는 정책이 거부해 선택되지 않았으므로 삭제되지 않는다.
      expect(notifier.currentState.scribble.textDrawables.length, 2);
    });
  });
}

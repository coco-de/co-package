import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:open_board/src/core/utils/ink_group_info.dart';
import 'package:open_board/src/module/painter/paint_delegate.dart';
import 'package:open_board/src/module/state/scribble.state.dart';
import 'package:open_board/src/module/state/scribble_mode.state.dart';

/// 커서/지우개 시각 표시를 담당하는 Delegate
class CursorPaintDelegate implements PaintDelegate {
  /// 현재 필기 상태
  final ScribbleState state;

  /// 현재 모드 상태
  final ScribbleModeState modeState;

  /// 지우개 표시 여부
  final bool drawEraser;

  const CursorPaintDelegate({
    required this.state,
    required this.modeState,
    required this.drawEraser,
  });

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    // 모드가 지우개로 유지될 때만 커서를 그린다. state(Erasing)가 stale하게 남아도
    // mode가 펜으로 바뀌면 커서를 그리지 않아 잔상을 방지한다.
    final isEraserMode =
        modeState.inkGroupInfo.selectedInk == InkModes.erase;
    if (state.pointerPosition != null &&
        state is Erasing &&
        isEraserMode &&
        drawEraser) {
      canvas.save();
      _drawPointer(canvas);
      canvas.restore();
    }
  }

  /// 포인터(커서/지우개) 렌더링
  void _drawPointer(ui.Canvas canvas) {
    Paint paint = Paint()..style = .fill;

    paint.style = switch (state) {
      Drawing() => .fill,
      Erasing() => .fill,
    };
    paint.color = switch (state) {
      Drawing() => modeState.inkGroupInfo.selectedColor,
      Erasing() => Colors.grey.withValues(alpha: 0.7),
    };
    paint.strokeWidth = 1;

    // 지우개 모드일 때 두께에 맞는 크기로 포인터 그리기
    final radius = state is Erasing
        ? modeState.inkGroupInfo.seletedStrokeWidth
        : modeState.options.size;

    canvas.drawCircle(
      Offset(state.pointerPosition!.x, state.pointerPosition!.y),
      radius,
      paint,
    );
  }
}

import 'package:flutter/foundation.dart';
import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';

enum ScribblePointerMode { all, mouseOnly, penOnly, mouseAndPen }

/// copyWith에서 `pointerPosition: null`(커서 제거)과 '미전달'(기존 값 유지)을
/// 구분하기 위한 sentinel. `?? this.pointerPosition` 병합은 null 전달을
/// 침묵 무시하여 지우개 커서 잔상이 남는 버그를 만든다.
const Object _unsetPointerPosition = Object();

@immutable
sealed class ScribbleState {
  final Scribble scribble;

  final List<int> activePointerIds;
  final Point? pointerPosition;

  const ScribbleState({
    required this.scribble,
    required this.activePointerIds,
    this.pointerPosition,
  });

  bool get active => activePointerIds.length <= 1;
}

@immutable
final class Drawing extends ScribbleState {
  /// The line that is currently being drawn
  final Stroke? activeLine;

  /// 올가미 도구로 선택된 스트로크의 IDs
  final List<int> selectedStrokeIds;

  const Drawing({
    required super.scribble,
    this.activeLine,
    super.activePointerIds = const [],
    this.selectedStrokeIds = const [],
    super.pointerPosition,
  });

  Drawing copyWith({
    Scribble? scribble,
    Stroke? activeLine,
    List<int>? activePointerIds,
    Object? pointerPosition = _unsetPointerPosition,
  }) => .new(
    scribble: scribble ?? this.scribble,
    activeLine: activeLine ?? this.activeLine,
    activePointerIds: activePointerIds ?? this.activePointerIds,
    selectedStrokeIds: selectedStrokeIds,
    pointerPosition: identical(pointerPosition, _unsetPointerPosition)
        ? this.pointerPosition
        : pointerPosition as Point?,
  );
}

@immutable
final class Erasing extends ScribbleState {
  const Erasing({
    required super.scribble,
    super.activePointerIds = const [],
    super.pointerPosition,
  });

  Erasing copyWith({
    Scribble? scribble,
    List<int>? activePointerIds,
    Object? pointerPosition = _unsetPointerPosition,
  }) => .new(
    scribble: scribble ?? this.scribble,
    activePointerIds: activePointerIds ?? this.activePointerIds,
    pointerPosition: identical(pointerPosition, _unsetPointerPosition)
        ? this.pointerPosition
        : pointerPosition as Point?,
  );
}

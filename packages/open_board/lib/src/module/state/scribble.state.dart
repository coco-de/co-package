import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';

enum ScribblePointerMode { all, mouseOnly, penOnly, mouseAndPen }

sealed class ScribbleState {
  const ScribbleState({
    required this.scribble,
    required this.activePointerIds,
    this.pointerPosition,
  });

  final Scribble scribble;
  final List<int> activePointerIds;
  final Point? pointerPosition;

  bool get active => activePointerIds.length <= 1;

  List<Stroke> get lines => switch (this) {
    Drawing(:final scribble, :final activeLine) =>
      activeLine == null ? scribble.strokes : [...scribble.strokes, activeLine],
    Erasing(:final scribble) => scribble.strokes,
  };
}

final class Drawing extends ScribbleState {
  const Drawing({
    required super.scribble,
    this.activeLine,
    super.activePointerIds = const [],
    this.selectedStrokeIds = const [],
    super.pointerPosition,
  });

  /// The line that is currently being drawn
  final Stroke? activeLine;

  /// 올가미 도구로 선택된 스트로크의 IDs
  final List<int> selectedStrokeIds;

  Drawing copyWith({
    Scribble? scribble,
    Stroke? activeLine,
    List<int>? activePointerIds,
    List<int>? selectedStrokeIds,
    Point? pointerPosition,
  }) => Drawing(
    scribble: scribble ?? this.scribble,
    activeLine: activeLine ?? this.activeLine,
    activePointerIds: activePointerIds ?? this.activePointerIds,
    selectedStrokeIds: selectedStrokeIds ?? this.selectedStrokeIds,
    pointerPosition: pointerPosition ?? this.pointerPosition,
  );
}

final class Erasing extends ScribbleState {
  const Erasing({
    required super.scribble,
    super.activePointerIds = const [],
    super.pointerPosition,
  });

  Erasing copyWith({
    Scribble? scribble,
    List<int>? activePointerIds,
    Point? pointerPosition,
  }) => Erasing(
    scribble: scribble ?? this.scribble,
    activePointerIds: activePointerIds ?? this.activePointerIds,
    pointerPosition: pointerPosition ?? this.pointerPosition,
  );
}

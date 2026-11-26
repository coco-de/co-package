import 'package:flutter/foundation.dart';

/// open_note: 지우개 방식.
enum ScribbleEraserMode {
  /// 닿은 스트로크를 통째로 지운다 (open_board 기본 동작).
  stroke,

  /// 지나간 부분만 지우고 남은 구간은 새 스트로크로 남긴다.
  pixel,
}

/// open_note: 펜의 획 안정화 · 필압 설정. 새로 그리는 스트로크에만 적용되고
/// 스트로크에 저장된 값(`StrokeOptions`)은 이후 바뀌지 않는다.
@immutable
class ScribblePenParams {
  const ScribblePenParams({
    this.streamline = 0.5,
    this.smoothing = 0.5,
    this.thinningScale = 1,
    this.pressureGamma = 1,
  }) : assert(streamline >= 0 && streamline <= 1),
       assert(smoothing >= 0 && smoothing <= 1),
       assert(thinningScale >= 0),
       assert(pressureGamma > 0);

  /// open_board 와 같은 기본값 — 지정하지 않으면 필기 결과가 바뀌지 않는다.
  static const ScribblePenParams standard = ScribblePenParams();

  /// perfect_freehand `streamline` (0..1). 클수록 손떨림이 더 눌리지만
  /// 획이 입력을 늦게 따라온다 ("획 안정화").
  final double streamline;

  /// perfect_freehand `smoothing` (0..1) — 외곽선 밀도 ("모션 스무딩").
  final double smoothing;

  /// 필압이 두께에 미치는 폭의 배율. 엔진 thinning(하드웨어 0.9 · 속도 0.7)에
  /// 곱해 0..0.99 로 자른다. 0 이면 균일 두께.
  final double thinningScale;

  /// 하드웨어 필압에 적용하는 감마. 1 이면 종전과 같고, 1 보다 작으면 약한
  /// 터치가 굵게, 크면 약한 터치가 얇게 기록된다.
  final double pressureGamma;

  ScribblePenParams copyWith({
    double? streamline,
    double? smoothing,
    double? thinningScale,
    double? pressureGamma,
  }) => ScribblePenParams(
    streamline: streamline ?? this.streamline,
    smoothing: smoothing ?? this.smoothing,
    thinningScale: thinningScale ?? this.thinningScale,
    pressureGamma: pressureGamma ?? this.pressureGamma,
  );

  @override
  bool operator ==(Object other) =>
      other is ScribblePenParams &&
      other.streamline == streamline &&
      other.smoothing == smoothing &&
      other.thinningScale == thinningScale &&
      other.pressureGamma == pressureGamma;

  @override
  int get hashCode =>
      Object.hash(streamline, smoothing, thinningScale, pressureGamma);
}

/// open_note: 모드 상태에 실려 [ScribbleNotifier] 가 읽는 필기 입력 옵션.
///
/// 모든 기본값은 open_board 의 기존 동작과 같다.
@immutable
class ScribbleInputOptions {
  const ScribbleInputOptions({
    this.pen = ScribblePenParams.standard,
    this.lineStyle = '',
    this.shapeStyle = '',
    this.eraserMode = ScribbleEraserMode.stroke,
    this.pressureEraser = false,
    this.pressureEraserThreshold = 0.8,
    this.holdToSnapShapes = false,
    this.rectangleLasso = false,
  }) : assert(pressureEraserThreshold > 0 && pressureEraserThreshold <= 1);

  static const ScribbleInputOptions standard = ScribbleInputOptions();

  /// 획 안정화 · 필압.
  final ScribblePenParams pen;

  /// 새 필기 스트로크의 선 스타일(`NoteLineStyle.encode()`). '' 는 실선.
  final String lineStyle;

  /// 새 도형 스트로크의 도형 스타일(`NoteShapeStyle.encode()`).
  final String shapeStyle;

  /// 지우개 방식.
  final ScribbleEraserMode eraserMode;

  /// 필기 도중 세게 누르면 그 제스처를 지우개로 바꾼다 (하드웨어 필압이 있는
  /// 입력에만 적용).
  final bool pressureEraser;

  /// [pressureEraser] 가 켜지는 정규화 필압(곡선 적용 전, 0..1].
  final double pressureEraserThreshold;

  /// 펜을 멈추고 있으면 손그림 도형(원·사각형·삼각형…)으로 보정한다. 인식하지
  /// 못하면 종전처럼 직선으로 편다. 꺼져 있으면 항상 직선화만 한다.
  final bool holdToSnapShapes;

  /// 올가미를 자유곡선 대신 사각형 드래그로 그린다.
  final bool rectangleLasso;

  ScribbleInputOptions copyWith({
    ScribblePenParams? pen,
    String? lineStyle,
    String? shapeStyle,
    ScribbleEraserMode? eraserMode,
    bool? pressureEraser,
    double? pressureEraserThreshold,
    bool? holdToSnapShapes,
    bool? rectangleLasso,
  }) => ScribbleInputOptions(
    pen: pen ?? this.pen,
    lineStyle: lineStyle ?? this.lineStyle,
    shapeStyle: shapeStyle ?? this.shapeStyle,
    eraserMode: eraserMode ?? this.eraserMode,
    pressureEraser: pressureEraser ?? this.pressureEraser,
    pressureEraserThreshold:
        pressureEraserThreshold ?? this.pressureEraserThreshold,
    holdToSnapShapes: holdToSnapShapes ?? this.holdToSnapShapes,
    rectangleLasso: rectangleLasso ?? this.rectangleLasso,
  );

  @override
  bool operator ==(Object other) =>
      other is ScribbleInputOptions &&
      other.pen == pen &&
      other.lineStyle == lineStyle &&
      other.shapeStyle == shapeStyle &&
      other.eraserMode == eraserMode &&
      other.pressureEraser == pressureEraser &&
      other.pressureEraserThreshold == pressureEraserThreshold &&
      other.holdToSnapShapes == holdToSnapShapes &&
      other.rectangleLasso == rectangleLasso;

  @override
  int get hashCode => Object.hash(
    pen,
    lineStyle,
    shapeStyle,
    eraserMode,
    pressureEraser,
    pressureEraserThreshold,
    holdToSnapShapes,
    rectangleLasso,
  );
}

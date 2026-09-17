import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';

/// Protobuf 모델 테스트 팩토리 헬퍼
///
/// protobuf 생성 클래스의 생성자가 복잡하므로, 테스트에서 자주 사용되는
/// 기본 인스턴스를 간편하게 생성하기 위한 팩토리 함수 모음.

/// 기본 [Point] 생성
Point createPoint({
  double x = 0,
  double y = 0,
  double p = 0.5,
  double altitude = 0,
  double azimuth = 0,
  double opacity = 1.0,
}) {
  return Point(
    x: x,
    y: y,
    p: p,
    altitude: altitude,
    azimuth: azimuth,
    opacity: opacity,
  );
}

/// [Point] 리스트를 좌표 쌍 리스트에서 생성
List<Point> createPoints(List<List<double>> coordinates) {
  return coordinates
      .map((c) => createPoint(x: c[0], y: c[1], p: c.length > 2 ? c[2] : 0.5))
      .toList();
}

/// 직선 포인트 리스트 생성 (from → to, count개)
List<Point> createLinePoints({
  double fromX = 0,
  double fromY = 0,
  double toX = 100,
  double toY = 100,
  int count = 10,
  double pressure = 0.5,
}) {
  return List.generate(count, (i) {
    final t = i / (count - 1);
    return createPoint(
      x: fromX + (toX - fromX) * t,
      y: fromY + (toY - fromY) * t,
      p: pressure,
    );
  });
}

/// 기본 [StrokeOptions] 생성
StrokeOptions createStrokeOptions({
  double size = 2.0,
  double thinning = 0.7,
  double smoothing = 0.5,
  double streamline = 0.5,
  double taperStart = 0.0,
  double taperEnd = 0.0,
  bool capStart = true,
  bool capEnd = true,
  bool simulatePressure = true,
  bool isComplete = false,
}) {
  return StrokeOptions(
    size: size,
    thinning: thinning,
    smoothing: smoothing,
    streamline: streamline,
    taperStart: taperStart,
    taperEnd: taperEnd,
    capStart: capStart,
    capEnd: capEnd,
    simulatePressure: simulatePressure,
    isComplete: isComplete,
  );
}

/// 기본 [Stroke] 생성
Stroke createStroke({
  List<Point>? points,
  int color = 0xFF000000,
  String ink = 'pencil',
  String? createdAt,
  StrokeOptions? options,
  String shapeType = '',
  double width = 2.0,
}) {
  return Stroke(
    points: points ?? createLinePoints(),
    color: color,
    ink: ink,
    createdAt: createdAt ?? DateTime.now().toIso8601String(),
    options: options ?? createStrokeOptions(),
    shapeType: shapeType,
    width: width,
  );
}

/// 기본 [TextDrawable] 생성
TextDrawable createTextDrawable({
  String? id,
  String text = 'Test Text',
  double x = 50,
  double y = 50,
  String fontFamily = 'Roboto',
  double fontSize = 16,
  int color = 0xFF000000,
  bool isBold = false,
  bool isItalic = false,
  bool isUnderlined = false,
  String textAlign = 'left',
  bool hidden = false,
  double rotation = 0,
}) {
  return TextDrawable(
    id: id ?? 'text_${DateTime.now().microsecondsSinceEpoch}',
    text: text,
    x: x,
    y: y,
    fontFamily: fontFamily,
    fontSize: fontSize,
    color: color,
    isBold: isBold,
    isItalic: isItalic,
    isUnderlined: isUnderlined,
    textAlign: textAlign,
    hidden: hidden,
    rotation: rotation,
  );
}

/// 기본 [Scribble] 생성
Scribble createScribble({
  double width = 400,
  double height = 600,
  List<Stroke>? strokes,
  List<TextDrawable>? textDrawables,
  String? createdAt,
  String? updatedAt,
  String version = '1.0.0',
  double x = 0,
  double y = 0,
}) {
  return Scribble(
    width: width,
    height: height,
    strokes: strokes ?? [],
    textDrawables: textDrawables ?? [],
    createdAt: createdAt ?? DateTime.now().toIso8601String(),
    updatedAt: updatedAt ?? DateTime.now().toIso8601String(),
    version: version,
    x: x,
    y: y,
  );
}

/// 여러 스트로크를 가진 Scribble 생성
Scribble createScribbleWithStrokes({
  int strokeCount = 3,
  double width = 400,
  double height = 600,
}) {
  final strokes = List.generate(strokeCount, (i) {
    final offset = i * 30.0;
    return createStroke(
      points: createLinePoints(
        fromX: offset,
        fromY: offset,
        toX: offset + 100,
        toY: offset + 100,
      ),
    );
  });
  return createScribble(width: width, height: height, strokes: strokes);
}

/// 사각형 포인트 리스트 생성 (도형 감지 테스트용)
List<Point> createRectanglePoints({
  double left = 0,
  double top = 0,
  double right = 100,
  double bottom = 100,
  int pointsPerSide = 5,
}) {
  final points = <Point>[];
  // top edge
  for (var i = 0; i < pointsPerSide; i++) {
    final t = i / (pointsPerSide - 1);
    points.add(createPoint(x: left + (right - left) * t, y: top));
  }
  // right edge
  for (var i = 1; i < pointsPerSide; i++) {
    final t = i / (pointsPerSide - 1);
    points.add(createPoint(x: right, y: top + (bottom - top) * t));
  }
  // bottom edge (reverse)
  for (var i = 1; i < pointsPerSide; i++) {
    final t = i / (pointsPerSide - 1);
    points.add(createPoint(x: right - (right - left) * t, y: bottom));
  }
  // left edge (reverse)
  for (var i = 1; i < pointsPerSide; i++) {
    final t = i / (pointsPerSide - 1);
    points.add(createPoint(x: left, y: bottom - (bottom - top) * t));
  }
  return points;
}

import 'dart:math' as math;
import 'dart:ui';
import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';

/// PDF와 Scribble 간의 좌표 변환을 처리하는 클래스
///
/// PDF는 고정된 크기(포인트 단위)를 가지지만, 화면에 표시될 때는
/// 다양한 크기와 위치로 변환됩니다. 이 클래스는 이러한 변환을
/// 정확하게 계산하여 필기 데이터의 일관성을 보장합니다.
class ScribbleCoordinateConverter {
  /// PDF 원본 크기 (포인트 단위)
  final Size pdfOriginalSize;

  /// 화면에 표시되는 PDF 영역 (픽셀 단위)
  final Rect pdfDisplayRect;

  /// Scribble 캔버스 크기 (픽셀 단위)
  final Size scribbleCanvasSize;

  /// 현재 확대/축소 비율
  final double scaleFactor;

  /// 스크롤 오프셋
  final Offset scrollOffset;

  /// 회전 각도 (라디안)
  final double rotationAngle;

  /// 양면 모드 여부
  final bool isDoublePage;

  /// 양면 모드에서 현재 페이지가 왼쪽인지 여부
  final bool isLeftPage;

  const ScribbleCoordinateConverter({
    required this.pdfOriginalSize,
    required this.pdfDisplayRect,
    required this.scribbleCanvasSize,
    this.scaleFactor = 1.0,
    this.scrollOffset = Offset.zero,
    this.rotationAngle = 0.0,
    this.isDoublePage = false,
    this.isLeftPage = true,
  });

  /// 팩토리 생성자: PDF 뷰어 상태로부터 변환기 생성
  factory ScribbleCoordinateConverter.fromPdfViewer({
    required Size pdfOriginalSize,
    required Rect pdfDisplayRect,
    required Size screenSize,
    double scaleFactor = 1.0,
    Offset scrollOffset = Offset.zero,
    double rotationAngle = 0.0,
    bool isDoublePage = false,
    bool isLeftPage = true,
  }) {
    return ScribbleCoordinateConverter(
      pdfOriginalSize: pdfOriginalSize,
      pdfDisplayRect: pdfDisplayRect,
      scribbleCanvasSize: screenSize,
      scaleFactor: scaleFactor,
      scrollOffset: scrollOffset,
      rotationAngle: rotationAngle,
      isDoublePage: isDoublePage,
      isLeftPage: isLeftPage,
    );
  }

  /// PDF 좌표를 Scribble 좌표로 변환
  ///
  /// PDF에서 필기할 때 사용되는 변환
  /// 화면 터치 좌표를 PDF 내의 상대적 위치로 변환
  Offset pdfToScribble(Offset pdfPoint) {
    // 1. PDF 원본 크기 기준으로 정규화 (0.0 ~ 1.0)
    final normalizedX = pdfPoint.dx / pdfOriginalSize.width;
    final normalizedY = pdfPoint.dy / pdfOriginalSize.height;

    // 2. 양면 모드 처리
    double adjustedNormalizedX = normalizedX;
    if (isDoublePage) {
      if (isLeftPage) {
        // 왼쪽 페이지: X 좌표를 절반으로 스케일
        adjustedNormalizedX = normalizedX * 0.5;
      } else {
        // 오른쪽 페이지: X 좌표를 절반으로 스케일하고 0.5 오프셋 추가
        adjustedNormalizedX = (normalizedX * 0.5) + 0.5;
      }
    }

    // 3. 회전 적용
    final rotatedPoint = _applyRotation(
      Offset(adjustedNormalizedX, normalizedY),
      rotationAngle,
    );

    // 4. Scribble 캔버스 크기로 스케일링
    final scribbleX = rotatedPoint.dx * scribbleCanvasSize.width;
    final scribbleY = rotatedPoint.dy * scribbleCanvasSize.height;

    // 5. 스크롤 오프셋 적용
    final finalX = scribbleX - scrollOffset.dx;
    final finalY = scribbleY - scrollOffset.dy;

    return Offset(finalX, finalY);
  }

  /// Scribble 좌표를 PDF 좌표로 변환
  ///
  /// 필기 데이터를 저장하거나 로드할 때 사용되는 변환
  /// Scribble 캔버스의 좌표를 PDF 원본 좌표로 변환
  Offset scribbleToPdf(Offset scribblePoint) {
    // 1. 스크롤 오프셋 보정
    final offsetCorrectedX = scribblePoint.dx + scrollOffset.dx;
    final offsetCorrectedY = scribblePoint.dy + scrollOffset.dy;

    // 2. Scribble 캔버스 크기 기준으로 정규화 (0.0 ~ 1.0)
    final normalizedX = offsetCorrectedX / scribbleCanvasSize.width;
    final normalizedY = offsetCorrectedY / scribbleCanvasSize.height;

    // 3. 회전 역변환 적용
    final derotatedPoint = _applyRotation(
      Offset(normalizedX, normalizedY),
      -rotationAngle,
    );

    // 4. 양면 모드 역변환 처리
    double adjustedNormalizedX = derotatedPoint.dx;
    if (isDoublePage) {
      if (isLeftPage) {
        // 왼쪽 페이지: X 좌표를 2배로 확대
        adjustedNormalizedX = derotatedPoint.dx * 2.0;
      } else {
        // 오른쪽 페이지: 0.5 오프셋 제거 후 2배로 확대
        adjustedNormalizedX = (derotatedPoint.dx - 0.5) * 2.0;
      }

      // 범위 제한 (0.0 ~ 1.0)
      adjustedNormalizedX = adjustedNormalizedX.clamp(0.0, 1.0);
    }

    // 5. PDF 원본 크기로 스케일링
    final pdfX = adjustedNormalizedX * pdfOriginalSize.width;
    final pdfY = derotatedPoint.dy * pdfOriginalSize.height;

    return Offset(pdfX, pdfY);
  }

  /// 화면 터치 좌표를 Scribble 좌표로 변환
  ///
  /// 사용자가 화면을 터치했을 때의 좌표를
  /// Scribble 캔버스 좌표로 변환
  Offset screenToScribble(Offset screenPoint) {
    // 1. PDF 표시 영역 내의 상대적 위치 계산
    final relativeX =
        (screenPoint.dx - pdfDisplayRect.left) / pdfDisplayRect.width;
    final relativeY =
        (screenPoint.dy - pdfDisplayRect.top) / pdfDisplayRect.height;

    // 2. 범위 체크 (PDF 영역 밖은 무시)
    if (relativeX < 0.0 ||
        relativeX > 1.0 ||
        relativeY < 0.0 ||
        relativeY > 1.0) {
      return Offset.infinite; // 무효한 좌표 표시
    }

    // 3. 스케일 팩터 적용
    final scaledRelativeX = relativeX / scaleFactor;
    final scaledRelativeY = relativeY / scaleFactor;

    // 4. PDF 원본 크기 기준 좌표로 변환
    final pdfX = scaledRelativeX * pdfOriginalSize.width;
    final pdfY = scaledRelativeY * pdfOriginalSize.height;

    // 5. PDF 좌표를 Scribble 좌표로 변환
    return pdfToScribble(Offset(pdfX, pdfY));
  }

  /// Scribble 좌표를 화면 좌표로 변환
  ///
  /// 저장된 필기 데이터를 화면에 표시할 때 사용
  Offset scribbleToScreen(Offset scribblePoint) {
    // 1. Scribble 좌표를 PDF 좌표로 변환
    final pdfPoint = scribbleToPdf(scribblePoint);

    // 2. PDF 원본 크기 기준으로 정규화
    final normalizedX = pdfPoint.dx / pdfOriginalSize.width;
    final normalizedY = pdfPoint.dy / pdfOriginalSize.height;

    // 3. 스케일 팩터 적용
    final scaledNormalizedX = normalizedX * scaleFactor;
    final scaledNormalizedY = normalizedY * scaleFactor;

    // 4. PDF 표시 영역 좌표로 변환
    final screenX =
        pdfDisplayRect.left + (scaledNormalizedX * pdfDisplayRect.width);
    final screenY =
        pdfDisplayRect.top + (scaledNormalizedY * pdfDisplayRect.height);

    return Offset(screenX, screenY);
  }

  /// 스트로크 전체를 PDF 좌표에서 Scribble 좌표로 변환
  Stroke convertStrokePdfToScribble(Stroke pdfStroke) {
    final convertedPoints = pdfStroke.points.map((point) {
      final pdfOffset = Offset(point.x, point.y);
      final scribbleOffset = pdfToScribble(pdfOffset);

      return Point(
        x: scribbleOffset.dx,
        y: scribbleOffset.dy,
        p: point.p, // 압력값은 그대로 유지
      );
    }).toList();

    return Stroke(
      points: convertedPoints,
      ink: pdfStroke.ink,
      options: pdfStroke.options,
    );
  }

  /// 스트로크 전체를 Scribble 좌표에서 PDF 좌표로 변환
  Stroke convertStrokeScribbleToPdf(Stroke scribbleStroke) {
    final convertedPoints = scribbleStroke.points.map((point) {
      final scribbleOffset = Offset(point.x, point.y);
      final pdfOffset = scribbleToPdf(scribbleOffset);

      return Point(
        x: pdfOffset.dx,
        y: pdfOffset.dy,
        p: point.p, // 압력값은 그대로 유지
      );
    }).toList();

    return Stroke(
      points: convertedPoints,
      ink: scribbleStroke.ink,
      options: scribbleStroke.options,
    );
  }

  /// Scribble 객체 전체를 PDF 좌표에서 Scribble 좌표로 변환
  Scribble convertScribblePdfToCanvas(Scribble pdfScribble) {
    final convertedStrokes = pdfScribble.strokes
        .map((stroke) => convertStrokePdfToScribble(stroke))
        .toList();

    final convertedTextDrawables = pdfScribble.textDrawables.map((
      textDrawable,
    ) {
      final pdfOffset = Offset(textDrawable.x, textDrawable.y);
      final scribbleOffset = pdfToScribble(pdfOffset);

      return TextDrawable(
        id: textDrawable.id,
        text: textDrawable.text,
        x: scribbleOffset.dx,
        y: scribbleOffset.dy,
        fontSize: textDrawable.fontSize,
        color: textDrawable.color,
        fontFamily: textDrawable.fontFamily,
        isBold: textDrawable.isBold,
        isItalic: textDrawable.isItalic,
        isUnderlined: textDrawable.isUnderlined,
        textAlign: textDrawable.textAlign,
        rotation: textDrawable.rotation,
        hidden: textDrawable.hidden,
        createdAt: textDrawable.createdAt,
        updatedAt: textDrawable.updatedAt,
      );
    }).toList();

    return Scribble(
      strokes: convertedStrokes,
      textDrawables: convertedTextDrawables,
      width: scribbleCanvasSize.width,
      height: scribbleCanvasSize.height,
      x: pdfScribble.x,
      y: pdfScribble.y,
      createdAt: pdfScribble.createdAt,
      updatedAt: pdfScribble.updatedAt,
      version: pdfScribble.version,
    );
  }

  /// Scribble 객체 전체를 Scribble 좌표에서 PDF 좌표로 변환
  Scribble convertScribbleCanvasToPdf(Scribble canvasScribble) {
    final convertedStrokes = canvasScribble.strokes
        .map((stroke) => convertStrokeScribbleToPdf(stroke))
        .toList();

    final convertedTextDrawables = canvasScribble.textDrawables.map((
      textDrawable,
    ) {
      final scribbleOffset = Offset(textDrawable.x, textDrawable.y);
      final pdfOffset = scribbleToPdf(scribbleOffset);

      return TextDrawable(
        id: textDrawable.id,
        text: textDrawable.text,
        x: pdfOffset.dx,
        y: pdfOffset.dy,
        fontSize: textDrawable.fontSize,
        color: textDrawable.color,
        fontFamily: textDrawable.fontFamily,
        isBold: textDrawable.isBold,
        isItalic: textDrawable.isItalic,
        isUnderlined: textDrawable.isUnderlined,
        textAlign: textDrawable.textAlign,
        rotation: textDrawable.rotation,
        hidden: textDrawable.hidden,
        createdAt: textDrawable.createdAt,
        updatedAt: textDrawable.updatedAt,
      );
    }).toList();

    return Scribble(
      strokes: convertedStrokes,
      textDrawables: convertedTextDrawables,
      width: pdfOriginalSize.width,
      height: pdfOriginalSize.height,
      x: canvasScribble.x,
      y: canvasScribble.y,
      createdAt: canvasScribble.createdAt,
      updatedAt: canvasScribble.updatedAt,
      version: canvasScribble.version,
    );
  }

  /// 현재 상태로 새로운 변환기 생성 (불변성 유지)
  ScribbleCoordinateConverter copyWith({
    Size? pdfOriginalSize,
    Rect? pdfDisplayRect,
    Size? scribbleCanvasSize,
    double? scaleFactor,
    Offset? scrollOffset,
    double? rotationAngle,
    bool? isDoublePage,
    bool? isLeftPage,
  }) {
    return ScribbleCoordinateConverter(
      pdfOriginalSize: pdfOriginalSize ?? this.pdfOriginalSize,
      pdfDisplayRect: pdfDisplayRect ?? this.pdfDisplayRect,
      scribbleCanvasSize: scribbleCanvasSize ?? this.scribbleCanvasSize,
      scaleFactor: scaleFactor ?? this.scaleFactor,
      scrollOffset: scrollOffset ?? this.scrollOffset,
      rotationAngle: rotationAngle ?? this.rotationAngle,
      isDoublePage: isDoublePage ?? this.isDoublePage,
      isLeftPage: isLeftPage ?? this.isLeftPage,
    );
  }

  /// 좌표 유효성 검증
  bool isValidScribbleCoordinate(Offset scribblePoint) {
    return scribblePoint.dx >= 0 &&
        scribblePoint.dx <= scribbleCanvasSize.width &&
        scribblePoint.dy >= 0 &&
        scribblePoint.dy <= scribbleCanvasSize.height;
  }

  /// PDF 좌표 유효성 검증
  bool isValidPdfCoordinate(Offset pdfPoint) {
    return pdfPoint.dx >= 0 &&
        pdfPoint.dx <= pdfOriginalSize.width &&
        pdfPoint.dy >= 0 &&
        pdfPoint.dy <= pdfOriginalSize.height;
  }

  /// 두 변환기가 호환되는지 확인
  bool isCompatibleWith(ScribbleCoordinateConverter other) {
    return pdfOriginalSize == other.pdfOriginalSize &&
        isDoublePage == other.isDoublePage &&
        isLeftPage == other.isLeftPage;
  }

  /// 디버깅을 위한 변환 정보 출력
  Map<String, dynamic> toDebugInfo() {
    return {
      'pdfOriginalSize': '${pdfOriginalSize.width}x${pdfOriginalSize.height}',
      'pdfDisplayRect':
          '${pdfDisplayRect.left},${pdfDisplayRect.top} ${pdfDisplayRect.width}x${pdfDisplayRect.height}',
      'scribbleCanvasSize':
          '${scribbleCanvasSize.width}x${scribbleCanvasSize.height}',
      'scaleFactor': scaleFactor,
      'scrollOffset': '${scrollOffset.dx},${scrollOffset.dy}',
      'rotationAngle': '${rotationAngle * 180 / math.pi}°',
      'isDoublePage': isDoublePage,
      'isLeftPage': isLeftPage,
      'scaleRatioX': scribbleCanvasSize.width / pdfOriginalSize.width,
      'scaleRatioY': scribbleCanvasSize.height / pdfOriginalSize.height,
    };
  }

  /// 회전 변환 적용 (내부 헬퍼 메서드)
  Offset _applyRotation(Offset point, double angle) {
    if (angle == 0.0) return point;

    final cos = math.cos(angle);
    final sin = math.sin(angle);

    // 중심점 (0.5, 0.5) 기준 회전
    final centeredX = point.dx - 0.5;
    final centeredY = point.dy - 0.5;

    final rotatedX = centeredX * cos - centeredY * sin;
    final rotatedY = centeredX * sin + centeredY * cos;

    return Offset(rotatedX + 0.5, rotatedY + 0.5);
  }

  @override
  String toString() {
    return 'ScribbleCoordinateConverter('
        'pdfSize: ${pdfOriginalSize.width}x${pdfOriginalSize.height}, '
        'canvasSize: ${scribbleCanvasSize.width}x${scribbleCanvasSize.height}, '
        'scale: $scaleFactor, '
        'doublePage: $isDoublePage)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ScribbleCoordinateConverter &&
        other.pdfOriginalSize == pdfOriginalSize &&
        other.pdfDisplayRect == pdfDisplayRect &&
        other.scribbleCanvasSize == scribbleCanvasSize &&
        other.scaleFactor == scaleFactor &&
        other.scrollOffset == scrollOffset &&
        other.rotationAngle == rotationAngle &&
        other.isDoublePage == isDoublePage &&
        other.isLeftPage == isLeftPage;
  }

  @override
  int get hashCode {
    return Object.hash(
      pdfOriginalSize,
      pdfDisplayRect,
      scribbleCanvasSize,
      scaleFactor,
      scrollOffset,
      rotationAngle,
      isDoublePage,
      isLeftPage,
    );
  }
}

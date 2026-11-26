import 'dart:ui';

import 'package:open_note/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_note/src/note/style/note_line_style.dart';
import 'package:open_note/src/note/style/note_line_style_kind.dart';
import 'package:open_note/src/note/style/note_shape_geometry.dart';
import 'package:open_note/src/note/style/note_shape_kind.dart';
import 'package:open_note/src/note/style/note_shape_style.dart';
import 'package:open_note/src/note/style/note_styled_stroke_painter.dart';

/// open_note: 스트로크의 선 스타일 · 도형 스타일 해석. 화면 페인터, 내보내기,
/// 지우개가 같은 해석을 쓰도록 한 곳에 둔다.
abstract final class StrokeStyles {
  /// 엔진 도형 페인터가 원래 그리던 2점 도형 — 스타일이 없으면 종전대로 그린다.
  static const Set<NoteShapeKind> _engineNative = {
    NoteShapeKind.line,
    NoteShapeKind.rectangle,
    NoteShapeKind.ellipse,
  };

  /// 닫지 않는 자동 인식 도형.
  static const Set<String> _openShapeTypes = {
    'line',
    'polyline',
    'arrow',
    'doubleArrow',
    'connector',
  };

  /// 실선이 아닌 선 스타일. 없으면 null.
  static NoteLineStyle? lineStyleOf(Stroke stroke) {
    if (stroke.lineStyle.isEmpty) return null;
    final style = NoteLineStyle.decode(stroke.lineStyle);

    return style.kind == NoteLineStyleKind.solid ? null : style;
  }

  /// 도형 스타일. 없으면 null.
  static NoteShapeStyle? shapeStyleOf(Stroke stroke) =>
      stroke.shapeStyle.isEmpty
      ? null
      : NoteShapeStyle.decode(stroke.shapeStyle);

  /// `Stroke.shapeType` 문자열에 해당하는 노트 도형 종류.
  static NoteShapeKind? kindOfShapeType(String shapeType) =>
      switch (shapeType) {
        'square' => NoteShapeKind.rectangle,
        'circle' => NoteShapeKind.ellipse,
        'equilateralTriangle' || 'isoscelesTriangle' => NoteShapeKind.triangle,
        _ => NoteShapeKind.values.asNameMap()[shapeType],
      };

  /// 두 점(드래그의 대각선)으로 정의한 도형이면 그 종류.
  static NoteShapeKind? twoPointShapeOf(Stroke stroke) {
    if (stroke.points.length != 2 || stroke.segments.isNotEmpty) return null;

    return kindOfShapeType(stroke.shapeType);
  }

  /// 2점 도형의 사각형. 화살표 방향이 유지되도록 첫 점 → 둘째 점이며
  /// 정규화하지 않는다.
  static Rect shapeRectOf(Stroke stroke) {
    final first = stroke.points.first;
    final last = stroke.points.last;

    return Rect.fromLTRB(first.x, first.y, last.x, last.y);
  }

  /// 노트 도형 렌더러가 그려야 하는 2점 도형과 그 스타일. 엔진이 원래 그리던
  /// 도형(선 · 사각형 · 타원)은 스타일이 있을 때만 해당한다.
  static ({NoteShapeKind kind, NoteShapeStyle style})? noteShapeOf(
    Stroke stroke,
  ) {
    final kind = twoPointShapeOf(stroke);
    if (kind == null) return null;
    final shapeStyle = shapeStyleOf(stroke);
    final lineStyle = lineStyleOf(stroke);
    if (_engineNative.contains(kind) &&
        shapeStyle == null &&
        lineStyle == null) {
      return null;
    }
    var style = shapeStyle ?? NoteShapeStyle.plain;
    if (lineStyle != null && style.lineStyle.kind == NoteLineStyleKind.solid) {
      style = style.copyWith(lineStyle: lineStyle);
    }

    return (kind: kind, style: style);
  }

  /// 노트 도형의 외곽 · 내부 모서리를 폴리라인들로 (지우개 판정 · 벡터
  /// 내보내기용). 닫힌 윤곽은 첫 점을 한 번 더 담는다.
  static List<List<Offset>> noteShapeContours(
    Stroke stroke,
    NoteShapeKind kind,
  ) {
    final style = shapeStyleOf(stroke) ?? NoteShapeStyle.plain;
    final drawing = NoteShapeGeometry.drawingFor(
      kind,
      shapeRectOf(stroke),
      cornerRadius: style.cornerRadius,
      headStyle: style.headStyle,
      containHeads: false,
    );

    return [
      for (final part in [
        drawing.outline,
        drawing.inner,
        drawing.hidden,
        drawing.heads,
      ])
        if (part != null)
          for (final contour in part.contours)
            contour.closed && contour.points.isNotEmpty
                ? [...contour.points, contour.points.first]
                : contour.points,
    ];
  }

  /// 여러 점으로 인식된 도형의 외곽 폴리라인(닫힌 도형이면 첫 점 반복).
  static List<Offset> recognizedOutlineOf(Stroke stroke) {
    final points = [
      for (final point in stroke.points) Offset(point.x, point.y),
    ];
    if (points.length > 2 &&
        !_openShapeTypes.contains(stroke.shapeType) &&
        points.first != points.last) {
      points.add(points.first);
    }

    return points;
  }

  /// 선 스타일이 있으면 [width] 두께의 [color] 로 중심선을 장식해 그리고
  /// true. 없으면 아무것도 하지 않는다.
  static bool paintStyledLine(
    Canvas canvas,
    Stroke stroke,
    Color color,
    double width,
  ) {
    final style = lineStyleOf(stroke);
    if (style == null) return false;
    NoteStyledStrokePainter.paint(
      canvas,
      [for (final point in stroke.points) Offset(point.x, point.y)],
      color,
      width,
      style,
    );

    return true;
  }
}

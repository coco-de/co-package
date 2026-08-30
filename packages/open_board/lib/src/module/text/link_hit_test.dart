import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_board/src/module/state/text_settings.dart';
import 'package:open_board/src/module/text/text_drawable_extensions.dart';
import 'package:open_board/src/module/text/text_span_builder.dart';

/// Touch padding (canvas px) added around a text box when resolving link taps,
/// mirroring `TextInteractionManager` selection hit-testing.
const double _kLinkTouchPadding = 8;

/// Returns the topmost [TextLinkSpan] hit by [canvasPoint] across [drawables]
/// (in canvas coordinates), or `null` when no link is under the point.
///
/// Iterates back-to-front so the visually top-most text wins, matching the
/// renderer's draw order. Only text drawables that actually carry link spans
/// are considered.
TextLinkSpan? findLinkAtCanvasPoint(
  List<TextDrawable> drawables,
  Offset canvasPoint,
) {
  for (var i = drawables.length - 1; i >= 0; i--) {
    final drawable = drawables[i];
    if (drawable.hidden) continue;
    if (drawable.linkSpans.isEmpty) continue;
    final link = _linkInDrawable(drawable, canvasPoint);
    if (link != null) return link;
  }
  return null;
}

TextLinkSpan? _linkInDrawable(TextDrawable drawable, Offset canvasPoint) {
  final textPainter = TextPainter(
    text: buildLinkAwareTextSpan(drawable),
    textAlign: drawable.alignment.textAlign,
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: drawable.layoutMaxWidth);

  final width = textPainter.width;
  final height = textPainter.height;

  final local = _toLocalOffset(drawable, canvasPoint, width, height);
  if (local == null) return null;

  final clamped = Offset(
    local.dx.clamp(0.0, width),
    local.dy.clamp(0.0, height),
  );
  final offset = textPainter.getPositionForOffset(clamped).offset;

  // 캐럿 경계(글자 사이) 보정: offset 과 그 직전 글자를 모두 검사.
  return linkSpanAtOffset(drawable, offset) ??
      (offset > 0 ? linkSpanAtOffset(drawable, offset - 1) : null);
}

/// Maps [canvasPoint] to a coordinate relative to the text's top-left, or
/// `null` if the point is outside the (padded) text box. Mirrors the geometry
/// in `TextInteractionManager._isPointInTextBounds` (alignment + rotation).
Offset? _toLocalOffset(
  TextDrawable drawable,
  Offset canvasPoint,
  double width,
  double height,
) {
  final rotation = drawable.rotation;
  final position = drawable.position;

  if (rotation == 0.0) {
    final Offset topLeft;
    switch (drawable.alignment) {
      case TextAlignment.center:
        topLeft = Offset(position.dx - width / 2, position.dy - height / 2);
      case TextAlignment.right:
        topLeft = Offset(position.dx - width, position.dy - height / 2);
      case TextAlignment.left:
        topLeft = Offset(position.dx, position.dy - height / 2);
    }
    final local = canvasPoint - topLeft;
    if (local.dx < -_kLinkTouchPadding ||
        local.dy < -_kLinkTouchPadding ||
        local.dx > width + _kLinkTouchPadding ||
        local.dy > height + _kLinkTouchPadding) {
      return null;
    }
    return local;
  }

  // 회전된 텍스트: 중심 기준 역회전 후 top-left 기준 좌표로 변환.
  final halfWidth = width / 2;
  final halfHeight = height / 2;
  final relative = canvasPoint - position;
  final cos = math.cos(-rotation);
  final sin = math.sin(-rotation);
  final rotated = Offset(
    relative.dx * cos - relative.dy * sin,
    relative.dx * sin + relative.dy * cos,
  );
  if (rotated.dx < -halfWidth - _kLinkTouchPadding ||
      rotated.dy < -halfHeight - _kLinkTouchPadding ||
      rotated.dx > halfWidth + _kLinkTouchPadding ||
      rotated.dy > halfHeight + _kLinkTouchPadding) {
    return null;
  }
  return Offset(rotated.dx + halfWidth, rotated.dy + halfHeight);
}

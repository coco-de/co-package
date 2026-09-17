import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:open_board/src/core/utils/geometry_utils.dart';
import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';

class ScribbleCoordinateConverter {
  const ScribbleCoordinateConverter._();

  static const double defaultPaddingFraction = 0.08;
  static const double _minPaddedExtent = 64;

  static List<Point> collectPoints(Iterable<Stroke> strokes) {
    final points = <Point>[];
    for (final stroke in strokes) {
      points.addAll(stroke.points);
    }
    return points;
  }

  static ({Offset center, Rect bounds, double scale}) fitHandwriting({
    required Iterable<Stroke> strokes,
    required Size viewportSize,
    double paddingFraction = defaultPaddingFraction,
  }) {
    final points = collectPoints(strokes);
    if (points.isEmpty || viewportSize.width <= 0 || viewportSize.height <= 0) {
      return (
        center: Offset(viewportSize.width / 2, viewportSize.height / 2),
        bounds: Rect.zero,
        scale: 1,
      );
    }

    final centroid = GeometryUtils.calculateCentroid(points);
    final center = Offset(centroid.x, centroid.y);
    final padded = _paddedBounds(
      GeometryUtils.calculateBoundingBox(points),
      center,
      paddingFraction,
    );
    final scale = math.min(
      viewportSize.width / padded.width,
      viewportSize.height / padded.height,
    );

    return (
      center: center,
      bounds: padded,
      scale: scale.isFinite && scale > 0 ? scale : 1,
    );
  }

  static Matrix4 fitHandwritingToViewport({
    required Iterable<Stroke> strokes,
    required Size contentLogicalSize,
    required Size viewportSize,
    double paddingFraction = defaultPaddingFraction,
    double minScale = 1,
    double maxScale = double.infinity,
  }) {
    if (contentLogicalSize.width <= 0 ||
        contentLogicalSize.height <= 0 ||
        viewportSize.width <= 0 ||
        viewportSize.height <= 0) {
      return Matrix4.identity();
    }

    final fit = fitHandwriting(
      strokes: strokes,
      viewportSize: viewportSize,
      paddingFraction: paddingFraction,
    );
    if (fit.bounds == Rect.zero) {
      return Matrix4.identity();
    }

    final widthScale = viewportSize.width / contentLogicalSize.width;
    final heightScale = viewportSize.height / contentLogicalSize.height;
    var pageFitScale = math.min(widthScale, heightScale);
    if (!pageFitScale.isFinite || pageFitScale <= 0) {
      pageFitScale = 0.001;
    }
    final displaySize = Size(
      contentLogicalSize.width * pageFitScale,
      contentLogicalSize.height * pageFitScale,
    );
    final letterbox = Offset(
      math.max((viewportSize.width - displaySize.width) / 2, 0),
      math.max((viewportSize.height - displaySize.height) / 2, 0),
    );

    final handwritingScale = math.min(
      viewportSize.width / fit.bounds.width,
      viewportSize.height / fit.bounds.height,
    );
    var interactiveScale = handwritingScale / pageFitScale;
    if (!interactiveScale.isFinite || interactiveScale <= 0) {
      interactiveScale = minScale;
    }
    interactiveScale = interactiveScale.clamp(minScale, maxScale);

    final displayCenter = Offset(
      fit.center.dx * pageFitScale + letterbox.dx,
      fit.center.dy * pageFitScale + letterbox.dy,
    );
    final translation = Offset(
      viewportSize.width / 2 - interactiveScale * displayCenter.dx,
      viewportSize.height / 2 - interactiveScale * displayCenter.dy,
    );

    return Matrix4.identity()
      ..setEntry(0, 0, interactiveScale)
      ..setEntry(1, 1, interactiveScale)
      ..setEntry(0, 3, translation.dx)
      ..setEntry(1, 3, translation.dy);
  }

  static Rect _paddedBounds(
    Rect bounds,
    Offset center,
    double paddingFraction,
  ) {
    var box = bounds;
    if (box.width < 1 && box.height < 1) {
      box = Rect.fromCenter(
        center: center,
        width: _minPaddedExtent,
        height: _minPaddedExtent,
      );
    }
    final pad = paddingFraction * math.max(box.width, box.height);
    final padded = box.inflate(pad);
    if (padded.width < _minPaddedExtent || padded.height < _minPaddedExtent) {
      return Rect.fromCenter(
        center: padded.center,
        width: math.max(padded.width, _minPaddedExtent),
        height: math.max(padded.height, _minPaddedExtent),
      );
    }
    return padded;
  }
}

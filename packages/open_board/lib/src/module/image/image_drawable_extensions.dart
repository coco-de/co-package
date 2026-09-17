import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';

/// Geometry / mutation helpers for [ImageDrawable].
///
/// Mirrors the convenience surface of `TextDrawableExtensions` so the
/// transform handler and interaction managers can treat both drawable kinds
/// uniformly.
extension ImageDrawableExtensions on ImageDrawable {
  /// Top-left offset of the drawable bounding box.
  Offset get position => Offset(x, y);

  /// Rendered bounding box size.
  Size get size => Size(width, height);

  /// Geometric centre of the bounding box.
  Offset get center => Offset(x + width / 2, y + height / 2);

  /// Whether [point] (canvas/local coordinates) falls within this
  /// drawable's rotated bounding box.
  ///
  /// [ImageDrawableLayer] renders the image via `Transform.rotate` around
  /// [center], so a straight `Rect.contains` check on the axis-aligned box
  /// is wrong once [rotation] != 0. Other tools (e.g. the lasso tool) use
  /// this to detect "the touch lands on an existing image" before falling
  /// back to their own gesture handling.
  bool containsPoint(Offset point) {
    final centerPoint = center;
    final dx = point.dx - centerPoint.dx;
    final dy = point.dy - centerPoint.dy;
    final cosA = math.cos(-rotation);
    final sinA = math.sin(-rotation);
    final localX = dx * cosA - dy * sinA;
    final localY = dx * sinA + dy * cosA;
    return localX.abs() <= width / 2 && localY.abs() <= height / 2;
  }

  /// Returns the natural aspect ratio (`naturalWidth / naturalHeight`), or
  /// `null` when either natural dimension is missing.
  double? get aspectRatio {
    if (naturalWidth <= 0 || naturalHeight <= 0) return null;
    return naturalWidth / naturalHeight;
  }

  ImageDrawable copyWithPosition(Offset newPosition) {
    return ImageDrawable()
      ..mergeFromMessage(this)
      ..x = newPosition.dx
      ..y = newPosition.dy
      ..updatedAt = DateTime.now().toIso8601String();
  }

  ImageDrawable copyWithSize(Size newSize) {
    return ImageDrawable()
      ..mergeFromMessage(this)
      ..width = newSize.width
      ..height = newSize.height
      ..updatedAt = DateTime.now().toIso8601String();
  }

  ImageDrawable copyWithRotation(double newRotation) {
    return ImageDrawable()
      ..mergeFromMessage(this)
      ..rotation = newRotation
      ..updatedAt = DateTime.now().toIso8601String();
  }

  ImageDrawable copyWithOpacity(double newOpacity) {
    return ImageDrawable()
      ..mergeFromMessage(this)
      ..opacity = newOpacity.clamp(0.0, 1.0)
      ..updatedAt = DateTime.now().toIso8601String();
  }

  ImageDrawable copyWithHidden(bool isHidden) {
    return ImageDrawable()
      ..mergeFromMessage(this)
      ..hidden = isHidden
      ..updatedAt = DateTime.now().toIso8601String();
  }

  ImageDrawable copyWithSource(String newSource) {
    return ImageDrawable()
      ..mergeFromMessage(this)
      ..source = newSource
      ..updatedAt = DateTime.now().toIso8601String();
  }
}

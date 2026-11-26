import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Pure zoom and pan arithmetic for a page or canvas shown in a viewport.
///
/// A view matrix maps content (page) coordinates to viewport coordinates, the
/// convention of a `TransformationController`: `viewport = matrix * content`.
/// The matrices built here are a uniform scale (set on all three axes, as
/// `InteractiveViewer` expects) plus a translation. Degenerate input (empty
/// content or viewport, non-finite numbers) yields the identity or an
/// unchanged copy instead of throwing.
abstract final class NoteZoomMath {
  /// Smallest zoom factor offered by default.
  static const double minZoom = 0.25;

  /// Largest zoom factor offered by default.
  static const double maxZoom = 8;

  /// [zoom] clamped into `[min, max]`; a non-finite value becomes [min].
  static double clampZoom(
    double zoom, {
    double min = minZoom,
    double max = maxZoom,
  }) => zoom.isFinite ? zoom.clamp(min, max) : min;

  /// The matrix `viewport = content * scale + translation`.
  static Matrix4 matrix(double scale, [Offset translation = Offset.zero]) =>
      Matrix4.identity()
        ..setEntry(0, 0, scale)
        ..setEntry(1, 1, scale)
        ..setEntry(2, 2, scale)
        ..setEntry(0, 3, translation.dx)
        ..setEntry(1, 3, translation.dy);

  /// The zoom factor of [matrix] (the length of its transformed x axis).
  static double scaleOf(Matrix4 matrix) {
    final x = matrix.entry(0, 0);
    final y = matrix.entry(1, 0);

    return math.sqrt(x * x + y * y);
  }

  /// The translation of [matrix]: where the content origin lands.
  static Offset translationOf(Matrix4 matrix) =>
      Offset(matrix.entry(0, 3), matrix.entry(1, 3));

  /// Maps a content point into the viewport.
  static Offset toViewport(Matrix4 matrix, Offset contentPoint) =>
      MatrixUtils.transformPoint(matrix, contentPoint);

  /// Maps a viewport point back into content coordinates
  /// ([Offset.zero] for a matrix that cannot be inverted).
  static Offset toContent(Matrix4 matrix, Offset viewportPoint) {
    final inverse = Matrix4.tryInvert(matrix);

    return inverse == null
        ? Offset.zero
        : MatrixUtils.transformPoint(inverse, viewportPoint);
  }

  /// The zoom at which [content] is as wide as the viewport minus [padding] on
  /// both sides, clamped to `[min, max]` (1 for degenerate input).
  static double fitWidthScale(
    Rect content,
    Size viewport, {
    double padding = 0,
    double min = minZoom,
    double max = maxZoom,
  }) {
    final width = viewport.width - 2 * padding;
    if (!_isUsable(content, viewport) || width <= 0) return 1;

    return clampZoom(width / content.width, min: min, max: max);
  }

  /// The zoom at which all of [content] fits in the viewport minus [padding]
  /// on every side, clamped to `[min, max]` (1 for degenerate input).
  static double fitPageScale(
    Rect content,
    Size viewport, {
    double padding = 0,
    double min = minZoom,
    double max = maxZoom,
  }) {
    final width = viewport.width - 2 * padding;
    final height = viewport.height - 2 * padding;
    if (!_isUsable(content, viewport) || width <= 0 || height <= 0) return 1;

    return clampZoom(
      math.min(width / content.width, height / content.height),
      min: min,
      max: max,
    );
  }

  /// Fits the width of [content] (see [fitWidthScale]) and centres it
  /// horizontally. Vertically it is centred when it fits, and otherwise starts
  /// at the top, [padding] below the viewport edge.
  static Matrix4 fitWidth(
    Rect content,
    Size viewport, {
    double padding = 0,
    double min = minZoom,
    double max = maxZoom,
  }) {
    if (!_isUsable(content, viewport) || viewport.width <= 2 * padding) {
      return Matrix4.identity();
    }
    final scale = fitWidthScale(
      content,
      viewport,
      padding: padding,
      min: min,
      max: max,
    );
    final height = content.height * scale;
    final top = height <= viewport.height - 2 * padding
        ? (viewport.height - height) / 2
        : padding;

    return matrix(
      scale,
      Offset(
        (viewport.width - content.width * scale) / 2 - content.left * scale,
        top - content.top * scale,
      ),
    );
  }

  /// Shows all of [content], centred (see [fitPageScale]).
  static Matrix4 fitPage(
    Rect content,
    Size viewport, {
    double padding = 0,
    double min = minZoom,
    double max = maxZoom,
  }) {
    if (!_isUsable(content, viewport) || viewport.shortestSide <= 2 * padding) {
      return Matrix4.identity();
    }
    final scale = fitPageScale(
      content,
      viewport,
      padding: padding,
      min: min,
      max: max,
    );

    return centerOn(content, viewport, scale);
  }

  /// The matrix with zoom [scale] that puts the centre of [content] in the
  /// middle of [viewport]. [scale] is used as given (clamp it with
  /// [clampZoom] if needed); a non-finite or non-positive one counts as 1.
  static Matrix4 centerOn(Rect content, Size viewport, double scale) {
    final zoom = scale.isFinite && scale > 0 ? scale : 1.0;
    final center = content.center;
    if (!center.dx.isFinite || !center.dy.isFinite || viewport.isEmpty) {
      return Matrix4.identity();
    }

    return matrix(zoom, viewport.center(Offset.zero) - center * zoom);
  }

  /// [matrix] zoomed to the absolute factor [scale] (clamped to
  /// `[min, max]`) while the content under the viewport point [focal] stays
  /// there. Use [scaleAround] for a relative factor.
  static Matrix4 zoomAround(
    Matrix4 matrix,
    Offset focal,
    double scale, {
    double min = minZoom,
    double max = maxZoom,
  }) {
    final current = scaleOf(matrix);
    if (!(current > 0) || !scale.isFinite || scale <= 0) return matrix.clone();
    final target = scale.clamp(min, max);
    final factor = target / current;
    final zoom = Matrix4.identity()
      ..setEntry(0, 0, factor)
      ..setEntry(1, 1, factor)
      ..setEntry(0, 3, focal.dx * (1 - factor))
      ..setEntry(1, 3, focal.dy * (1 - factor));

    return zoom.multiplied(matrix)..setEntry(2, 2, target);
  }

  /// [matrix] with its zoom multiplied by [factor] around [focal]; the result
  /// is clamped to `[min, max]` like [zoomAround].
  static Matrix4 scaleAround(
    Matrix4 matrix,
    Offset focal,
    double factor, {
    double min = minZoom,
    double max = maxZoom,
  }) => zoomAround(matrix, focal, scaleOf(matrix) * factor, min: min, max: max);

  static bool _isUsable(Rect content, Size viewport) =>
      content.width.isFinite &&
      content.height.isFinite &&
      content.width > 0 &&
      content.height > 0 &&
      viewport.width.isFinite &&
      viewport.height.isFinite &&
      !viewport.isEmpty;
}

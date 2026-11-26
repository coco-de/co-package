import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:open_note/src/note/core/core.dart';

/// The size of an endless page that grows as ink gets close to its edges.
///
/// Immutable and pure. Canvas coordinates start at the top-left (0, 0) and stay
/// non-negative: growing to the left or up moves the origin, so existing ink
/// must be translated by [NoteCanvasGrowth.shift].
///
/// JSON: `{size: {w, h}, content?: {x, y, w, h}, growthStep, margin}`.
@immutable
class NoteInfiniteCanvas {
  /// A canvas of [size]; [growthStep] must be positive and [margin] must not be
  /// negative.
  const NoteInfiniteCanvas({
    this.size = defaultSize,
    this.contentBounds,
    this.growthStep = defaultGrowthStep,
    this.margin = defaultMargin,
  }) : assert(growthStep > 0, 'growthStep must be positive'),
       assert(margin >= 0, 'margin must not be negative');

  /// Reads [toJson]. Never throws: bad values get the defaults and
  /// `growthStep` is clamped to 1–[maxGrowthStep], `margin` to
  /// 0–[maxGrowthStep].
  factory NoteInfiniteCanvas.fromJson(Object? value) {
    final map = NoteJson.asMap(value) ?? <String, Object?>{};
    final size = NoteJson.map(map, 'size');
    final width = NoteJson.number(size, 'w');
    final height = NoteJson.number(size, 'h');
    // An unreadable rect comes back as the negative-size sentinel.
    final content = NoteJson.rect(
      map,
      'content',
      const Rect.fromLTRB(0, 0, -1, -1),
    );
    final hasContent = content.width >= 0 && content.height >= 0;

    return NoteInfiniteCanvas(
      size: width > 0 && height > 0 ? Size(width, height) : defaultSize,
      contentBounds: hasContent ? content : null,
      growthStep: NoteJson.number(
        map,
        'growthStep',
        defaultGrowthStep,
      ).clamp(1, maxGrowthStep),
      margin: NoteJson.number(
        map,
        'margin',
        defaultMargin,
      ).clamp(0, maxGrowthStep),
    );
  }

  /// Size of a new canvas, in page units.
  static const Size defaultSize = Size(2000, 2000);

  /// Default [growthStep].
  static const double defaultGrowthStep = 500;

  /// Default [margin].
  static const double defaultMargin = 200;

  /// Upper bound [NoteInfiniteCanvas.fromJson] accepts.
  static const double maxGrowthStep = 100000;

  /// Current size in page units.
  final Size size;

  /// Union of the ink and object rectangles seen so far, in canvas
  /// coordinates; `null` while the canvas is empty.
  final Rect? contentBounds;

  /// The canvas grows in whole multiples of this on each side.
  final double growthStep;

  /// Free space kept between new content and every edge.
  final double margin;

  /// Whether nothing was ever added.
  bool get isEmpty => contentBounds == null;

  /// Centre of [contentBounds] — the target of "move to content".
  Offset? get contentCenter => contentBounds?.center;

  /// Records new content at [strokeBounds] and grows the canvas so at least
  /// [margin] stays free around it. Each side that needs room grows by the
  /// smallest whole number of [growthStep]s. A rectangle with a non-finite
  /// edge changes nothing.
  NoteCanvasGrowth ensureRoom(Rect strokeBounds) {
    if (!_isFinite(strokeBounds)) {
      return NoteCanvasGrowth(size: size, shift: Offset.zero, canvas: this);
    }
    final added = Rect.fromPoints(
      strokeBounds.topLeft,
      strokeBounds.bottomRight,
    );
    final left = _steps(margin - added.left);
    final top = _steps(margin - added.top);
    final right = _steps(added.right + margin - size.width);
    final bottom = _steps(added.bottom + margin - size.height);
    final shift = Offset(left, top);
    final grown = Size(size.width + left + right, size.height + top + bottom);
    final moved = added.shift(shift);
    final content = contentBounds?.shift(shift).expandToInclude(moved) ?? moved;

    return NoteCanvasGrowth(
      size: grown,
      shift: shift,
      grew: grown != size,
      canvas: NoteInfiniteCanvas(
        size: grown,
        contentBounds: content,
        growthStep: growthStep,
        margin: margin,
      ),
    );
  }

  /// A copy whose [contentBounds] is the union of [items] (use after erasing).
  /// The size never shrinks; non-finite items are skipped.
  NoteInfiniteCanvas withContent(Iterable<Rect> items) {
    Rect? bounds;
    for (final item in items.where(_isFinite)) {
      bounds = bounds?.expandToInclude(item) ?? item;
    }

    return NoteInfiniteCanvas(
      size: size,
      contentBounds: bounds,
      growthStep: growthStep,
      margin: margin,
    );
  }

  /// The item of [items] closest to [from] (0 distance when [from] is inside;
  /// ties go to the first) — where "move to content" should go. Without items
  /// the answer is [contentBounds].
  Rect? nearestContent(Offset from, {Iterable<Rect> items = const []}) {
    Rect? nearest;
    var best = double.infinity;
    for (final item in items.where(_isFinite)) {
      final distance = _distanceSquared(item, from);
      if (distance < best) {
        best = distance;
        nearest = item;
      }
    }

    return nearest ?? contentBounds;
  }

  /// Whether any content shows inside [visible] (in canvas coordinates), to
  /// decide whether to offer "move to content".
  bool isContentVisible(Rect visible) =>
      contentBounds != null && visible.overlaps(contentBounds!.inflate(0.5));

  /// A copy with the given fields replaced.
  NoteInfiniteCanvas copyWith({
    Size? size,
    Rect? contentBounds,
    double? growthStep,
    double? margin,
  }) => NoteInfiniteCanvas(
    size: size ?? this.size,
    contentBounds: contentBounds ?? this.contentBounds,
    growthStep: growthStep ?? this.growthStep,
    margin: margin ?? this.margin,
  );

  /// The persisted form (see the class comment).
  JsonMap toJson() => {
    'size': {'w': size.width, 'h': size.height},
    if (contentBounds != null) 'content': NoteJson.rectToJson(contentBounds!),
    'growthStep': growthStep,
    'margin': margin,
  };

  static bool _isFinite(Rect rect) =>
      rect.left.isFinite &&
      rect.top.isFinite &&
      rect.right.isFinite &&
      rect.bottom.isFinite;

  static double _distanceSquared(Rect rect, Offset point) {
    final dx = math.max(
      math.max(rect.left - point.dx, point.dx - rect.right),
      0.0,
    );
    final dy = math.max(
      math.max(rect.top - point.dy, point.dy - rect.bottom),
      0.0,
    );

    return dx * dx + dy * dy;
  }

  /// The growth that covers a shortfall of [deficit] page units.
  double _steps(double deficit) => deficit <= 0
      ? 0
      : math.max((deficit / growthStep - 1e-9).ceil(), 0) * growthStep;

  @override
  bool operator ==(Object other) =>
      other is NoteInfiniteCanvas &&
      other.size == size &&
      other.contentBounds == contentBounds &&
      other.growthStep == growthStep &&
      other.margin == margin;

  @override
  int get hashCode => Object.hash(size, contentBounds, growthStep, margin);

  @override
  String toString() => 'NoteInfiniteCanvas($size, content: $contentBounds)';
}

/// The result of [NoteInfiniteCanvas.ensureRoom].
@immutable
class NoteCanvasGrowth {
  /// Created by [NoteInfiniteCanvas.ensureRoom].
  const NoteCanvasGrowth({
    required this.size,
    required this.shift,
    required this.canvas,
    this.grew = false,
  });

  /// The canvas size after growing.
  final Size size;

  /// How far existing content must move (non-zero only when the canvas grew to
  /// the left or up). Add it to every stroke, object and viewport position.
  final Offset shift;

  /// The updated canvas, with the new content included.
  final NoteInfiniteCanvas canvas;

  /// Whether the canvas got bigger.
  final bool grew;

  @override
  bool operator ==(Object other) =>
      other is NoteCanvasGrowth &&
      other.size == size &&
      other.shift == shift &&
      other.canvas == canvas &&
      other.grew == grew;

  @override
  int get hashCode => Object.hash(size, shift, canvas, grew);

  @override
  String toString() => 'NoteCanvasGrowth($size, shift: $shift)';
}

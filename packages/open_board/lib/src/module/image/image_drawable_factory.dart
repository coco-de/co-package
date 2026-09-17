import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_board/src/module/adapters/image_picker_adapter.dart';

/// Factory for [ImageDrawable] protobuf instances.
class ImageDrawableFactory {
  const ImageDrawableFactory._();

  /// Default rendered size when the picker does not report natural dimensions.
  static const Size defaultSize = Size(200, 200);

  /// Default maximum rendered size for picked images.
  ///
  /// 일반 스마트폰 사진(예: 4032x3024px)을 자연 해상도 그대로 삽입하면
  /// 수백 pt 페이지를 덮는 초대형 드로어블이 생성되고 좌표가 캔버스 밖
  /// 큰 음수가 되므로, 비율을 유지한 채 이 크기 이내로 축소한다.
  static const Size defaultMaxSize = Size(400, 400);

  /// Build an [ImageDrawable] from a [PickedImage] and an insertion centre.
  ///
  /// The rendered box is centred on [center]. If the picked image reports
  /// natural dimensions they are preserved on the resulting drawable so callers
  /// can resize while keeping aspect ratio. The rendered box is clamped to
  /// [maxSize] (aspect-ratio preserving) unless an explicit [size] is given.
  static ImageDrawable fromPickedImage({
    required String id,
    required PickedImage picked,
    required Offset center,
    Size? size,
    Size maxSize = defaultMaxSize,
  }) {
    final box = _resolveBox(picked, size, maxSize);
    final now = DateTime.now().toIso8601String();
    return ImageDrawable(
      id: id,
      source: picked.source,
      x: center.dx - box.width / 2,
      y: center.dy - box.height / 2,
      width: box.width,
      height: box.height,
      rotation: 0,
      opacity: 1,
      hidden: false,
      createdAt: now,
      updatedAt: now,
      naturalWidth: picked.naturalWidth,
      naturalHeight: picked.naturalHeight,
    );
  }

  /// Build an [ImageDrawable] directly from a `source` identifier. Convenience
  /// for callers that already know the geometry (e.g. paste / drag-and-drop).
  static ImageDrawable create({
    required String id,
    required String source,
    required Offset position,
    required Size size,
    double rotation = 0,
    double opacity = 1,
    double naturalWidth = 0,
    double naturalHeight = 0,
  }) {
    final now = DateTime.now().toIso8601String();
    final safeSize = _sanitizeSize(size) ?? defaultSize;
    return ImageDrawable(
      id: id,
      source: source,
      x: position.dx.isFinite ? position.dx : 0,
      y: position.dy.isFinite ? position.dy : 0,
      width: safeSize.width,
      height: safeSize.height,
      rotation: rotation.isFinite ? rotation : 0,
      opacity: opacity.isFinite ? opacity.clamp(0.0, 1.0) : 1,
      hidden: false,
      createdAt: now,
      updatedAt: now,
      naturalWidth: naturalWidth.isFinite && naturalWidth > 0
          ? naturalWidth
          : 0,
      naturalHeight: naturalHeight.isFinite && naturalHeight > 0
          ? naturalHeight
          : 0,
    );
  }

  static Size _resolveBox(PickedImage picked, Size? override, Size maxSize) {
    final explicit = _sanitizeSize(override);
    if (explicit != null) return explicit;

    final natural = _sanitizeSize(
      Size(picked.naturalWidth, picked.naturalHeight),
    );
    if (natural == null) return defaultSize;

    // 비율 유지 축소 (maxSize 이내면 그대로)
    final scale = math.min(
      maxSize.width / natural.width,
      maxSize.height / natural.height,
    );
    if (scale >= 1.0) return natural;
    return Size(natural.width * scale, natural.height * scale);
  }

  /// 음수/0/NaN/무한대 크기를 걸러낸다.
  static Size? _sanitizeSize(Size? size) {
    if (size == null) return null;
    if (!size.width.isFinite || !size.height.isFinite) return null;
    if (size.width <= 0 || size.height <= 0) return null;
    return size;
  }
}

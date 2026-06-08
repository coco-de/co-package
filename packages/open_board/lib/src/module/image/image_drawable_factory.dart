import 'package:flutter/widgets.dart';
import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_board/src/module/adapters/image_picker_adapter.dart';

/// Factory for [ImageDrawable] protobuf instances.
class ImageDrawableFactory {
  const ImageDrawableFactory._();

  /// Default rendered size when the picker does not report natural dimensions.
  static const Size defaultSize = Size(200, 200);

  /// Build an [ImageDrawable] from a [PickedImage] and an insertion centre.
  ///
  /// The rendered box is centred on [center]. If the picked image reports
  /// natural dimensions they are preserved on the resulting drawable so callers
  /// can resize while keeping aspect ratio.
  static ImageDrawable fromPickedImage({
    required String id,
    required PickedImage picked,
    required Offset center,
    Size? size,
  }) {
    final box = _resolveBox(picked, size);
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
    return ImageDrawable(
      id: id,
      source: source,
      x: position.dx,
      y: position.dy,
      width: size.width,
      height: size.height,
      rotation: rotation,
      opacity: opacity,
      hidden: false,
      createdAt: now,
      updatedAt: now,
      naturalWidth: naturalWidth,
      naturalHeight: naturalHeight,
    );
  }

  static Size _resolveBox(PickedImage picked, Size? override) {
    if (override != null) return override;
    if (picked.naturalWidth > 0 && picked.naturalHeight > 0) {
      return Size(picked.naturalWidth, picked.naturalHeight);
    }
    return defaultSize;
  }
}

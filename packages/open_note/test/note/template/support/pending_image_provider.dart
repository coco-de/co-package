import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// An image provider whose picture arrives when the test says so.
class PendingImageProvider extends ImageProvider<PendingImageProvider> {
  final Completer<ImageInfo> completer = Completer<ImageInfo>();

  @override
  Future<PendingImageProvider> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
    PendingImageProvider key,
    ImageDecoderCallback decode,
  ) => OneFrameImageStreamCompleter(completer.future);
}

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/core/core.dart';

import '../../support/note_test_host.dart';

/// Hosts [child] in a [size]d box at the top-left corner, so local and global
/// coordinates are the same.
Widget boxed(Widget child, {Size size = const Size(200, 100)}) => noteTestHost(
  Align(
    alignment: Alignment.topLeft,
    child: SizedBox.fromSize(size: size, child: child),
  ),
);

/// A [size] x [size] picture of one [color].
ui.Image solidImage(Color color, {int size = 8}) {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawRect(
    Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
    Paint()..color = color,
  );

  return recorder.endRecording().toImageSync(size, size);
}

/// An image provider that delivers [image] immediately.
class ReadyImageProvider extends ImageProvider<ReadyImageProvider> {
  ReadyImageProvider(this.image);

  final ui.Image image;

  @override
  Future<ReadyImageProvider> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<ReadyImageProvider>(this);

  @override
  ImageStreamCompleter loadImage(
    ReadyImageProvider key,
    ImageDecoderCallback decode,
  ) => OneFrameImageStreamCompleter(
    SynchronousFuture<ImageInfo>(ImageInfo(image: image.clone())),
  );
}

/// Paints [object] alone on a transparent canvas and returns the straight
/// ARGB value of each pixel in [at].
Future<List<int>> pixelsOf(
  NoteObject object,
  List<Offset> at, {
  int width = 200,
  int height = 100,
  NoteObjectPaintContext context = NoteObjectPaintContext.empty,
}) async {
  final recorder = ui.PictureRecorder();
  object.paintToCanvas(Canvas(recorder), context);
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  final bytes = (await image.toByteData(
    format: ui.ImageByteFormat.rawStraightRgba,
  ))!;
  image.dispose();
  picture.dispose();

  return [
    for (final point in at)
      _argb(bytes.getUint32((point.dy.toInt() * width + point.dx.toInt()) * 4)),
  ];
}

int _argb(int rgba) => ((rgba & 0xFF) << 24) | (rgba >>> 8);

import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:open_note/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_note/src/note/core/core.dart';

/// A 16 x 8 solid red JPEG (made once with `sips`).
final Uint8List redJpeg16x8 = base64Decode(
  '/9j/4AAQSkZJRgABAQAASABIAAD/4QBMRXhpZgAATU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAA'
  'A6ABAAMAAAABAAEAAKACAAQAAAABAAAAEKADAAQAAAABAAAACAAAAAD/7QA4UGhvdG9zaG9wIDMu'
  'MAA4QklNBAQAAAAAAAA4QklNBCUAAAAAABDUHYzZjwCyBOmACZjs+EJ+/8AAEQgACAAQAwEiAAIR'
  'AQMRAf/EAB8AAAEFAQEBAQEBAAAAAAAAAAABAgMEBQYHCAkKC//EALUQAAIBAwMCBAMFBQQEAAAB'
  'fQECAwAEEQUSITFBBhNRYQcicRQygZGhCCNCscEVUtHwJDNicoIJChYXGBkaJSYnKCkqNDU2Nzg5'
  'OkNERUZHSElKU1RVVldYWVpjZGVmZ2hpanN0dXZ3eHl6g4SFhoeIiYqSk5SVlpeYmZqio6Slpqeo'
  'qaqys7S1tre4ubrCw8TFxsfIycrS09TV1tfY2drh4uPk5ebn6Onq8fLz9PX29/j5+v/EAB8BAAMB'
  'AQEBAQEBAQEAAAAAAAABAgMEBQYHCAkKC//EALURAAIBAgQEAwQHBQQEAAECdwABAgMRBAUhMQYS'
  'QVEHYXETIjKBCBRCkaGxwQkjM1LwFWJy0QoWJDThJfEXGBkaJicoKSo1Njc4OTpDREVGR0hJSlNU'
  'VVZXWFlaY2RlZmdoaWpzdHV2d3h5eoKDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5'
  'usLDxMXGx8jJytLT1NXW19jZ2uLj5OXm5+jp6vLz9PX29/j5+v/bAEMABAQEBAQEBgQEBgkGBgYJ'
  'DAkJCQkMDwwMDAwMDxIPDw8PDw8SEhISEhISEhUVFRUVFRkZGRkZHBwcHBwcHBwcHP/bAEMBBAUF'
  'BwcHDAcHDB0UEBQdHR0dHR0dHR0dHR0dHR0dHR0dHR0dHR0dHR0dHR0dHR0dHR0dHR0dHR0dHR0d'
  'HR0dHf/dAAQAAf/aAAwDAQACEQMRAD8A8vooor4k/qA//9k=',
);

/// A point list from `[x, y]` or `[x, y, pressure]` triples.
List<Point> testPoints(List<List<num>> coordinates) => [
  for (final c in coordinates)
    Point(
      x: c[0].toDouble(),
      y: c[1].toDouble(),
      p: c.length > 2 ? c[2].toDouble() : 0.5,
    ),
];

/// A wavy hand-like stroke of [count] points starting at [origin].
List<Point> wavePoints({
  ui.Offset origin = const ui.Offset(20, 60),
  int count = 24,
  double step = 6,
}) => [
  for (var i = 0; i < count; i++)
    Point(
      x: origin.dx + i * step,
      y: origin.dy + 18 * math.sin(i / 3),
      p: 0.3 + 0.4 * ((i % 5) / 4),
    ),
];

/// A completed engine stroke with the engine's usual options.
Stroke testStroke({
  String ink = 'pen',
  List<Point>? points,
  int color = 0xFF000000,
  double size = 4,
  String shapeType = '',
  double thinning = 0.5,
  bool simulatePressure = true,
  bool isComplete = true,
  List<Segment> segments = const [],
}) => Stroke(
  ink: ink,
  color: color,
  shapeType: shapeType,
  segments: segments,
  points: points ?? wavePoints(),
  options: StrokeOptions(
    size: size,
    thinning: thinning,
    smoothing: 0.5,
    streamline: 0.5,
    capStart: true,
    capEnd: true,
    simulatePressure: simulatePressure,
    isComplete: isComplete,
  ),
);

/// A solid image of [color].
Future<ui.Image> solidImage(int width, int height, ui.Color color) async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawRect(
    ui.Rect.fromLTWH(0, 0, width * 1.0, height * 1.0),
    ui.Paint()..color = color,
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  picture.dispose();

  return image;
}

/// A solid PNG of [color].
Future<Uint8List> solidPng(int width, int height, ui.Color color) async {
  final image = await solidImage(width, height, color);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();

  return data!.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
}

/// Decodes [png] bytes.
Future<ui.Image> decodeImage(Uint8List png) async {
  final codec = await ui.instantiateImageCodec(png);
  final frame = await codec.getNextFrame();
  codec.dispose();

  return frame.image;
}

/// Straight-alpha pixel at ([x], [y]) as an ARGB colour.
Future<ui.Color> pixelAt(ui.Image image, int x, int y) async {
  final data = await image.toByteData(
    format: ui.ImageByteFormat.rawStraightRgba,
  );
  final offset = (y * image.width + x) * 4;

  return ui.Color.fromARGB(
    data!.getUint8(offset + 3),
    data.getUint8(offset),
    data.getUint8(offset + 1),
    data.getUint8(offset + 2),
  );
}

/// A minimal object that fills its bounds, for object painting tests.
class BoxObject extends NoteObject {
  const BoxObject({
    required super.id,
    required super.bounds,
    this.color = const ui.Color(0xFF00FF00),
    super.rotation,
    super.opacity,
    super.locked,
  });

  final ui.Color color;

  @override
  String get kind => 'test.box';

  @override
  NoteObject withBase({
    ui.Rect? bounds,
    double? rotation,
    double? opacity,
    bool? locked,
  }) => BoxObject(
    id: id,
    bounds: bounds ?? this.bounds,
    color: color,
    rotation: rotation ?? this.rotation,
    opacity: opacity ?? this.opacity,
    locked: locked ?? this.locked,
  );

  @override
  JsonMap payloadToJson() => {'color': color.toARGB32()};

  @override
  void paintToCanvas(ui.Canvas canvas, NoteObjectPaintContext context) {
    // Leaves an extra save open on purpose: painting must restore it.
    canvas
      ..save()
      ..drawRect(bounds, ui.Paint()..color = color);
  }
}

import 'dart:typed_data';
import 'package:co_golden/src/design/geometry.dart';
import 'package:co_golden/src/design/image_raster_evidence.dart';
import 'package:co_golden/src/design/pixel_diff.dart';
import 'package:co_golden/src/design/render_node.dart';
import 'package:co_golden/src/design/spec.dart';
import 'package:co_golden/src/design/tolerance.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;

image.Image texture({bool noise = false, bool wrongTone = false}) {
  final result = image.Image(width: 20, height: 20, numChannels: 4);
  for (var y = 0; y < 20; y++) {
    for (var x = 0; x < 20; x++) {
      final c = wrongTone ? 180 : 50 + (x * 3 + y * 2) % 40;
      result.setPixelRgba(
        x,
        y,
        c + (noise && x == 10 && y == 10 ? 1 : 0),
        c + 10,
        c + 20,
        255,
      );
    }
  }
  return result;
}

GoldenImageRasterEvidence? evidence({
  Map<String, Object?> changes = const {},
  Uint8List? bytes,
  bool wrongDigest = false,
  bool wrongTone = false,
  double opacity = 1,
}) {
  final source = Uint8List.fromList(image.encodePng(texture()));
  final design = GoldenDesignSpec.parse({
    'schema': 'co_golden.design_spec',
    'schemaVersion': 1,
    'frame': {'id': 'f', 'width': 20, 'height': 20},
    'nodes': [
      {
        'id': 'photo',
        'type': 'RECTANGLE',
        'rect': [0, 0, 20, 20],
        'radius': [0, 0, 0, 0],
        'fills': [
          {
            'type': 'IMAGE',
            'imageFit': 'cover',
            'sourceDigest':
                'sha256:${wrongDigest ? '0' * 64 : sha256.convert(source)}',
          },
        ],
      },
    ],
  }).nodes.single;
  return GoldenImageRasterEvidence.compare(
    design: design,
    render: GoldenRenderNode(
      id: 0,
      kind: GoldenRenderKind.image,
      widget: 'Image',
      rect: const GoldenRect(0, 0, 20, 20),
      visibleRect: const GoldenRect(0, 0, 20, 20),
      opacity: opacity,
      imagePaint: {
        'fit': 'cover',
        'alignment': [0, 0],
        'clipRadius': [0, 0, 0, 0],
        'verifiedGeometry': true,
        'tinted': false,
        'mirrored': false,
        'repeat': 'noRepeat',
        'paintOpacity': 1,
        'decodedWidth': 20,
        'decodedHeight': 20,
        ...changes,
      },
    ),
    sourceBytes: bytes ?? source,
    reference: GoldenRgbImage.fromImage(texture()),
    actual: GoldenRgbImage.fromImage(
      texture(noise: true, wrongTone: wrongTone),
    ),
    logicalWidth: 20,
    tolerance: const GoldenDesignTolerance(),
  );
}

void main() {
  test(
    'identical source and verified paint can explain tiny texture sampling noise',
    () {
      expect(evidence(), isNotNull);
    },
  );
  test('a different asset or source digest never has sampling evidence', () {
    expect(evidence(wrongDigest: true), isNull);
    expect(
      evidence(
        bytes: Uint8List.fromList(image.encodePng(texture(wrongTone: true))),
      ),
      isNull,
    );
  });
  for (final change in [
    <String, Object?>{'fit': 'contain'},
    {
      'alignment': [.2, 0],
    },
    {
      'clipRadius': [4, 4, 4, 4],
    },
    {'tinted': true},
    {'verifiedGeometry': false},
    {'decodedWidth': 10},
    {'mirrored': true},
    {'paintOpacity': .5},
  ]) {
    test('unverified or different paint remains actionable: $change', () {
      expect(evidence(changes: change), isNull);
    });
  }
  test('a color or opacity change is not sampling evidence', () {
    expect(evidence(wrongTone: true), isNull);
    expect(evidence(opacity: .8), isNull);
  });
}

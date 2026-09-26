import 'dart:convert';
import 'dart:typed_data';

import 'package:co_golden_gallery/co_golden_gallery.dart';
import 'package:crypto/crypto.dart';
import 'package:test/test.dart';

void main() {
  GalleryFavicon named(String fileName) =>
      galleryFavicons.singleWhere((icon) => icon.fileName == fileName);

  test('ships the files cocode.im serves, byte for byte', () {
    // sha256 of https://cocode.im/favicon.svg, /favicon.ico, and
    // /apple-touch-icon.png (coco-de/cocode-home site/web/, commit 5f05629e).
    expect(
      {
        for (final icon in galleryFavicons)
          icon.fileName: sha256.convert(icon.bytes).toString(),
      },
      {
        'favicon.svg':
            '1da49c41fc9ec8eb5ee7023c6dd076324fda5fa15ddc7a9cbe810a99b8e84ed8',
        'favicon.ico':
            'fa0cfdf10f16e5776d86e2d1a4f758d45fa52b702c758e376789986f1f6ca6ba',
        'apple-touch-icon.png':
            '2c2bfe63b3a4cbb4195503f2c43054fb456d2add49a8104299f232cf93358801',
      },
    );
  });

  test('declares the size of the 32 px raster it links', () {
    expect(_pngSize(named('favicon.ico').bytes), (32, 32));
    expect(named('favicon.ico').link, contains('sizes="32x32"'));
    expect(_pngSize(named('apple-touch-icon.png').bytes), (180, 180));
  });

  test('draws the SVG mark in the browser theme', () {
    final svg = utf8.decode(named('favicon.svg').bytes);

    expect(svg, contains('path { fill: #111113; }'));
    expect(
      svg,
      contains(
        '@media (prefers-color-scheme: dark) { path { fill: #ffffff; } }',
      ),
    );
  });
}

/// Width and height from the IHDR chunk of a PNG file.
(int, int) _pngSize(Uint8List bytes) {
  expect(bytes.sublist(0, 8), [137, 80, 78, 71, 13, 10, 26, 10]);
  expect(ascii.decode(bytes.sublist(12, 16)), 'IHDR');
  final header = ByteData.sublistView(bytes);
  return (header.getUint32(16), header.getUint32(20));
}

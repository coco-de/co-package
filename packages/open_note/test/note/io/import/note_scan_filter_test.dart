import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/io/import/note_scan_filter.dart';

Uint8List _pixels(List<List<int>> rgba) =>
    Uint8List.fromList([for (final pixel in rgba) ...pixel]);

void main() {
  final input = _pixels([
    [255, 0, 0, 255],
    [0, 255, 0, 128],
    [0, 0, 255, 0],
    [255, 255, 255, 10],
    [0, 0, 0, 255],
  ]);

  test('none copies the pixels', () {
    final output = NoteScanFilter.none.apply(input);

    expect(output, input);
    expect(output, isNot(same(input)));
  });

  test('grayscale uses Rec. 601 weights and keeps alpha', () {
    expect(
      NoteScanFilter.grayscale.apply(input),
      _pixels([
        [76, 76, 76, 255],
        [149, 149, 149, 128],
        [29, 29, 29, 0],
        [255, 255, 255, 10],
        [0, 0, 0, 255],
      ]),
    );
  });

  test('black and white splits at the threshold', () {
    expect(
      NoteScanFilter.blackWhite(100).apply(input),
      _pixels([
        [0, 0, 0, 255],
        [255, 255, 255, 128],
        [0, 0, 0, 0],
        [255, 255, 255, 10],
        [0, 0, 0, 255],
      ]),
    );
    final grey = _pixels([
      [128, 128, 128, 255],
    ]);
    expect(NoteScanFilter.blackWhite(128).apply(grey).first, 255);
    expect(NoteScanFilter.blackWhite(129).apply(grey).first, 0);
  });

  test('the input is not modified', () {
    final copy = Uint8List.fromList(input);

    NoteScanFilter.blackWhite().apply(input);

    expect(input, copy);
  });

  test('rejects data that is not RGBA', () {
    expect(() => NoteScanFilter.none.apply(Uint8List(3)), throwsArgumentError);
    expect(NoteScanFilter.grayscale.apply(Uint8List(0)), isEmpty);
  });

  test('thresholds are clamped', () {
    expect(NoteScanFilter.blackWhite(-5).threshold, 0);
    expect(NoteScanFilter.blackWhite(999).threshold, 255);
    expect(NoteScanFilter.blackWhite().threshold, 128);
    expect(
      NoteScanFilter.blackWhite(0)
          .apply(
            _pixels([
              [0, 0, 0, 255],
            ]),
          )
          .first,
      255,
    );
  });

  test('round trips through JSON', () {
    for (final filter in [
      NoteScanFilter.none,
      NoteScanFilter.grayscale,
      NoteScanFilter.blackWhite(90),
    ]) {
      expect(NoteScanFilter.fromJson(filter.toJson()), filter);
      expect(
        NoteScanFilter.fromJson(filter.toJson()).hashCode,
        filter.hashCode,
      );
    }
    expect(NoteScanFilter.blackWhite(1), isNot(NoteScanFilter.blackWhite(2)));
    expect('${NoteScanFilter.blackWhite(7)}', 'NoteScanFilter.blackWhite(7)');
  });

  test('JSON is lenient', () {
    expect(NoteScanFilter.fromJson(null), NoteScanFilter.none);
    expect(NoteScanFilter.fromJson({'kind': 'sepia'}), NoteScanFilter.none);
    expect(
      NoteScanFilter.fromJson({'kind': 'blackWhite', 'threshold': 'x'}),
      NoteScanFilter.blackWhite(),
    );
    expect(
      NoteScanFilter.fromJson({'kind': 'blackWhite', 'threshold': 4000}),
      NoteScanFilter.blackWhite(255),
    );
  });
}

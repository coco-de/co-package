// Story: S1.10 — BookPositionCodec façade tests

import 'package:test/test.dart';
import 'package:open_epub_engine/src/api/epub_position.dart';
import 'package:open_epub_engine/src/data/codec/book_position_codec.dart';

void main() {
  const codec = BookPositionCodec();

  test('encode / decode Reflowable round-trip', () {
    const pos = EpubReflowablePosition(
      spineHref: 'ch01.xhtml',
      progress: 0.42,
      charOffset: 800,
    );
    final token = codec.encode(pos);
    expect(codec.decode(token), pos);
  });

  test('encode / decode Fixed round-trip', () {
    const pos = EpubFixedPosition(
      spineHref: 'p2.xhtml',
      progress: 0.66,
      pageIndex: 5,
    );
    final token = codec.encode(pos);
    expect(codec.decode(token), pos);
  });

  test('decode invalid token rethrows from EpubPosition.fromToken', () {
    expect(
      () => codec.decode('not-json'),
      throwsA(isA<EpubPositionDecodeException>()),
    );
  });
}

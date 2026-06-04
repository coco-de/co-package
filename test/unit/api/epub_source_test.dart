// Story: S1.20 (#36) — EpubSource tests (bytes/file)
// url 소스는 네트워크 의존이라 unit에서 제외(통합/E2E에서 검증).

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:open_epub/src/api/epub_source.dart';

void main() {
  group('EpubSource.bytes', () {
    test('readBytes는 원본 바이트를 그대로 반환', () async {
      final bytes = Uint8List.fromList([1, 2, 3, 4]);
      final src = EpubSource.bytes(bytes);
      expect(await src.readBytes(), bytes);
      expect(src.debugIdentifier, contains('bytes('));
    });
  });

  group('EpubSource.file', () {
    test('파일에서 바이트를 읽는다', () async {
      final dir = await Directory.systemTemp.createTemp('oe_src');
      addTearDown(() => dir.delete(recursive: true));
      final file = File('${dir.path}/book.epub');
      final data = Uint8List.fromList(List.generate(32, (i) => i));
      await file.writeAsBytes(data);

      final src = EpubSource.file(file.path);
      expect(await src.readBytes(), data);
      expect(src.debugIdentifier, contains('file('));
    });

    test('없는 파일은 EpubSourceException', () {
      final src = EpubSource.file('/no/such/path/x.epub');
      expect(src.readBytes(), throwsA(isA<EpubSourceException>()));
    });
  });
}

// Story: S9.1 (#65) — 압축 해제 캐시 LRU eviction 검증 (OOM 방지)

import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:test/test.dart';
import 'package:open_epub_engine/src/data/repository/archive_resource_reader.dart';

/// 실제 EpubRepositoryImpl 경로(ZipDecoder().decodeBytes)와 동일하게
/// 인코딩→디코딩을 거쳐, ArchiveFile.content가 지연 압축해제되는 실제
/// 경로(FileContent 기반)를 그대로 재현한다.
Archive _archiveWithFiles(Map<String, Uint8List> files) {
  final archive = Archive();
  files.forEach((name, bytes) {
    archive.addFile(ArchiveFile(name, bytes.length, bytes));
  });
  final zipped = ZipEncoder().encode(archive)!;
  return ZipDecoder().decodeBytes(Uint8List.fromList(zipped));
}

Uint8List _bytesOf(String marker, int size) {
  final content = (marker * (size ~/ marker.length + 1)).substring(0, size);
  return Uint8List.fromList(utf8.encode(content));
}

void main() {
  group('ArchiveResourceReader — LRU eviction (S9.1 #65)', () {
    test('상한을 넘으면 가장 오래전에 접근한 리소스부터 캐시가 해제된다', () {
      const chunkSize = 1024 * 1024; // 1MiB
      final archive = _archiveWithFiles({
        'a.bin': _bytesOf('A', chunkSize),
        'b.bin': _bytesOf('B', chunkSize),
        'c.bin': _bytesOf('C', chunkSize),
      });
      // 상한 1.5MiB → 2번째 리소스를 읽는 순간 1번째가 evict되어야 함.
      final reader = ArchiveResourceReader(
        archive,
        '',
        maxCachedBytes: (chunkSize * 1.5).round(),
      );

      reader.readBytes('a.bin');
      expect(reader.debugCachedEntryCount, 1);
      expect(reader.debugCachedBytes, chunkSize);

      reader.readBytes('b.bin');
      // a가 evict되어 b 하나만 남아야 함 (상한 유지).
      expect(reader.debugCachedEntryCount, 1);
      expect(reader.debugCachedBytes, chunkSize);

      reader.readBytes('c.bin');
      expect(reader.debugCachedEntryCount, 1);
      expect(reader.debugCachedBytes, lessThanOrEqualTo(chunkSize * 2));
    });

    test('많은 리소스를 순차로 읽어도 캐시가 상한을 넘지 않는다 (OOM 방지 핵심 시나리오)', () {
      const chunkSize = 512 * 1024; // 512KiB
      const maxBytes = 2 * 1024 * 1024; // 2MiB
      final files = <String, Uint8List>{
        for (var i = 0; i < 50; i++) 'img$i.bin': _bytesOf('img$i-', chunkSize),
      };
      final archive = _archiveWithFiles(files);
      final reader =
          ArchiveResourceReader(archive, '', maxCachedBytes: maxBytes);

      for (var i = 0; i < 50; i++) {
        reader.readBytes('img$i.bin');
        expect(
          reader.debugCachedBytes,
          lessThanOrEqualTo(maxBytes + chunkSize),
          reason: '$i번째 리소스를 읽은 후에도 캐시가 무한정 누적되면 안 된다',
        );
      }
    });

    test('evict된 리소스를 다시 읽으면 정확한 원본 바이트를 반환한다', () {
      const chunkSize = 1024 * 1024;
      final aBytes = _bytesOf('A', chunkSize);
      final bBytes = _bytesOf('B', chunkSize);
      final archive = _archiveWithFiles({'a.bin': aBytes, 'b.bin': bBytes});
      final reader = ArchiveResourceReader(
        archive,
        '',
        maxCachedBytes: (chunkSize * 1.5).round(),
      );

      final firstRead = reader.readBytes('a.bin');
      expect(firstRead, aBytes);

      reader.readBytes('b.bin'); // a를 evict시킴
      expect(reader.debugCachedEntryCount, 1);

      final reread = reader.readBytes('a.bin'); // 재압축해제
      expect(reread, aBytes, reason: 'evict 후 재읽기는 원본과 동일해야 한다');
    });

    test('상한 이내에서는 evict 없이 모두 캐시에 남는다', () {
      const chunkSize = 100 * 1024; // 100KiB
      final archive = _archiveWithFiles({
        'a.bin': _bytesOf('A', chunkSize),
        'b.bin': _bytesOf('B', chunkSize),
      });
      final reader = ArchiveResourceReader(archive, ''); // 기본 상한(32MiB)

      reader.readBytes('a.bin');
      reader.readBytes('b.bin');
      expect(reader.debugCachedEntryCount, 2);
      expect(reader.debugCachedBytes, chunkSize * 2);
    });

    test('디렉토리를 넘나드는 href도 evict 이후 정확히 재해석된다', () {
      const chunkSize = 1024 * 1024;
      final archive = _archiveWithFiles({
        'OEBPS/img/a.png': _bytesOf('A', chunkSize),
        'OEBPS/img/b.png': _bytesOf('B', chunkSize),
      });
      final reader = ArchiveResourceReader(
        archive,
        'OEBPS',
        maxCachedBytes: (chunkSize * 1.5).round(),
      );

      final aBytes = reader.readBytes('img/a.png');
      reader.readBytes('img/b.png');
      final reread = reader.readBytes('img/a.png');
      expect(reread, aBytes);
    });

    test('같은 리소스를 반복 읽어도 LRU 순서만 갱신되고 캐시가 중복 누적되지 않는다', () {
      const chunkSize = 1024 * 1024;
      final archive = _archiveWithFiles({
        'a.bin': _bytesOf('A', chunkSize),
        'b.bin': _bytesOf('B', chunkSize),
      });
      final reader = ArchiveResourceReader(archive, '');

      reader.readBytes('a.bin');
      reader.readBytes('a.bin');
      reader.readBytes('a.bin');
      expect(reader.debugCachedEntryCount, 1);
      expect(reader.debugCachedBytes, chunkSize);
    });
  });
}

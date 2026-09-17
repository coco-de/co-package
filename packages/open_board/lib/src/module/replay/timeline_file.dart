import 'dart:io';
import 'dart:typed_data';

import 'package:open_board/src/data/model/timeline/timeline_models.dart';
import 'package:open_board/src/data/model/timeline/timeline_serializer.dart';
import 'package:open_board/src/module/replay/timeline_migrator.dart';

/// .obt (Open Board Timeline) 파일 읽기/쓰기 유틸리티
///
/// 바이너리 구조:
/// ```
/// Offset  Size    Description
/// 0x00    4       Magic Bytes ("OBT\0")
/// 0x04    4       Format Version (uint32, little-endian)
/// 0x08    ~       Payload (TimelineSerializer)
/// ```
class TimelineFile {
  /// Magic bytes: "OBT\0"
  static const List<int> magicBytes = [0x4F, 0x42, 0x54, 0x00];

  /// 현재 포맷 버전
  static const int currentFormatVersion = 1;

  /// 헤더 크기 (magic 4B + version 4B)
  static const int headerSize = 8;

  const TimelineFile._();

  /// .obt 파일 저장
  static Future<void> write(String path, ScribbleTimeline timeline) async {
    final payload = TimelineSerializer.serialize(timeline);

    final buffer = BytesBuilder()
      ..add(magicBytes)
      ..add(_uint32ToBytes(currentFormatVersion))
      ..add(payload);

    await File(path).writeAsBytes(buffer.toBytes());
  }

  /// .obt 파일 로드
  ///
  /// Throws [FormatException] if magic bytes mismatch or unsupported version.
  static Future<ScribbleTimeline> read(String path) async {
    final bytes = await File(path).readAsBytes();

    _validateHeader(bytes);

    final formatVersion = _readUint32(bytes, 4);
    if (formatVersion > currentFormatVersion) {
      throw FormatException(
        'Unsupported .obt format version: $formatVersion '
        '(max supported: $currentFormatVersion)',
      );
    }

    final payload = Uint8List.sublistView(bytes, headerSize);
    final timeline = TimelineSerializer.deserialize(payload);

    if (formatVersion < currentFormatVersion) {
      return TimelineMigrator.migrate(timeline, from: formatVersion);
    }

    return timeline;
  }

  /// 포맷 버전만 빠르게 확인 (파일 전체 로드 없이)
  ///
  /// Returns -1 if invalid file.
  static Future<int> readFormatVersion(String path) async {
    final file = File(path);
    if (!await file.exists()) return -1;

    final raf = await file.open();
    try {
      final header = await raf.read(headerSize);
      if (header.length < headerSize) return -1;
      if (!_matchesMagic(header)) return -1;
      return _readUint32(header, 4);
    } finally {
      await raf.close();
    }
  }

  /// .obt 파일인지 빠르게 확인
  static Future<bool> isValidObtFile(String path) async {
    final version = await readFormatVersion(path);
    return version > 0 && version <= currentFormatVersion;
  }

  // ===== 내부 유틸 =====

  static void _validateHeader(Uint8List bytes) {
    if (bytes.length < headerSize) {
      throw const FormatException('Invalid .obt file: too short');
    }
    if (!_matchesMagic(bytes)) {
      throw const FormatException('Invalid .obt file: magic bytes mismatch');
    }
  }

  static bool _matchesMagic(List<int> bytes) {
    for (var i = 0; i < magicBytes.length; i++) {
      if (bytes[i] != magicBytes[i]) return false;
    }
    return true;
  }

  static Uint8List _uint32ToBytes(int value) {
    final data = ByteData(4)..setUint32(0, value, .little);
    return data.buffer.asUint8List();
  }

  static int _readUint32(List<int> bytes, int offset) {
    return ByteData.sublistView(
      Uint8List.fromList(bytes),
    ).getUint32(offset, .little);
  }
}

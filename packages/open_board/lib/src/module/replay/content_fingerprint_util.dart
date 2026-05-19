import 'dart:convert';

import 'package:open_board/src/data/model/timeline/timeline_models.dart';

/// 콘텐츠 핑거프린트 생성/검증 유틸리티
///
/// .obt 파일이 어떤 콘텐츠에 속하는지 SHA-256 해시로 식별하고,
/// 재생 시 현재 콘텐츠와 매칭되는지 검증한다.
class ContentFingerprintUtil {
  const ContentFingerprintUtil._();

  /// 콘텐츠 핑거프린트 생성
  ///
  /// SHA-256(contentId + pageIds + 각 page.bin 크기)
  /// → 동일 콘텐츠 + 동일 페이지 구성이면 같은 해시
  static ContentFingerprint generate({
    required String contentId,
    required List<String> pageIds,
    required Map<String, int> pageBinSizes,
    Map<String, String> metadata = const {},
  }) {
    final input = StringBuffer()
      ..write(contentId)
      ..write('|')
      ..write(pageIds.join(','))
      ..write('|')
      ..write(pageIds.map((id) => pageBinSizes[id] ?? 0).join(','));

    // dart:convert의 sha256는 crypto 패키지 필요 → 간단한 해시 사용
    // 실제 SHA-256은 앱에서 crypto 패키지로 구현 가능
    final hash = _simpleHash(input.toString());

    return ContentFingerprint(
      hash: hash,
      algorithm: 'fnv1a',
      metadata: metadata,
    );
  }

  /// 현재 콘텐츠와 .obt의 핑거프린트 매칭 검증
  ///
  /// Returns null if 일치, 에러 메시지 if 불일치
  static String? verify({
    required ContentFingerprint expected,
    required String contentId,
    required List<String> pageIds,
    required Map<String, int> pageBinSizes,
  }) {
    final current = generate(
      contentId: contentId,
      pageIds: pageIds,
      pageBinSizes: pageBinSizes,
    );

    if (current.hash != expected.hash) {
      return 'Content fingerprint mismatch: '
          'expected=${expected.hash.substring(0, 8)}... '
          'actual=${current.hash.substring(0, 8)}...';
    }
    return null;
  }

  /// FNV-1a 32-bit 해시 (Web/JavaScript 호환)
  ///
  /// 간단한 내장 해시. 앱 레벨에서 SHA-256으로 대체 가능.
  static String _simpleHash(String input) {
    final bytes = utf8.encode(input);
    var hash = 0x811c9dc5; // FNV offset basis (32-bit)
    for (final byte in bytes) {
      hash ^= byte;
      hash = (hash * 0x01000193) & 0xFFFFFFFF; // FNV prime (32-bit)
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }
}

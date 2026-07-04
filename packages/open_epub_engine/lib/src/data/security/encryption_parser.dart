// Data Security — open_epub 1.0
// Story: S13.5 (#102) — encryption.xml 파싱 + IDPF/Adobe 폰트 난독화 해제 (gap #8)
//
// META-INF/encryption.xml은 W3C XML Encryption 형식이다. EPUB에서 흔한 용도는
// (1) IDPF/Adobe 폰트 난독화(무키, XOR — 해제 가능) (2) 상업 DRM(ADEPT/LCP/AES —
// 스코프 밖). 전자는 [FontObfuscation]으로 투명 해제하고, 후자는 호출측이
// EpubEncryptedUnsupported로 매핑한다.

import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:xml/xml.dart';

/// encryption.xml의 한 `<EncryptedData>` 항목.
class EpubEncryptionEntry {
  const EpubEncryptionEntry({required this.uri, required this.algorithm});

  /// `<CipherReference URI>` — ZIP 루트 기준 경로.
  final String uri;

  /// `<EncryptionMethod Algorithm>` URI.
  final String algorithm;

  /// IDPF/Adobe 폰트 난독화(무키 XOR)인지 — 그러면 투명 해제 가능.
  bool get isFontObfuscation => FontObfuscation.isObfuscation(algorithm);
}

/// META-INF/encryption.xml 파서.
class EncryptionParser {
  const EncryptionParser();

  static const String _encNs = 'http://www.w3.org/2001/04/xmlenc#';

  /// encryption.xml에서 암호화 항목을 추출한다. XML이 유효하지 않으면 빈 리스트.
  List<EpubEncryptionEntry> parse(String encryptionXml) {
    final XmlDocument doc;
    try {
      doc = XmlDocument.parse(encryptionXml);
    } on XmlException {
      return const [];
    }
    final result = <EpubEncryptionEntry>[];
    for (final data in doc.findAllElements('EncryptedData', namespace: _encNs)) {
      final method =
          data.findElements('EncryptionMethod', namespace: _encNs).firstOrNull;
      final algorithm = method?.getAttribute('Algorithm');
      final cipherRef = data
          .findAllElements('CipherReference', namespace: _encNs)
          .firstOrNull;
      final uri = cipherRef?.getAttribute('URI');
      if (algorithm == null || uri == null || uri.isEmpty) continue;
      result.add(EpubEncryptionEntry(uri: _decodeUri(uri), algorithm: algorithm));
    }
    return result;
  }

  /// CipherReference URI는 퍼센트 인코딩될 수 있다(공백 등).
  String _decodeUri(String uri) {
    try {
      return Uri.decodeFull(uri);
    } on Object {
      return uri;
    }
  }
}

/// IDPF/Adobe 폰트 난독화(무키 대칭 XOR) 해제 유틸리티.
///
/// 두 방식 모두 책의 unique-identifier에서 키를 유도해 리소스 앞부분을 XOR한다.
/// XOR은 대칭이라 난독화==해제(round-trip).
class FontObfuscation {
  /// IDPF OCF 폰트 난독화 알고리즘 URI.
  static const String idpf = 'http://www.idpf.org/2008/embedding';

  /// Adobe 폰트 난독화 알고리즘 URI.
  static const String adobe = 'http://ns.adobe.com/pdf/enc#RC';

  static bool isObfuscation(String algorithm) =>
      algorithm == idpf || algorithm == adobe;

  /// [algorithm]에 맞춰 [data]의 난독화를 해제한다(대칭이라 난독화와 동일 연산).
  /// [identifier]는 OPF의 unique-identifier(dc:identifier). 미지원 알고리즘이면
  /// [data]를 그대로 반환(호출측이 별도 처리).
  static Uint8List deobfuscate({
    required Uint8List data,
    required String algorithm,
    required String identifier,
  }) {
    switch (algorithm) {
      case idpf:
        return _xorPrefix(data, _idpfKey(identifier), 1040);
      case adobe:
        return _xorPrefix(data, _adobeKey(identifier), 1024);
      default:
        return data;
    }
  }

  /// IDPF 키 = 공백 제거한 identifier의 SHA-1(20 bytes).
  static List<int> _idpfKey(String identifier) {
    final stripped = identifier.replaceAll(RegExp(r'\s'), '');
    return sha1.convert(stripped.codeUnits).bytes;
  }

  /// Adobe 키 = identifier에서 "urn:uuid:"·하이픈 제거 후 hex 디코드(16 bytes).
  static List<int> _adobeKey(String identifier) {
    var hex = identifier.trim();
    final idx = hex.lastIndexOf(':');
    if (idx >= 0) hex = hex.substring(idx + 1);
    hex = hex.replaceAll('-', '');
    final bytes = <int>[];
    for (var i = 0; i + 1 < hex.length && bytes.length < 16; i += 2) {
      final b = int.tryParse(hex.substring(i, i + 2), radix: 16);
      if (b == null) break;
      bytes.add(b);
    }
    return bytes;
  }

  static Uint8List _xorPrefix(Uint8List data, List<int> key, int prefixLen) {
    if (key.isEmpty) return data;
    final out = Uint8List.fromList(data);
    final n = data.length < prefixLen ? data.length : prefixLen;
    for (var i = 0; i < n; i++) {
      out[i] = data[i] ^ key[i % key.length];
    }
    return out;
  }
}

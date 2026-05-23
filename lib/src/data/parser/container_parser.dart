// Data Parser — open_epub 1.0
// Status: SCAFFOLD STUB. Implementation deferred to Story S1.1, S1.24.
// BDD: F1.1 (container.xml → OPF path), Edge-security (zip slip)

class ContainerParser {
  /// META-INF/container.xml에서 OPF 파일 경로 추출.
  /// path normalization으로 zip slip 차단.
  String parse(String containerXml) {
    throw UnimplementedError('S1.1');
  }

  /// 경로 안전 확인. `../` escape 시 false 반환.
  bool isSafePath(String path) {
    throw UnimplementedError('S1.24');
  }
}

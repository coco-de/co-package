// Data Parser — open_epub 1.0
// Story: S1.1 (#7) — OPF 파서 + container.xml
// BDD: F1.1 (책 열기), Edge-security (zip slip)

import 'package:xml/xml.dart';

import '../../domain/entity/epub_rendition.dart';

/// EPUB 표준의 META-INF/container.xml을 파싱하여 OPF 패키지 파일의 경로를
/// 추출한다.
///
/// 표준 구조:
/// ```xml
/// <container xmlns="urn:oasis:names:tc:opendocument:xmlns:container"
///            version="1.0">
///   <rootfiles>
///     <rootfile full-path="OEBPS/content.opf"
///               media-type="application/oebps-package+xml"/>
///   </rootfiles>
/// </container>
/// ```
class ContainerParser {
  const ContainerParser();

  static const String _containerNs =
      'urn:oasis:names:tc:opendocument:xmlns:container';
  static const String _opfMediaType = 'application/oebps-package+xml';
  static const String _renditionNs =
      'http://www.idpf.org/2013/rendition';

  /// container.xml 문자열에서 OPF 파일의 ZIP 내부 경로를 반환한다.
  ///
  /// 여러 rootfile이 정의된 경우 OPF media-type을 가진 첫 항목을 선택한다.
  /// rootfile이 없거나 OPF 형식이 아니면 [ContainerParseException]을 던진다.
  /// full-path가 ZIP 외부로 escape하는 경로(`../`)면 [ZipSlipException]을 던진다.
  String parse(String containerXml) {
    final XmlDocument doc;
    try {
      doc = XmlDocument.parse(containerXml);
    } on XmlException catch (e) {
      throw ContainerParseException('container.xml is not valid XML: $e');
    }

    final rootfiles = doc.findAllElements('rootfile', namespace: _containerNs);
    final rootfile = rootfiles.firstWhere(
      (e) => e.getAttribute('media-type') == _opfMediaType,
      orElse: () => rootfiles.isEmpty
          ? throw ContainerParseException(
              'container.xml has no <rootfile> elements',
            )
          : rootfiles.first,
    );

    final fullPath = rootfile.getAttribute('full-path');
    if (fullPath == null || fullPath.isEmpty) {
      throw ContainerParseException('rootfile has empty full-path');
    }

    if (!isSafePath(fullPath)) {
      throw ZipSlipException(fullPath);
    }

    return fullPath;
  }

  /// container.xml의 모든 `<rootfile>`(복수 rendition)을 안전 경로만 골라
  /// 반환한다. OPF media-type을 가진 첫 항목이 default(=[parse] 반환값)로
  /// 표시된다. rootfile이 없으면 빈 리스트. (S13.4, gap #7)
  List<EpubRendition> parseRootfiles(String containerXml) {
    final XmlDocument doc;
    try {
      doc = XmlDocument.parse(containerXml);
    } on XmlException {
      return const [];
    }
    final rootfiles =
        doc.findAllElements('rootfile', namespace: _containerNs).toList();
    if (rootfiles.isEmpty) return const [];

    // default = OPF media-type을 가진 첫 안전-경로 rootfile.
    String? defaultPath;
    for (final rf in rootfiles) {
      final path = rf.getAttribute('full-path');
      if (rf.getAttribute('media-type') == _opfMediaType &&
          path != null &&
          path.isNotEmpty &&
          isSafePath(path)) {
        defaultPath = path;
        break;
      }
    }

    final result = <EpubRendition>[];
    for (final rf in rootfiles) {
      final path = rf.getAttribute('full-path');
      final mediaType = rf.getAttribute('media-type');
      if (path == null || path.isEmpty || mediaType == null) continue;
      if (!isSafePath(path)) continue; // zip slip rootfile은 제외
      result.add(EpubRendition(
        fullPath: path,
        mediaType: mediaType,
        label: rf.getAttribute('label', namespace: _renditionNs)?.trim(),
        isDefault: path == defaultPath,
      ));
    }
    return result;
  }

  /// ZIP 내부 경로 안전성 검사.
  ///
  /// 다음 케이스를 거부한다:
  /// - 절대 경로 (`/...` 또는 Windows drive `C:\...`)
  /// - 부모 디렉토리 escape (`..`)
  /// - 빈 경로
  /// - URL 스킴 포함 (`file://`, `http://`)
  bool isSafePath(String path) {
    if (path.isEmpty) return false;
    if (path.startsWith('/') || path.startsWith(r'\')) return false;
    if (path.contains('://')) return false;
    if (RegExp(r'^[A-Za-z]:[\\/]').hasMatch(path)) return false;
    final segments = path.replaceAll(r'\', '/').split('/');
    for (final s in segments) {
      if (s == '..') return false;
    }
    return true;
  }
}

class ContainerParseException implements Exception {
  ContainerParseException(this.message);
  final String message;
  @override
  String toString() => 'ContainerParseException: $message';
}

class ZipSlipException implements Exception {
  ZipSlipException(this.path);
  final String path;
  @override
  String toString() =>
      'ZipSlipException: path "$path" escapes ZIP root (security violation)';
}

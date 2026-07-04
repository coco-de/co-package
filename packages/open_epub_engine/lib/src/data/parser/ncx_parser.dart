// Data Parser — open_epub 1.0
// Story: S1.2 (#8) — NCX 파서 (EPUB 2)
// BDD: F4 (목차)
//
// EPUB 2.0의 NCX(`*.ncx`)를 파싱하여 [EpubOutline] 트리로 변환한다.
// EPUB 3.x의 nav.xhtml은 S1.3 (#9)에서 별도 처리.
//
// sparse-NCX 보정(누락 spine 자동 추가)은 S1.15 (#: sparse_ncx patch)
// 책임이므로 본 파서는 NCX 원문 구조만 충실히 반영한다.

import 'package:xml/xml.dart';

import '../../domain/entity/epub_outline.dart';

class NcxParser {
  const NcxParser();

  static const String _ncxNs = 'http://www.daisy.org/z3986/2005/ncx/';

  /// NCX XML에서 목차 트리를 추출한다.
  ///
  /// `<navMap>` 하위의 `<navPoint>`를 재귀 순회하여 [EpubOutlineItem]을
  /// 만든다. `<navPoint>`의 자식 `<navPoint>`는 `children`에 중첩된다.
  /// 순서는 문서 순서를 그대로 유지한다 (NCX `playOrder` 권장값과 일치하지
  /// 않는 EPUB에 대한 호환성).
  ///
  /// `<navMap>`이 비어 있으면 [EpubOutline.empty]를 반환한다 (empty-toc
  /// 보정은 S1.18 책임).
  EpubOutline parse(String ncxXml) {
    final XmlDocument doc;
    try {
      doc = XmlDocument.parse(ncxXml);
    } on XmlException catch (e) {
      throw NcxParseException('NCX is not valid XML: $e');
    }

    final root = doc.rootElement;
    if (root.localName != 'ncx' || root.namespaceUri != _ncxNs) {
      throw NcxParseException(
        'NCX root element must be <ncx> in namespace $_ncxNs '
        '(found <${root.qualifiedName}> in ${root.namespaceUri ?? "no namespace"})',
      );
    }

    final navMap = root.findElements('navMap', namespace: _ncxNs).firstOrNull;
    if (navMap == null) return EpubOutline.empty;

    final items = navMap
        .findElements('navPoint', namespace: _ncxNs)
        .map(_parseNavPoint)
        .whereType<EpubOutlineItem>()
        .toList(growable: false);

    return EpubOutline(items: items);
  }

  /// 단일 `<navPoint>`를 [EpubOutlineItem]으로 변환. 변환 불가능하면 null.
  EpubOutlineItem? _parseNavPoint(XmlElement navPoint) {
    final title = navPoint
        .findElements('navLabel', namespace: _ncxNs)
        .firstOrNull
        ?.findElements('text', namespace: _ncxNs)
        .firstOrNull
        ?.innerText
        .trim();
    final contentSrc = navPoint
        .findElements('content', namespace: _ncxNs)
        .firstOrNull
        ?.getAttribute('src');

    if (title == null || title.isEmpty || contentSrc == null) {
      return null; // 결측 항목은 진단 없이 skip — 호환성 보정 책임 분리
    }

    final children = navPoint
        .findElements('navPoint', namespace: _ncxNs)
        .map(_parseNavPoint)
        .whereType<EpubOutlineItem>()
        .toList(growable: false);

    return EpubOutlineItem(
      title: title,
      spineHref: _extractFilePart(contentSrc),
      children: children,
    );
  }

  /// `ch01.xhtml#fragment` → `ch01.xhtml`. fragment는 별도 처리되지 않으며
  /// 정확한 charOffset 매핑은 [ResolvePositionUseCase]가 spine 파싱 후 수행.
  String _extractFilePart(String src) {
    final hash = src.indexOf('#');
    return hash < 0 ? src : src.substring(0, hash);
  }
}

class NcxParseException implements Exception {
  NcxParseException(this.message);
  final String message;
  @override
  String toString() => 'NcxParseException: $message';
}

// Data Parser — open_epub 1.0
// Story: S1.3 (#9) — nav.xhtml 파서 (EPUB 3)
// BDD: F4 (목차)
//
// EPUB 3.x의 `nav.xhtml`을 파싱하여 [EpubOutline]으로 변환한다.
// 표준 구조 (단순화):
//
// <html xmlns="http://www.w3.org/1999/xhtml"
//       xmlns:epub="http://www.idpf.org/2007/ops">
//   <body>
//     <nav epub:type="toc">
//       <ol>
//         <li><a href="ch01.xhtml">1장</a>
//           <ol><li><a href="ch01.xhtml#sec1">1.1절</a></li></ol>
//         </li>
//       </ol>
//     </nav>
//   </body>
// </html>
//
// `epub:type="toc"`인 <nav>를 우선 선택하고, 없으면 첫 <nav>를 사용.
// EPUB 3 표준은 nav.xhtml이 well-formed XHTML이어야 하므로 xml 패키지로
// 파싱한다. (html 패키지는 정합성 낮은 HTML5 파싱용이라 본 케이스에는
// 과한 의존성)

import 'package:xml/xml.dart';

import '../../domain/entity/epub_outline.dart';

class NavParser {
  const NavParser();

  static const String _xhtmlNs = 'http://www.w3.org/1999/xhtml';
  static const String _epubOpsNs = 'http://www.idpf.org/2007/ops';

  /// nav.xhtml XML에서 toc 목차를 추출한다.
  ///
  /// `<nav epub:type="toc">`이 있으면 선택, 없으면 첫 `<nav>`를 사용한다.
  /// `<nav>`가 전혀 없거나 `<ol>`이 비어 있으면 [EpubOutline.empty] 반환
  /// (empty-toc 보정은 S1.18 영역).
  EpubOutline parse(String navXhtml) {
    final XmlDocument doc;
    try {
      doc = XmlDocument.parse(navXhtml);
    } on XmlException catch (e) {
      throw NavParseException('nav.xhtml is not valid XML: $e');
    }

    final root = doc.rootElement;
    if (root.localName != 'html' || root.namespaceUri != _xhtmlNs) {
      throw NavParseException(
        'nav.xhtml root must be <html> in XHTML namespace '
        '(found <${root.qualifiedName}> in ${root.namespaceUri ?? "no namespace"})',
      );
    }

    final tocNav = _findTocNav(root);
    if (tocNav == null) return EpubOutline.empty;

    final firstOl = tocNav.findElements('ol', namespace: _xhtmlNs).firstOrNull;
    if (firstOl == null) return EpubOutline.empty;

    return EpubOutline(items: _parseOl(firstOl));
  }

  /// epub:type="toc"인 nav를 우선 검색, 없으면 첫 nav. body 하위로 한정.
  XmlElement? _findTocNav(XmlElement htmlRoot) {
    final body = htmlRoot
        .findElements('body', namespace: _xhtmlNs)
        .firstOrNull;
    if (body == null) return null;

    final navs = body.findAllElements('nav', namespace: _xhtmlNs).toList();
    if (navs.isEmpty) return null;

    final tocNav = navs.firstWhere(
      (n) => n.getAttribute('type', namespace: _epubOpsNs) == 'toc',
      orElse: () => navs.first,
    );
    return tocNav;
  }

  List<EpubOutlineItem> _parseOl(XmlElement ol) {
    return ol
        .findElements('li', namespace: _xhtmlNs)
        .map(_parseLi)
        .whereType<EpubOutlineItem>()
        .toList(growable: false);
  }

  EpubOutlineItem? _parseLi(XmlElement li) {
    // 첫 <a> 또는 <span>(헤더용)을 찾는다. EPUB 3에서 a 또는 span이 표준.
    final anchor = li.findElements('a', namespace: _xhtmlNs).firstOrNull;
    final href = anchor?.getAttribute('href');
    final title = anchor?.innerText.trim();

    if (title == null || title.isEmpty || href == null || href.isEmpty) {
      return null;
    }

    final nestedOl = li.findElements('ol', namespace: _xhtmlNs).firstOrNull;
    final children = nestedOl == null ? const <EpubOutlineItem>[] : _parseOl(nestedOl);

    return EpubOutlineItem(
      title: title,
      spineHref: _extractFilePart(href),
      children: children,
    );
  }

  /// `ch01.xhtml#sec1` → `ch01.xhtml`. fragment는 ResolvePositionUseCase
  /// (S1.10+)에서 charOffset으로 변환된다.
  String _extractFilePart(String href) {
    final hash = href.indexOf('#');
    return hash < 0 ? href : href.substring(0, hash);
  }
}

class NavParseException implements Exception {
  NavParseException(this.message);
  final String message;
  @override
  String toString() => 'NavParseException: $message';
}

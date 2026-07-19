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

import '../../domain/entity/epub_navigation.dart';
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
  EpubOutline parse(String navXhtml) => parseDiagnosed(navXhtml).outline;

  /// [parse]와 동일하되, 정정한 구조 결함(비표준 epub:type, 불완전 항목 등)을
  /// 함께 보고한다. 결함이 있어도 최대한 목차를 복원한다. (S13.7, gap #10a)
  NavParseResult parseDiagnosed(String navXhtml) {
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

    final defects = <String>{};
    final tocNav = _findTocNav(root, defects);
    if (tocNav == null) {
      return NavParseResult(EpubOutline.empty, defects);
    }

    final firstOl =
        tocNav.findElements('ol', namespaceUri: _xhtmlNs).firstOrNull;
    if (firstOl == null) {
      return NavParseResult(EpubOutline.empty, defects);
    }

    return NavParseResult(
        EpubOutline(items: _parseOl(firstOl, defects)), defects);
  }

  /// nav.xhtml에서 보조 내비게이션(landmarks / page-list)을 추출한다. (S13.1)
  ///
  /// 각 nav는 `epub:type`으로 구분한다. 해당 nav가 없으면 빈 리스트.
  /// XML이 유효하지 않거나 `<html>` 루트가 아니면 [EpubNavigation.empty]
  /// (toc 파싱과 달리 예외를 던지지 않는다 — 보조 정보이므로 관대하게 처리).
  EpubNavigation parseNavigation(String navXhtml) {
    final XmlDocument doc;
    try {
      doc = XmlDocument.parse(navXhtml);
    } on XmlException {
      return EpubNavigation.empty;
    }
    final root = doc.rootElement;
    if (root.localName != 'html' || root.namespaceUri != _xhtmlNs) {
      return EpubNavigation.empty;
    }
    final body = root.findElements('body', namespaceUri: _xhtmlNs).firstOrNull;
    if (body == null) return EpubNavigation.empty;

    final navs = body.findAllElements('nav', namespaceUri: _xhtmlNs).toList();
    final landmarksNav = _navByType(navs, 'landmarks');
    final pageListNav = _navByType(navs, 'page-list');

    return EpubNavigation(
      landmarks:
          landmarksNav == null ? const [] : _parseLandmarks(landmarksNav),
      pageList: pageListNav == null ? const [] : _parsePageList(pageListNav),
    );
  }

  XmlElement? _navByType(List<XmlElement> navs, String type) {
    for (final n in navs) {
      if (n.getAttribute('type', namespaceUri: _epubOpsNs) == type) return n;
    }
    return null;
  }

  List<EpubLandmark> _parseLandmarks(XmlElement nav) {
    final ol = nav.findElements('ol', namespaceUri: _xhtmlNs).firstOrNull;
    if (ol == null) return const [];
    final result = <EpubLandmark>[];
    for (final li in ol.findElements('li', namespaceUri: _xhtmlNs)) {
      final anchor = li.findElements('a', namespaceUri: _xhtmlNs).firstOrNull;
      final href = anchor?.getAttribute('href');
      final title = anchor?.innerText.trim();
      // landmark의 epub:type은 <a>에 붙는다 (예: epub:type="bodymatter").
      final type =
          anchor?.getAttribute('type', namespaceUri: _epubOpsNs)?.trim();
      if (href == null || href.isEmpty || title == null || title.isEmpty) {
        continue;
      }
      result.add(EpubLandmark(type: type ?? '', title: title, href: href));
    }
    return result.isEmpty ? const [] : result;
  }

  List<EpubPageTarget> _parsePageList(XmlElement nav) {
    final ol = nav.findElements('ol', namespaceUri: _xhtmlNs).firstOrNull;
    if (ol == null) return const [];
    final result = <EpubPageTarget>[];
    for (final li in ol.findElements('li', namespaceUri: _xhtmlNs)) {
      final anchor = li.findElements('a', namespaceUri: _xhtmlNs).firstOrNull;
      final href = anchor?.getAttribute('href');
      final label = anchor?.innerText.trim();
      if (href == null || href.isEmpty || label == null || label.isEmpty) {
        continue;
      }
      result.add(EpubPageTarget(label: label, href: href));
    }
    return result.isEmpty ? const [] : result;
  }

  /// epub:type="toc"인 nav를 우선 검색, 없으면 첫 nav. body 하위로 한정.
  /// 정확한 `epub:type="toc"`가 없어 fallback했으면 [defects]에 기록. (S13.7)
  XmlElement? _findTocNav(XmlElement htmlRoot, Set<String> defects) {
    final body =
        htmlRoot.findElements('body', namespaceUri: _xhtmlNs).firstOrNull;
    if (body == null) return null;

    final navs = body.findAllElements('nav', namespaceUri: _xhtmlNs).toList();
    if (navs.isEmpty) return null;

    for (final n in navs) {
      if (n.getAttribute('type', namespaceUri: _epubOpsNs) == 'toc') return n;
    }
    // 정확한 toc 타입이 없음 → 첫 nav로 복원하되 결함 기록. (gap #10a)
    defects.add(NavParseResult.nonstandardTocType);
    return navs.first;
  }

  List<EpubOutlineItem> _parseOl(XmlElement ol, Set<String> defects) {
    return ol
        .findElements('li', namespaceUri: _xhtmlNs)
        .map((li) => _parseLi(li, defects))
        .whereType<EpubOutlineItem>()
        .toList(growable: false);
  }

  EpubOutlineItem? _parseLi(XmlElement li, Set<String> defects) {
    final anchor = li.findElements('a', namespaceUri: _xhtmlNs).firstOrNull;
    final href = anchor?.getAttribute('href');
    final title = anchor?.innerText.trim();
    final nestedOl = li.findElements('ol', namespaceUri: _xhtmlNs).firstOrNull;
    final children = nestedOl == null
        ? const <EpubOutlineItem>[]
        : _parseOl(nestedOl, defects);

    // 정상: 유효한 <a href>.
    if (title != null && title.isNotEmpty && href != null && href.isNotEmpty) {
      return EpubOutlineItem(
        title: title,
        spineHref: _extractFilePart(href),
        children: children,
      );
    }

    // 링크 없는 <span> 헤더 + 하위 목차 = 유효 EPUB3 섹션 그룹(현재 미지원 →
    // 복원). 제목은 span, spineHref는 첫 자식으로 대체(그룹 자체는 링크 없음).
    final span = li.findElements('span', namespaceUri: _xhtmlNs).firstOrNull;
    final spanTitle = span?.innerText.trim();
    if (spanTitle != null && spanTitle.isNotEmpty && children.isNotEmpty) {
      defects.add(NavParseResult.spanHeading);
      return EpubOutlineItem(
        title: spanTitle,
        spineHref: children.first.spineHref,
        children: children,
      );
    }

    // <a>가 있었으나 href/title 불완전한 결함 항목.
    if (anchor != null) {
      defects.add(NavParseResult.incompleteEntries);
    }
    return null;
  }

  /// `ch01.xhtml#sec1` → `ch01.xhtml`. fragment는 ResolvePositionUseCase
  /// (S1.10+)에서 charOffset으로 변환된다.
  String _extractFilePart(String href) {
    final hash = href.indexOf('#');
    return hash < 0 ? href : href.substring(0, hash);
  }
}

/// [NavParser.parseDiagnosed] 결과 — 복원된 목차 + 정정한 구조 결함 코드.
/// (S13.7, gap #10a). 결함 코드는 repository가 AppliedPatch로 기록한다.
class NavParseResult {
  const NavParseResult(this.outline, this.defects);

  final EpubOutline outline;

  /// 정정한 구조 결함(AppliedPatch id). 없으면 빈 집합.
  final Set<String> defects;

  /// 정확한 `epub:type="toc"`가 없어 첫 nav로 fallback했다.
  static const String nonstandardTocType = 'nav-nonstandard-toc-type';

  /// `<a>`가 있으나 href/title이 비어 항목을 건너뛰었다.
  static const String incompleteEntries = 'nav-incomplete-entries';

  /// 링크 없는 `<span>` 헤더 + 하위 목차를 섹션 그룹으로 복원했다.
  static const String spanHeading = 'nav-span-heading';
}

class NavParseException implements Exception {
  NavParseException(this.message);
  final String message;
  @override
  String toString() => 'NavParseException: $message';
}

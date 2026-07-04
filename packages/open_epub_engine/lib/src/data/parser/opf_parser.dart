// Data Parser — open_epub 1.0
// Story: S1.1 (#7) — OPF 파서 (initial)
// Story: S1.4 (#10) — rendition:layout / rendition:spread 메타 추출
// BDD: F1.1 (책 열기), F3 (Fixed Layout 감지)

import 'package:xml/xml.dart';

import '../../domain/entity/epub_capabilities.dart';
import '../../domain/entity/epub_metadata.dart';
import '../../domain/entity/epub_spine_item.dart';
import '../../schema/opf/package/epub_version.dart';
import '../../schema/opf/package/epub_version_detection.dart';

/// OPF(`*.opf`) XML을 파싱하여 [EpubMetadata]와 spine 항목 리스트로 변환.
///
/// EPUB 2.0과 EPUB 3.x를 모두 지원한다. namespace는 `package@version` 속성으로
/// 구분한다.
class OpfParser {
  const OpfParser();

  static const String _opfNs = 'http://www.idpf.org/2007/opf';
  static const String _dcNs = 'http://purl.org/dc/elements/1.1/';

  /// OPF XML에서 metadata + spine을 추출한다.
  ///
  /// 반환값의 spine은 manifest와 join된 결과로, 각 항목은 spine itemref의
  /// 순서를 유지하며 `href` / `mediaType`이 채워져 있다. manifest에 매칭되지
  /// 않는 itemref는 결과에서 제외된다 (broken-spine-href 보정은 S1.17 영역).
  ({EpubMetadata metadata, List<EpubSpineItem> spine}) parse(String opfXml) {
    final XmlDocument doc;
    try {
      doc = XmlDocument.parse(opfXml);
    } on XmlException catch (e) {
      throw OpfParseException('OPF is not valid XML: $e');
    }

    final root = doc.rootElement;
    if (root.localName != 'package' || root.namespaceUri != _opfNs) {
      throw OpfParseException(
        'OPF root element must be <package> in namespace $_opfNs '
        '(found <${root.qualifiedName}> in ${root.namespaceUri ?? "no namespace"})',
      );
    }

    final epubVersion = root.getAttribute('version') ?? '2.0';

    return (
      metadata: _parseMetadata(root, epubVersion),
      spine: _parseSpine(root),
    );
  }

  /// OPF에서 목차 문서(NCX/nav)의 href(OPF 기준 상대경로)를 찾는다.
  ///
  /// - EPUB 3: manifest item의 `properties`에 `nav` 포함 → [navHref]
  /// - EPUB 2: `<spine toc="...">`가 가리키는 manifest item, 또는 media-type이
  ///   `application/x-dtbncx+xml`인 item → [ncxHref]
  ///
  /// 둘 다 없으면 각각 null. (호출 전 [parse]로 OPF 유효성이 검증된 상태를 가정)
  ({String? ncxHref, String? navHref}) tocRefs(String opfXml) {
    final root = XmlDocument.parse(opfXml).rootElement;
    final manifestEl = root
        .findElements('manifest', namespace: _opfNs)
        .firstOrNull;
    if (manifestEl == null) return (ncxHref: null, navHref: null);

    String? navHref;
    String? ncxByMediaType;
    final hrefById = <String, String>{};
    for (final item in manifestEl.findElements('item', namespace: _opfNs)) {
      final id = item.getAttribute('id');
      final href = item.getAttribute('href');
      final mediaType = item.getAttribute('media-type') ?? '';
      if (href == null) continue;
      if (id != null) hrefById[id] = href;
      if (_splitProperties(item.getAttribute('properties')).contains('nav')) {
        navHref ??= href;
      }
      if (mediaType == 'application/x-dtbncx+xml') ncxByMediaType ??= href;
    }

    var ncxHref = ncxByMediaType;
    final tocId = root
        .findElements('spine', namespace: _opfNs)
        .firstOrNull
        ?.getAttribute('toc');
    if (tocId != null && hrefById.containsKey(tocId)) {
      ncxHref = hrefById[tocId];
    }

    return (ncxHref: ncxHref, navHref: navHref);
  }

  /// `package@version` 선언과 목차 구조(nav/NCX 존재)를 교차검증해 실효 버전을
  /// 도출한다. (gap #9, S10.6)
  ///
  /// - version 속성이 없거나 미지원이면 [EpubVersion.unknown]으로 보고 feature로 추론.
  /// - 선언과 feature가 모순되면 [EpubVersionDetection.hasMismatch]로 표시.
  ///
  /// (호출 전 [parse]로 OPF 유효성이 검증된 상태를 가정)
  EpubVersionDetection detectVersion(String opfXml) {
    final root = XmlDocument.parse(opfXml).rootElement;
    final declared = EpubVersion.parse(root.getAttribute('version'));
    final toc = tocRefs(opfXml);
    return EpubVersionDetection.resolve(
      declared: declared,
      hasNav: toc.navHref != null,
      hasNcx: toc.ncxHref != null,
    );
  }

  /// OPF metadata의 `rendition:layout` 원문 값을 반환한다(없으면 null).
  ///
  /// [parse]는 비표준 값을 [EpubLayout.reflowable]로 fallback하므로 원래 값이
  /// 소실된다. invalid-rendition-layout 보정 진단(S1.18)을 위해 raw 값을 노출한다.
  String? rawRenditionLayout(String opfXml) {
    final root = XmlDocument.parse(opfXml).rootElement;
    final metadataEl =
        root.findElements('metadata', namespace: _opfNs).firstOrNull;
    if (metadataEl == null) return null;
    for (final m in metadataEl.findElements('meta', namespace: _opfNs)) {
      if (m.getAttribute('property') == 'rendition:layout') {
        final v = m.innerText.trim();
        return v.isEmpty ? null : v;
      }
    }
    return null;
  }

  /// spine `page-progression-direction` + 미디어 오버레이 존재를 읽어 책의
  /// 읽기전용 [BookCapabilities]를 도출한다. writingMode는 OPF에 없어 기본값
  /// (세로쓰기 감지는 Phase 5). (S13.3, gap #3)
  BookCapabilities parseCapabilities(String opfXml) {
    final root = XmlDocument.parse(opfXml).rootElement;
    final spineEl = root.findElements('spine', namespace: _opfNs).firstOrNull;
    final ppd = _parsePageProgression(
      spineEl?.getAttribute('page-progression-direction'),
    );
    return BookCapabilities(
      pageProgressionDirection: ppd,
      hasMediaOverlay: _detectMediaOverlay(root),
    );
  }

  EpubPageProgression _parsePageProgression(String? raw) {
    switch (raw) {
      case 'ltr':
        return EpubPageProgression.ltr;
      case 'rtl':
        return EpubPageProgression.rtl;
      case 'default':
      case null:
      default:
        return EpubPageProgression.auto;
    }
  }

  /// manifest에 SMIL(application/smil+xml) 리소스나 media-overlay 참조가 있으면
  /// 미디어 오버레이 보유로 본다. (gap #6 신호)
  bool _detectMediaOverlay(XmlElement packageEl) {
    final manifestEl =
        packageEl.findElements('manifest', namespace: _opfNs).firstOrNull;
    if (manifestEl == null) return false;
    for (final item in manifestEl.findElements('item', namespace: _opfNs)) {
      if (item.getAttribute('media-type') == 'application/smil+xml') return true;
      if (item.getAttribute('media-overlay') != null) return true;
    }
    return false;
  }

  EpubMetadata _parseMetadata(XmlElement packageEl, String epubVersion) {
    final metadataEl = packageEl
        .findElements('metadata', namespace: _opfNs)
        .firstOrNull;
    if (metadataEl == null) {
      throw OpfParseException('OPF has no <metadata> element');
    }

    String? dcText(String name) {
      final el = metadataEl.findElements(name, namespace: _dcNs).firstOrNull;
      return el?.innerText.trim();
    }

    final title = dcText('title');
    if (title == null || title.isEmpty) {
      throw OpfParseException('OPF metadata missing <dc:title>');
    }

    // EPUB 3 rendition:* property meta. EPUB 2에는 없으므로 default 유지.
    String? prop(String property) {
      for (final m in metadataEl.findElements('meta', namespace: _opfNs)) {
        if (m.getAttribute('property') == property) {
          return m.innerText.trim();
        }
      }
      return null;
    }

    return EpubMetadata(
      title: title,
      epubVersion: epubVersion,
      language: dcText('language'),
      author: dcText('creator'),
      identifier: dcText('identifier'),
      layout: _parseLayout(prop('rendition:layout')),
      spread: _parseSpread(prop('rendition:spread')),
      orientation: _parseOrientation(prop('rendition:orientation')),
      viewport: _parseViewport(prop('rendition:viewport')),
      modified: prop('dcterms:modified'),
    );
  }

  /// rendition:orientation 문자열을 enum으로 매핑. 비표준/미명시는 auto. (gap #1)
  EpubOrientation _parseOrientation(String? raw) {
    switch (raw) {
      case 'landscape':
        return EpubOrientation.landscape;
      case 'portrait':
        return EpubOrientation.portrait;
      case 'auto':
      case null:
      default:
        return EpubOrientation.auto;
    }
  }

  /// rendition:viewport("width=1200, height=1600")를 [EpubViewport]로 파싱.
  /// width/height 중 하나라도 없거나 비정상이면 null. (gap #1)
  EpubViewport? _parseViewport(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final width = _dimension(raw, 'width');
    final height = _dimension(raw, 'height');
    if (width == null || height == null || width <= 0 || height <= 0) {
      return null;
    }
    return EpubViewport(width: width, height: height);
  }

  double? _dimension(String raw, String name) {
    final match =
        RegExp('$name\\s*=\\s*(\\d+(?:\\.\\d+)?)').firstMatch(raw);
    return match == null ? null : double.tryParse(match.group(1)!);
  }

  /// rendition:layout 문자열을 enum으로 매핑.
  /// 비표준 값은 reflowable로 fallback (S1.18 invalid_rendition patch가 진단).
  EpubLayout _parseLayout(String? raw) {
    if (raw == 'pre-paginated') return EpubLayout.fixedLayout;
    return EpubLayout.reflowable;
  }

  /// rendition:spread 문자열을 enum으로 매핑. 비표준 값은 auto fallback.
  EpubSpread _parseSpread(String? raw) {
    switch (raw) {
      case 'none':
        return EpubSpread.none;
      case 'both':
        return EpubSpread.both;
      case 'landscape':
        return EpubSpread.landscape;
      case 'portrait':
        return EpubSpread.portrait;
      case 'auto':
      case null:
      default:
        return EpubSpread.auto;
    }
  }

  List<EpubSpineItem> _parseSpine(XmlElement packageEl) {
    final manifestEl = packageEl
        .findElements('manifest', namespace: _opfNs)
        .firstOrNull;
    final spineEl = packageEl
        .findElements('spine', namespace: _opfNs)
        .firstOrNull;
    if (manifestEl == null) {
      throw OpfParseException('OPF has no <manifest> element');
    }
    if (spineEl == null) {
      throw OpfParseException('OPF has no <spine> element');
    }

    final manifest = <String, _ManifestItem>{};
    for (final item in manifestEl.findElements('item', namespace: _opfNs)) {
      final id = item.getAttribute('id');
      final href = item.getAttribute('href');
      final mediaType = item.getAttribute('media-type');
      if (id == null || href == null || mediaType == null) continue;
      manifest[id] = _ManifestItem(
        href: href,
        mediaType: mediaType,
        mediaOverlayId: item.getAttribute('media-overlay'),
      );
    }

    final spine = <EpubSpineItem>[];
    for (final ref in spineEl.findElements('itemref', namespace: _opfNs)) {
      final idref = ref.getAttribute('idref');
      if (idref == null) continue;
      final item = manifest[idref];
      if (item == null) continue; // broken-spine-href → S1.17이 진단 기록

      // media-overlay id(SMIL manifest item 참조) → SMIL href 해석. (S15.1)
      final moId = item.mediaOverlayId;
      final mediaOverlayHref = moId == null ? null : manifest[moId]?.href;

      spine.add(
        EpubSpineItem(
          idref: idref,
          href: item.href,
          mediaType: item.mediaType,
          linear: ref.getAttribute('linear') != 'no',
          properties: _splitProperties(ref.getAttribute('properties')),
          mediaOverlayHref: mediaOverlayHref,
        ),
      );
    }

    return spine;
  }

  List<String> _splitProperties(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const [];
    return raw.trim().split(RegExp(r'\s+'));
  }
}

class _ManifestItem {
  const _ManifestItem({
    required this.href,
    required this.mediaType,
    this.mediaOverlayId,
  });
  final String href;
  final String mediaType;

  /// `media-overlay` 속성 값 — 이 문서의 SMIL manifest item id 참조. (S15.1)
  final String? mediaOverlayId;
}

class OpfParseException implements Exception {
  OpfParseException(this.message);
  final String message;
  @override
  String toString() => 'OpfParseException: $message';
}

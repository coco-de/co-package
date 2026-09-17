// Domain UseCase — open_epub 1.0
// Story: S1.13 — Text Layer Detection (Fixed Layout)
// BDD: F5.5, F5.6, F7.4
// RFC-2 (tech-spec §3): XHTML 가시 텍스트 ≥ 50자 또는 비이미지 요소 ≥ 3개(+텍스트>0)
// 시 텍스트 레이어 available. 그 외 image-only / too-sparse.

import 'package:xml/xml.dart';

import '../entity/text_layer_verdict.dart';

/// Fixed Layout 페이지의 XHTML에서 텍스트 선택 가능 여부를 판정한다.
///
/// 판정 규칙(RFC-2):
/// 1. 가시 텍스트 ≥ [_minVisibleChars] → available (`text:N`)
/// 2. 비이미지 요소 ≥ [_minNonImageElements] 이고 텍스트 > 0 → available (`mixed:E/N`)
/// 3. 가시 텍스트 = 0 → unavailable (`image-only`)
/// 4. 그 외(희소) → unavailable (`too-sparse:N`)
///
/// 가시 텍스트 누적 시 `display:none`/`visibility:hidden`/`aria-hidden="true"`
/// 요소와 `<head>`(title·meta 등)는 제외한다. (tech-spec §3.3)
class DetectTextLayerUseCase {
  const DetectTextLayerUseCase();

  static const int _minVisibleChars = 50;
  static const int _minNonImageElements = 3;

  static const Set<String> _imageTags = {
    'img',
    'image',
    'svg',
    'picture',
    'source',
    'canvas',
  };
  static const Set<String> _skipTags = {
    'head',
    'title',
    'meta',
    'link',
    'script',
    'style',
  };

  /// 비동기 진입점(향후 무거운 파싱·격리 여지). 내부는 [detect]에 위임.
  Future<TextLayerVerdict> call(String xhtmlContent) async =>
      detect(xhtmlContent);

  /// 동기 판정.
  TextLayerVerdict detect(String xhtmlContent) {
    final XmlDocument doc;
    try {
      doc = XmlDocument.parse(xhtmlContent);
    } on XmlException {
      // 비정형 XHTML(미정의 엔티티·미닫힘 태그 등)은 태그 제거 폴백으로 판정.
      return _fallback(xhtmlContent);
    }

    final root = _bodyOf(doc) ?? doc.rootElement;
    final visibleTextLen = _visibleTextLength(root);
    final nonImgElementCount = _nonImageElementCount(root);

    if (visibleTextLen >= _minVisibleChars) {
      return TextLayerVerdict.available(
        visibleCharCount: visibleTextLen,
        reason: 'text:$visibleTextLen',
      );
    }
    if (nonImgElementCount >= _minNonImageElements && visibleTextLen > 0) {
      return TextLayerVerdict.available(
        visibleCharCount: visibleTextLen,
        reason: 'mixed:$nonImgElementCount/$visibleTextLen',
      );
    }
    if (visibleTextLen == 0) {
      return TextLayerVerdict.unavailable(reason: 'image-only');
    }
    return TextLayerVerdict.unavailable(
      visibleCharCount: visibleTextLen,
      reason: 'too-sparse:$visibleTextLen',
    );
  }

  XmlElement? _bodyOf(XmlDocument doc) {
    for (final el in doc.descendants.whereType<XmlElement>()) {
      if (el.localName.toLowerCase() == 'body') return el;
    }
    return null;
  }

  int _visibleTextLength(XmlElement root) {
    final buffer = StringBuffer();
    _accumulate(root, buffer, hidden: false);
    final normalized = buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
    return normalized.length;
  }

  void _accumulate(XmlElement el, StringBuffer buf, {required bool hidden}) {
    if (_skipTags.contains(el.localName.toLowerCase())) return;
    final isHidden = hidden || _isHidden(el);
    for (final node in el.children) {
      if (node is XmlText) {
        if (!isHidden) buf.write(node.value);
      } else if (node is XmlCDATA) {
        if (!isHidden) buf.write(node.value);
      } else if (node is XmlElement) {
        _accumulate(node, buf, hidden: isHidden);
      }
    }
  }

  bool _isHidden(XmlElement el) {
    if (el.getAttribute('aria-hidden') == 'true') return true;
    final style = el.getAttribute('style');
    if (style == null) return false;
    final compact = style.toLowerCase().replaceAll(' ', '');
    return compact.contains('display:none') ||
        compact.contains('visibility:hidden');
  }

  int _nonImageElementCount(XmlElement root) {
    var count = 0;
    for (final el in root.descendants.whereType<XmlElement>()) {
      final name = el.localName.toLowerCase();
      if (_imageTags.contains(name)) continue;
      if (_skipTags.contains(name)) continue;
      count++;
    }
    return count;
  }

  TextLayerVerdict _fallback(String raw) {
    final text = raw
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final len = text.length;
    if (len >= _minVisibleChars) {
      return TextLayerVerdict.available(
          visibleCharCount: len, reason: 'text:$len');
    }
    if (len == 0) {
      return TextLayerVerdict.unavailable(reason: 'image-only');
    }
    return TextLayerVerdict.unavailable(
      visibleCharCount: len,
      reason: 'too-sparse:$len',
    );
  }
}

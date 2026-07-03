// open_epub CFI 어댑터 — S12.2 (#95), ADR-010.
//
// 우리 canonical charOffset(=SpineTextExtractor.extractPlainText 공간, raw)과
// CFI(문서-내 경로 + 디코드된 텍스트 노드의 :offset)를 양방향 매핑한다.
// epub_pro의 EpubBookRef 결합 계층(epub/ manager) 대신 우리 EpubBook/텍스트
// 파이프라인에 맞춰 자작했다. reflowable 전용 — FXL은 pageIndex canonical.
//
// 브리지 3단:
//   charOffset(raw) ─(SpineTextExtractor.decodePlainText)→ 디코드 offset
//   디코드 offset ─(body 텍스트 노드 순회)→ DOMPosition(text node, local)
//   DOMPosition ─(HTMLNavigator)→ CFIPath → CFI 문자열
// 역방향은 각 단계를 뒤집는다.

import '../data/text/spine_text_extractor.dart';
import 'core/cfi.dart';
import 'core/cfi_structure.dart';
import 'dom/dom_abstraction.dart';
import 'dom/html_navigator.dart';

/// charOffset(평문) ↔ 문서-내 CFI 문자열 매퍼. (reflowable 전용)
class EpubCfiMapper {
  const EpubCfiMapper([this._extractor = const SpineTextExtractor()]);

  final SpineTextExtractor _extractor;

  /// spine [xhtml]의 평문 [charOffset](canonical)을 문서-내 CFI 문자열로 변환.
  ///
  /// spine step(`/6/N!`)은 포함하지 않는 **문서 내부** CFI다(전체-책 interop CFI는
  /// S12.4에서 spine step을 앞에 붙인다). 매핑 실패 시 null.
  String? charOffsetToCfi(String xhtml, int charOffset) {
    final mapping = _extractor.decodePlainText(xhtml);
    final decodedOffset =
        mapping.rawToDecoded(charOffset).clamp(0, mapping.decoded.length);
    final doc = DOMDocument.parseHTML(xhtml);
    final position = _decodedOffsetToPosition(doc, decodedOffset);
    if (position == null) return null;
    final path = HTMLNavigator.createPathFromPosition(position);
    if (path.parts.isEmpty) return null;
    return CFI.fromStructure(CFIStructure(start: path)).toString();
  }

  /// 문서-내 CFI 문자열 [cfi]를 spine [xhtml]의 평문 charOffset(canonical)으로 변환.
  ///
  /// 파싱/해석 실패 시 null.
  int? cfiToCharOffset(String xhtml, String cfi) {
    final CFI parsed;
    try {
      parsed = CFI(cfi);
    } on FormatException {
      return null;
    }
    final doc = DOMDocument.parseHTML(xhtml);
    final path = _effectiveStartPath(parsed.structure);
    final position = HTMLNavigator.navigateToPosition(doc, path);
    if (position == null) return null;
    final decodedOffset = _positionToDecodedOffset(doc, position);
    if (decodedOffset == null) return null;
    final mapping = _extractor.decodePlainText(xhtml);
    return mapping.decodedToRaw(decodedOffset.clamp(0, mapping.decoded.length));
  }

  /// range CFI 등에서 시작 지점 경로(parent + start)를 합성한다.
  CFIPath _effectiveStartPath(CFIStructure structure) {
    final parent = structure.parent;
    if (parent == null) return structure.start;
    return CFIPath(parts: [...parent.parts, ...structure.start.parts]);
  }

  /// body 텍스트 노드를 document 순서로 순회하며 누적 디코드 길이가
  /// [decodedOffset]에 도달하는 (텍스트 노드, local offset)을 찾는다.
  DOMPosition? _decodedOffsetToPosition(DOMNode root, int decodedOffset) {
    final body = _findBody(root) ?? root;
    var consumed = 0;
    DOMNode? lastText;
    var lastLen = 0;
    for (final text in _bodyTextNodes(body)) {
      final value = text.nodeValue ?? '';
      if (value.isEmpty) continue;
      if (decodedOffset <= consumed + value.length) {
        return DOMPosition(
          container: text,
          offset: (decodedOffset - consumed).clamp(0, value.length),
        );
      }
      consumed += value.length;
      lastText = text;
      lastLen = value.length;
    }
    // offset이 마지막 텍스트 끝을 넘으면 끝 위치로 clamp.
    if (lastText != null) {
      return DOMPosition(container: lastText, offset: lastLen);
    }
    return null;
  }

  /// [position](텍스트 노드 + local offset)의 누적 디코드 offset을 구한다.
  int? _positionToDecodedOffset(DOMNode root, DOMPosition position) {
    final body = _findBody(root) ?? root;
    final target = position.container;
    var consumed = 0;
    for (final text in _bodyTextNodes(body)) {
      if (identical(text, target) || text == target) {
        final value = text.nodeValue ?? '';
        return consumed + position.offset.clamp(0, value.length);
      }
      consumed += (text.nodeValue ?? '').length;
    }
    // container가 텍스트 노드가 아니면(element 위치) 그 지점까지의 누적을 근사.
    return consumed;
  }

  /// body element를 찾는다(없으면 null).
  DOMNode? _findBody(DOMNode root) {
    if (root.tagName?.toLowerCase() == 'body') return root;
    for (final child in root.childNodes) {
      final found = _findBody(child);
      if (found != null) return found;
    }
    return null;
  }

  /// [node] 하위의 텍스트 노드를 document 순서로 yield한다. script/style 하위는
  /// 제외 — extractPlainText의 _runs 규칙과 정합.
  Iterable<DOMNode> _bodyTextNodes(DOMNode node) sync* {
    for (final child in node.childNodes) {
      if (child.nodeType == DOMNodeType.text) {
        yield child;
      } else if (child.nodeType == DOMNodeType.element) {
        final tag = child.tagName?.toLowerCase();
        if (tag == 'script' || tag == 'style') continue;
        yield* _bodyTextNodes(child);
      }
    }
  }
}

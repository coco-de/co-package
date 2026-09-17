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

  /// 문서-내 CFI([charOffsetToCfi] 출력)에 spine step을 붙여 **전체-책 CFI**로
  /// 만든다. 표준 형식 `epubcfi(/6/N[idref]!/docpath)` — `/6`=spine 요소,
  /// `N`=2*(spineIndex+1)=itemref, `!`=spine 문서로의 indirection. (S12.4 interop)
  String? toBookCfi(
    String docCfi, {
    required int spineIndex,
    String? idref,
  }) {
    if (spineIndex < 0) return null;
    final inner = _unwrap(docCfi);
    if (inner == null || inner.isEmpty) return null;
    final step = 2 * (spineIndex + 1);
    final assertion = (idref != null && idref.isNotEmpty) ? '[$idref]' : '';
    final docPart = inner.startsWith('!') ? inner : '!$inner';
    return 'epubcfi(/6/$step$assertion$docPart)';
  }

  /// 전체-책 CFI에서 spine step과 문서-내 CFI를 분리한다. spine indirection(`!`)이
  /// 없으면(문서-내 CFI) null. (S12.4 interop)
  BookCfiParts? splitBookCfi(String bookCfi) {
    final inner = _unwrap(bookCfi);
    if (inner == null) return null;
    final bang = inner.indexOf('!');
    if (bang < 0) return null;
    final spineStep = inner.substring(0, bang);
    final docPath = inner.substring(bang + 1);
    if (docPath.isEmpty) return null;
    return BookCfiParts(
      spineIndex: _spineIndexFromStep(spineStep),
      idref: _idrefFromStep(spineStep),
      docCfi: 'epubcfi($docPath)',
    );
  }

  String? _unwrap(String cfi) {
    final t = cfi.trim();
    if (!t.startsWith('epubcfi(') || !t.endsWith(')')) return null;
    return t.substring('epubcfi('.length, t.length - 1);
  }

  /// spine step("/6/4[chap01]")의 마지막 `/N`에서 spineIndex(=N/2-1)를 구한다.
  int? _spineIndexFromStep(String step) {
    final segments = step.split('/').where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) return null;
    var last = segments.last;
    final bracket = last.indexOf('[');
    if (bracket >= 0) last = last.substring(0, bracket);
    final n = int.tryParse(last);
    if (n == null || n < 2 || n.isOdd) return null;
    return n ~/ 2 - 1;
  }

  /// spine step의 마지막 `[idref]` assertion을 추출한다(없으면 null).
  String? _idrefFromStep(String step) {
    final open = step.lastIndexOf('[');
    final close = step.lastIndexOf(']');
    if (open < 0 || close <= open) return null;
    final id = step.substring(open + 1, close);
    return id.isEmpty ? null : id;
  }

  /// [charOffset]을 [xhtml] 평문(extractPlainText) 길이 범위로 clamp한다.
  /// 저장된 위치의 charOffset이 (콘텐츠 변경으로) 범위를 벗어난 경우의 1차 가드.
  int clampCharOffset(String xhtml, int charOffset) {
    final len = _extractor.extractPlainText(xhtml).length;
    return charOffset.clamp(0, len);
  }

  /// 콘텐츠 교체(hot-swap 등) 시 reflowable 위치를 재앵커한다. ADR-010 우선순위:
  ///
  /// 1. **charOffset(anchor-of-record)**: [oldCharOffset]이 새 콘텐츠 평문 범위
  ///    안이면 그대로 유지(동일/유사 콘텐츠에서 최적, 불필요한 drift 방지).
  /// 2. **CFI fuzzy fallback**: 범위를 벗어나면 old 콘텐츠에서 CFI를 만들어 new
  ///    콘텐츠에 구조적으로 해석해 근접 위치를 복원.
  /// 3. **clamp**: CFI 해석 실패 시 새 길이로 clamp.
  int reanchorAcrossContent({
    required String oldXhtml,
    required int oldCharOffset,
    required String newXhtml,
  }) {
    final newLen = _extractor.extractPlainText(newXhtml).length;
    if (oldCharOffset >= 0 && oldCharOffset <= newLen) {
      return oldCharOffset;
    }
    final cfi = charOffsetToCfi(oldXhtml, oldCharOffset);
    if (cfi != null) {
      final resolved = cfiToCharOffset(newXhtml, cfi);
      if (resolved != null) return resolved.clamp(0, newLen);
    }
    return oldCharOffset.clamp(0, newLen);
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

/// [EpubCfiMapper.splitBookCfi]의 결과 — 전체-책 CFI에서 분리한 spine 식별 정보와
/// 문서-내 CFI. (S12.4 interop)
class BookCfiParts {
  const BookCfiParts({
    required this.spineIndex,
    required this.idref,
    required this.docCfi,
  });

  /// spine step `/6/N`에서 유도한 인덱스(N/2-1). 파싱 불가 시 null.
  final int? spineIndex;

  /// spine step의 `[idref]` assertion(있으면). spineIndex 대조/폴백용.
  final String? idref;

  /// `!` 이후 문서-내 CFI(`epubcfi(...)`).
  final String docCfi;
}

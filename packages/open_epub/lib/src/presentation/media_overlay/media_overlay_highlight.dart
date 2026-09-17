// Presentation — Media Overlays (open_epub 1.0)
// Story: S15.3 (#110) — 낭독 하이라이트 주입 (gap #6 동기화분)
//
// 재생 중인 par의 `<text src="doc#frag">` fragment가 가리키는 요소에 배경색을
// 입혀 현재 낭독 문장을 강조한다. 사용자 하이라이트(SpineTextExtractor의 char
// offset span 주입)와 별개 레이어라 서로 공존한다 — 이쪽은 요소 여는 태그의
// style 속성만 병합하므로 텍스트 노드 오프셋을 건드리지 않는다.

/// 낭독 하이라이트 기본 배경(반투명 노랑). 사용자 하이라이트와 구분되도록.
const String kMediaOverlayHighlightColor = 'rgba(255,214,0,0.45)';

/// [xhtml] 본문에서 `id="[fragmentId]"`인 요소의 여는 태그에 배경색을 병합한다.
/// 해당 id가 없으면 원본을 그대로 반환한다(안전). [color]는 CSS 색.
///
/// 문자열 기반 대상 주입 — 요소를 재직렬화하지 않아 다른 요소·텍스트 오프셋에
/// 영향이 없다. `style`이 이미 있으면 뒤에 병합하고, 없으면 추가한다.
String injectMediaOverlayHighlight(
  String xhtml,
  String fragmentId, {
  String color = kMediaOverlayHighlightColor,
}) {
  if (fragmentId.isEmpty) return xhtml;
  final esc = RegExp.escape(fragmentId);
  // id="frag" 또는 id='frag'를 포함하는 여는 태그.
  final tagRe = RegExp('''<[a-zA-Z][^>]*\\bid\\s*=\\s*["']$esc["'][^>]*>''');
  final match = tagRe.firstMatch(xhtml);
  if (match == null) return xhtml;
  final tag = match.group(0)!;
  final styled = _mergeStyle(tag, 'background-color:$color');
  return xhtml.replaceRange(match.start, match.end, styled);
}

/// 여는 태그 [tag]에 CSS 선언 [css]를 병합한다.
String _mergeStyle(String tag, String css) {
  final styleRe = RegExp('style\\s*=\\s*"([^"]*)"');
  final m = styleRe.firstMatch(tag);
  if (m != null) {
    final existing = m.group(1)!.trimRight();
    final merged = existing.endsWith(';') || existing.isEmpty
        ? '$existing$css'
        : '$existing;$css';
    return tag.replaceRange(m.start, m.end, 'style="$merged"');
  }
  // style 속성이 없으면 닫는 `>` (또는 self-closing `/>`) 앞에 추가한다.
  final selfClose = tag.endsWith('/>');
  final insertAt = selfClose ? tag.length - 2 : tag.length - 1;
  return '${tag.substring(0, insertAt)} style="$css"${tag.substring(insertAt)}';
}

/// `<text src>` 값(예: `ch1.xhtml#s1`, `ch1.xhtml`)에서 (경로, fragment)를 분리.
/// fragment가 없으면 fragment=null.
({String path, String? fragment}) splitTextSrc(String textSrc) {
  final i = textSrc.indexOf('#');
  if (i < 0) return (path: textSrc, fragment: null);
  return (
    path: textSrc.substring(0, i),
    fragment: i + 1 < textSrc.length ? textSrc.substring(i + 1) : null,
  );
}

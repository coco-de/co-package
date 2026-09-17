// Presentation Engine — open_epub 1.0
// Issue: #278 — 렌더 입력을 <body>로 좁혀 <head><title>이 본문에 새지 않게 한다.

/// 렌더에 넘길 XHTML을 본문으로 좁힌다.
///
/// `HtmlWidget`은 문서 전체를 그리므로 `<head><title>`이 챕터 첫 줄로 새어 나온다.
/// `<body …>…</body>`가 있으면 그 태그(속성 포함)만 반환하고, 없으면 `<head>`만
/// 벗겨 프래그먼트를 그대로 둔다.
String extractRenderableHtml(String xhtml) {
  final body = RegExp(
    r'<body\b[^>]*>[\s\S]*</body\s*>',
    caseSensitive: false,
  ).firstMatch(xhtml);
  if (body != null) return body.group(0)!;
  return xhtml.replaceAll(
    RegExp(r'<head\b[^>]*>[\s\S]*?</head\s*>', caseSensitive: false),
    '',
  );
}

// Data Security — open_epub 1.0
// Story: S1.24 (#40) — 본문 XHTML 보안 sanitize
// BDD: Edge-security (script/iframe 차단)
//
// EpubSecurityConfig에 따라 본문에서 위험 요소를 제거한다. Reflowable 렌더 직전
// 적용하는 것을 의도하며(위젯 통합 시 ReflowableEngine이 호출), 크기 제한·zip slip
// 가드는 각각 EpubRepositoryImpl / ContainerParser가 담당한다.

import '../../api/epub_security_config.dart';

class HtmlSanitizer {
  const HtmlSanitizer([this.config = const EpubSecurityConfig()]);

  final EpubSecurityConfig config;

  String sanitize(String html) {
    var out = html;
    if (config.blockExternalScripts) out = _stripTag(out, 'script');
    if (config.blockIframes) out = _stripTag(out, 'iframe');
    return out;
  }

  String _stripTag(String html, String tag) {
    final paired =
        RegExp('<$tag\\b[^>]*>[\\s\\S]*?</$tag\\s*>', caseSensitive: false);
    final lone = RegExp('<$tag\\b[^>]*/?>', caseSensitive: false);
    return html.replaceAll(paired, '').replaceAll(lone, '');
  }
}

// Story: S1.24 (#40) — HtmlSanitizer tests
// BDD: Edge-security (script/iframe 차단)

import 'package:flutter_test/flutter_test.dart';
import 'package:open_epub_engine/src/api/epub_security_config.dart';
import 'package:open_epub_engine/src/data/security/html_sanitizer.dart';

void main() {
  test('기본 설정은 script/iframe을 제거하고 본문은 보존', () {
    const sanitizer = HtmlSanitizer();
    final out = sanitizer.sanitize(
      '<p>hello</p><script>alert(1)</script>'
      '<iframe src="evil"></iframe><p>bye</p>',
    );
    expect(out, contains('<p>hello</p>'));
    expect(out, contains('<p>bye</p>'));
    expect(out.toLowerCase(), isNot(contains('<script')));
    expect(out.toLowerCase(), isNot(contains('<iframe')));
    expect(out, isNot(contains('alert(1)')));
  });

  test('대문자 태그도 제거', () {
    const sanitizer = HtmlSanitizer();
    final out = sanitizer.sanitize('<SCRIPT>x</SCRIPT>ok');
    expect(out, 'ok');
  });

  test('config로 차단을 끄면 유지', () {
    const sanitizer = HtmlSanitizer(
      EpubSecurityConfig(blockExternalScripts: false, blockIframes: false),
    );
    final out = sanitizer.sanitize('<script>x</script>');
    expect(out, contains('<script>'));
  });
}

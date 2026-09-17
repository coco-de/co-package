// Story: S12.2 (#95) — EpubCfiMapper: charOffset(canonical) ↔ 문서-내 CFI 왕복.

import 'package:open_epub_engine/src/cfi/epub_cfi_mapper.dart';
import 'package:open_epub_engine/src/data/text/spine_text_extractor.dart';
import 'package:test/test.dart';

void main() {
  const mapper = EpubCfiMapper();
  const extractor = SpineTextExtractor();

  const xhtml = '<html><body>'
      '<h1>First Chapter</h1>'
      '<p>Hello world. This is paragraph one.</p>'
      '<p>Second paragraph here.</p>'
      '</body></html>';

  group('S12.2 — charOffset ↔ CFI round-trip', () {
    final plain = extractor.extractPlainText(xhtml);

    test('여러 charOffset이 CFI 왕복으로 보존된다', () {
      // 본문 곳곳의 offset (경계·중간)
      for (final off in [
        0,
        1,
        5,
        12,
        20,
        30,
        plain.length ~/ 2,
        plain.length - 1
      ]) {
        final cfi = mapper.charOffsetToCfi(xhtml, off);
        expect(cfi, isNotNull, reason: 'charOffset $off → CFI 생성 실패');
        expect(cfi, startsWith('epubcfi('));
        final back = mapper.cfiToCharOffset(xhtml, cfi!);
        expect(back, isNotNull, reason: 'CFI → charOffset 실패 (off=$off)');
        expect(back, equals(off),
            reason: 'round-trip 불일치 (off=$off, cfi=$cfi)');
      }
    });

    test('CFI가 가리키는 위치의 문자가 기대와 일치', () {
      // "Hello" 의 'H' 위치를 찾아 CFI 왕복 후 같은 문자를 가리키는지
      final idx = plain.indexOf('Hello');
      expect(idx, greaterThanOrEqualTo(0));
      final cfi = mapper.charOffsetToCfi(xhtml, idx);
      final back = mapper.cfiToCharOffset(xhtml, cfi!);
      expect(plain.substring(back!, back + 5), equals('Hello'));
    });
  });

  group('S12.2 — 엔티티 포함 본문 (raw charOffset 공간 정합)', () {
    const entXhtml =
        '<html><body><p>Tom &amp; Jerry &lt;fun&gt; end</p></body></html>';
    final entPlain = extractor.extractPlainText(entXhtml);

    test('엔티티 뒤 문자의 charOffset이 왕복 보존된다', () {
      // raw 평문에서 'Jerry' 위치(엔티티 &amp; 다음)
      final idx = entPlain.indexOf('Jerry');
      expect(idx, greaterThanOrEqualTo(0));
      final cfi = mapper.charOffsetToCfi(entXhtml, idx);
      expect(cfi, isNotNull);
      final back = mapper.cfiToCharOffset(entXhtml, cfi!);
      expect(back, equals(idx));
      expect(entPlain.substring(back!, back + 5), equals('Jerry'));
    });
  });

  group('S12.2 — 실패/경계', () {
    test('잘못된 CFI는 null', () {
      expect(mapper.cfiToCharOffset(xhtml, 'garbage'), isNull);
    });

    test('offset 0 → CFI → 0', () {
      final cfi = mapper.charOffsetToCfi(xhtml, 0);
      expect(mapper.cfiToCharOffset(xhtml, cfi!), equals(0));
    });
  });
}

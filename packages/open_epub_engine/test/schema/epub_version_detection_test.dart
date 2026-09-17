// S10.6 (#83) — version-branching 교차검증 테스트 (gap #9).
import 'package:open_epub_engine/open_epub_engine.dart';
import 'package:test/test.dart';

String _opf({
  String? version,
  bool nav = false,
  bool ncx = false,
}) {
  final versionAttr = version == null ? '' : ' version="$version"';
  final navItem = nav
      ? '<item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" '
          'properties="nav"/>'
      : '';
  final ncxItem = ncx
      ? '<item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>'
      : '';
  final spineToc = ncx ? ' toc="ncx"' : '';
  return '''
<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf"$versionAttr
    unique-identifier="bookid">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>t</dc:title>
    <dc:identifier id="bookid">urn:uuid:x</dc:identifier>
  </metadata>
  <manifest>
    $navItem
    $ncxItem
    <item id="c1" href="ch1.xhtml" media-type="application/xhtml+xml"/>
  </manifest>
  <spine$spineToc>
    <itemref idref="c1"/>
  </spine>
</package>
''';
}

void main() {
  group('EpubVersionDetection.resolve — 교차검증 로직', () {
    test('선언 2 + NCX → epub2, mismatch 없음', () {
      final d = EpubVersionDetection.resolve(
        declared: EpubVersion.epub2,
        hasNav: false,
        hasNcx: true,
      );
      expect(d.resolved, EpubVersion.epub2);
      expect(d.hasMismatch, isFalse);
    });

    test('선언 3 + nav → epub3, mismatch 없음', () {
      final d = EpubVersionDetection.resolve(
        declared: EpubVersion.epub3,
        hasNav: true,
        hasNcx: false,
      );
      expect(d.resolved, EpubVersion.epub3);
      expect(d.hasMismatch, isFalse);
    });

    test('EPUB3는 nav+NCX 병기 허용 → mismatch 없음', () {
      final d = EpubVersionDetection.resolve(
        declared: EpubVersion.epub3,
        hasNav: true,
        hasNcx: true,
      );
      expect(d.hasMismatch, isFalse);
    });

    test('선언 누락(unknown) + nav → epub3 추론', () {
      final d = EpubVersionDetection.resolve(
        declared: EpubVersion.unknown,
        hasNav: true,
        hasNcx: false,
      );
      expect(d.resolved, EpubVersion.epub3);
      expect(d.hasMismatch, isFalse);
    });

    test('선언 누락(unknown) + NCX → epub2 추론', () {
      final d = EpubVersionDetection.resolve(
        declared: EpubVersion.unknown,
        hasNav: false,
        hasNcx: true,
      );
      expect(d.resolved, EpubVersion.epub2);
      expect(d.hasMismatch, isFalse);
    });

    test('선언 누락 + feature 전무 → unknown', () {
      final d = EpubVersionDetection.resolve(
        declared: EpubVersion.unknown,
        hasNav: false,
        hasNcx: false,
      );
      expect(d.resolved, EpubVersion.unknown);
      expect(d.hasMismatch, isFalse);
    });

    test('불일치: 선언 3 인데 nav 없음(NCX만) → resolved 3 유지, mismatch', () {
      final d = EpubVersionDetection.resolve(
        declared: EpubVersion.epub3,
        hasNav: false,
        hasNcx: true,
      );
      expect(d.resolved, EpubVersion.epub3);
      expect(d.hasMismatch, isTrue);
    });

    test('불일치: 선언 3.1 인데 nav 없음 → mismatch', () {
      final d = EpubVersionDetection.resolve(
        declared: EpubVersion.epub31,
        hasNav: false,
        hasNcx: false,
      );
      expect(d.hasMismatch, isTrue);
    });

    test('불일치: 선언 2 인데 nav 존재 → mismatch', () {
      final d = EpubVersionDetection.resolve(
        declared: EpubVersion.epub2,
        hasNav: true,
        hasNcx: false,
      );
      expect(d.resolved, EpubVersion.epub2);
      expect(d.hasMismatch, isTrue);
    });
  });

  group('OpfParser.detectVersion — OPF 통합', () {
    const parser = OpfParser();

    test('version=2.0 + NCX → epub2, mismatch 없음', () {
      final d = parser.detectVersion(_opf(version: '2.0', ncx: true));
      expect(d.declared, EpubVersion.epub2);
      expect(d.resolved, EpubVersion.epub2);
      expect(d.hasNcx, isTrue);
      expect(d.hasNav, isFalse);
      expect(d.hasMismatch, isFalse);
    });

    test('version=3.0 + nav → epub3, mismatch 없음', () {
      final d = parser.detectVersion(_opf(version: '3.0', nav: true));
      expect(d.declared, EpubVersion.epub3);
      expect(d.resolved, EpubVersion.epub3);
      expect(d.hasNav, isTrue);
      expect(d.hasMismatch, isFalse);
    });

    test('version 누락 + nav → epub3 추론', () {
      final d = parser.detectVersion(_opf(nav: true));
      expect(d.declared, EpubVersion.unknown);
      expect(d.resolved, EpubVersion.epub3);
      expect(d.hasMismatch, isFalse);
    });

    test('불일치: version=3.0 인데 NCX만(nav 없음) → mismatch', () {
      final d = parser.detectVersion(_opf(version: '3.0', ncx: true));
      expect(d.declared, EpubVersion.epub3);
      expect(d.resolved, EpubVersion.epub3);
      expect(d.hasNav, isFalse);
      expect(d.hasNcx, isTrue);
      expect(d.hasMismatch, isTrue);
    });

    test('불일치: version=2.0 인데 nav 존재 → mismatch', () {
      final d = parser.detectVersion(_opf(version: '2.0', nav: true));
      expect(d.declared, EpubVersion.epub2);
      expect(d.hasNav, isTrue);
      expect(d.hasMismatch, isTrue);
    });
  });
}

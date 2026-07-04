// Story: S13.4 (#101) — multiple renditions + 확장 메타 (gap #7)

import 'package:open_epub_engine/open_epub_engine.dart';
import 'package:test/test.dart';

const _multiRendition = '''
<?xml version="1.0"?>
<container version="1.0"
    xmlns="urn:oasis:names:tc:opendocument:xmlns:container"
    xmlns:rendition="http://www.idpf.org/2013/rendition">
  <rootfiles>
    <rootfile full-path="OEBPS/reflow.opf"
        media-type="application/oebps-package+xml" rendition:label="Reflowable"/>
    <rootfile full-path="OEBPS/fxl.opf"
        media-type="application/oebps-package+xml" rendition:label="Fixed"/>
  </rootfiles>
</container>''';

void main() {
  const container = ContainerParser();
  const opf = OpfParser();

  group('S13.4 — container 복수 rootfile', () {
    test('모든 rootfile + default 표시 + label', () {
      final renditions = container.parseRootfiles(_multiRendition);
      expect(renditions, hasLength(2));
      expect(renditions[0].fullPath, 'OEBPS/reflow.opf');
      expect(renditions[0].label, 'Reflowable');
      expect(renditions[0].isDefault, isTrue); // OPF media-type 첫 항목
      expect(renditions[1].label, 'Fixed');
      expect(renditions[1].isDefault, isFalse);
    });

    test('parse()는 default OPF 경로를 그대로 반환(회귀 없음)', () {
      expect(container.parse(_multiRendition), 'OEBPS/reflow.opf');
    });

    test('zip slip rootfile은 제외', () {
      const evil = '''
<?xml version="1.0"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/ok.opf" media-type="application/oebps-package+xml"/>
    <rootfile full-path="../../../etc/x.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>''';
      final r = container.parseRootfiles(evil);
      expect(r, hasLength(1));
      expect(r.first.fullPath, 'OEBPS/ok.opf');
    });
  });

  group('S13.4 — 확장 메타 dcterms:modified', () {
    test('modified 파싱', () {
      const opfXml = '''
<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0" unique-identifier="b">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>t</dc:title><dc:identifier id="b">urn:uuid:x</dc:identifier>
    <meta property="dcterms:modified">2024-05-01T12:00:00Z</meta>
  </metadata>
  <manifest><item id="c1" href="c.xhtml" media-type="application/xhtml+xml"/></manifest>
  <spine><itemref idref="c1"/></spine>
</package>''';
      expect(opf.parse(opfXml).metadata.modified, '2024-05-01T12:00:00Z');
    });

    test('없으면 null', () {
      const opfXml = '''
<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0" unique-identifier="b">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>t</dc:title><dc:identifier id="b">urn:uuid:x</dc:identifier>
  </metadata>
  <manifest><item id="c1" href="c.xhtml" media-type="application/xhtml+xml"/></manifest>
  <spine><itemref idref="c1"/></spine>
</package>''';
      expect(opf.parse(opfXml).metadata.modified, isNull);
    });
  });
}

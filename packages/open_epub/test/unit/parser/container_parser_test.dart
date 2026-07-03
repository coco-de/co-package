// Story: S1.1 (#7) — container.xml parser tests
// BDD: F1.1, Edge-security

import 'package:flutter_test/flutter_test.dart';
import 'package:open_epub/src/data/parser/container_parser.dart';

void main() {
  group('ContainerParser.parse', () {
    final parser = const ContainerParser();

    test('표준 EPUB 3 container.xml에서 OPF 경로 추출', () {
      const xml = '''
<?xml version="1.0"?>
<container xmlns="urn:oasis:names:tc:opendocument:xmlns:container" version="1.0">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>''';
      expect(parser.parse(xml), 'OEBPS/content.opf');
    });

    test('여러 rootfile 중 OPF media-type을 가진 항목 선택', () {
      const xml = '''
<?xml version="1.0"?>
<container xmlns="urn:oasis:names:tc:opendocument:xmlns:container" version="1.0">
  <rootfiles>
    <rootfile full-path="META-INF/other.xml" media-type="text/xml"/>
    <rootfile full-path="package.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>''';
      expect(parser.parse(xml), 'package.opf');
    });

    test('rootfile이 없으면 ContainerParseException', () {
      const xml = '''
<?xml version="1.0"?>
<container xmlns="urn:oasis:names:tc:opendocument:xmlns:container" version="1.0">
  <rootfiles></rootfiles>
</container>''';
      expect(() => parser.parse(xml), throwsA(isA<ContainerParseException>()));
    });

    test('full-path가 비어 있으면 ContainerParseException', () {
      const xml = '''
<?xml version="1.0"?>
<container xmlns="urn:oasis:names:tc:opendocument:xmlns:container" version="1.0">
  <rootfiles>
    <rootfile full-path="" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>''';
      expect(() => parser.parse(xml), throwsA(isA<ContainerParseException>()));
    });

    test('잘못된 XML이면 ContainerParseException', () {
      expect(
        () => parser.parse('not <xml/>'),
        throwsA(isA<ContainerParseException>()),
      );
    });

    test('zip slip 경로면 ZipSlipException', () {
      const xml = '''
<?xml version="1.0"?>
<container xmlns="urn:oasis:names:tc:opendocument:xmlns:container" version="1.0">
  <rootfiles>
    <rootfile full-path="../../../etc/passwd" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>''';
      expect(() => parser.parse(xml), throwsA(isA<ZipSlipException>()));
    });

    test('절대 경로면 ZipSlipException', () {
      const xml = '''
<?xml version="1.0"?>
<container xmlns="urn:oasis:names:tc:opendocument:xmlns:container" version="1.0">
  <rootfiles>
    <rootfile full-path="/etc/passwd" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>''';
      expect(() => parser.parse(xml), throwsA(isA<ZipSlipException>()));
    });
  });

  group('ContainerParser.isSafePath', () {
    final parser = const ContainerParser();

    test('일반 상대 경로는 safe', () {
      expect(parser.isSafePath('OEBPS/content.opf'), isTrue);
      expect(parser.isSafePath('package.opf'), isTrue);
      expect(parser.isSafePath('nested/deep/file.xhtml'), isTrue);
    });

    test('빈 경로는 unsafe', () {
      expect(parser.isSafePath(''), isFalse);
    });

    test('절대 경로는 unsafe', () {
      expect(parser.isSafePath('/etc/passwd'), isFalse);
      expect(parser.isSafePath(r'\windows\system32'), isFalse);
    });

    test('parent escape는 unsafe', () {
      expect(parser.isSafePath('../escape'), isFalse);
      expect(parser.isSafePath('OEBPS/../../../etc'), isFalse);
      expect(parser.isSafePath(r'OEBPS\..\..\etc'), isFalse);
    });

    test('URL 스킴 포함은 unsafe', () {
      expect(parser.isSafePath('http://evil.com/x'), isFalse);
      expect(parser.isSafePath('file:///etc/passwd'), isFalse);
    });

    test('Windows drive letter는 unsafe', () {
      expect(parser.isSafePath(r'C:\Windows\System32'), isFalse);
      expect(parser.isSafePath('C:/Windows/System32'), isFalse);
    });
  });
}

// Story: S13.5 (#102) — encryption.xml 파싱 + IDPF/Adobe 폰트 난독화 (gap #8)

import 'dart:typed_data';

import 'package:open_epub_engine/open_epub_engine.dart';
import 'package:open_epub_engine/testing.dart';
import 'package:test/test.dart';

const _idpf = FontObfuscation.idpf;
const _adobe = FontObfuscation.adobe;

void main() {
  group('S13.5 — EncryptionParser', () {
    const xml = '''
<?xml version="1.0"?>
<encryption xmlns="urn:oasis:names:tc:opendocument:xmlns:container"
    xmlns:enc="http://www.w3.org/2001/04/xmlenc#">
  <enc:EncryptedData>
    <enc:EncryptionMethod Algorithm="http://www.idpf.org/2008/embedding"/>
    <enc:CipherData><enc:CipherReference URI="OEBPS/fonts/x.otf"/></enc:CipherData>
  </enc:EncryptedData>
  <enc:EncryptedData>
    <enc:EncryptionMethod Algorithm="http://www.w3.org/2001/04/xmlenc#aes256-cbc"/>
    <enc:CipherData><enc:CipherReference URI="OEBPS/ch1.xhtml"/></enc:CipherData>
  </enc:EncryptedData>
</encryption>''';

    test('항목 파싱 + 폰트 난독화 분류', () {
      final entries = const EncryptionParser().parse(xml);
      expect(entries, hasLength(2));
      expect(entries[0].uri, 'OEBPS/fonts/x.otf');
      expect(entries[0].algorithm, _idpf);
      expect(entries[0].isFontObfuscation, isTrue);
      expect(entries[1].isFontObfuscation, isFalse); // AES = 상업 DRM
    });

    test('잘못된 XML은 빈 리스트', () {
      expect(const EncryptionParser().parse('<nope').isEmpty, isTrue);
    });
  });

  group('S13.5 — FontObfuscation round-trip (대칭 XOR)', () {
    final original = Uint8List.fromList(
      List<int>.generate(2000, (i) => (i * 7 + 3) % 256),
    );

    test('IDPF: 난독화 후 해제하면 원본 (앞 1040 바이트 변경)', () {
      const id = 'urn:uuid:9a306f5e-1234-5678-9abc-def012345678';
      final obf = FontObfuscation.deobfuscate(
          data: original, algorithm: _idpf, identifier: id);
      // 앞부분은 바뀌고 뒷부분(1040~)은 그대로
      expect(obf.sublist(0, 20), isNot(equals(original.sublist(0, 20))));
      expect(obf.sublist(1040), equals(original.sublist(1040)));
      final restored = FontObfuscation.deobfuscate(
          data: obf, algorithm: _idpf, identifier: id);
      expect(restored, equals(original));
    });

    test('Adobe: 난독화 후 해제하면 원본 (앞 1024 바이트 변경)', () {
      const id = 'urn:uuid:9a306f5e-1234-5678-9abc-def012345678';
      final obf = FontObfuscation.deobfuscate(
          data: original, algorithm: _adobe, identifier: id);
      expect(obf.sublist(0, 16), isNot(equals(original.sublist(0, 16))));
      expect(obf.sublist(1024), equals(original.sublist(1024)));
      final restored = FontObfuscation.deobfuscate(
          data: obf, algorithm: _adobe, identifier: id);
      expect(restored, equals(original));
    });

    test('미지원 알고리즘은 원본 그대로', () {
      final out = FontObfuscation.deobfuscate(
          data: original, algorithm: 'aes', identifier: 'x');
      expect(out, equals(original));
      expect(FontObfuscation.isObfuscation('aes'), isFalse);
    });
  });

  group('S13.5 — 세션 통합', () {
    const identifier = 'urn:uuid:font-book-0001';
    final fontOriginal =
        Uint8List.fromList(List<int>.generate(1500, (i) => (i * 3) % 256));

    Uint8List epubWithEncryption({
      required String encryptionXml,
      required Object fontContent,
    }) =>
        zipEpubBinary({
          'mimetype': 'application/epub+zip',
          'META-INF/container.xml': '''
<?xml version="1.0"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles><rootfile full-path="OEBPS/content.opf"
      media-type="application/oebps-package+xml"/></rootfiles>
</container>''',
          'META-INF/encryption.xml': encryptionXml,
          'OEBPS/content.opf': '''
<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0" unique-identifier="b">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>font</dc:title><dc:identifier id="b">$identifier</dc:identifier>
  </metadata>
  <manifest>
    <item id="c1" href="ch1.xhtml" media-type="application/xhtml+xml"/>
    <item id="f1" href="fonts/x.otf" media-type="font/otf"/>
  </manifest>
  <spine><itemref idref="c1"/></spine>
</package>''',
          'OEBPS/ch1.xhtml':
              '<html xmlns="http://www.w3.org/1999/xhtml"><body><p>본문</p></body></html>',
          'OEBPS/fonts/x.otf': fontContent,
        });

    test('난독화된 폰트가 읽을 때 투명 해제된다', () async {
      // 아카이브엔 난독화된 형태(=deobfuscate 대칭 적용)로 저장.
      final obf = FontObfuscation.deobfuscate(
          data: fontOriginal, algorithm: _idpf, identifier: identifier);
      const encXml = '''
<?xml version="1.0"?>
<encryption xmlns:enc="http://www.w3.org/2001/04/xmlenc#">
  <enc:EncryptedData>
    <enc:EncryptionMethod Algorithm="http://www.idpf.org/2008/embedding"/>
    <enc:CipherData><enc:CipherReference URI="OEBPS/fonts/x.otf"/></enc:CipherData>
  </enc:EncryptedData>
</encryption>''';
      final session = await EpubBookSession.open(
        EpubSource.bytes(
            epubWithEncryption(encryptionXml: encXml, fontContent: obf)),
      );
      final read = session.resources.readBytes('fonts/x.otf');
      expect(read, equals(fontOriginal)); // 투명 해제 → 원본
      await session.dispose();
    });

    test('본문(spine)이 미지원 암호화면 EpubEncryptedUnsupported', () async {
      const encXml = '''
<?xml version="1.0"?>
<encryption xmlns:enc="http://www.w3.org/2001/04/xmlenc#">
  <enc:EncryptedData>
    <enc:EncryptionMethod Algorithm="http://www.w3.org/2001/04/xmlenc#aes256-cbc"/>
    <enc:CipherData><enc:CipherReference URI="OEBPS/ch1.xhtml"/></enc:CipherData>
  </enc:EncryptedData>
</encryption>''';
      expect(
        () => EpubBookSession.open(EpubSource.bytes(epubWithEncryption(
            encryptionXml: encXml, fontContent: fontOriginal))),
        throwsA(isA<EpubEncryptedUnsupported>()),
      );
    });
  });
}

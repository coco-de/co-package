import 'package:open_epub_engine/open_epub_engine.dart';
import 'package:test/test.dart';

void main() {
  group('EpubVersion.parse', () {
    test('2.0 / 2.0.1 → epub2', () {
      expect(EpubVersion.parse('2.0'), EpubVersion.epub2);
      expect(EpubVersion.parse('2.0.1'), EpubVersion.epub2);
    });

    test('3.0 / 3.0.1 / 3.2 / 3.3 → epub3', () {
      expect(EpubVersion.parse('3.0'), EpubVersion.epub3);
      expect(EpubVersion.parse('3.0.1'), EpubVersion.epub3);
      expect(EpubVersion.parse('3.2'), EpubVersion.epub3);
      expect(EpubVersion.parse('3.3'), EpubVersion.epub3);
    });

    test('3.1 → epub31 (deprecated)', () {
      expect(EpubVersion.parse('3.1'), EpubVersion.epub31);
    });

    test('null / empty / 미지원 → unknown', () {
      expect(EpubVersion.parse(null), EpubVersion.unknown);
      expect(EpubVersion.parse(''), EpubVersion.unknown);
      expect(EpubVersion.parse('  '), EpubVersion.unknown);
      expect(EpubVersion.parse('99'), EpubVersion.unknown);
    });

    test('앞뒤 공백 허용', () {
      expect(EpubVersion.parse(' 3.0 '), EpubVersion.epub3);
    });

    test('versionString', () {
      expect(EpubVersion.epub2.versionString, '2');
      expect(EpubVersion.epub3.versionString, '3');
      expect(EpubVersion.epub31.versionString, '3.1');
    });
  });
}

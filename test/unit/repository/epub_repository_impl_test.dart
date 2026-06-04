// Story: S1.20 (#36), S1.21 (#37) — EpubRepositoryImpl ZIP→파서→조립 tests
// BDD: F1.1 (책 열기), F4 (목차)

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:open_epub/src/api/epub_security_config.dart';
import 'package:open_epub/src/api/epub_source.dart';
import 'package:open_epub/src/data/repository/epub_repository_impl.dart';
import 'package:open_epub/src/domain/entity/epub_metadata.dart';

import '../_fixtures/epub_fixtures.dart';

void main() {
  final repo = EpubRepositoryImpl();

  group('EpubRepositoryImpl.load — EPUB 3 (nav)', () {
    test('container.xml → OPF → metadata 추출', () async {
      final book = await repo.load(EpubSource.bytes(validEpub3()));
      expect(book.metadata.title, '테스트 책');
      expect(book.metadata.epubVersion, '3.0');
      expect(book.metadata.language, 'ko');
      expect(book.metadata.author, '홍길동');
      expect(book.layout, EpubLayout.reflowable);
    });

    test('spine은 manifest와 join되어 순서 유지', () async {
      final book = await repo.load(EpubSource.bytes(validEpub3()));
      expect(book.spine.map((s) => s.href), ['ch1.xhtml', 'ch2.xhtml']);
      expect(book.spine.every((s) => s.linear), isTrue);
    });

    test('nav.xhtml 목차가 파싱된다', () async {
      final book = await repo.load(EpubSource.bytes(validEpub3()));
      expect(book.outline.items.map((i) => i.title), ['1장', '2장']);
      expect(book.outline.items.map((i) => i.spineHref),
          ['ch1.xhtml', 'ch2.xhtml']);
    });
  });

  group('EpubRepositoryImpl.load — EPUB 2 (NCX)', () {
    test('OPF spine@toc → NCX 목차 파싱 (보정 전 raw)', () async {
      final book = await repo.load(EpubSource.bytes(sparseNcxEpub2()));
      expect(book.metadata.epubVersion, '2.0');
      expect(book.spine, hasLength(4));
      // 보정(sparse-ncx)은 UseCase 단계에서 적용되므로 repository raw는 1개만.
      expect(book.outline.items, hasLength(1));
      expect(book.outline.items.single.spineHref, 'ch1.xhtml');
    });
  });

  group('EpubRepositoryImpl.load — 실패 경로', () {
    test('ZIP이 아니면 EpubLoadException', () {
      final junk = EpubSource.bytes(Uint8List.fromList([1, 2, 3, 4, 5]));
      expect(repo.load(junk), throwsA(isA<EpubLoadException>()));
    });

    test('크기 제한 초과 시 EpubLoadException', () {
      final small = EpubRepositoryImpl(
        security: const EpubSecurityConfig(maxFileSizeBytes: 16),
      );
      expect(
        small.load(EpubSource.bytes(validEpub3())),
        throwsA(isA<EpubLoadException>()),
      );
    });
  });
}

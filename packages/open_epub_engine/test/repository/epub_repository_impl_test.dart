// Story: S1.20 (#36), S1.21 (#37) — EpubRepositoryImpl ZIP→파서→조립 tests
// BDD: F1.1 (책 열기), F4 (목차)

import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:open_epub_engine/src/api/epub_security_config.dart';
import 'package:open_epub_engine/src/api/epub_source.dart';
import 'package:open_epub_engine/src/data/repository/epub_repository_impl.dart';
import 'package:open_epub_engine/src/domain/entity/epub_failure.dart';
import 'package:open_epub_engine/src/domain/entity/epub_metadata.dart';

import 'package:open_epub_engine/testing.dart';

void main() {
  final repo = EpubRepositoryImpl();

  group('EpubRepositoryImpl.load — EPUB 3 (nav)', () {
    test('container.xml → OPF → metadata 추출', () async {
      final book = (await repo.load(EpubSource.bytes(validEpub3()))).book;
      expect(book.metadata.title, '테스트 책');
      expect(book.metadata.epubVersion, '3.0');
      expect(book.metadata.language, 'ko');
      expect(book.metadata.author, '홍길동');
      expect(book.layout, EpubLayout.reflowable);
    });

    test('spine은 manifest와 join되어 순서 유지', () async {
      final book = (await repo.load(EpubSource.bytes(validEpub3()))).book;
      expect(book.spine.map((s) => s.href), ['ch1.xhtml', 'ch2.xhtml']);
      expect(book.spine.every((s) => s.linear), isTrue);
    });

    test('nav.xhtml 목차가 파싱된다', () async {
      final book = (await repo.load(EpubSource.bytes(validEpub3()))).book;
      expect(book.outline.items.map((i) => i.title), ['1장', '2장']);
      expect(book.outline.items.map((i) => i.spineHref),
          ['ch1.xhtml', 'ch2.xhtml']);
    });
  });

  group('EpubRepositoryImpl.load — EPUB 2 (NCX)', () {
    test('OPF spine@toc → NCX 목차 파싱 (보정 전 raw)', () async {
      final book = (await repo.load(EpubSource.bytes(sparseNcxEpub2()))).book;
      expect(book.metadata.epubVersion, '2.0');
      expect(book.spine, hasLength(4));
      // 보정(sparse-ncx)은 UseCase 단계에서 적용되므로 repository raw는 1개만.
      expect(book.outline.items, hasLength(1));
      expect(book.outline.items.single.spineHref, 'ch1.xhtml');
    });
  });

  group('EpubRepositoryImpl.load — 실패 경로', () {
    test('ZIP이 아니면 EpubCorrupted', () {
      final junk = EpubSource.bytes(Uint8List.fromList([1, 2, 3, 4, 5]));
      expect(repo.load(junk), throwsA(isA<EpubCorrupted>()));
    });

    test('크기 제한 초과 시 EpubFileTooLarge', () {
      final small = EpubRepositoryImpl(
        security: const EpubSecurityConfig(maxFileSizeBytes: 16),
      );
      expect(
        small.load(EpubSource.bytes(validEpub3())),
        throwsA(isA<EpubFileTooLarge>()),
      );
    });
  });

  group('raw-레벨 보정 진단 (S1.18 #34)', () {
    test('mimetype 누락 시 missing-mimetype 진단', () async {
      final loaded = await repo.load(EpubSource.bytes(sparseNcxEpub2()));
      expect(
        loaded.patches.map((p) => p.patchId),
        contains('missing-mimetype'),
      );
    });

    test('정상 mimetype이면 missing-mimetype 없음', () async {
      final loaded = await repo.load(EpubSource.bytes(validEpub3()));
      expect(
        loaded.patches.map((p) => p.patchId),
        isNot(contains('missing-mimetype')),
      );
    });

    test('비표준 rendition:layout 시 진단 + reflowable fallback', () async {
      final loaded = await repo.load(EpubSource.bytes(invalidRenditionEpub3()));
      expect(
        loaded.patches.map((p) => p.patchId),
        contains('invalid-rendition-layout'),
      );
      expect(loaded.book.metadata.layout, EpubLayout.reflowable);
    });
  });

  group('isolate 오프로딩 (S9.6 #70)', () {
    // isolateThresholdBytes: 0 → 작은 픽스처도 강제로 isolate 경로를 타게 해
    // 오프로딩 전후 결과 동등성을 검증한다(기본값에서는 대용량만 오프로딩).
    final offloaded = EpubRepositoryImpl(isolateThresholdBytes: 0);

    test('오프로딩(isolate) 후 재구성된 리소스 reader가 spine 본문을 읽는다', () async {
      // 파싱(ZIP 디코드+XML)은 별도 isolate에서, Archive/리소스 reader는 호출
      // isolate에서 재구성된다. 재구성된 reader가 본문을 정상 반환해야 한다.
      final loaded = await offloaded.load(EpubSource.bytes(validEpub3()));
      final ch1 = loaded.resources.readString('ch1.xhtml');
      expect(ch1, isNotNull);
      expect(ch1, contains('1장'));
      // 존재하지 않는 리소스는 null.
      expect(loaded.resources.readString('nope.xhtml'), isNull);
    });

    test('오프로딩 결과가 동기 파싱과 동일한 book/navigation/capabilities를 만든다', () async {
      final viaIsolate = await offloaded.load(EpubSource.bytes(validEpub3()));
      final viaSync = await repo.load(EpubSource.bytes(validEpub3()));
      expect(viaIsolate.book.metadata.title, viaSync.book.metadata.title);
      expect(viaIsolate.book.spine.map((s) => s.href),
          viaSync.book.spine.map((s) => s.href));
      expect(viaIsolate.book.outline.items.map((i) => i.title),
          viaSync.book.outline.items.map((i) => i.title));
      expect(viaIsolate.patches.map((p) => p.patchId),
          viaSync.patches.map((p) => p.patchId));
    });

    test('오프로딩 경로도 실패를 동일하게 전파한다', () {
      final junk = EpubSource.bytes(Uint8List.fromList([9, 9, 9, 9]));
      expect(offloaded.load(junk), throwsA(isA<EpubCorrupted>()));
    });
  });
}

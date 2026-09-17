// Story: S1.14 — PatchCatalog 인프라 + ApplyPatchesUseCase tests
// BDD: F9 (호환성 보정 + 진단)

import 'dart:convert';

import 'package:test/test.dart';
import 'package:open_epub_engine/src/data/compat/patch_catalog.dart';
import 'package:open_epub_engine/src/domain/entity/epub_metadata.dart';
import 'package:open_epub_engine/src/domain/entity/epub_outline.dart';
import 'package:open_epub_engine/src/domain/entity/epub_spine_item.dart';
import 'package:open_epub_engine/src/domain/usecase/apply_patches_use_case.dart';

class _FakeBook implements EpubBook {
  const _FakeBook({
    this.metadata = const EpubMetadata(title: 't', epubVersion: '3.0'),
  });

  @override
  final EpubMetadata metadata;
  @override
  List<EpubSpineItem> get spine => const <EpubSpineItem>[];
  @override
  EpubOutline get outline => EpubOutline.empty;
  @override
  EpubLayout get layout => metadata.layout;
}

/// 항상 적용되는 fake patch (impact 기록).
class _TagPatch implements EpubPatch {
  const _TagPatch(this.patchId, this.severity);
  @override
  final String patchId;
  @override
  final PatchSeverity severity;
  @override
  String get description => 'fake $patchId';
  @override
  PatchResult? apply(EpubBook book) => PatchResult(
      book: PatchedEpubBook.from(book), impact: {'applied': patchId});
}

/// 절대 적용되지 않는 patch.
class _NoopPatch implements EpubPatch {
  const _NoopPatch();
  @override
  String get patchId => 'noop';
  @override
  String get description => 'never applies';
  @override
  PatchSeverity get severity => PatchSeverity.info;
  @override
  PatchResult? apply(EpubBook book) => null;
}

/// 직전 결과 book을 입력으로 받아 title에 `*`를 덧붙인다(체이닝 검증용).
class _StarPatch implements EpubPatch {
  const _StarPatch();
  @override
  String get patchId => 'star';
  @override
  String get description => 'append star';
  @override
  PatchSeverity get severity => PatchSeverity.info;
  @override
  PatchResult? apply(EpubBook book) => PatchResult(
        book: PatchedEpubBook.from(book).copyWith(
          metadata: EpubMetadata(
            title: '${book.metadata.title}*',
            epubVersion: book.metadata.epubVersion,
          ),
        ),
      );
}

class _TestCatalog extends PatchCatalog {
  const _TestCatalog(this.patches);
  final List<EpubPatch> patches;
  @override
  List<EpubPatch> get all => patches;
}

void main() {
  group('PatchCatalog.all', () {
    const catalog = PatchCatalog();

    test('5종 patch 등록 (raw-레벨 2종·image-only-fxl 제외)', () {
      final ids = catalog.all.map((p) => p.patchId).toList();
      expect(
        ids,
        containsAll([
          'sparse-ncx',
          'cover-skip',
          'broken-spine-href',
          'mixed-href-encoding',
          'empty-toc',
        ]),
      );
      expect(ids.length, 5);
      expect(ids, isNot(contains('image-only-fxl')));
      // raw-레벨 보정은 EpubRepositoryImpl이 진단을 직접 기록(카탈로그 제외).
      expect(ids, isNot(contains('missing-mimetype')));
      expect(ids, isNot(contains('invalid-rendition-layout')));
    });

    test('patchId 중복 없음', () {
      final ids = catalog.all.map((p) => p.patchId).toList();
      expect(ids.toSet().length, ids.length);
    });
  });

  group('ApplyPatchesUseCase — 순회/집계', () {
    test('기본 카탈로그 patch는 정상 EPUB에 적용되지 않음 (no-op)', () {
      const usecase = ApplyPatchesUseCase();
      final result = usecase.call(const _FakeBook());
      expect(result.diagnostics.appliedPatches, isEmpty);
      expect(
        (result.diagnostics as BookSessionDiagnosticsData).isClean,
        isTrue,
      );
      expect(result.book, isA<EpubBook>());
    });

    test('적용된 patch만 진단에 기록 (no-op 제외)', () {
      const usecase = ApplyPatchesUseCase(
        catalog: _TestCatalog([
          _TagPatch('a', PatchSeverity.low),
          _NoopPatch(),
          _TagPatch('b', PatchSeverity.high),
        ]),
      );
      final ids = usecase
          .call(const _FakeBook())
          .diagnostics
          .appliedPatches
          .map((p) => p.patchId)
          .toList();
      expect(ids, ['a', 'b']);
    });

    test('AppliedPatch에 severity/impact 보존', () {
      const usecase = ApplyPatchesUseCase(
        catalog: _TestCatalog([_TagPatch('sparse-ncx', PatchSeverity.medium)]),
      );
      final applied =
          usecase.call(const _FakeBook()).diagnostics.appliedPatches.single;
      expect(applied.patchId, 'sparse-ncx');
      expect(applied.severity, PatchSeverity.medium);
      expect(applied.impact, {'applied': 'sparse-ncx'});
    });

    test('앞 patch 결과 book이 다음 patch 입력으로 체이닝', () {
      const usecase = ApplyPatchesUseCase(
        catalog: _TestCatalog([_StarPatch(), _StarPatch()]),
      );
      final result = usecase.call(const _FakeBook());
      expect(result.book.metadata.title, 't**');
    });
  });

  group('BookSessionDiagnostics — JSON', () {
    test('toJson 유효 JSON + patchId/severity/issue 포함', () {
      const diag = BookSessionDiagnosticsData(
        appliedPatches: [
          AppliedPatch(
            patchId: 'cover-skip',
            description: 'd',
            severity: PatchSeverity.low,
            impact: {'k': 1},
          ),
        ],
        unresolvedIssues: [
          UnresolvedIssue(code: 'sec', message: 'blocked'),
        ],
      );
      final decoded = jsonDecode(diag.toJson()) as Map<String, Object?>;
      final patch = (decoded['appliedPatches'] as List).single as Map;
      expect(patch['patchId'], 'cover-skip');
      expect(patch['severity'], 'low');
      expect(patch['impact'], {'k': 1});
      final issue = (decoded['unresolvedIssues'] as List).single as Map;
      expect(issue['code'], 'sec');
      expect(diag.isClean, isFalse);
    });

    test('빈 진단은 isClean + 빈 배열 JSON', () {
      const diag = BookSessionDiagnosticsData();
      expect(diag.isClean, isTrue);
      expect(
        jsonDecode(diag.toJson()),
        {'appliedPatches': <Object?>[], 'unresolvedIssues': <Object?>[]},
      );
    });
  });

  group('PatchedEpubBook', () {
    test('from + copyWith 부분 변형 (나머지 필드 유지)', () {
      const original = _FakeBook(
        metadata: EpubMetadata(
          title: 'A',
          epubVersion: '3.0',
          layout: EpubLayout.fixedLayout,
        ),
      );
      final patched = PatchedEpubBook.from(original);
      expect(patched.metadata.title, 'A');
      expect(patched.layout, EpubLayout.fixedLayout);

      final changed = patched.copyWith(outline: const EpubOutline(items: []));
      expect(changed.metadata.title, 'A'); // 유지
      expect(changed.layout, EpubLayout.fixedLayout); // metadata 위임 유지
    });
  });
}

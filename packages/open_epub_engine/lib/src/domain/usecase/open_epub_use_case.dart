// Domain UseCase — open_epub 1.0
// Story: S1.21 (#37) — 책 열기 오케스트레이션
// BDD: F1 (EPUB 책 열기), F9 (보정 + 진단)
//
// Repository(raw EpubBook 조립) → ApplyPatchesUseCase(호환성 보정 + 진단) 순서로
// 호출하여 [LoadedEpub]을 산출한다.

import '../../api/epub_source.dart';
import '../../data/compat/patch_catalog.dart' show BookSessionDiagnosticsData;
import '../entity/loaded_epub.dart';
import '../repository/epub_repository.dart';
import 'apply_patches_use_case.dart';

class OpenEpubUseCase {
  OpenEpubUseCase(this._repository, {ApplyPatchesUseCase? patcher})
      : _patcher = patcher ?? const ApplyPatchesUseCase();

  final EpubRepository _repository;
  final ApplyPatchesUseCase _patcher;

  Future<LoadedEpub> call(EpubSource source) async {
    final raw = await _repository.load(source);
    final result = _patcher.call(raw.book);
    // raw-레벨 진단(repository) + EpubBook 보정 진단(patcher)을 병합.
    final diagnostics = BookSessionDiagnosticsData(
      appliedPatches: [...raw.patches, ...result.diagnostics.appliedPatches],
      unresolvedIssues: result.diagnostics.unresolvedIssues,
    );
    return LoadedEpub(
      book: result.book,
      diagnostics: diagnostics,
      resources: raw.resources,
      navigation: raw.navigation,
      capabilities: raw.capabilities,
    );
  }
}

// Domain UseCase — open_epub 1.0
// Story: S1.21 (#37) — 책 열기 오케스트레이션
// BDD: F1 (EPUB 책 열기), F9 (보정 + 진단)
//
// Repository(raw EpubBook 조립) → ApplyPatchesUseCase(호환성 보정 + 진단) 순서로
// 호출하여 [LoadedEpub]을 산출한다.

import '../../api/epub_source.dart';
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
    final result = _patcher.call(raw);
    return LoadedEpub(book: result.book, diagnostics: result.diagnostics);
  }
}

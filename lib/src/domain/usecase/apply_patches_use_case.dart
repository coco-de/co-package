// Domain UseCase — open_epub 1.0
// Story: S1.14 — 보정 카탈로그 순회 적용 + 진단 집계
// BDD: F9 (호환성 보정 + 진단)
//
// 개별 patch 로직은 S1.15~S1.18에서 구현한다(현재 카탈로그 patch는 no-op).

import '../../data/compat/patch_catalog.dart';

/// [PatchCatalog]의 모든 보정을 등록 순서대로 적용하고 진단을 집계한다.
///
/// 각 patch는 직전 patch의 결과 book을 입력으로 받아 누적 변형된다(체이닝).
/// 적용되지 않은 patch(`apply` → null)는 진단에 기록되지 않는다.
class ApplyPatchesUseCase {
  const ApplyPatchesUseCase({PatchCatalog catalog = const PatchCatalog()})
      : _catalog = catalog;

  final PatchCatalog _catalog;

  ApplyPatchesResult call(EpubBook book) {
    var current = book;
    final applied = <AppliedPatch>[];

    for (final patch in _catalog.all) {
      final result = patch.apply(current);
      if (result == null) continue;
      current = result.book;
      applied.add(
        AppliedPatch(
          patchId: patch.patchId,
          description: patch.description,
          severity: patch.severity,
          impact: result.impact,
        ),
      );
    }

    return ApplyPatchesResult(
      book: current,
      diagnostics: BookSessionDiagnosticsData(appliedPatches: applied),
    );
  }
}

/// [ApplyPatchesUseCase]의 결과 — 보정된 book + 진단.
class ApplyPatchesResult {
  const ApplyPatchesResult({required this.book, required this.diagnostics});

  final EpubBook book;
  final BookSessionDiagnostics diagnostics;
}

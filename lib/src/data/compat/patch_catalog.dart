// Data Compat — open_epub 1.0
// Status: SCAFFOLD STUB. Implementation deferred to Story S1.14.
// BDD: F9 (보정 카탈로그 + 진단)

/// 보정 가능한 모든 patch의 등록부. OCP 적용 — 새 patch 추가만, 기존 수정 없음.
class PatchCatalog {
  const PatchCatalog();

  List<EpubPatch> get all => throw UnimplementedError('S1.14');
}

abstract class EpubPatch {
  String get patchId; // "sparse-ncx" | "cover-skip" | ...
  String get description;
  PatchSeverity get severity;
}

enum PatchSeverity { low, medium, high }

class AppliedPatch {
  const AppliedPatch({
    required this.patchId,
    required this.description,
    required this.severity,
    required this.impact,
  });

  final String patchId;
  final String description;
  final PatchSeverity severity;
  final String impact; // 사람이 읽는 영향 설명
}

abstract class BookSessionDiagnostics {
  List<AppliedPatch> get appliedPatches;
  List<String> get unresolvedIssues;
  String toJson();
}

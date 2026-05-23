// Compat Patch — open_epub 1.0
// Status: SCAFFOLD STUB. Implementation deferred to Story S1.15.
// BDD: F4.3 (sparse-NCX 자동 보정), F9 (진단 기록)

import '../patch_catalog.dart';

class SparseNcxPatch implements EpubPatch {
  const SparseNcxPatch();
  @override
  String get patchId => 'sparse-ncx';
  @override
  String get description => 'NCX 누락된 spine 항목을 목차에 자동 추가';
  @override
  PatchSeverity get severity => PatchSeverity.medium;
}

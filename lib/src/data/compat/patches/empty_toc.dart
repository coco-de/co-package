// Compat Patch — open_epub 1.0
// Status: SCAFFOLD STUB. Implementation deferred to Story S1.18.
// BDD: F4.4, F9 (empty-toc → spine 기반 fallback)

import '../patch_catalog.dart';

class EmptyTocPatch implements EpubPatch {
  const EmptyTocPatch();
  @override
  String get patchId => 'empty-toc';
  @override
  String get description => 'NCX/nav 모두 비어 있을 때 spine 기반 자동 목차 생성';
  @override
  PatchSeverity get severity => PatchSeverity.high;
}

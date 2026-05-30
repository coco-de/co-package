// Compat Patch — open_epub 1.0
// Status: SCAFFOLD STUB. Implementation deferred to Story S1.18.
// BDD: F9.2 (missing-mimetype 보정)

import '../patch_catalog.dart';

class MissingMimetypePatch implements EpubPatch {
  const MissingMimetypePatch();
  @override
  String get patchId => 'missing-mimetype';
  @override
  String get description => 'mimetype 파일 누락 시 EPUB로 가정하여 진행';
  @override
  PatchSeverity get severity => PatchSeverity.low;

  @override
  PatchResult? apply(EpubBook book) => null; // 보정 로직은 S1.18에서 구현
}

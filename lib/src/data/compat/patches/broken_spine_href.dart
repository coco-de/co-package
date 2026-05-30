// Compat Patch — open_epub 1.0
// Status: SCAFFOLD STUB. Implementation deferred to Story S1.17.
// BDD: F9.2 (broken-spine-href 보정)

import '../patch_catalog.dart';

class BrokenSpineHrefPatch implements EpubPatch {
  const BrokenSpineHrefPatch();
  @override
  String get patchId => 'broken-spine-href';
  @override
  String get description => 'spine href가 manifest/OPF에 없는 경우 제거';
  @override
  PatchSeverity get severity => PatchSeverity.high;

  @override
  PatchResult? apply(EpubBook book) => null; // 보정 로직은 S1.17에서 구현
}

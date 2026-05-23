// Compat Patch — open_epub 1.0
// Status: SCAFFOLD STUB. Implementation deferred to Story S1.16.
// BDD: F9.2 (cover-skip 보정)

import '../patch_catalog.dart';

class CoverSkipPatch implements EpubPatch {
  const CoverSkipPatch();
  @override
  String get patchId => 'cover-skip';
  @override
  String get description => 'spine[0]이 cover 메타인 경우 본문에서 제외';
  @override
  PatchSeverity get severity => PatchSeverity.low;
}

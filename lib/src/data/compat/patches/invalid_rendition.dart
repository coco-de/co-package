// Compat Patch — open_epub 1.0
// Status: SCAFFOLD STUB. Implementation deferred to Story S1.18.
// BDD: F9 (invalid-rendition-layout 보정)

import '../patch_catalog.dart';

class InvalidRenditionPatch implements EpubPatch {
  const InvalidRenditionPatch();
  @override
  String get patchId => 'invalid-rendition-layout';
  @override
  String get description => 'rendition:layout 값이 비표준일 때 reflowable로 fallback';
  @override
  PatchSeverity get severity => PatchSeverity.medium;
}

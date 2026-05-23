// Compat Patch — open_epub 1.0
// Status: SCAFFOLD STUB. Implementation deferred to Story S1.18.
// BDD: F9 (mixed href encoding 보정)

import '../patch_catalog.dart';

class MixedHrefEncodingPatch implements EpubPatch {
  const MixedHrefEncodingPatch();
  @override
  String get patchId => 'mixed-href-encoding';
  @override
  String get description => 'href의 percent-encoding 정규화';
  @override
  PatchSeverity get severity => PatchSeverity.low;
}

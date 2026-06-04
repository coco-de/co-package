// Compat Patch — open_epub 1.0
// Story: S1.18 (#34) — missing-mimetype 보정 — 현 모델 한계로 보류(no-op)
// BDD: F9.2 (missing-mimetype 보정)
//
// 한계: mimetype 파일 유무는 ZIP 컨테이너 레벨 정보이며 EpubBook(메타/spine/목차)에는
// 존재하지 않는다. 올바른 위치는 EpubRepositoryImpl이 ZIP 해제 직후 mimetype 부재를
// 감지해 진단으로 기록하는 것. 보정 파이프라인이 EpubBook만 받는 현 설계로는 구현이
// 불가능하므로 no-op으로 둔다(#34).

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
  PatchResult? apply(EpubBook book) => null; // ZIP 레벨 정보 필요 — 보류
}

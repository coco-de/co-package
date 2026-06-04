// Compat Patch — open_epub 1.0
// Story: S1.18 (#34) — invalid-rendition-layout 보정 — 현 모델 한계로 보류(no-op)
// BDD: F9 (invalid-rendition-layout 보정)
//
// 한계: 비표준 rendition:layout 감지는 OPF 원문 값이 필요하나, OpfParser가
// 파싱 단계에서 이미 비표준 값을 EpubLayout.reflowable로 fallback하므로
// EpubBook(메타/spine/목차) 입력만으로는 "원래 비표준이었는지"를 알 수 없다.
// 올바른 위치는 OpfParser가 fallback 시 진단을 직접 기록하거나, 보정 파이프라인이
// raw OPF 컨텍스트를 받도록 확장하는 것. 해당 설계 결정 전까지 no-op으로 둔다(#34).

import '../patch_catalog.dart';

class InvalidRenditionPatch implements EpubPatch {
  const InvalidRenditionPatch();
  @override
  String get patchId => 'invalid-rendition-layout';
  @override
  String get description => 'rendition:layout 값이 비표준일 때 reflowable로 fallback';
  @override
  PatchSeverity get severity => PatchSeverity.medium;

  @override
  PatchResult? apply(EpubBook book) => null; // raw OPF 컨텍스트 필요 — 보류
}

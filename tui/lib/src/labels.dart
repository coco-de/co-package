import 'gh.dart';

/// CSV를 trim된 · 중복 없는 라벨 리스트로 분리한다.
List<String> splitLabelsCsv(String csv) {
  final seen = <String>{};
  final out = <String>[];
  for (final part in csv.split(',')) {
    final label = part.trim();
    if (label.isNotEmpty && seen.add(label)) out.add(label);
  }
  return out;
}

/// 라벨 피커(`l` 키)에 올릴 후보 라벨 — 스코프의 러너들이 쓰는 커스텀 라벨의
/// 합집합을 이름순으로 정렬한 것.
///
/// 다른 러너가 이미 쓰는 라벨을 그대로 골라 붙일 수 있게 하는 게 목적이다.
/// [target]의 read-only 라벨은 제외한다 — 다른 러너에서 커스텀이더라도
/// [target]에서 read-only면 라벨 API가 거부하므로 고를 수 있게 두면 안 된다.
List<String> pickerLabels(Iterable<RunnerInfo> runners, RunnerInfo target) {
  final labels = <String>{
    for (final r in runners) ...r.customLabels,
    ...target.customLabels,
  }..removeAll(target.readOnlyLabels);
  return labels.toList()..sort();
}

/// [requested]를 (편집 가능 라벨, read-only라 건너뛸 라벨)로 나눈다.
///
/// GitHub는 `self-hosted`·OS·아키텍처 등 read-only 라벨의 추가/삭제를
/// 커스텀 라벨 API에서 거부하므로 호출 전에 걸러낸다.
(List<String> editable, List<String> skipped) splitEditableLabels(
  List<String> requested,
  Set<String> readOnly,
) {
  final editable = <String>[];
  final skipped = <String>[];
  for (final label in requested) {
    (readOnly.contains(label) ? skipped : editable).add(label);
  }
  return (editable, skipped);
}

/// 러너 라벨 편집(`l` 키) 입력을 해석한 결과.
sealed class LabelEdit {
  const LabelEdit(this.labels);
  final List<String> labels;
}

/// `+a,b` — 기존 라벨을 유지한 채 [labels]를 추가.
final class LabelAdd extends LabelEdit {
  const LabelAdd(super.labels);
}

/// `-a,b` — [labels]를 커스텀 라벨에서 제거.
final class LabelRemove extends LabelEdit {
  const LabelRemove(super.labels);
}

/// CSV — 커스텀 라벨 전체를 [labels]로 교체. 빈 리스트면 전체 삭제.
final class LabelReplace extends LabelEdit {
  const LabelReplace(super.labels);
}

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

/// 라벨 프롬프트 입력을 편집 명령으로 해석한다.
///
/// `+` 접두는 추가, `-` 접두는 삭제, 그 외는 전체 교체(빈 입력 = 전체 삭제).
LabelEdit parseLabelInput(String raw) {
  final trimmed = raw.trim();
  if (trimmed.startsWith('+')) {
    return LabelAdd(splitLabelsCsv(trimmed.substring(1)));
  }
  if (trimmed.startsWith('-')) {
    return LabelRemove(splitLabelsCsv(trimmed.substring(1)));
  }
  return LabelReplace(splitLabelsCsv(trimmed));
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

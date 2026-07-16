import 'scope.dart';

/// register-runner.sh에 넘길 인자를 조립한다.
///
/// [dir]은 항상 `--dir`로 명시한다 (스크립트 기본값에 암묵적으로 기대지 않음).
/// [name]/[labels]가 비어있지 않으면 각각 `--name`/`--labels`로 전달해
/// 스크립트의 기본값(호스트명 기반 이름 · 기본 라벨)을 덮어쓴다.
List<String> registerArgs(
  Scope scope,
  String dir, {
  String? name,
  String? labels,
}) =>
    [
      ...scope.scriptArgs,
      '--dir',
      dir,
      if (name != null && name.isNotEmpty) ...['--name', name],
      if (labels != null && labels.isNotEmpty) ...['--labels', labels],
    ];

/// 이름/라벨 직접 입력 프롬프트(`A` 키)의 텍스트를 `(name, labels)`로 분리한다.
///
/// 형식: `이름[ 라벨1,라벨2,...]` — 첫 공백 앞은 이름, 뒤는 라벨 CSV.
/// 빈 입력이면 `(null, null)`을 반환해 register-runner.sh의 기본값을 쓰도록 한다.
(String? name, String? labels) parseRegisterInput(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return (null, null);

  final spaceIdx = trimmed.indexOf(RegExp(r'\s+'));
  if (spaceIdx == -1) return (trimmed, null);

  final name = trimmed.substring(0, spaceIdx);
  final labels = trimmed.substring(spaceIdx).trim();
  return (name.isEmpty ? null : name, labels.isEmpty ? null : labels);
}

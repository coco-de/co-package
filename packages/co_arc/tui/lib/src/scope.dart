import 'dart:convert';
import 'dart:io';

/// 러너 조회/등록 대상 스코프 — org 전체 또는 단일 repo.
final class Scope {
  const Scope.org(this.name) : isOrg = true;
  const Scope.repo(this.name) : isOrg = false;

  final bool isOrg;

  /// org 이름(`coco-de`) 또는 `owner/repo` 전체 이름.
  final String name;

  /// `/`가 포함되면 repo, 아니면 org로 해석.
  factory Scope.parse(String s) =>
      s.contains('/') ? Scope.repo(s) : Scope.org(s);

  String get apiBase => isOrg ? 'orgs/$name' : 'repos/$name';

  String get label => isOrg ? 'org $name' : 'repo $name';

  /// scripts/register-runner.sh · remove-runner.sh 에 넘길 인자.
  List<String> get scriptArgs => [isOrg ? '--org' : '--repo', name];

  Map<String, dynamic> toJson() =>
      {'type': isOrg ? 'org' : 'repo', 'name': name};

  static Scope? fromJson(Object? json) {
    if (json is! Map) return null;
    final name = json['name'];
    if (name is! String || name.isEmpty) return null;
    return json['type'] == 'repo' ? Scope.repo(name) : Scope.org(name);
  }
}

/// `~/.config/co-arc/tui.json` 에 저장되는 TUI 설정.
final class TuiConfig {
  TuiConfig({
    required this.scope,
    required this.runnerDir,
    required this.runnersRoot,
  });

  Scope scope;

  /// 현재 추적 중인(마지막으로 등록·조작한) 러너의 설치 경로.
  String runnerDir;

  /// 모든 러너가 이름별 하위 디렉토리로 설치되는 루트(`~/actions`).
  String runnersRoot;

  static String get _path {
    final home = Platform.environment['HOME'] ?? '.';
    return '$home/.config/co-arc/tui.json';
  }

  /// `~/actions` — 러너 설치 루트 기본값.
  static String get defaultRunnersRoot {
    final home = Platform.environment['HOME'] ?? '.';
    return '$home/actions';
  }

  static TuiConfig load() {
    try {
      final raw = File(_path).readAsStringSync();
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final root = (json['runnersRoot'] as String?) ?? defaultRunnersRoot;
      return TuiConfig(
        scope: Scope.fromJson(json['scope']) ?? const Scope.org('coco-de'),
        runnerDir: (json['runnerDir'] as String?) ?? root,
        runnersRoot: root,
      );
    } catch (_) {
      return TuiConfig(
        scope: const Scope.org('coco-de'),
        runnerDir: defaultRunnersRoot,
        runnersRoot: defaultRunnersRoot,
      );
    }
  }

  void save() {
    try {
      final file = File(_path);
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert({
          'scope': scope.toJson(),
          'runnerDir': runnerDir,
          'runnersRoot': runnersRoot,
        }),
      );
    } catch (_) {
      // 설정 저장 실패는 치명적이지 않음
    }
  }
}

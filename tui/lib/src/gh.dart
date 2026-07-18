import 'dart:convert';
import 'dart:io';

import 'scope.dart';

/// GitHub에 등록된 self-hosted 러너 한 대의 정보.
final class RunnerInfo {
  const RunnerInfo({
    required this.id,
    required this.name,
    required this.os,
    required this.status,
    required this.busy,
    required this.labels,
    required this.customLabels,
  });

  final int id;
  final String name;
  final String os;

  /// `online` | `offline`
  final String status;
  final bool busy;

  /// 전체 라벨 (read-only 포함, 표시용).
  final List<String> labels;

  /// `type == custom`인 라벨 — 라벨 API로 편집 가능한 유일한 대상.
  final List<String> customLabels;

  bool get online => status == 'online';

  /// GitHub가 부여한 read-only 라벨 (`self-hosted`, OS, 아키텍처 등).
  Set<String> get readOnlyLabels => {
        for (final l in labels)
          if (!customLabels.contains(l)) l,
      };

  factory RunnerInfo.fromJson(Map<String, dynamic> json) {
    final labels = <String>[];
    final customLabels = <String>[];
    for (final l in (json['labels'] as List? ?? const [])) {
      if (l is! Map || l['name'] is! String) continue;
      final name = l['name'] as String;
      labels.add(name);
      if (l['type'] == 'custom') customLabels.add(name);
    }
    return RunnerInfo(
      id: json['id'] as int,
      name: json['name'] as String? ?? '?',
      os: json['os'] as String? ?? '?',
      status: json['status'] as String? ?? '?',
      busy: json['busy'] as bool? ?? false,
      labels: labels,
      customLabels: customLabels,
    );
  }
}

/// 러너 라벨 API 경로 (`{org|repo}/actions/runners/{id}/labels`).
String runnerLabelsPath(Scope scope, int id) =>
    '${scope.apiBase}/actions/runners/$id/labels';

/// `gh api`에 라벨 배열 본문을 실어 보내는 `-f labels[]=...` 인자.
List<String> labelFieldArgs(List<String> labels) => [
      for (final l in labels) ...['-f', 'labels[]=$l']
    ];

final class GhFailure implements Exception {
  GhFailure(this.message);
  final String message;

  @override
  String toString() => message;
}

/// `gh` CLI를 통한 GitHub Actions runner API 래퍼.
final class GhClient {
  const GhClient();

  Future<ProcessResult> _gh(List<String> args) =>
      Process.run('gh', args, runInShell: false);

  String _errorOf(ProcessResult r) {
    final err = (r.stderr as String).trim();
    final out = (r.stdout as String).trim();
    return err.isNotEmpty ? err : (out.isNotEmpty ? out : 'exit ${r.exitCode}');
  }

  /// 스코프에 등록된 러너 목록 (최대 100대).
  Future<List<RunnerInfo>> fetchRunners(Scope scope) async {
    final r =
        await _gh(['api', '${scope.apiBase}/actions/runners?per_page=100']);
    if (r.exitCode != 0) throw GhFailure(_errorOf(r));
    final json = jsonDecode(r.stdout as String) as Map<String, dynamic>;
    return [
      for (final item in (json['runners'] as List? ?? const []))
        RunnerInfo.fromJson(item as Map<String, dynamic>),
    ]..sort((a, b) => a.name.compareTo(b.name));
  }

  /// GitHub 쪽 러너 등록 삭제. 온라인 상태면 GitHub가 422로 거부한다.
  Future<void> deleteRunner(Scope scope, int id) async {
    final r = await _gh(
        ['api', '-X', 'DELETE', '${scope.apiBase}/actions/runners/$id']);
    if (r.exitCode != 0) throw GhFailure(_errorOf(r));
  }

  /// 커스텀 라벨 전체 교체. 빈 리스트면 커스텀 라벨 전체 삭제.
  /// (read-only 라벨은 GitHub가 항상 유지한다.)
  Future<void> setRunnerLabels(Scope scope, int id, List<String> labels) async {
    final r = await _gh(
      labels.isEmpty
          ? ['api', '-X', 'DELETE', runnerLabelsPath(scope, id)]
          : [
              'api',
              '-X',
              'PUT',
              runnerLabelsPath(scope, id),
              ...labelFieldArgs(labels),
            ],
    );
    if (r.exitCode != 0) throw GhFailure(_errorOf(r));
  }
}

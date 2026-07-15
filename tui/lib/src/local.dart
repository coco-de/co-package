import 'dart:convert';
import 'dart:io';

/// 이 머신에 설치된 러너 에이전트의 스냅샷.
final class LocalStatus {
  const LocalStatus({
    required this.dir,
    required this.configured,
    this.agentName,
    this.gitHubUrl,
    required this.listenerRunning,
    required this.svcInstalled,
    this.workUsage,
  });

  final String dir;

  /// `.runner` 구성 파일이 존재하는지 (config.sh 완료 여부).
  final bool configured;
  final String? agentName;
  final String? gitHubUrl;

  /// Runner.Listener 프로세스가 떠 있는지.
  final bool listenerRunning;

  /// launchd 서비스(plist)가 설치돼 있는지.
  final bool svcInstalled;

  /// `_work` 디렉토리 사용량 (`du -sh`).
  final String? workUsage;

  static LocalStatus empty(String dir) => LocalStatus(
        dir: dir,
        configured: false,
        listenerRunning: false,
        svcInstalled: false,
      );
}

/// 로컬 러너 디렉토리(~/actions-runner) 및 co-arc scripts/ 접근.
final class LocalRunner {
  LocalRunner({required this.dir});

  final String dir;

  Future<LocalStatus> status() async {
    String? agentName;
    String? gitHubUrl;
    var configured = false;

    final runnerFile = File('$dir/.runner');
    if (runnerFile.existsSync()) {
      configured = true;
      try {
        var raw = runnerFile.readAsStringSync();
        if (raw.startsWith('\uFEFF')) raw = raw.substring(1);
        final json = jsonDecode(raw) as Map<String, dynamic>;
        agentName = json['agentName'] as String?;
        gitHubUrl = json['gitHubUrl'] as String?;
      } catch (_) {}
    }

    final pgrep = await Process.run('pgrep', ['-f', 'Runner.Listener']);
    final listenerRunning = pgrep.exitCode == 0;

    var svcInstalled = false;
    final home = Platform.environment['HOME'];
    if (home != null) {
      final agents = Directory('$home/Library/LaunchAgents');
      if (agents.existsSync()) {
        svcInstalled = agents
            .listSync()
            .any((e) => e.path.split('/').last.startsWith('actions.runner.'));
      }
    }

    String? workUsage;
    if (Directory('$dir/_work').existsSync()) {
      final du = await Process.run('du', ['-sh', '$dir/_work']);
      if (du.exitCode == 0) {
        workUsage = (du.stdout as String).trim().split(RegExp(r'\s+')).first;
      }
    }

    return LocalStatus(
      dir: dir,
      configured: configured,
      agentName: agentName,
      gitHubUrl: gitHubUrl,
      listenerRunning: listenerRunning,
      svcInstalled: svcInstalled,
      workUsage: workUsage,
    );
  }

  /// co-arc 레포의 scripts/<name> 경로를 찾는다.
  /// 실행 파일 위치와 현재 디렉토리에서 위로 올라가며 탐색.
  static String? findScript(String name) {
    final starts = <String>{
      File(Platform.script.toFilePath()).parent.path,
      Directory.current.path,
    };
    for (final start in starts) {
      var d = Directory(start);
      for (var i = 0; i < 6; i++) {
        final candidate = File('${d.path}/scripts/$name');
        if (candidate.existsSync()) return candidate.path;
        final parent = d.parent;
        if (parent.path == d.path) break;
        d = parent;
      }
    }
    return null;
  }
}

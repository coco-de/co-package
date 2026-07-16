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

  /// 이 러너([dir])의 Runner.Listener 프로세스가 떠 있는지 (다른 러너의
  /// listener는 세지 않는다 — [LocalRunner.listenerRunningIn] 참고).
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

/// 로컬 러너 디렉토리 및 co-arc scripts/ 접근.
///
/// [root]는 모든 러너가 이름별 하위 디렉토리로 설치되는 루트(`~/actions`)이고,
/// [dir]은 현재 추적 중인(마지막으로 등록·조작한) 러너의 설치 경로다.
final class LocalRunner {
  LocalRunner({required this.dir, String? root}) : root = root ?? defaultRoot;

  final String dir;

  /// 러너 설치 루트. 새 러너는 `<root>/<러너이름>`에 설치된다.
  final String root;

  /// `~/actions` — 루트 미지정 시 기본값.
  static String get defaultRoot {
    final home = Platform.environment['HOME'] ?? '.';
    return '$home/actions';
  }

  /// 러너 이름으로 설치 디렉토리 경로를 만든다 (`<root>/<name>`).
  String dirFor(String name) => '$root/$name';

  /// [dir]만 새 경로로 바꾼 복제본 ([root]는 유지).
  LocalRunner withDir(String newDir) => LocalRunner(dir: newDir, root: root);

  /// [dir]\uC5D0 \uAD6C\uC131\uB41C \uB7EC\uB108\uC758 `.runner`(config.sh\uAC00 \uB0A8\uAE30\uB294 \uAD6C\uC131 \uD30C\uC77C)\uB97C \uC77D\uB294\uB2E4.
  /// \uD30C\uC77C\uC774 \uC5C6\uC73C\uBA74(=\uBBF8\uAD6C\uC131) null, \uC788\uC9C0\uB9CC \uB0B4\uC6A9\uC774 \uAE68\uC84C\uC73C\uBA74 \uD544\uB4DC\uAC00 \uC804\uBD80 null\uC778
  /// \uB808\uCF54\uB4DC \u2014 "\uAD6C\uC131\uB428 + \uC774\uB984 \uBBF8\uC0C1"\uACFC "\uBBF8\uAD6C\uC131"\uC744 \uAD6C\uBD84\uD55C\uB2E4.
  static ({String? agentName, String? gitHubUrl})? readConfig(String dir) {
    final file = File('$dir/.runner');
    if (!file.existsSync()) return null;
    try {
      var raw = file.readAsStringSync();
      if (raw.startsWith('\uFEFF')) raw = raw.substring(1);
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return (
        agentName: json['agentName'] as String?,
        gitHubUrl: json['gitHubUrl'] as String?,
      );
    } catch (_) {
      return (agentName: null, gitHubUrl: null);
    }
  }

  /// GitHub \uBAA9\uB85D\uC5D0 \uB72C [name] \uB7EC\uB108\uAC00 \uC774 \uBA38\uC2E0 \uC5B4\uB514\uC5D0 \uC124\uCE58\uB3FC \uC788\uB294\uC9C0 \uCC3E\uB294\uB2E4. \uC774
  /// \uBA38\uC2E0\uC758 \uB7EC\uB108\uAC00 \uC544\uB2C8\uBA74 null.
  ///
  /// \uC774\uB984\uBCC4 \uB514\uB809\uD1A0\uB9AC(`<root>/<name>`)\uB97C \uBA3C\uC800 \uBCF4\uACE0, \uC5C6\uC73C\uBA74 \uD604\uC7AC \uCD94\uC801 \uC911\uC778
  /// [dir]\uB3C4 \uD655\uC778\uD55C\uB2E4 \u2014 \uC774\uB984\uBCC4 \uC124\uCE58 \uADDC\uCE59\uC774 \uC0DD\uAE30\uAE30 \uC804\uC5D0 \uB4F1\uB85D\uB410\uAC70\uB098 `--dir`\uB85C
  /// \uB2E4\uB978 \uACBD\uB85C\uB97C \uC9C0\uC815\uD55C \uB7EC\uB108\uB294 \uC774\uB984\uACFC \uACBD\uB85C\uAC00 \uB300\uC751\uD558\uC9C0 \uC54A\uAE30 \uB54C\uBB38\uC774\uB2E4.
  ///
  /// \uB514\uB809\uD1A0\uB9AC \uC874\uC7AC\uB9CC \uBCF4\uC9C0 \uC54A\uACE0 `.runner`\uC758 agentName\uC774 [name]\uACFC \uC77C\uCE58\uD558\uB294\uC9C0\uAE4C\uC9C0
  /// \uD655\uC778\uD55C\uB2E4. \uAC19\uC740 \uACBD\uB85C\uC5D0 \uC774\uB984\uC774 \uB2E4\uB978 \uB7EC\uB108\uAC00 \uAD6C\uC131\uB3FC \uC788\uC744 \uC218 \uC788\uACE0, \uADF8 \uC0C1\uD0DC\uB85C
  /// svc.sh\uB97C \uC2E4\uD589\uD558\uBA74 \uC5C9\uB6B1\uD55C \uB7EC\uB108\uB97C \uBA48\uCD94\uAC8C \uB41C\uB2E4.
  String? findDirFor(String name) {
    for (final candidate in <String>{dirFor(name), dir}) {
      if (readConfig(candidate)?.agentName == name) return candidate;
    }
    return null;
  }

  Future<LocalStatus> status() async {
    final config = readConfig(dir);
    final configured = config != null;
    final agentName = config?.agentName;
    final gitHubUrl = config?.gitHubUrl;

    // 머신 전역이 아니라 이 러너([dir])의 listener만 본다 — 이유는
    // [listenerRunningIn] 참고.
    final pgrep = await Process.run('pgrep', ['-lf', 'Runner.Listener']);
    final listenerRunning =
        pgrep.exitCode == 0 && listenerRunningIn(dir, pgrep.stdout as String);

    // 이 러너(agentName)의 plist만 확인한다 — 파일명 접두사(actions.runner.)만
    // 보면 한 머신에 여러 러너를 띄운 멀티 인스턴스 구성(docs/self-hosted-runner.md
    // "여러 인스턴스 운영" 참고)에서 다른 러너의 서비스 설치 여부를 이 러너의
    // 것으로 착각하게 된다.
    var svcInstalled = false;
    final home = Platform.environment['HOME'];
    if (home != null) {
      final agents = Directory('$home/Library/LaunchAgents');
      if (agents.existsSync()) {
        final names = agents.listSync().map((e) => e.path.split('/').last);
        svcInstalled = agentName != null
            ? names.any(
                (n) =>
                    n.startsWith('actions.runner.') &&
                    n.endsWith('.$agentName.plist'),
              )
            : names.any((n) => n.startsWith('actions.runner.'));
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

  /// `pgrep -lf Runner.Listener` 출력([pgrepOutput])에 [dir]에 설치된 러너의
  /// listener가 있는지.
  ///
  /// 머신 전체에서 `Runner.Listener` 프로세스의 존재만 보면, 한 머신에 여러
  /// 러너를 띄운 구성(docs/self-hosted-runner.md "여러 인스턴스 운영")에서 다른
  /// 러너의 listener를 이 러너의 것으로 착각한다. 그러면 [svcSubcommands]가 아직
  /// 떠 있지도 않은 러너에 `stop`을 실행해(`not installed` / `Unload failed`)
  /// 정작 필요한 `install`+`start`로 넘어가지 못한다.
  ///
  /// `run.sh`(run-helper.sh)와 launchd 서비스 모두 listener를
  /// `<설치경로>/bin/Runner.Listener` 절대경로로 실행하므로 이 경로로 매칭한다.
  /// `/bin/Runner.Listener`까지 붙여야 `action-1`이 `action-10`의 listener에
  /// 걸리지 않는다.
  static bool listenerRunningIn(String dir, String pgrepOutput) {
    final needle = '${_canonical(dir)}/bin/Runner.Listener';
    return pgrepOutput.split('\n').any((line) => line.contains(needle));
  }

  /// pgrep 출력의 절대경로와 비교할 수 있도록 [dir]을 정규화한다 (심볼릭 링크
  /// 해석 → 실패 시 절대경로 + 끝 슬래시 제거).
  static String _canonical(String dir) {
    try {
      return Directory(dir).resolveSymbolicLinksSync();
    } catch (_) {
      final abs = Directory(dir).absolute.path;
      return abs.length > 1 ? abs.replaceAll(RegExp(r'/+$'), '') : abs;
    }
  }

  /// `s` 키를 눌렀을 때 실행할 `svc.sh` 서브커맨드 시퀀스를 결정한다.
  ///
  /// [LocalStatus.listenerRunning]을 최우선으로 확인한다 — launchd 서비스든
  /// `./run.sh` 포그라운드든 이 러너의 Runner.Listener가 이미 떠 있다면 무조건
  /// `stop`한다. 여기서 `svcInstalled`가 false라고 해서 바로 `install`+`start`를
  /// 실행하면, 포그라운드로 띄워둔 러너가 아직 살아있는 상태에서 launchd가
  /// 두 번째 Runner.Listener를 띄워 같은 러너 등록/`_work` 디렉토리를 두
  /// 프로세스가 동시에 건드리게 된다.
  ///
  /// 아무 것도 떠 있지 않을 때만(`listenerRunning == false`) `svcInstalled`를
  /// 본다 — 재부팅 등으로 launchd plist가 사라졌거나 애초에 서비스로 등록한
  /// 적이 없다면(`false`) `install`을 먼저 실행한 뒤 `start`하고, 이미
  /// 설치돼 있다면(`true`) `start`만 실행한다.
  static List<String> svcSubcommands(LocalStatus status) {
    if (status.listenerRunning) return const ['stop'];
    if (!status.svcInstalled) return const ['install', 'start'];
    return const ['start'];
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

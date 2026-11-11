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
    this.svcPlistPath,
    this.svcHardened,
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

  /// 이 러너의 launchd plist 경로 ([LocalRunner.plistPathIn]). 경로를 특정하지
  /// 못했으면 null — [svcInstalled]가 true여도(이름 미상 러너의 plist를 이름
  /// 없이 찾아낸 경우) null일 수 있다.
  final String? svcPlistPath;

  /// plist에 크래시 자동 복구(KeepAlive)가 적용돼 있는지. plist가 없거나
  /// 판정하지 못했으면(PlistBuddy 부재 등) null — "적용 안 됨(false)"과
  /// 구분해야 [LocalRunner.hardenAllInstalled]가 헛돌지 않는다.
  final bool? svcHardened;

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

    final plistPath = plistPathIn(dir, agentName);

    return LocalStatus(
      dir: dir,
      configured: configured,
      agentName: agentName,
      gitHubUrl: gitHubUrl,
      listenerRunning: listenerRunning,
      svcInstalled: svcInstalled,
      svcPlistPath: plistPath,
      svcHardened: await isHardened(plistPath),
      workUsage: workUsage,
    );
  }

  /// [dir]에 설치된 러너의 launchd plist 경로. 찾지 못하면 null.
  ///
  /// `svc.sh install`이 설치 시점의 정확한 경로를 `<dir>/.service`에 남기므로
  /// 그 기록을 우선 쓴다 — 이름/스코프로 plist 파일명을 다시 조립하는 것보다
  /// 정확하다(스코프가 org인지 owner/repo인지에 따라 중간 마디가 달라진다).
  /// 기록이 없거나 가리키는 파일이 사라졌으면 `~/Library/LaunchAgents`에서
  /// 이 러너 이름으로 끝나는 plist를 찾는다.
  static String? plistPathIn(String dir, String? agentName) {
    final service = File('$dir/.service');
    if (service.existsSync()) {
      final recorded = service.readAsStringSync().trim();
      if (recorded.isNotEmpty && File(recorded).existsSync()) return recorded;
    }
    if (agentName == null) return null;
    final home = Platform.environment['HOME'];
    if (home == null) return null;
    final agents = Directory('$home/Library/LaunchAgents');
    if (!agents.existsSync()) return null;
    for (final entry in agents.listSync()) {
      final name = entry.path.split('/').last;
      if (name.startsWith('actions.runner.') &&
          name.endsWith('.$agentName.plist')) {
        return entry.path;
      }
    }
    return null;
  }

  static const plistBuddy = '/usr/libexec/PlistBuddy';

  /// launchd plist에 크래시 자동 복구(KeepAlive)를 심는 PlistBuddy 인자.
  ///
  /// 평범한 `KeepAlive: true`가 아니라 `{SuccessfulExit: false}`인 이유: 러너의
  /// `bin/RunnerService.js`는 listener 종료코드를 직접 해석해서 2(retryable)·
  /// 3·4(자체 업데이트)는 스스로 5초 뒤 재기동하고, 0(정상)·1(terminated)·
  /// 5(세션 충돌)는 `stopping = true`로 서비스를 내리며 exit 0으로 끝낸다.
  /// `true`로 걸면 러너가 "멈춰야 한다"고 판단한 상황 — 특히 같은 등록을 두
  /// 프로세스가 잡은 세션 충돌 — 에서 launchd가 무한 재기동시켜 정면 충돌한다.
  /// `SuccessfulExit: false`는 비정상 종료(크래시·OOM·강제 kill)만 되살린다.
  static List<String> keepAliveAddArgs(String plist) => [
    '-c',
    'Add :KeepAlive dict',
    '-c',
    'Add :KeepAlive:SuccessfulExit bool false',
    plist,
  ];

  /// [keepAliveAddArgs] 앞에 실행하는 삭제 인자. `Add`는 키가 이미 있으면
  /// 실패하므로, 먼저 지워야 재적용이 멱등해진다 (키가 없을 때의 Delete
  /// 실패는 정상 경로라 무시한다).
  static List<String> keepAliveDeleteArgs(String plist) => [
    '-c',
    'Delete :KeepAlive',
    plist,
  ];

  static List<String> keepAliveReadArgs(String plist) => [
    '-c',
    'Print :KeepAlive:SuccessfulExit',
    plist,
  ];

  /// [plist]에 이미 하드닝이 적용돼 있는지 ([keepAliveReadArgs]의 stdout 판정).
  static bool keepAliveHardened(String plistBuddyOutput) =>
      plistBuddyOutput.trim() == 'false';

  /// [plist]에 KeepAlive가 적용돼 있는지. plist가 없거나 판정하지 못했으면
  /// null — "적용 안 됨(false)"과 구분해야 판정 실패를 무한 재시도하지 않는다.
  static Future<bool?> isHardened(String? plist) async {
    if (plist == null || !File(plistBuddy).existsSync()) return null;
    try {
      final read = await Process.run(plistBuddy, keepAliveReadArgs(plist));
      // 키 자체가 없으면 PlistBuddy가 non-zero로 끝난다 = 적용 안 됨.
      return read.exitCode == 0 && keepAliveHardened(read.stdout as String);
    } catch (_) {
      return null;
    }
  }

  /// [plist]에 KeepAlive를 실제로 써 넣는다. 성공하면 null, 실패하면 사유.
  ///
  /// 종료코드만 믿지 않고 쓴 값을 되읽어 확인한다 — PlistBuddy는 파일 저장에
  /// 실패해도(권한 없음 등) **exit 0으로 끝나고** 사유를 stderr에만 남긴다.
  /// 그대로 두면 아무것도 안 바뀐 러너를 "적용 완료"로 보고하게 되고, 사용자는
  /// 재부팅한 뒤에야 크래시 복구가 없다는 걸 알게 된다.
  static Future<String?> _applyKeepAlive(String plist) async {
    try {
      await Process.run(plistBuddy, keepAliveDeleteArgs(plist));
      final add = await Process.run(plistBuddy, keepAliveAddArgs(plist));
      final stderr = (add.stderr as String).trim();
      if (add.exitCode != 0) {
        return stderr.isEmpty ? 'exit ${add.exitCode}' : stderr;
      }
      if (await isHardened(plist) == true) return null;
      return stderr.isEmpty ? '적용 후 확인 실패' : stderr;
    } catch (e) {
      return '$e';
    }
  }

  /// [plist]에 KeepAlive 하드닝을 적용하고 로그 줄을 돌려준다 (멱등 — 이미
  /// 적용돼 있으면 파일을 건드리지 않고 빈 목록).
  ///
  /// 서비스를 켜는 경로(`s`)에서 `svc.sh start`(=`launchctl load`) **직전에**
  /// 부른다. 이미 떠 있는 러너에 적용하는 건 [hardenAllInstalled] 몫이다.
  static Future<List<String>> hardenPlist(String? plist) async {
    if (plist == null) {
      return const ['launchd plist를 찾지 못해 KeepAlive 설정을 건너뜁니다'];
    }
    if (!File(plistBuddy).existsSync()) {
      return const ['PlistBuddy가 없어 KeepAlive 설정을 건너뜁니다'];
    }
    if (await isHardened(plist) == true) return const [];
    final error = await _applyKeepAlive(plist);
    return [
      error == null
          ? 'KeepAlive(SuccessfulExit=false) 적용 — 비정상 종료 시 launchd가 러너를 되살립니다'
          : 'KeepAlive 설정 실패 — 크래시 자동 복구 없이 진행합니다 ($error)',
    ];
  }

  /// 이 머신에 구성된 러너 **전부**의 plist에 KeepAlive를 심는다 (멱등).
  ///
  /// 서비스를 껐다 켜지 않고 **파일만** 고친다. launchd는 로드 시점에 plist를
  /// 읽으므로 이미 떠 있는 러너의 동작은 그대로고, 다음 로드(재부팅·로그인·
  /// 서비스 재시작)부터 KeepAlive가 붙는다. 이 설정의 목적이 재부팅·크래시
  /// 이후의 복귀라서, 잡을 돌리는 중일지 모르는 서비스를 지금 내렸다 올릴
  /// 이유가 없다 — 무중단으로 적용하고 효력은 다음 로드로 넘긴다.
  ///
  /// (`svc.sh start`는 `launchctl load -w`만 하고 plist를 다시 만들지 않으며,
  /// `-w`도 파일이 아니라 launchd의 override DB에 쓴다. 그래서 제자리 수정이
  /// 다음 로드까지 안전하게 남는다.)
  ///
  /// 이미 적용된 러너와 서비스로 등록되지 않은 러너는 건너뛴다. 실제로 바뀐
  /// 게 없으면 빈 목록 — 로그 패널을 매번 같은 줄로 채우지 않는다.
  Future<List<String>> hardenAllInstalled() async {
    if (!File(plistBuddy).existsSync()) return const [];

    final applied = <String>[];
    final failed = <String>[];
    for (final runnerDir in configuredDirs()) {
      final name = readConfig(runnerDir)?.agentName;
      final plist = plistPathIn(runnerDir, name);
      if (plist == null) continue; // 서비스 미등록 — 켤 때 심는다
      // false(=적용 안 됨)일 때만 손댄다. null(판정 실패)은 건너뛰어야
      // 갱신 때마다 같은 실패를 반복하지 않는다.
      if (await isHardened(plist) != false) continue;

      final label = name ?? runnerDir.split('/').last;
      final error = await _applyKeepAlive(plist);
      if (error == null) {
        applied.add(label);
      } else {
        failed.add('$label($error)');
      }
    }

    return [
      if (applied.isNotEmpty)
        'KeepAlive 적용: ${applied.join(', ')} — 실행 중인 러너는 다음 서비스 '
            '로드(재부팅·s 재시작)부터 유효',
      if (failed.isNotEmpty) 'KeepAlive 적용 실패: ${failed.join(', ')}',
    ];
  }

  /// 이 머신에 구성된(=`.runner`가 있는) 러너 설치 경로 전부.
  ///
  /// 이름별 디렉토리(`<root>/<이름>`)를 훑고 추적 중인 [dir]도 포함한다 —
  /// 이름별 설치 규칙이 생기기 전에 등록했거나 `--dir`로 다른 경로를 지정한
  /// 러너는 root 아래에 없다 ([findDirFor]가 두 곳을 보는 것과 같은 이유).
  List<String> configuredDirs() {
    final dirs = <String>{};
    final rootDir = Directory(root);
    if (rootDir.existsSync()) {
      for (final entry in rootDir.listSync().whereType<Directory>()) {
        if (readConfig(entry.path) != null) dirs.add(entry.path);
      }
    }
    if (readConfig(dir) != null) dirs.add(dir);
    return dirs.toList()..sort();
  }

  /// `pmset -g custom` 출력에서 AC 전원 구간의 [key] 값을 읽는다.
  ///
  /// 배터리 구간에도 같은 키가 있어서 구간을 구분해야 한다 — 러너는 전원이
  /// 연결된 상태를 전제하므로 AC 값만 본다. 기종이 지원하지 않는 키(예:
  /// 노트북의 `autorestart`)는 출력에 아예 없으므로 null.
  static String? pmsetAcValue(String output, String key) {
    var inAc = false;
    for (final line in output.split('\n')) {
      // 구간 머리글(`AC Power:`)만 열 0에서 시작하고 설정 줄은 들여쓰기돼 있다.
      if (!line.startsWith(' ')) {
        inAc = line.startsWith('AC Power');
        continue;
      }
      if (!inAc) continue;
      // 설정 줄은 `키 값` 두 토큰이다. `Sleep On Power Button 1`처럼 이름에
      // 공백이 들어간 줄을 값으로 잘못 읽지 않도록 토큰 수까지 본다.
      final parts = line.trim().split(RegExp(r'\s+'));
      if (parts.length == 2 && parts.first == key) return parts[1];
    }
    return null;
  }

  /// 서비스는 켰지만 "재부팅하면 알아서 돌아온다"를 막는 머신 레벨 조건을
  /// 사람이 읽을 경고 줄로 만든다. 문제가 없으면 빈 목록.
  ///
  /// 여기서 자동으로 고치지 않는 이유: 전부 sudo가 필요하고, FileVault 해제는
  /// 디스크 전체 복호화라는 비가역 작업이다. 러너 하나 서비스로 켜는
  /// 부수효과로 머신 정책을 바꿀 일이 아니라서, 무엇이 막고 있는지와 명령만
  /// 알려준다. (같은 판정을 scripts/register-runner.sh의
  /// `boot_readiness_report`가 등록 경로에서 수행한다.)
  static List<String> bootWarnings({
    required String? autoLoginUser,
    required String fileVaultStatus,
    required String pmsetCustom,
  }) {
    final warnings = <String>[];

    // LaunchAgent는 '부팅 시'가 아니라 'GUI 로그인 시' 로드된다 — 로그인
    // 세션이 자동으로 생기지 않으면 재부팅 후 러너는 계속 오프라인이다.
    if (autoLoginUser == null || autoLoginUser.trim().isEmpty) {
      warnings.add(
        fileVaultStatus.contains('FileVault is On')
            ? '⚠️ 자동 로그인 꺼짐 + FileVault On — 재부팅 후 잠금해제(=로그인) 전까지 러너가 뜨지 않습니다 '
                  '(무인 재부팅: sudo fdesetup authrestart)'
            : '⚠️ 자동 로그인 꺼짐 — 재부팅 후 로그인해야 러너가 뜹니다 '
                  '(시스템 설정 > 사용자 및 그룹 > 자동 로그인)',
      );
    }

    final sleep = pmsetAcValue(pmsetCustom, 'sleep');
    if (sleep != null && sleep != '0') {
      warnings.add(
        '⚠️ 전원 연결 시 $sleep분 뒤 잠듭니다 — 잠들면 잡이 대기합니다 '
        '(sudo pmset -c sleep 0 disksleep 0)',
      );
    }

    final autorestart = pmsetAcValue(pmsetCustom, 'autorestart');
    if (autorestart != null && autorestart != '1') {
      warnings.add('⚠️ 정전 후 자동 부팅 꺼짐 (sudo pmset -c autorestart 1)');
    }

    return warnings;
  }

  /// 머신 설정을 조회해 [bootWarnings]를 만든다. 조회 자체가 실패한 항목은
  /// 빈 값으로 넘겨 "모름"이 경고를 만들지 않게 한다.
  static Future<List<String>> bootReadiness() async {
    Future<String> run(String exe, List<String> args) async {
      try {
        final r = await Process.run(exe, args);
        return r.exitCode == 0 ? (r.stdout as String) : '';
      } catch (_) {
        return '';
      }
    }

    final autoLogin = await run('defaults', [
      'read',
      '/Library/Preferences/com.apple.loginwindow',
      'autoLoginUser',
    ]);
    return bootWarnings(
      autoLoginUser: autoLogin,
      fileVaultStatus: await run('fdesetup', ['status']),
      pmsetCustom: await run('pmset', ['-g', 'custom']),
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

  /// co_arc 패키지의 `scripts/<name>` 경로를 찾는다.
  /// 실행 파일 위치와 현재 디렉토리에서 위로 올라가며 탐색하며,
  /// co-package 모노레포 루트에서 실행한 경우도 찾을 수 있게
  /// `packages/co_arc/scripts/`도 함께 본다.
  static String? findScript(String name) {
    final starts = <String>{
      File(Platform.script.toFilePath()).parent.path,
      Directory.current.path,
    };
    for (final start in starts) {
      var d = Directory(start);
      for (var i = 0; i < 6; i++) {
        for (final rel in ['scripts/$name', 'packages/co_arc/scripts/$name']) {
          final candidate = File('${d.path}/$rel');
          if (candidate.existsSync()) return candidate.path;
        }
        final parent = d.parent;
        if (parent.path == d.path) break;
        d = parent;
      }
    }
    return null;
  }
}

import 'dart:io';

import 'package:co_arc/co_arc.dart';
import 'package:dart_tui/dart_tui.dart';

const _usage = '''
coarc — co-arc self-hosted 러너 관리 TUI

사용법:
  coarc                        TUI 실행 (마지막 스코프 기억)
  coarc --org coco-de          org 스코프로 실행
  coarc --repo coco-de/<repo>  repo 스코프로 실행
  coarc --root <path>          러너 설치 루트 지정 (기본: ~/actions)
  coarc --dir <path>           추적할 러너 디렉토리 지정 (기본: <root>)
  coarc list                   TUI 없이 러너 목록만 출력

새 러너는 <root>/<러너이름>에 설치됩니다. 이름 미지정 등록(a)은
{컴퓨터이름}-{랜덤공룡} 조합으로 유일한 이름을 만듭니다.
''';

Future<void> main(List<String> args) async {
  final config = TuiConfig.load();
  var listOnly = false;

  for (var i = 0; i < args.length; i++) {
    switch (args[i]) {
      case 'list':
        listOnly = true;
      case '--org' when i + 1 < args.length:
        config.scope = Scope.org(args[++i]);
      case '--repo' when i + 1 < args.length:
        config.scope = Scope.repo(args[++i]);
      case '--root' when i + 1 < args.length:
        config.runnersRoot = args[++i];
      case '--dir' when i + 1 < args.length:
        config.runnerDir = args[++i];
      case '-h' || '--help':
        stdout.write(_usage);
        return;
      default:
        stderr.writeln('알 수 없는 옵션: ${args[i]}\n');
        stderr.write(_usage);
        exitCode = 64;
        return;
    }
  }
  config.save();

  if (listOnly) {
    await _printList(config.scope);
    return;
  }

  if (!stdin.hasTerminal) {
    stderr.writeln('TUI는 터미널에서만 실행할 수 있습니다. (coarc list를 사용하세요)');
    exitCode = 1;
    return;
  }

  await Program(
    options: const ProgramOptions(
      altScreen: true,
      tickInterval: Duration(milliseconds: 100),
    ),
    // application cursor key 모드(DECCKM)에서 방향키가 보내는 SS3(ESC O A~D)를
    // dart_tui가 이해하는 CSI(ESC [ A~D)로 재매핑한다 — 터미널·멀티플렉서가
    // 처음부터 그 모드로 떠 있어도 러너 선택 이동이 죽지 않게.
    programOptions: [withInput(remapSs3ArrowKeys(stdin))],
  ).run(
    AppModel(
      scope: config.scope,
      local: LocalRunner(dir: config.runnerDir, root: config.runnersRoot),
    ),
  );
  // 자동 새로고침 타이머의 Future.delayed가 isolate를 붙잡아
  // 종료가 최대 15초 늦어지는 것을 방지.
  exit(0);
}

Future<void> _printList(Scope scope) async {
  try {
    final runners = await const GhClient().fetchRunners(scope);
    stdout.writeln('${scope.label} — ${runners.length}대');
    if (runners.isEmpty) return;
    final nameWidth = runners
        .map((r) => r.name.length)
        .reduce((a, b) => a > b ? a : b)
        .clamp(4, 40);
    for (final r in runners) {
      final status = r.online ? 'online ' : 'offline';
      final busy = r.busy ? 'busy' : 'idle';
      stdout.writeln(
        '${r.name.padRight(nameWidth)}  $status  $busy  ${r.os.padRight(6)}  ${r.labels.join(',')}',
      );
    }
  } on GhFailure catch (e) {
    stderr.writeln('gh 오류: $e');
    exitCode = 1;
  }
}

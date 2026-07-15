import 'dart:io';

import 'package:coarc_tui/coarc_tui.dart';
import 'package:dart_tui/dart_tui.dart';

const _usage = '''
coarc — co-arc self-hosted 러너 관리 TUI

사용법:
  coarc                        TUI 실행 (마지막 스코프 기억)
  coarc --org coco-de          org 스코프로 실행
  coarc --repo coco-de/<repo>  repo 스코프로 실행
  coarc --dir <path>           러너 디렉토리 지정 (기본: ~/actions-runner)
  coarc list                   TUI 없이 러너 목록만 출력
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
  ).run(AppModel(
    scope: config.scope,
    local: LocalRunner(dir: config.runnerDir),
  ));
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
          '${r.name.padRight(nameWidth)}  $status  $busy  ${r.os.padRight(6)}  ${r.labels.join(',')}');
    }
  } on GhFailure catch (e) {
    stderr.writeln('gh 오류: $e');
    exitCode = 1;
  }
}

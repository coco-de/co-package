import 'dart:io';

import 'package:co_arc/co_arc.dart';
import 'package:test/test.dart';

/// scripts/ 의 셸 스크립트 회귀 검사.
///
/// - 문법(`bash -n`)과 `remove-runner.sh` 의 폴더 정리(`--purge`)는 모든 OS 에서 돈다.
///   gh · config.sh 는 임시 폴더의 가짜 명령으로 바꿔 끼워 진짜 GitHub 는 건드리지 않는다.
/// - `seed-runner-tools.sh` 는 APFS 복제(clonefile)를 쓰므로 macOS 에서만 돈다.
void main() {
  final scriptsDir = _scriptsDir();
  const allScripts = [
    'register-runner.sh',
    'remove-runner.sh',
    'cleanup-work.sh',
    'seed-runner-tools.sh',
  ];

  group('문법', () {
    for (final name in allScripts) {
      test('$name 은 bash -n 을 통과한다', () async {
        final result = await Process.run('bash', ['-n', '$scriptsDir/$name']);
        expect(result.exitCode, 0, reason: '${result.stderr}');
      });
    }
  });

  group('remove-runner.sh', () {
    late Directory tmp;
    late Directory runner;
    late String path;

    setUp(() {
      tmp = Directory.systemTemp.createTempSync('co_arc_remove_');
      runner = Directory('${tmp.path}/actions/runX')
        ..createSync(recursive: true);
      // macOS 의 임시 폴더는 /var → /private/var 심볼릭 링크라, 스크립트가 보는 실제 경로로 맞춘다
      runner = Directory(runner.resolveSymbolicLinksSync());
      File('${runner.path}/.runner').writeAsStringSync('{}');
      File('${runner.path}/.credentials').writeAsStringSync('{}');
      _executable(
        '${runner.path}/config.sh',
        // 가짜 `config.sh remove` — 진짜처럼 등록 정보를 지운다 (FAKE_CONFIG_KEEP=1 이면 남겨 실패를 흉내 낸다)
        '#!/bin/sh\n[ "\${FAKE_CONFIG_KEEP:-0}" = 1 ] || rm -f .runner .credentials\nexit 0\n',
      );
      Directory(
        '${runner.path}/_work/_tool/flutter',
      ).createSync(recursive: true);
      File(
        '${runner.path}/_work/_tool/flutter/sdk.bin',
      ).writeAsBytesSync(List.filled(64 * 1024, 7));
      Directory('${tmp.path}/bin').createSync();
      _executable('${tmp.path}/bin/gh', '#!/bin/sh\necho fake-token\n');
      path = '${tmp.path}/bin:${Platform.environment['PATH']}';
    });

    tearDown(() => tmp.deleteSync(recursive: true));

    Future<ProcessResult> remove(
      List<String> extra, {
      Map<String, String> env = const {},
    }) => Process.run(
      'bash',
      [
        '$scriptsDir/remove-runner.sh',
        '--org',
        'coco-de',
        '--dir',
        runner.path,
        ...extra,
      ],
      environment: {'PATH': path, ...env},
    );

    test('--purge 없이는 폴더를 남기고 남은 크기를 알려 준다', () async {
      final result = await remove([]);

      expect(result.exitCode, 0, reason: '${result.stderr}');
      expect(runner.existsSync(), isTrue);
      expect(File('${runner.path}/.runner').existsSync(), isFalse);
      expect(result.stdout, contains('남아 있습니다'));
      expect(result.stdout, contains('--purge'));
    });

    test('--purge 는 해제가 끝난 뒤 폴더까지 지운다', () async {
      final result = await remove(['--purge']);

      expect(result.exitCode, 0, reason: '${result.stderr}');
      expect(runner.existsSync(), isFalse);
      expect(result.stdout, contains('러너 폴더를 지웠습니다'));
    });

    test('--purge 는 등록 정보가 남아 있으면 지우지 않는다', () async {
      final result = await remove(['--purge'], env: {'FAKE_CONFIG_KEEP': '1'});

      expect(result.exitCode, isNot(0));
      expect(runner.existsSync(), isTrue);
      expect(result.stderr, contains('등록 정보'));
    });

    test('--purge 는 그 폴더를 쓰는 프로세스가 있으면 지우지 않는다', () async {
      // 명령줄에 러너 폴더 경로가 있는 프로세스 — 해제 뒤에도 남은 잡 프로세스를 흉내 낸다.
      // 'sleep 60' 한 줄이면 bash 가 exec 로 sleep 자체가 돼 경로 인자가 명령줄에서 사라지므로 뒤에 ':' 를 붙인다.
      final busy = await Process.start('bash', [
        '-c',
        'sleep 60; :',
        '_',
        '${runner.path}/_work/job',
      ]);
      addTearDown(busy.kill);

      final result = await remove(['--purge']);

      expect(result.exitCode, isNot(0));
      expect(runner.existsSync(), isTrue);
      expect(result.stderr, contains('쓰는 프로세스'));
    });

    test('--purge 는 홈 폴더 자체는 지우지 않는다', () async {
      final result = await remove(['--purge'], env: {'HOME': runner.path});

      expect(result.exitCode, isNot(0));
      expect(runner.existsSync(), isTrue);
      expect(result.stderr, contains('지울 수 없는 경로'));
    });
  });

  group('seed-runner-tools.sh', () {
    late Directory tmp;
    late String src;
    late String dst;

    void write(String path, String body) {
      File(path)
        ..createSync(recursive: true)
        ..writeAsStringSync(body);
    }

    setUp(() {
      tmp = Directory.systemTemp.createTempSync('co_arc_seed_');
      final base = Directory('${tmp.path}/actions')..createSync();
      src = '${base.resolveSymbolicLinksSync()}/src';
      dst = '${base.resolveSymbolicLinksSync()}/dst';
      Directory(dst).createSync(recursive: true);
      final tool = '$src/_work/_tool';
      write(
        '$tool/flutter/stable-1-arm64/flutter/bin/flutter',
        'flutter sdk\n' * 100,
      );
      write('$tool/node/20.0.0/arm64/bin/node', 'node binary\n' * 100);
      write('$tool/Java_Temurin/17/arm64/bin/java', 'java binary\n' * 100);
      write('$tool/Python/3.12/arm64/bin/pip3', '#!$src/python\n');
      write(
        '$tool/flutter-src/stable-1-arm64/x',
        'named after the source runner\n',
      );
      write('$tool/pub-cache-src/hosted/x', 'named after the source runner\n');
      write('$src/_work/repo/checkout.txt', 'a checkout is never seeded\n');
    });

    tearDown(() => tmp.deleteSync(recursive: true));

    Future<ProcessResult> seed(
      List<String> extra, {
      Map<String, String> env = const {},
    }) => Process.run('bash', [
      '$scriptsDir/seed-runner-tools.sh',
      '--from',
      src,
      '--to',
      dst,
      ...extra,
    ], environment: env.isEmpty ? null : env);

    List<String> seededTools() {
      final dir = Directory('$dst/_work/_tool');
      if (!dir.existsSync()) return const [];
      return dir
          .listSync()
          .map((e) => e.uri.pathSegments.where((s) => s.isNotEmpty).last)
          .toList()
        ..sort();
    }

    test('--dry-run 은 가져올 것만 보여 주고 아무것도 만들지 않는다', () async {
      final result = await seed(['--dry-run']);

      expect(result.exitCode, 0, reason: '${result.stderr}');
      expect(result.stdout, contains('[dry] flutter'));
      expect(result.stdout, contains('[dry] node'));
      expect(result.stdout, contains('[dry] Java_Temurin'));
      expect(result.stdout, isNot(contains('Python')));
      expect(Directory('$dst/_work').existsSync(), isFalse);
    });

    test('이식해도 안전한 도구만 복제하고 원본은 그대로 둔다', () async {
      final result = await seed([]);

      expect(result.exitCode, 0, reason: '${result.stderr}');
      expect(seededTools(), ['Java_Temurin', 'flutter', 'node']);
      expect(
        File(
          '$dst/_work/_tool/flutter/stable-1-arm64/flutter/bin/flutter',
        ).readAsStringSync(),
        'flutter sdk\n' * 100,
      );
      // Python(설치 경로가 박힘) · 원본 러너 이름이 붙은 폴더 · 체크아웃은 가져오지 않는다
      expect(Directory('$dst/_work/_tool/Python').existsSync(), isFalse);
      expect(Directory('$dst/_work/_tool/flutter-src').existsSync(), isFalse);
      expect(Directory('$dst/_work/_tool/pub-cache-src').existsSync(), isFalse);
      expect(Directory('$dst/_work/repo').existsSync(), isFalse);
      expect(
        File('$src/_work/_tool/node/20.0.0/arm64/bin/node').existsSync(),
        isTrue,
      );
    });

    test('다시 실행해도 안전하다 — 이미 있는 항목은 건너뛴다', () async {
      await seed([]);
      File(
        '$dst/_work/_tool/node/20.0.0/arm64/bin/node',
      ).writeAsStringSync('새 러너가 고친 파일\n');

      final result = await seed([]);

      expect(result.exitCode, 0, reason: '${result.stderr}');
      expect(result.stdout, contains('이미 있어 건너뜀'));
      expect(result.stdout, isNot(contains('✓'))); // 새로 복제한 항목이 없다
      // 복제본은 원본과 따로 고쳐진다 — 새 러너의 변경이 기존 러너에 번지지 않는다
      expect(
        File('$src/_work/_tool/node/20.0.0/arm64/bin/node').readAsStringSync(),
        'node binary\n' * 100,
      );
      expect(
        File('$dst/_work/_tool/node/20.0.0/arm64/bin/node').readAsStringSync(),
        '새 러너가 고친 파일\n',
      );
    });

    test('SEED_TOOLS 로 가져올 도구를 바꿀 수 있다', () async {
      final result = await seed(
        [],
        env: {...Platform.environment, 'SEED_TOOLS': 'Python'},
      );

      expect(result.exitCode, 0, reason: '${result.stderr}');
      expect(seededTools(), ['Python']);
    });

    test('기존 러너에 _work/_tool 이 없으면 아무것도 하지 않는다', () async {
      Directory('$src/_work/_tool').deleteSync(recursive: true);

      final result = await seed([]);

      expect(result.exitCode, 0, reason: '${result.stderr}');
      expect(result.stdout, contains('가져올 것이 없습니다'));
      expect(seededTools(), isEmpty);
    });
  }, skip: Platform.isMacOS ? false : 'APFS 복제(clonefile)는 macOS 에만 있다');
}

String _scriptsDir() {
  final script = LocalRunner.findScript('seed-runner-tools.sh');
  if (script == null) {
    throw StateError('scripts/seed-runner-tools.sh 를 찾지 못했습니다');
  }
  return File(script).parent.path;
}

void _executable(String path, String body) {
  File(path).writeAsStringSync(body);
  Process.runSync('chmod', ['755', path]);
}

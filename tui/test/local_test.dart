import 'dart:convert';
import 'dart:io';

import 'package:coarc_tui/coarc_tui.dart';
import 'package:test/test.dart';

LocalStatus _status({
  required bool svcInstalled,
  required bool listenerRunning,
}) =>
    LocalStatus(
      dir: '/tmp/runner',
      configured: true,
      listenerRunning: listenerRunning,
      svcInstalled: svcInstalled,
    );

void main() {
  group('LocalRunner.svcSubcommands', () {
    test('실행 중이면(launchd 서비스) 설치 여부와 무관하게 stop', () {
      final status = _status(svcInstalled: true, listenerRunning: true);
      expect(LocalRunner.svcSubcommands(status), ['stop']);
    });

    test(
        '실행 중이면(포그라운드 ./run.sh, 서비스 미설치) 두 번째 listener를 '
        '띄우지 않고 stop만 시도', () {
      final status = _status(svcInstalled: false, listenerRunning: true);
      expect(LocalRunner.svcSubcommands(status), ['stop']);
    });

    test('미실행 + 서비스 설치됨 → start', () {
      final status = _status(svcInstalled: true, listenerRunning: false);
      expect(LocalRunner.svcSubcommands(status), ['start']);
    });

    test(
        '미실행 + 서비스 미설치(재부팅으로 등록이 사라졌거나 등록한 적 없음) '
        '→ install 후 start', () {
      final status = _status(svcInstalled: false, listenerRunning: false);
      expect(LocalRunner.svcSubcommands(status), ['install', 'start']);
    });

    test('LocalStatus.empty()는 미실행+미설치이므로 install+start', () {
      expect(
        LocalRunner.svcSubcommands(LocalStatus.empty('/tmp/runner')),
        ['install', 'start'],
      );
    });
  });

  group('LocalRunner.listenerRunningIn', () {
    const svc = '99170 /Users/me/actions/action-01/bin/Runner.Listener run '
        '--startuptype service';
    const foreground = '92948 /Users/me/actions/action-02/bin/Runner.Listener '
        'run';

    test('이 러너의 listener가 떠 있으면 true (launchd)', () {
      expect(
        LocalRunner.listenerRunningIn('/Users/me/actions/action-01', svc),
        isTrue,
      );
    });

    test('이 러너의 listener가 떠 있으면 true (포그라운드 ./run.sh)', () {
      expect(
        LocalRunner.listenerRunningIn(
            '/Users/me/actions/action-02', '$svc\n$foreground'),
        isTrue,
      );
    });

    test(
        '다른 러너의 listener만 떠 있으면 false — 이게 s 키가 stop을 '
        '잘못 실행하던 원인', () {
      expect(
        LocalRunner.listenerRunningIn('/Users/me/actions/action-99', svc),
        isFalse,
      );
    });

    test('이름이 접두사로 겹치는 러너의 listener를 제 것으로 세지 않는다', () {
      const listener10 =
          '1 /Users/me/actions/action-10/bin/Runner.Listener run';
      expect(
        LocalRunner.listenerRunningIn('/Users/me/actions/action-1', listener10),
        isFalse,
      );
    });

    test('아무 listener도 없으면 false', () {
      expect(
        LocalRunner.listenerRunningIn('/Users/me/actions/action-01', ''),
        isFalse,
      );
    });

    test('끝 슬래시가 붙은 설치 경로도 매칭된다', () {
      expect(
        LocalRunner.listenerRunningIn('/Users/me/actions/action-01/', svc),
        isTrue,
      );
    });
  });

  group('LocalRunner.findDirFor', () {
    late Directory tmp;

    /// `<root>/<name>` 에 config.sh가 남기는 형태의 `.runner`를 만든다.
    /// [agentName]이 없으면 디렉토리만 만들고 구성은 하지 않는다(미구성 러너).
    String install(String root, String dirName, {String? agentName}) {
      final dir = Directory('$root/$dirName')..createSync(recursive: true);
      if (agentName != null) {
        File('${dir.path}/.runner').writeAsStringSync(
          jsonEncode({
            'agentName': agentName,
            'gitHubUrl': 'https://github.com/coco-de',
          }),
        );
      }
      return dir.path;
    }

    setUp(() => tmp = Directory.systemTemp.createTempSync('coarc_find'));
    tearDown(() => tmp.deleteSync(recursive: true));

    test('이름별 디렉토리(<root>/<이름>)에 설치된 러너를 찾는다', () {
      final root = tmp.path;
      final dir = install(root, 'kentrosaurus', agentName: 'kentrosaurus');
      final local = LocalRunner(dir: '$root/oviraptor', root: root);

      expect(local.findDirFor('kentrosaurus'), dir);
    });

    test('추적 중인 러너가 아니어도 찾는다 — s가 커서 러너를 대상으로 삼는 근거', () {
      final root = tmp.path;
      install(root, 'oviraptor', agentName: 'oviraptor');
      final kentro = install(root, 'kentrosaurus', agentName: 'kentrosaurus');
      // 추적 대상(dir)은 oviraptor지만, 커서가 가리키는 kentrosaurus를 찾아야 한다.
      final local = LocalRunner(dir: '$root/oviraptor', root: root);

      expect(local.findDirFor('kentrosaurus'), kentro);
    });

    test('다른 머신의 러너면 null — 아무 명령도 실행하지 않는다', () {
      final root = tmp.path;
      install(root, 'oviraptor', agentName: 'oviraptor');
      final local = LocalRunner(dir: '$root/oviraptor', root: root);

      expect(local.findDirFor('action-09'), isNull);
    });

    test('이름별 규칙을 따르지 않는 설치 경로는 추적 중인 dir로 찾는다', () {
      final root = tmp.path;
      final legacy = install(root, 'legacy-path', agentName: 'oviraptor');
      final local = LocalRunner(dir: legacy, root: root);

      expect(local.findDirFor('oviraptor'), legacy);
    });

    test('경로만 있고 .runner가 없으면 null (구성되지 않은 디렉토리)', () {
      final root = tmp.path;
      install(root, 'kentrosaurus');
      final local = LocalRunner(dir: '$root/kentrosaurus', root: root);

      expect(local.findDirFor('kentrosaurus'), isNull);
    });

    test(
        '같은 경로에 이름이 다른 러너가 구성돼 있으면 null — 엉뚱한 러너에 '
        'svc.sh를 실행하지 않는다', () {
      final root = tmp.path;
      // <root>/kentrosaurus 인데 실제 구성된 러너는 oviraptor.
      install(root, 'kentrosaurus', agentName: 'oviraptor');
      final local = LocalRunner(dir: '$root/kentrosaurus', root: root);

      expect(local.findDirFor('kentrosaurus'), isNull);
    });
  });

  group('LocalRunner.readConfig', () {
    late Directory tmp;

    setUp(() => tmp = Directory.systemTemp.createTempSync('coarc_cfg'));
    tearDown(() => tmp.deleteSync(recursive: true));

    test('.runner가 없으면 null (미구성)', () {
      expect(LocalRunner.readConfig(tmp.path), isNull);
    });

    test('BOM이 붙은 .runner도 읽는다 (config.sh가 BOM을 남긴다)', () {
      File('${tmp.path}/.runner').writeAsStringSync(
        '﻿${jsonEncode({'agentName': 'oviraptor'})}',
      );
      expect(LocalRunner.readConfig(tmp.path)?.agentName, 'oviraptor');
    });

    test('내용이 깨졌으면 이름 미상으로 읽는다 — 미구성(null)과 구분된다', () {
      File('${tmp.path}/.runner').writeAsStringSync('{ 깨진 json');
      final config = LocalRunner.readConfig(tmp.path);

      expect(config, isNotNull);
      expect(config?.agentName, isNull);
    });
  });

  group('LocalRunner.plistPathIn', () {
    late Directory tmp;

    setUp(() => tmp = Directory.systemTemp.createTempSync('coarc_plist'));
    tearDown(() => tmp.deleteSync(recursive: true));

    test('svc.sh install이 남긴 .service 기록을 그대로 쓴다', () {
      final plist = File('${tmp.path}/actions.runner.coco-de.raptor.plist')
        ..writeAsStringSync('<plist/>');
      File('${tmp.path}/.service').writeAsStringSync('${plist.path}\n');

      expect(LocalRunner.plistPathIn(tmp.path, 'raptor'), plist.path);
    });

    test('.service가 없으면(서비스 미설치) 이름 없이는 null', () {
      expect(LocalRunner.plistPathIn(tmp.path, null), isNull);
    });

    test('.service가 가리키는 파일이 사라졌으면 그 경로를 쓰지 않는다', () {
      File('${tmp.path}/.service').writeAsStringSync('${tmp.path}/사라진.plist');

      // 이름 매칭 폴백은 실제 ~/Library/LaunchAgents를 보므로, 임시 이름으로는
      // 아무것도 찾지 못해야 한다.
      expect(
        LocalRunner.plistPathIn(tmp.path, 'coarc-test-존재하지-않는-러너'),
        isNull,
      );
    });
  });

  group('LocalRunner.hardenPlist', () {
    late Directory tmp;
    final hasPlistBuddy = File(LocalRunner.plistBuddy).existsSync();

    /// svc.sh가 만드는 형태의(=KeepAlive가 없는) plist를 만든다.
    File writePlist() => File('${tmp.path}/svc.plist')
      ..writeAsStringSync('''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>Label</key>
    <string>actions.runner.coco-de.raptor</string>
    <key>RunAtLoad</key>
    <true/>
  </dict>
</plist>
''');

    Future<String?> keepAlive(String plist) async {
      final r = await Process.run(
          LocalRunner.plistBuddy, LocalRunner.keepAliveReadArgs(plist));
      return r.exitCode == 0 ? (r.stdout as String).trim() : null;
    }

    setUp(() => tmp = Directory.systemTemp.createTempSync('coarc_harden'));
    tearDown(() => tmp.deleteSync(recursive: true));

    test('KeepAlive가 없던 plist에 SuccessfulExit=false를 심는다', () async {
      final plist = writePlist();
      final lines = await LocalRunner.hardenPlist(plist.path);

      expect(lines.single, contains('KeepAlive'));
      expect(await keepAlive(plist.path), 'false');
    }, skip: hasPlistBuddy ? null : 'PlistBuddy 없음 (macOS 전용)');

    test('이미 적용된 plist는 건드리지 않고 조용히 지나간다 (멱등)', () async {
      final plist = writePlist();
      await LocalRunner.hardenPlist(plist.path);
      final before = plist.readAsStringSync();

      // 두 번째 호출은 로그도 남기지 않는다 — 서비스를 켤 때마다 같은 줄이
      // 로그 패널을 차지하면 정작 svc.sh 출력이 밀려난다.
      expect(await LocalRunner.hardenPlist(plist.path), isEmpty);
      expect(plist.readAsStringSync(), before);
      expect(await keepAlive(plist.path), 'false');
    }, skip: hasPlistBuddy ? null : 'PlistBuddy 없음 (macOS 전용)');

    test('KeepAlive가 true로 잘못 들어가 있으면 SuccessfulExit=false로 바로잡는다',
        () async {
      final plist = writePlist();
      await Process.run(LocalRunner.plistBuddy,
          ['-c', 'Add :KeepAlive bool true', plist.path]);

      await LocalRunner.hardenPlist(plist.path);

      expect(await keepAlive(plist.path), 'false');
    }, skip: hasPlistBuddy ? null : 'PlistBuddy 없음 (macOS 전용)');

    test('plist를 찾지 못했으면 실패가 아니라 안내만 남기고 서비스 기동은 계속된다', () async {
      expect(await LocalRunner.hardenPlist(null), [
        contains('건너뜁니다'),
      ]);
    });
  });

  group('LocalRunner.pmsetAcValue', () {
    // `pmset -g custom`은 배터리 구간을 먼저 찍는다 — 구간을 구분하지 않으면
    // 노트북에서 배터리 값을 AC 값으로 읽는다.
    const output = '''
Battery Power:
 sleep                1
 displaysleep         2
 womp                 0
AC Power:
 Sleep On Power Button 1
 displaysleep         10
 sleep                0
 womp                 1
 disksleep            10
''';

    test('AC 구간의 값을 읽는다', () {
      expect(LocalRunner.pmsetAcValue(output, 'sleep'), '0');
      expect(LocalRunner.pmsetAcValue(output, 'womp'), '1');
      expect(LocalRunner.pmsetAcValue(output, 'disksleep'), '10');
    });

    test('배터리 구간의 같은 키를 집어오지 않는다', () {
      expect(LocalRunner.pmsetAcValue(output, 'sleep'), isNot('1'));
    });

    test('기종이 지원하지 않는 키(예: 노트북의 autorestart)는 null', () {
      expect(LocalRunner.pmsetAcValue(output, 'autorestart'), isNull);
    });

    test("'Sleep On Power Button' 같은 다른 줄을 sleep으로 오인하지 않는다", () {
      expect(LocalRunner.pmsetAcValue(output, 'Sleep'), isNull);
    });

    test('조회 실패로 빈 출력이 와도 터지지 않는다', () {
      expect(LocalRunner.pmsetAcValue('', 'sleep'), isNull);
    });
  });

  group('LocalRunner.bootWarnings', () {
    const readyPmset = 'AC Power:\n sleep                0\n autorestart 1\n';

    test('자동 로그인·전원 설정이 모두 맞으면 경고 없음', () {
      expect(
        LocalRunner.bootWarnings(
          autoLoginUser: 'dongwoo',
          fileVaultStatus: 'FileVault is Off.',
          pmsetCustom: readyPmset,
        ),
        isEmpty,
      );
    });

    test('자동 로그인이 꺼져 있으면 경고 — LaunchAgent는 GUI 로그인 시 로드된다', () {
      final warnings = LocalRunner.bootWarnings(
        autoLoginUser: null,
        fileVaultStatus: 'FileVault is Off.',
        pmsetCustom: readyPmset,
      );

      expect(warnings.single, contains('자동 로그인'));
      expect(warnings.single, isNot(contains('FileVault')));
    });

    test('FileVault가 켜져 있으면 authrestart를 함께 안내한다', () {
      final warnings = LocalRunner.bootWarnings(
        autoLoginUser: '',
        fileVaultStatus: 'FileVault is On.',
        pmsetCustom: readyPmset,
      );

      expect(warnings.single, contains('fdesetup authrestart'));
    });

    test('AC에서 잠들도록 설정돼 있으면 경고', () {
      final warnings = LocalRunner.bootWarnings(
        autoLoginUser: 'dongwoo',
        fileVaultStatus: 'FileVault is Off.',
        pmsetCustom: 'AC Power:\n sleep                10\n',
      );

      expect(warnings.single, contains('10분'));
    });

    test('autorestart를 지원하는 기종에서 꺼져 있으면 경고', () {
      final warnings = LocalRunner.bootWarnings(
        autoLoginUser: 'dongwoo',
        fileVaultStatus: 'FileVault is Off.',
        pmsetCustom: 'AC Power:\n sleep 0\n autorestart 0\n',
      );

      expect(warnings.single, contains('autorestart'));
    });

    test('조회에 실패해 값이 비면(모름) 전원 관련 경고를 만들지 않는다', () {
      final warnings = LocalRunner.bootWarnings(
        autoLoginUser: 'dongwoo',
        fileVaultStatus: '',
        pmsetCustom: '',
      );

      expect(warnings, isEmpty);
    });
  });
}

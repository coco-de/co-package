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

  group('LocalRunner.configuredDirs', () {
    late Directory tmp;

    String install(String root, String dirName, {String? agentName}) {
      final dir = Directory('$root/$dirName')..createSync(recursive: true);
      if (agentName != null) {
        File('${dir.path}/.runner')
            .writeAsStringSync(jsonEncode({'agentName': agentName}));
      }
      return dir.path;
    }

    setUp(() => tmp = Directory.systemTemp.createTempSync('coarc_dirs'));
    tearDown(() => tmp.deleteSync(recursive: true));

    test('root 아래 구성된 러너를 전부 모은다', () {
      final a = install(tmp.path, 'raptor', agentName: 'raptor');
      final b = install(tmp.path, 'stego', agentName: 'stego');
      final local = LocalRunner(dir: a, root: tmp.path);

      expect(local.configuredDirs(), [a, b]..sort());
    });

    test('.runner가 없는 디렉토리(미구성)는 빼낸다', () {
      install(tmp.path, 'raptor', agentName: 'raptor');
      install(tmp.path, '내려받다-만-디렉토리');
      final local = LocalRunner(dir: '${tmp.path}/raptor', root: tmp.path);

      expect(local.configuredDirs(), ['${tmp.path}/raptor']);
    });

    test('root 밖의 추적 중인 러너(--dir·구규칙)도 포함한다', () {
      final legacy = Directory('${tmp.path}-legacy')..createSync();
      addTearDown(() => legacy.deleteSync(recursive: true));
      File('${legacy.path}/.runner')
          .writeAsStringSync(jsonEncode({'agentName': 'oviraptor'}));
      final local = LocalRunner(dir: legacy.path, root: tmp.path);

      expect(local.configuredDirs(), contains(legacy.path));
    });

    test('추적 중인 러너가 root 아래에도 있으면 한 번만 센다', () {
      final a = install(tmp.path, 'raptor', agentName: 'raptor');
      final local = LocalRunner(dir: a, root: tmp.path);

      expect(local.configuredDirs(), [a]);
    });

    test('root가 아예 없어도 터지지 않는다', () {
      final local =
          LocalRunner(dir: '${tmp.path}/없음', root: '${tmp.path}/없는루트');

      expect(local.configuredDirs(), isEmpty);
    });
  });

  group('LocalRunner.hardenAllInstalled', () {
    late Directory tmp;
    final hasPlistBuddy = File(LocalRunner.plistBuddy).existsSync();

    // 러너 이름은 실제 등록과 절대 겹치지 않는 값이어야 한다. `.service`가 없는
    // 러너는 plistPathIn이 실제 ~/Library/LaunchAgents를 이름으로 뒤지는 폴백을
    // 타므로(local_test.dart 위쪽 plistPathIn 그룹의 같은 이유), 이름이 겹치면
    // 테스트가 임시 디렉토리를 벗어나 이 머신의 진짜 launchd 설정을 고친다.
    // 'raptor' 같은 공룡 이름은 --name/A 키로 실제 등록 가능한 값이라 위험하다.
    const alpha = 'coarc-test-알파';
    const beta = 'coarc-test-베타';

    /// `<root>/<name>`에 러너를 설치하고, [withService]면 svc.sh install이
    /// 남기는 형태로 plist(KeepAlive 없음) + `.service` 기록까지 만든다.
    String install(String root, String name, {bool withService = true}) {
      final dir = Directory('$root/$name')..createSync(recursive: true);
      File('${dir.path}/.runner')
          .writeAsStringSync(jsonEncode({'agentName': name}));
      if (withService) {
        final plist = File('${dir.path}/actions.runner.coco-de.$name.plist')
          ..writeAsStringSync('''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>Label</key>
    <string>actions.runner.coco-de.$name</string>
    <key>RunAtLoad</key>
    <true/>
  </dict>
</plist>
''');
        File('${dir.path}/.service').writeAsStringSync(plist.path);
      }
      return dir.path;
    }

    Future<String?> keepAlive(String dir, String name) async {
      final r = await Process.run(
        LocalRunner.plistBuddy,
        LocalRunner.keepAliveReadArgs(
            '$dir/actions.runner.coco-de.$name.plist'),
      );
      return r.exitCode == 0 ? (r.stdout as String).trim() : null;
    }

    setUp(() => tmp = Directory.systemTemp.createTempSync('coarc_sweep'));
    tearDown(() => tmp.deleteSync(recursive: true));

    test('서비스로 등록된 러너 전부에 KeepAlive를 심는다 — 커서 러너만이 아니다', () async {
      final a = install(tmp.path, alpha);
      final b = install(tmp.path, beta);
      final local = LocalRunner(dir: a, root: tmp.path);

      final lines = await local.hardenAllInstalled();

      expect(lines.single, allOf(contains(alpha), contains(beta)));
      expect(await keepAlive(a, alpha), 'false');
      expect(await keepAlive(b, beta), 'false');
    }, skip: hasPlistBuddy ? null : 'PlistBuddy 없음 (macOS 전용)');

    test('실행 중이든 아니든 plist만 고친다 — 서비스를 내렸다 올리지 않는다', () async {
      // 서비스 제어는 svc.sh를 통해서만 일어난다(Dart 코드가 launchctl을 직접
      // 부르는 곳은 없다). 이 스윕이 서비스를 건드리지 않는다는 건 러너
      // 디렉토리에 svc.sh가 아예 없어도 — 즉 내렸다 올릴 수단이 없어도 —
      // 정상 동작한다는 것으로 확인한다. 스윕에 bounce를 넣으면 이 테스트는
      // ProcessException(No such file or directory)으로 죽는다.
      final a = install(tmp.path, alpha);
      final local = LocalRunner(dir: a, root: tmp.path);

      expect(File('$a/svc.sh').existsSync(), isFalse);
      expect(await local.hardenAllInstalled(), hasLength(1));
      expect(await keepAlive(a, alpha), 'false');
    }, skip: hasPlistBuddy ? null : 'PlistBuddy 없음 (macOS 전용)');

    test('이미 적용된 러너만 있으면 로그를 남기지 않는다 (멱등)', () async {
      final a = install(tmp.path, alpha);
      final local = LocalRunner(dir: a, root: tmp.path);

      await local.hardenAllInstalled();

      // 두 번째 스윕은 조용해야 한다 — TUI를 켤 때마다 같은 줄이 쌓이면
      // 로그 패널 6줄이 그것만으로 찬다.
      expect(await local.hardenAllInstalled(), isEmpty);
    }, skip: hasPlistBuddy ? null : 'PlistBuddy 없음 (macOS 전용)');

    test('서비스로 등록되지 않은 러너는 건너뛴다 — 켤 때 심으면 된다', () async {
      final a = install(tmp.path, alpha, withService: false);
      final local = LocalRunner(dir: a, root: tmp.path);

      // 폴백이 이 머신의 실제 plist를 물어오지 않았는지 먼저 못박는다. 이게
      // 없으면 "건너뛴다"가 아니라 "내 홈에 마침 같은 이름이 없다"를 검증하는
      // 테스트가 되고, 머신에 따라 조용히 의미가 달라진다.
      expect(LocalRunner.plistPathIn(a, alpha), isNull);
      expect(await local.hardenAllInstalled(), isEmpty);
    }, skip: hasPlistBuddy ? null : 'PlistBuddy 없음 (macOS 전용)');

    test('일부가 실패해도 나머지는 적용하고 실패한 러너를 따로 알린다', () async {
      final ok = install(tmp.path, alpha);
      final broken = install(tmp.path, beta);
      // plist를 XML이 아닌 내용으로 덮어 PlistBuddy가 실패하게 만든다.
      File('$broken/actions.runner.coco-de.$beta.plist')
          .writeAsStringSync('plist가 아님');
      final local = LocalRunner(dir: ok, root: tmp.path);

      final lines = await local.hardenAllInstalled();

      expect(lines, hasLength(2));
      expect(lines.first, contains(alpha));
      expect(lines.last, allOf(contains('실패'), contains(beta)));
      expect(await keepAlive(ok, alpha), 'false');
    }, skip: hasPlistBuddy ? null : 'PlistBuddy 없음 (macOS 전용)');

    test('쓰기 불가 plist를 "적용 완료"로 보고하지 않는다', () async {
      // PlistBuddy는 저장에 실패해도 exit 0으로 끝나고 사유는 stderr에만
      // 남긴다. 종료코드만 믿으면 아무것도 안 바뀐 러너를 적용됐다고 보고하고,
      // 사용자는 재부팅한 뒤에야 크래시 복구가 없다는 걸 알게 된다.
      final a = install(tmp.path, alpha);
      final plist = File('$a/actions.runner.coco-de.$alpha.plist');
      await Process.run('chmod', ['444', plist.path]);
      addTearDown(() => Process.run('chmod', ['644', plist.path]));
      final local = LocalRunner(dir: a, root: tmp.path);

      final lines = await local.hardenAllInstalled();

      expect(lines.single, allOf(contains('실패'), contains(alpha)));
      expect(await keepAlive(a, alpha), isNull);
    }, skip: hasPlistBuddy ? null : 'PlistBuddy 없음 (macOS 전용)');
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

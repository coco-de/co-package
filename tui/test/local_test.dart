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
}

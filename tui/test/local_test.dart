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
        LocalRunner.listenerRunningIn('/Users/me/actions/action-02',
            '$svc\n$foreground'),
        isTrue,
      );
    });

    test('다른 러너의 listener만 떠 있으면 false — 이게 s 키가 stop을 '
        '잘못 실행하던 원인', () {
      expect(
        LocalRunner.listenerRunningIn('/Users/me/actions/action-99', svc),
        isFalse,
      );
    });

    test('이름이 접두사로 겹치는 러너의 listener를 제 것으로 세지 않는다', () {
      const listener10 = '1 /Users/me/actions/action-10/bin/Runner.Listener run';
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
}

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
}

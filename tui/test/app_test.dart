import 'dart:convert';
import 'dart:io';

import 'package:coarc_tui/coarc_tui.dart';
import 'package:dart_tui/dart_tui.dart';
import 'package:test/test.dart';

RunnerInfo _runner(String name) => RunnerInfo(
      id: name.hashCode,
      name: name,
      os: 'macOS',
      status: 'online',
      busy: false,
      labels: const ['self-hosted', 'macOS', 'ARM64'],
      customLabels: const [],
    );

/// `<root>/<name>`에 config.sh가 남기는 형태로 러너를 설치한다.
String _install(String root, String name) {
  final dir = Directory('$root/$name')..createSync(recursive: true);
  File('${dir.path}/.runner').writeAsStringSync(
    jsonEncode({'agentName': name, 'gitHubUrl': 'https://github.com/coco-de'}),
  );
  return dir.path;
}

void main() {
  group('AppModel.selectedLocalDir', () {
    late Directory tmp;
    late List<RunnerInfo> runners;
    late LocalRunner local;

    setUp(() {
      tmp = Directory.systemTemp.createTempSync('coarc_app');
      _install(tmp.path, 'kentrosaurus');
      _install(tmp.path, 'oviraptor');
      runners = [
        _runner('action-09'), // 다른 머신
        _runner('kentrosaurus'), // 로컬 — 추적 대상 아님
        _runner('oviraptor'), // 로컬 — 추적 대상
      ];
      // 추적 대상(dir)은 oviraptor 하나로 고정 — s가 이것만 보던 게 버그였다.
      local = LocalRunner(dir: '${tmp.path}/oviraptor', root: tmp.path);
    });

    tearDown(() => tmp.deleteSync(recursive: true));

    AppModel modelAt(int cursor) => AppModel(
          scope: const Scope.org('coco-de'),
          local: local,
          runners: runners,
          table: TableModel(
            columns: const [TableColumn(title: 'NAME', width: 26)],
            rows: [
              for (final r in runners) [r.name],
            ],
            height: 10,
            cursor: cursor,
          ),
        );

    test('추적 대상이 아니어도 커서 러너를 대상으로 삼는다', () {
      expect(modelAt(1).selectedLocalDir, '${tmp.path}/kentrosaurus');
    });

    test('커서를 옮기면 대상도 따라 옮겨간다', () {
      expect(modelAt(2).selectedLocalDir, '${tmp.path}/oviraptor');
    });

    test('다른 머신의 러너는 대상 없음 — 로컬 조작을 실행하지 않는다', () {
      expect(modelAt(0).selectedLocalDir, isNull);
    });

    test('러너 목록이 비면 대상 없음', () {
      final empty = AppModel(
        scope: const Scope.org('coco-de'),
        local: local,
      );
      expect(empty.selected, isNull);
      expect(empty.selectedLocalDir, isNull);
    });
  });

  group('AppModel.copyWith', () {
    test('clearLocalStatusFor로 localStatusFor를 null로 되돌린다', () {
      // 러너가 0대인 스코프를 거칠 때 이전 러너 이름이 남으면, 그 러너로
      // 돌아왔을 때 재조회 없이 빈 상태를 붙여 '설치되지 않음'으로 오표시한다.
      final model = AppModel(
        scope: const Scope.org('coco-de'),
        local: LocalRunner(dir: '/tmp/x', root: '/tmp'),
        localStatusFor: 'kentrosaurus',
      );

      expect(model.copyWith().localStatusFor, 'kentrosaurus');
      expect(model.copyWith(clearLocalStatusFor: true).localStatusFor, isNull);
    });
  });
}

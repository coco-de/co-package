import 'dart:convert';
import 'dart:io';

import 'package:co_arc/co_arc.dart';
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

/// 이름·라벨이 길어 좁은 터미널에서 가장 먼저 넘치는 러너.
RunnerInfo _wideRunner(int i) => RunnerInfo(
  id: i,
  name: 'cocode-m2-ultra-runner-$i',
  os: 'macOS',
  status: i.isEven ? 'online' : 'offline',
  busy: i.isEven,
  labels: const [
    'self-hosted',
    'macOS',
    'ARM64',
    'flutter',
    'serverpod',
    'jaspr',
  ],
  customLabels: const ['flutter', 'serverpod', 'jaspr'],
);

AppModel _pressKey(AppModel m, String key) =>
    m.update(KeyPressMsg(TeaKey(code: KeyCode.rune, text: key))).$1 as AppModel;

AppModel _resize(AppModel m, int w, int h) =>
    m.update(WindowSizeMsg(w, h)).$1 as AppModel;

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
      final empty = AppModel(scope: const Scope.org('coco-de'), local: local);
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

  group('터미널 리사이즈', () {
    AppModel base() => AppModel(
      scope: const Scope.org('coco-de'),
      local: LocalRunner(dir: '/tmp/coarc-x', root: '/tmp/coarc-x'),
      runners: [for (var i = 0; i < 40; i++) _wideRunner(i)],
      log: [for (var i = 0; i < 30; i++) '로그 줄 $i — 러너 서비스 상태 변경 기록'],
      loading: false,
      lastUpdated: DateTime(2026, 7, 29, 14, 2, 31),
    );

    /// 프레임이 터미널 안에 들어가는지 — 이 계약이 깨지면 터미널이 스크롤하거나
    /// 줄이 래핑돼, 이후 렌더가 전부 어긋난다.
    void expectFits(String label, AppModel m, int w, int h) {
      final lines = m.view().content.split('\n');
      expect(
        lines.length,
        lessThanOrEqualTo(h),
        reason: '$label ${w}x$h: ${lines.length}줄을 그려 화면을 넘는다',
      );
      for (var i = 0; i < lines.length; i++) {
        expect(
          visibleWidth(lines[i]),
          lessThanOrEqualTo(w - 1),
          reason:
              '$label ${w}x$h: ${i + 1}번째 줄이 '
              '${visibleWidth(lines[i])}칸 — 예산 ${w - 1}칸을 넘어 래핑된다',
        );
      }
    }

    const sizes = <(int, int)>[
      (20, 8),
      (24, 10),
      (30, 12),
      (40, 15),
      (50, 18),
      (60, 20),
      (72, 22),
      (80, 24),
      (90, 26),
      (100, 30),
      (120, 40),
      (160, 50),
      (200, 60),
      (300, 100),
      (81, 25),
      (76, 23),
      (75, 9),
    ];

    test('일반 화면이 모든 크기에 들어간다', () {
      for (final (w, h) in sizes) {
        expectFits('일반', _resize(base(), w, h), w, h);
      }
    });

    test('러너가 없는 스코프도 들어간다', () {
      final empty = AppModel(
        scope: const Scope.org('coco-de'),
        local: LocalRunner(dir: '/tmp/coarc-x', root: '/tmp/coarc-x'),
        loading: false,
      );
      for (final (w, h) in sizes) {
        expectFits('빈 목록', _resize(empty, w, h), w, h);
      }
    });

    test('gh 오류 화면도 들어간다', () {
      final failed = base().copyWith(
        error: List.generate(
          12,
          (i) => 'gh: 오류 상세 $i — 아주 긴 설명이 붙는다',
        ).join('\n'),
      );
      for (final (w, h) in sizes) {
        expectFits('오류', _resize(failed, w, h), w, h);
      }
    });

    test('도움말 화면도 들어간다', () {
      for (final (w, h) in sizes) {
        expectFits('도움말', _pressKey(_resize(base(), w, h), '?'), w, h);
      }
    });

    test('라벨 피커도 들어간다', () {
      for (final (w, h) in sizes) {
        expectFits('피커', _pressKey(_resize(base(), w, h), 'l'), w, h);
      }
    });

    test('피커 위의 새 라벨 입력도 들어간다', () {
      for (final (w, h) in sizes) {
        final picking = _pressKey(_resize(base(), w, h), 'l');
        expectFits('새 라벨 입력', _pressKey(picking, 'n'), w, h);
      }
    });

    test('확인·입력 푸터가 뜬 상태도 들어간다', () {
      for (final (w, h) in sizes) {
        for (final key in const ['d', 'g', 'A']) {
          expectFits('$key 모드', _pressKey(_resize(base(), w, h), key), w, h);
        }
      }
    });

    test('푸터가 잘려 나가지 않는다 — 세로 예산이 맞다는 증거', () {
      // fitFrame은 마지막 안전망일 뿐이다. 패널별 예산이 어긋나면 프레임이
      // 화면보다 커지고, 안전망이 맨 아래 푸터부터 잘라낸다. 푸터가 살아
      // 있다는 건 예산 계산 자체가 맞았다는 뜻이다.
      for (final (w, h) in sizes) {
        for (final m in [
          _resize(base(), w, h),
          _resize(base().copyWith(error: '인증 실패\n' * 12), w, h),
        ]) {
          // 좁으면 푸터도 가로로 잘리므로 앞머리('↑↓')로만 확인한다.
          final last = m.view().content.split('\n').last;
          expect(
            last,
            contains('↑↓'),
            reason: '${w}x$h: 마지막 줄이 푸터가 아니다 — 프레임이 화면을 넘겨 잘렸다',
          );
        }
      }
    });

    test('표 안에 들어간 러너 수가 예산과 일치한다', () {
      // 행이 래핑되거나 잘리면 이 수가 어긋난다.
      for (final (w, h) in sizes) {
        final m = _resize(base(), w, h);
        final l = Layout.forTerminal(w, h);
        // 이름은 좁은 폭에서 잘리므로, 항상 온전히 남는 ST 열의 글리프로 센다.
        final rows = m
            .view()
            .content
            .split('\n')
            .where((line) => line.contains('●') || line.contains('○'))
            .length;
        final expected = l.tableRows < m.runners.length
            ? l.tableRows
            : m.runners.length;
        expect(
          rows,
          expected,
          reason: '${w}x$h: 표에 $rows행이 떴다 — 예산은 $expected행',
        );
      }
    });

    test('리사이즈하면 diff 렌더러 캐시를 버리게 한다', () async {
      // 렌더러는 이전 프레임과 같은 행을 건너뛴다. 터미널이 스스로 버퍼를
      // 리플로우한 뒤에도 캐시가 남아 있으면 옛 레이아웃 조각이 화면에 남는다.
      final (_, cmd) = base().update(WindowSizeMsg(80, 24));
      expect(cmd, isNotNull, reason: '리사이즈에 아무 커맨드도 내지 않으면 잔상이 남는다');
      expect(await cmd!(), isA<ClearScreenMsg>());
    });

    test('리사이즈가 테이블 높이·열 폭을 새 크기로 갱신한다', () {
      final wide = _resize(base(), 200, 60);
      final narrow = _resize(wide, 60, 20);

      final expected = Layout.forTerminal(60, 20);
      expect(narrow.table.height, expected.tableRows);
      expect(narrow.table.columns.last.width, expected.labelColumnWidth);
      expect(
        narrow.table.columns.last.width,
        lessThan(wide.table.columns.last.width),
      );
    });

    test('열어 둔 라벨 피커도 새 높이로 갱신된다', () {
      // 생성 시점 높이를 그대로 두면 창을 줄였을 때 항목이 화면 밖으로 넘친다.
      final picking = _pressKey(_resize(base(), 200, 60), 'l');
      expect(picking.picker, isNotNull);

      final shrunk = _resize(picking, 80, 16);
      expect(shrunk.picker!.height, Layout.forTerminal(80, 16).pickerRows);
      expect(shrunk.picker!.height, lessThan(picking.picker!.height));
    });

    test('피커 갱신이 체크·커서 상태를 잃지 않는다', () {
      final picking = _pressKey(_resize(base(), 200, 60), 'l');
      final moved = _pressKey(picking, 'j');
      final shrunk = _resize(moved, 80, 16);

      expect(shrunk.picker!.cursor, moved.picker!.cursor);
      expect(shrunk.picker!.selectedValues, moved.picker!.selectedValues);
      expect(
        shrunk.picker!.items.map((i) => i.label),
        moved.picker!.items.map((i) => i.label),
      );
    });

    test('커서 위치는 리사이즈를 넘어 유지된다', () {
      var m = _resize(base(), 200, 60);
      for (var i = 0; i < 5; i++) {
        m = _pressKey(m, 'j');
      }
      expect(m.table.cursor, 5);
      expect(_resize(m, 60, 20).table.cursor, 5);
    });

    test('확대·축소를 반복해도 계약이 유지된다', () {
      // 실제 사용은 한 번의 리사이즈가 아니라 연속된 SIGWINCH다.
      var m = base();
      for (final (w, h) in [...sizes, ...sizes.reversed]) {
        m = _resize(m, w, h);
        expectFits('연속 리사이즈', m, w, h);
      }
    });
  });
}

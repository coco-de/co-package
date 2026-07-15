import 'dart:io';

import 'package:dart_tui/dart_tui.dart';

import 'gh.dart';
import 'local.dart';
import 'scope.dart';

// ─── 색상 팔레트 (256색) ────────────────────────────────────────────────────
const _green = 42;
const _yellow = 214;
const _red = 203;
const _gray = 245;
const _cyan = 45;

Style _fg(int c) => const Style().foregroundColor256(c);

// ─── 메시지 ─────────────────────────────────────────────────────────────────
final class _RunnersLoadedMsg extends Msg {
  _RunnersLoadedMsg(this.scope, this.runners);
  final Scope scope;
  final List<RunnerInfo> runners;
}

final class _RunnersFailedMsg extends Msg {
  _RunnersFailedMsg(this.scope, this.error);
  final Scope scope;
  final String error;
}

final class _LocalStatusMsg extends Msg {
  _LocalStatusMsg(this.status);
  final LocalStatus status;
}

final class _LogMsg extends Msg {
  _LogMsg(this.lines);
  final List<String> lines;
}

final class _RefreshTickMsg extends Msg {}

final class _ScriptExitMsg extends Msg {
  _ScriptExitMsg(this.label, this.exitCode);
  final String label;
  final int exitCode;
}

// ─── 모드 ───────────────────────────────────────────────────────────────────
enum _Mode { normal, confirmDelete, scopeInput, help }

/// co-arc self-hosted 러너 관리 TUI의 루트 모델.
final class AppModel extends TeaModel {
  AppModel({
    required this.scope,
    required this.local,
    this.gh = const GhClient(),
    this.runners = const [],
    TableModel? table,
    SpinnerModel? spinner,
    this.loading = true,
    this.error,
    LocalStatus? localStatus,
    this.log = const [],
    this.mode = _Mode.normal,
    this.input = '',
    this.lastUpdated,
    this.width = 100,
    this.height = 30,
  })  : localStatus = localStatus ?? LocalStatus.empty(local.dir),
        spinner = spinner ?? SpinnerModel(),
        table = table ?? _buildTable(const [], 100, 30, cursor: 0);

  final Scope scope;
  final LocalRunner local;
  final GhClient gh;
  final List<RunnerInfo> runners;
  final TableModel table;
  final SpinnerModel spinner;
  final bool loading;
  final String? error;
  final LocalStatus localStatus;
  final List<String> log;
  final _Mode mode;
  final String input;
  final DateTime? lastUpdated;
  final int width;
  final int height;

  AppModel copyWith({
    Scope? scope,
    List<RunnerInfo>? runners,
    TableModel? table,
    SpinnerModel? spinner,
    bool? loading,
    String? error,
    bool clearError = false,
    LocalStatus? localStatus,
    List<String>? log,
    _Mode? mode,
    String? input,
    DateTime? lastUpdated,
    int? width,
    int? height,
  }) =>
      AppModel(
        scope: scope ?? this.scope,
        local: local,
        gh: gh,
        runners: runners ?? this.runners,
        table: table ?? this.table,
        spinner: spinner ?? this.spinner,
        loading: loading ?? this.loading,
        error: clearError ? null : (error ?? this.error),
        localStatus: localStatus ?? this.localStatus,
        log: log ?? this.log,
        mode: mode ?? this.mode,
        input: input ?? this.input,
        lastUpdated: lastUpdated ?? this.lastUpdated,
        width: width ?? this.width,
        height: height ?? this.height,
      );

  RunnerInfo? get selected =>
      runners.isEmpty || table.cursor >= runners.length
          ? null
          : runners[table.cursor];

  // ─── 테이블 구성 ──────────────────────────────────────────────────────────

  static int _tableHeight(int termHeight) => (termHeight - 14).clamp(3, 40);

  static TableModel _buildTable(
    List<RunnerInfo> runners,
    int width,
    int termHeight, {
    required int cursor,
  }) {
    final labelWidth = (width - 4 - 8 - 26 - 6 - 9 - 12).clamp(20, 120);
    final rows = [
      for (final r in runners)
        [
          r.online ? '● on' : '○ off',
          r.name,
          r.busy ? 'busy' : 'idle',
          r.os,
          r.labels.join(','),
        ],
    ];
    return TableModel(
      columns: [
        const TableColumn(title: 'ST', width: 5),
        const TableColumn(title: 'NAME', width: 26),
        const TableColumn(title: 'JOB', width: 5),
        const TableColumn(title: 'OS', width: 6),
        TableColumn(title: 'LABELS', width: labelWidth),
      ],
      rows: rows,
      height: _tableHeight(termHeight),
      cursor: runners.isEmpty ? 0 : cursor.clamp(0, runners.length - 1),
      styles: TableStyles(
        header: const Style().bold(),
        selectedRow: const Style().backgroundColor256(238),
        separator: _fg(_gray),
        styleFunc: (row, col) {
          if (row >= runners.length) return null;
          final r = runners[row];
          if (col == 0) return _fg(r.online ? _green : _gray);
          if (col == 2 && r.busy) return _fg(_yellow);
          if (col == 4) return _fg(_gray);
          return null;
        },
      ),
    );
  }

  // ─── 커맨드 ──────────────────────────────────────────────────────────────

  // scope를 파라미터로 받는다 — 스코프 전환 직후에는 새 스코프로 조회해야 하는데,
  // 클로저가 이전 모델 인스턴스의 scope를 캡처하면 안 되기 때문.
  Cmd _fetchRunnersFor(Scope target) => () async {
        try {
          return _RunnersLoadedMsg(target, await gh.fetchRunners(target));
        } catch (e) {
          return _RunnersFailedMsg(target, '$e');
        }
      };

  Cmd _fetchRunners() => _fetchRunnersFor(scope);

  Cmd _fetchLocal() => () async => _LocalStatusMsg(await local.status());

  Cmd _refreshTimer() =>
      tick(const Duration(seconds: 15), (_) => _RefreshTickMsg());

  /// 외부 명령을 백그라운드로 실행하고 출력을 로그 패널로 보낸다.
  Cmd _runLogged(String label, String exe, List<String> args,
          {String? workingDir}) =>
      () async {
        try {
          final r = await Process.run(exe, args,
              workingDirectory: workingDir, runInShell: false);
          final lines = <String>[
            '\$ $label',
            ...(r.stdout as String).trim().split('\n'),
            ...(r.stderr as String).trim().split('\n'),
          ]..removeWhere((l) => l.isEmpty);
          if (r.exitCode != 0) lines.add('(exit ${r.exitCode})');
          return _LogMsg(lines);
        } catch (e) {
          return _LogMsg(['\$ $label', 'error: $e']);
        }
      };

  Cmd _deleteRunner(RunnerInfo r) => () async {
        try {
          await gh.deleteRunner(scope, r.id);
          return _LogMsg(['러너 해제 완료: ${r.name} (id ${r.id})']);
        } catch (e) {
          return _LogMsg([
            '러너 해제 실패: ${r.name} — $e',
            '온라인 러너는 GitHub API로 지울 수 없습니다. 해당 머신에서 remove-runner.sh를 실행하세요.',
          ]);
        }
      };

  // ─── 라이프사이클 ────────────────────────────────────────────────────────

  @override
  Cmd? init() => batch([
        setWindowTitle('co-arc runners'),
        () => requestWindowSize(),
        _fetchRunners(),
        _fetchLocal(),
        _refreshTimer(),
      ]);

  @override
  (Model, Cmd?) update(Msg msg) {
    switch (msg) {
      case WindowSizeMsg(:final width, :final height):
        return (
          copyWith(
            width: width,
            height: height,
            table: _buildTable(runners, width, height, cursor: table.cursor),
          ),
          null,
        );

      case _RunnersLoadedMsg(:final scope, :final runners):
        // 스코프 전환 직전에 나간 요청의 늦은 응답은 무시
        if (scope.apiBase != this.scope.apiBase) return (this, null);
        return (
          copyWith(
            runners: runners,
            table: _buildTable(runners, width, height, cursor: table.cursor),
            loading: false,
            clearError: true,
            lastUpdated: DateTime.now(),
          ),
          null,
        );

      case _RunnersFailedMsg(:final scope, :final error):
        if (scope.apiBase != this.scope.apiBase) return (this, null);
        return (copyWith(loading: false, error: error), null);

      case _LocalStatusMsg(:final status):
        return (copyWith(localStatus: status), null);

      case _LogMsg(:final lines):
        final next = [...log, ...lines];
        return (
          copyWith(
              log: next.length > 200
                  ? next.sublist(next.length - 200)
                  : next),
          null,
        );

      case _RefreshTickMsg():
        final fetch = (mode == _Mode.normal && !loading)
            ? batch([_fetchRunners(), _fetchLocal()])
            : null;
        return (loading ? this : copyWith(loading: fetch != null),
            batch([fetch, _refreshTimer()]));

      case _ScriptExitMsg(:final label, :final exitCode):
        return (
          copyWith(
            log: [...log, '\$ $label → exit $exitCode'],
            loading: true,
          ),
          batch([_fetchRunners(), _fetchLocal()]),
        );

      case TickMsg():
        final (next, cmd) = spinner.update(msg);
        return (copyWith(spinner: next as SpinnerModel), cmd);

      case KeyMsg(:final key):
        return _onKey(key, msg);

      default:
        return (this, null);
    }
  }

  // ─── 키 입력 ─────────────────────────────────────────────────────────────

  (Model, Cmd?) _onKey(String key, KeyMsg msg) {
    if (key == 'ctrl+c') return (this, () => quit());

    switch (mode) {
      case _Mode.help:
        return (copyWith(mode: _Mode.normal), null);

      case _Mode.confirmDelete:
        final target = selected;
        if (key == 'y' && target != null) {
          return (
            copyWith(mode: _Mode.normal, loading: true),
            sequence([_deleteRunner(target), _fetchRunners()]),
          );
        }
        return (copyWith(mode: _Mode.normal), null);

      case _Mode.scopeInput:
        return _onScopeInputKey(key, msg);

      case _Mode.normal:
        return _onNormalKey(key, msg);
    }
  }

  (Model, Cmd?) _onScopeInputKey(String key, KeyMsg msg) {
    switch (key) {
      case 'esc':
        return (copyWith(mode: _Mode.normal, input: ''), null);
      case 'enter':
        final trimmed = input.trim();
        if (trimmed.isEmpty) {
          return (copyWith(mode: _Mode.normal, input: ''), null);
        }
        final next = Scope.parse(trimmed);
        TuiConfig(scope: next, runnerDir: local.dir).save();
        return (
          copyWith(
            scope: next,
            mode: _Mode.normal,
            input: '',
            loading: true,
            runners: const [],
            table: _buildTable(const [], width, height, cursor: 0),
            log: [...log, '스코프 변경: ${next.label}'],
          ),
          _fetchRunnersFor(next),
        );
      case 'backspace':
        return (
          copyWith(
              input: input.isEmpty ? '' : input.substring(0, input.length - 1)),
          null,
        );
      default:
        // 빠른 입력/붙여넣기는 여러 글자가 하나의 rune 키로 들어올 수 있다.
        final k = msg.keyEvent;
        if (k.code == KeyCode.rune &&
            k.modifiers.isEmpty &&
            k.text.isNotEmpty) {
          return (copyWith(input: input + k.text), null);
        }
        return (this, null);
    }
  }

  (Model, Cmd?) _onNormalKey(String key, KeyMsg msg) {
    switch (key) {
      case 'q':
        return (this, () => quit());

      case '?':
        return (copyWith(mode: _Mode.help), null);

      case 'r':
        if (loading) return (this, null);
        return (
          copyWith(loading: true, clearError: true),
          batch([_fetchRunners(), _fetchLocal()]),
        );

      case 'g':
        return (copyWith(mode: _Mode.scopeInput, input: ''), null);

      case 'd':
        if (selected == null) return (this, null);
        return (copyWith(mode: _Mode.confirmDelete), null);

      case 'a':
        final script = LocalRunner.findScript('register-runner.sh');
        if (script == null) {
          return (
            copyWith(log: [...log, 'register-runner.sh를 찾지 못했습니다 (co-arc 레포 안에서 실행하세요)']),
            null,
          );
        }
        return (
          copyWith(log: [...log, '\$ register-runner.sh ${scope.scriptArgs.join(' ')}']),
          execProcess(
            script,
            scope.scriptArgs,
            inheritStdio: true,
            onExit: (code) => _ScriptExitMsg('register-runner.sh', code),
          ),
        );

      case 's':
        if (!localStatus.configured) {
          return (
            copyWith(log: [...log, '로컬 러너가 구성돼 있지 않습니다: ${local.dir} (a로 등록)']),
            null,
          );
        }
        final action = localStatus.listenerRunning ? 'stop' : 'start';
        return (
          this,
          sequence([
            _runLogged('svc.sh $action', './svc.sh', [action],
                workingDir: local.dir),
            _fetchLocal(),
          ]),
        );

      case 'c':
      case 'C':
        final script = LocalRunner.findScript('cleanup-work.sh');
        if (script == null) {
          return (copyWith(log: [...log, 'cleanup-work.sh를 찾지 못했습니다']), null);
        }
        final args = [
          '--dir', local.dir,
          if (key == 'c') '--dry-run',
        ];
        return (
          this,
          sequence([
            _runLogged('cleanup-work.sh ${args.join(' ')}', script, args),
            _fetchLocal(),
          ]),
        );

      default:
        final (next, cmd) = table.update(msg);
        return (copyWith(table: next as TableModel), cmd);
    }
  }

  // ─── 뷰 ──────────────────────────────────────────────────────────────────

  @override
  View view() {
    if (mode == _Mode.help) return newView(_helpView());

    final b = StringBuffer();
    b.writeln(_headerLine());
    b.writeln();

    if (error != null) {
      for (final line in error!.split('\n')) {
        b.writeln(_fg(_red).render(_clip(' gh 오류: $line')));
      }
      b.writeln(_fg(_gray).render(' gh auth status를 확인하세요. r로 재시도.'));
    } else if (runners.isEmpty && !loading) {
      b.writeln(_fg(_gray).render(' 등록된 러너가 없습니다. a를 눌러 이 머신을 등록하세요.'));
    } else {
      b.writeln(table.view().content);
    }

    b.writeln();
    b.writeln(_localLine());
    b.writeln(_fg(_gray).render('─' * width.clamp(20, 200)));
    for (final line in _logTail(6)) {
      b.writeln(_fg(_gray).render(_clip(' $line')));
    }
    b.writeln();
    b.write(_footerLine());
    return newView(b.toString());
  }

  String _headerLine() {
    final title = const Style().bold().render(' co-arc runners');
    final spin = loading ? ' ${spinner.view().content}' : '';
    final updated = lastUpdated == null
        ? ''
        : ' · ${lastUpdated!.hour.toString().padLeft(2, '0')}:'
            '${lastUpdated!.minute.toString().padLeft(2, '0')}:'
            '${lastUpdated!.second.toString().padLeft(2, '0')} 갱신';
    final online = runners.where((r) => r.online).length;
    final info = _fg(_cyan).render(
        '${scope.label} · ${runners.length}대 (온라인 $online)$updated');
    return '$title$spin   $info';
  }

  String _localLine() {
    final s = localStatus;
    final parts = <String>[];
    if (!s.configured) {
      parts.add(_fg(_gray).render('구성 안 됨 (${s.dir})'));
    } else {
      parts.add(const Style().bold().render(s.agentName ?? '(이름 미상)'));
      parts.add(s.listenerRunning
          ? _fg(_green).render('listener 실행 중')
          : _fg(_red).render('listener 중지'));
      parts.add(s.svcInstalled
          ? _fg(_gray).render('launchd 등록됨')
          : _fg(_gray).render('launchd 미등록'));
      if (s.workUsage != null) {
        parts.add(_fg(_gray).render('_work ${s.workUsage}'));
      }
    }
    return ' 로컬: ${parts.join(' · ')}';
  }

  List<String> _logTail(int n) {
    if (log.isEmpty) return const ['(로그 없음)'];
    return log.length <= n ? log : log.sublist(log.length - n);
  }

  String _footerLine() {
    switch (mode) {
      case _Mode.confirmDelete:
        final r = selected;
        return _fg(_yellow).render(
            " '${r?.name}' (id ${r?.id}) 러너를 GitHub에서 해제할까요? [y/N]");
      case _Mode.scopeInput:
        return ' ${_fg(_cyan).render('scope>')} $input█'
            '${_fg(_gray).render('   (org 이름 또는 owner/repo · Enter 확정 · Esc 취소)')}';
      default:
        return _fg(_gray).render(_clip(
            ' ↑↓ 이동 · r 갱신 · a 등록 · d 해제 · s 서비스 · c/C 정리 · g 스코프 · ? 도움말 · q 종료'));
    }
  }

  /// 터미널 폭을 넘는 줄이 래핑돼 잔상을 남기지 않도록 자른다.
  /// (한글 등 전각 문자는 폭 2로 계산)
  String _clip(String s) {
    final max = width - 1;
    var w = 0;
    final b = StringBuffer();
    for (final rune in s.runes) {
      final cw = _runeWidth(rune);
      if (w + cw > max) break;
      b.writeCharCode(rune);
      w += cw;
    }
    return b.toString();
  }

  static int _runeWidth(int code) {
    if (code >= 0x1100 &&
        (code <= 0x11ff ||
            (code >= 0x2e80 && code <= 0x9fff) ||
            (code >= 0xac00 && code <= 0xd7af) ||
            (code >= 0xf900 && code <= 0xfaff) ||
            (code >= 0xfe30 && code <= 0xfe4f) ||
            (code >= 0xff00 && code <= 0xff60) ||
            (code >= 0x1f300 && code <= 0x1f9ff))) {
      return 2;
    }
    return 1;
  }

  String _helpView() {
    const rows = <(String, String)>[
      ('↑/↓, j/k', '러너 선택 이동'),
      ('r', 'GitHub 러너 목록 + 로컬 상태 새로고침 (15초마다 자동)'),
      ('a', '이 머신을 러너로 등록 — scripts/register-runner.sh 실행 (TUI 일시 중단)'),
      ('d', '선택한 러너를 GitHub에서 해제 (오프라인 러너만 가능)'),
      ('s', '로컬 launchd 서비스 시작/중지 (svc.sh)'),
      ('c / C', '_work 정리 — c는 dry-run, C는 실제 삭제 (scripts/cleanup-work.sh)'),
      ('g', '스코프 전환 — org 이름(coco-de) 또는 owner/repo 입력'),
      ('q, ctrl+c', '종료'),
    ];
    final b = StringBuffer();
    b.writeln(const Style().bold().render(' co-arc runner TUI — 도움말'));
    b.writeln();
    for (final (k, desc) in rows) {
      b.writeln('  ${_fg(_cyan).render(k.padRight(12))} $desc');
    }
    b.writeln();
    b.writeln(_fg(_gray).render(
        ' 현재 스코프: ${scope.label} · 러너 디렉토리: ${local.dir}'));
    b.writeln(_fg(_gray).render(
        ' 온라인 러너 해제는 해당 머신에서 scripts/remove-runner.sh를 사용하세요.'));
    b.writeln();
    b.write(_fg(_gray).render(' 아무 키나 누르면 돌아갑니다.'));
    return b.toString();
  }
}

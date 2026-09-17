import 'dart:io';

import 'package:characters/characters.dart';
import 'package:dart_tui/dart_tui.dart';

import 'gh.dart';
import 'labels.dart';
import 'layout.dart';
import 'local.dart';
import 'naming.dart';
import 'register.dart';
import 'scope.dart';
import 'terminal.dart';

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
  _LocalStatusMsg(this.runnerName, this.status);

  /// 조회 대상이었던 러너 이름(=조회를 낸 시점의 커서 러너). 목록이 비어
  /// 대상이 없었으면 null. 응답이 도착했을 때 커서가 이미 다른 러너로
  /// 옮겨갔는지 판별하는 데 쓴다.
  final String? runnerName;
  final LocalStatus status;
}

final class _LogMsg extends Msg {
  _LogMsg(this.lines);
  final List<String> lines;
}

final class _RefreshTickMsg extends Msg {}

/// `s`로 시작한 svc.sh 시퀀스가 끝났음 — [AppModel.svcBusy]를 푸는 유일한
/// 신호다. 상태 조회([_LocalStatusMsg])로 풀면 커서 이동이나 15초 자동 갱신이
/// 실행 도중에 플래그를 풀어, 재진입 방지가 무력화된다.
final class _SvcDoneMsg extends Msg {}

final class _ScriptExitMsg extends Msg {
  _ScriptExitMsg(this.label, this.exitCode);
  final String label;
  final int exitCode;
}

// ─── 모드 ───────────────────────────────────────────────────────────────────
enum _Mode {
  normal,
  confirmDelete,
  scopeInput,
  registerInput,

  /// 라벨 멀티셀렉트 피커 (`l`).
  labelPicker,

  /// 피커에 없는 새 라벨을 입력하는 중 (`n`) — 피커 위에 겹쳐 뜬다.
  labelNewInput,
  help;

  /// 한 줄 텍스트 입력을 받는 모드인지 — [AppModel.input]이 살아 있고
  /// 붙여넣기([PasteMsg])를 받아야 하는 모드다.
  bool get isTextInput =>
      this == scopeInput || this == registerInput || this == labelNewInput;
}

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
    this.localStatusFor,
    this.log = const [],
    this.mode = _Mode.normal,
    TextInputModel? input,
    this.picker,
    this.labelTarget,
    this.lastUpdated,
    this.width = 100,
    this.height = 30,
    this.svcBusy = false,
  }) : localStatus = localStatus ?? LocalStatus.empty(local.dir),
       spinner = spinner ?? SpinnerModel(),
       input = input ?? TextInputModel(),
       table =
           table ??
           _buildTable(const [], Layout.forTerminal(width, height), cursor: 0);

  final Scope scope;
  final LocalRunner local;
  final GhClient gh;
  final List<RunnerInfo> runners;
  final TableModel table;
  final SpinnerModel spinner;
  final bool loading;
  final String? error;

  /// 커서가 가리키는 러너의 로컬 상태 — 이 머신에 설치돼 있지 않으면 빈 상태.
  final LocalStatus localStatus;

  /// [localStatus]가 설명하는 러너 이름. 커서를 옮긴 직후처럼 이 값이 커서
  /// 러너와 어긋나 있으면 [_localLine]이 이전 러너의 상태를 새 러너 이름 옆에
  /// 붙여 보여주지 않는다 — 그 착시가 이 화면의 오해를 만든다.
  final String? localStatusFor;
  final List<String> log;
  final _Mode mode;

  /// 한 줄 텍스트 입력(스코프·등록·새 라벨)의 상태. 커서 이동·단어 삭제 등은
  /// [TextInputModel.update]에 맡기고, 붙여넣기만 [_pasteIntoInput]이 처리한다.
  final TextInputModel input;

  /// 라벨 피커(`l`)의 체크박스 목록 — 피커 밖에서는 null.
  final MultiSelectModel? picker;

  /// 라벨 편집(`l`) 진입 시점의 대상 러너 — 편집 중 목록이 갱신돼
  /// 커서가 다른 러너를 가리키게 되더라도 원래 대상에 적용하기 위해 고정한다.
  final RunnerInfo? labelTarget;
  final DateTime? lastUpdated;
  final int width;
  final int height;

  /// `s` 키로 시작한 svc.sh 시퀀스가 아직 끝나지 않았는지. 끝나기 전에
  /// 'install'을 두 번 겹쳐 실행하는 걸 막는 재진입 방지 플래그 —
  /// 시퀀스 마지막의 [_SvcDoneMsg]로만 풀린다.
  final bool svcBusy;

  AppModel copyWith({
    Scope? scope,
    LocalRunner? local,
    List<RunnerInfo>? runners,
    TableModel? table,
    SpinnerModel? spinner,
    bool? loading,
    String? error,
    bool clearError = false,
    LocalStatus? localStatus,
    String? localStatusFor,
    bool clearLocalStatusFor = false,
    List<String>? log,
    _Mode? mode,
    TextInputModel? input,
    MultiSelectModel? picker,
    bool clearPicker = false,
    RunnerInfo? labelTarget,
    bool clearLabelTarget = false,
    DateTime? lastUpdated,
    int? width,
    int? height,
    bool? svcBusy,
  }) => AppModel(
    scope: scope ?? this.scope,
    local: local ?? this.local,
    gh: gh,
    runners: runners ?? this.runners,
    table: table ?? this.table,
    spinner: spinner ?? this.spinner,
    loading: loading ?? this.loading,
    error: clearError ? null : (error ?? this.error),
    localStatus: localStatus ?? this.localStatus,
    localStatusFor: clearLocalStatusFor
        ? null
        : (localStatusFor ?? this.localStatusFor),
    log: log ?? this.log,
    mode: mode ?? this.mode,
    input: input ?? this.input,
    picker: clearPicker ? null : (picker ?? this.picker),
    labelTarget: clearLabelTarget ? null : (labelTarget ?? this.labelTarget),
    lastUpdated: lastUpdated ?? this.lastUpdated,
    width: width ?? this.width,
    height: height ?? this.height,
    svcBusy: svcBusy ?? this.svcBusy,
  );

  RunnerInfo? get selected => runners.isEmpty || table.cursor >= runners.length
      ? null
      : runners[table.cursor];

  /// 커서 러너가 이 머신에 설치돼 있으면 그 설치 경로, 아니면 null.
  ///
  /// 로컬 전용 조작(`s`·`c`/`C`·`d`)이 공유하는 관문이다. 목록에는 다른
  /// 머신의 러너도 함께 뜨므로, 여기서 null이면 아무 명령도 실행하지 않는다.
  String? get selectedLocalDir {
    final name = selected?.name;
    return name == null ? null : local.findDirFor(name);
  }

  // ─── 테이블 구성 ──────────────────────────────────────────────────────────

  /// 현재 터미널 크기의 레이아웃 예산. 폭·높이가 바뀌면 이 값도 따라 바뀌므로
  /// 뷰는 항상 여기서 몫을 받아 그린다.
  Layout get layout => Layout.forTerminal(width, height);

  static TableModel _buildTable(
    List<RunnerInfo> runners,
    Layout layout, {
    required int cursor,
  }) {
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
        TableColumn(title: 'NAME', width: layout.nameColumnWidth),
        const TableColumn(title: 'JOB', width: 5),
        const TableColumn(title: 'OS', width: 6),
        TableColumn(title: 'LABELS', width: layout.labelColumnWidth),
      ],
      rows: rows,
      height: layout.tableRows,
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

  /// 커서 러너의 로컬 상태를 조회한다 (하단 '로컬:' 줄). 이 머신에 설치돼
  /// 있지 않으면 조회 없이 빈 상태를 돌려준다 — [_localLine]이 '이 머신에
  /// 설치되지 않음'으로 표시한다.
  ///
  /// 대상은 이 커맨드를 만드는 시점의 커서 러너로 고정된다. 응답이 늦게
  /// 도착했을 때 커서가 어디로 옮겨갔는지는 [_LocalStatusMsg.runnerName]으로
  /// 판별한다.
  Cmd _fetchLocal() {
    final name = selected?.name;
    if (name == null) {
      return () async => _LocalStatusMsg(null, LocalStatus.empty(local.dir));
    }
    final dir = local.findDirFor(name);
    if (dir == null) {
      return () async =>
          _LocalStatusMsg(name, LocalStatus.empty(local.dirFor(name)));
    }
    return () async => _LocalStatusMsg(name, await local.withDir(dir).status());
  }

  Cmd _refreshTimer() =>
      tick(const Duration(seconds: 15), (_) => _RefreshTickMsg());

  /// 이 머신 러너들의 plist에 KeepAlive를 심는다 — 이미 실행 중인 러너도
  /// 포함해 무중단으로([LocalRunner.hardenAllInstalled] 참고).
  ///
  /// 15초 폴링에는 걸지 않는다. 멱등이라 반복해도 해롭진 않지만, 러너 수만큼
  /// PlistBuddy를 계속 띄우게 되고 하드닝이 실패하는 환경에서는 같은 실패
  /// 로그가 15초마다 쌓인다. 상태가 바뀔 수 있는 시점(시작·스크립트 종료·
  /// 서비스 조작)에만 부른다.
  Cmd _hardenInstalled() =>
      () async => _LogMsg(await local.hardenAllInstalled());

  /// 자식 스크립트가 남긴 application cursor key 모드를 되돌린다
  /// (이유는 [resetCursorKeyMode] 참고). 순수 update를 지키려고 커맨드로 낸다.
  Cmd _resetCursorKeys() => () {
    resetCursorKeyMode();
    return null;
  };

  /// 외부 명령을 백그라운드로 실행하고 출력을 로그 패널로 보낸다.
  Cmd _runLogged(
    String label,
    String exe,
    List<String> args, {
    String? workingDir,
  }) => () async {
    try {
      final r = await Process.run(
        exe,
        args,
        workingDirectory: workingDir,
        runInShell: false,
      );
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

  /// [dir]에 설치된 러너의 서비스를 토글한다 (`s`).
  ///
  /// 실행할 서브커맨드는 화면의 [localStatus]가 아니라 이 커맨드 안에서 상태를
  /// 새로 조회해 정한다. [localStatus]는 15초 주기 폴링 결과라, 커서를 막
  /// 옮겼거나 그 사이 러너가 죽었으면 stop/start를 거꾸로 실행하게 된다.
  ///
  /// 한 단계가 실패하면 이후 단계는 건너뛴다. (단순히 각 서브커맨드를 개별
  /// `_runLogged`로 순차 실행하면 `install`이 실패해도 `start`가 그대로 이어져
  /// 실패해, 로그에 관련 없어 보이는 두 번째 에러가 쌓여 실제 원인이 묻힌다.)
  ///
  /// 서비스를 켜는 경로에서는 plist에 KeepAlive를 심고(크래시 자동 복구) 재부팅
  /// 자동 복귀를 막는 머신 설정을 점검한다 — 자세한 배경은
  /// [LocalRunner.keepAliveAddArgs]·[LocalRunner.bootWarnings] 참고.
  Cmd _toggleSvcIn(String dir) => () async {
    final status = await local.withDir(dir).status();
    final subcommands = LocalRunner.svcSubcommands(status);
    final lines = <String>[];
    var started = false;
    for (final sub in subcommands) {
      // launchd는 load 시점에 plist를 읽으므로 start 직전이 하드닝을 심을
      // 유일한 자리다. install 바로 다음이기도 해서 새로 등록한 러너와 이
      // 변경 이전에 등록해둔 기존 러너가 같은 경로로 KeepAlive를 얻는다.
      if (sub == 'start') {
        lines.addAll(
          await LocalRunner.hardenPlist(
            LocalRunner.plistPathIn(dir, status.agentName),
          ),
        );
      }
      // 어느 러너에 실행했는지 로그에 남긴다 — 여러 러너가 뜬 목록에서
      // 명령만 찍히면 대상을 되짚을 수 없다.
      lines.add('\$ svc.sh $sub  (${status.agentName ?? dir})');
      try {
        final r = await Process.run(
          './svc.sh',
          [sub],
          workingDirectory: dir,
          runInShell: false,
        );
        lines
          ..addAll((r.stdout as String).trim().split('\n'))
          ..addAll((r.stderr as String).trim().split('\n'))
          ..removeWhere((l) => l.isEmpty);
        if (r.exitCode != 0) {
          lines.add('(exit ${r.exitCode})');
          if (sub != subcommands.last) {
            lines.add('→ 이전 단계 실패로 다음 단계를 건너뜁니다');
          }
          break;
        }
        started = started || sub == 'start';
      } catch (e) {
        lines.add('error: $e');
        break;
      }
    }
    // 경고는 마지막에 붙인다 — 로그 패널은 꼬리 6줄만 보여주므로 여기 있어야
    // svc.sh 출력에 밀려나지 않는다.
    if (started) lines.addAll(await LocalRunner.bootReadiness());
    return _LogMsg(lines);
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

  /// [dir]에 설치된 로컬 러너의 해제를 준비한다. GitHub API만으로 지우면
  /// (=`_deleteRunner`) 로컬 `.runner`/`.credentials`가 남아, 이후
  /// register-runner.sh가 이미 등록된 러너로 오인해 재등록을 건너뛴다. 로컬
  /// 러너는 remove-runner.sh로 서비스 중지 + GitHub 해제 + 로컬 구성 정리까지
  /// 한 번에 처리한다.
  (List<String> logLines, Cmd? cmd) _removeLocalScript(String dir) {
    final script = LocalRunner.findScript('remove-runner.sh');
    if (script == null) {
      return (
        const ['remove-runner.sh를 찾지 못했습니다 (co-package 레포 안에서 실행하세요)'],
        null,
      );
    }
    final args = removeArgs(scope, dir);
    return (
      ['\$ remove-runner.sh ${args.join(' ')}'],
      execProcess(
        script,
        args,
        inheritStdio: true,
        onExit: (code) => _ScriptExitMsg('remove-runner.sh', code),
      ),
    );
  }

  /// 라벨 변경을 실행하고 결과를 로그로 보낸다.
  Cmd _mutateLabels(String desc, RunnerInfo r, Future<void> Function() run) =>
      () async {
        try {
          await run();
          return _LogMsg(['$desc 완료 (${r.name})']);
        } catch (e) {
          return _LogMsg(['$desc 실패 (${r.name}) — $e']);
        }
      };

  /// 피커에서 체크한 [labels]로 [r]의 커스텀 라벨을 교체하는 (안내 로그, 커맨드).
  ///
  /// 실행할 변경이 없으면 커맨드는 null. 피커 항목은 만들 때부터 편집 가능한
  /// 라벨만 담으므로([pickerLabels], `n` 입력의 read-only 필터) 여기서 다시
  /// 거르지 않는다.
  (List<String> logLines, Cmd? cmd) _labelReplacePlan(
    RunnerInfo r,
    List<String> labels,
  ) {
    if (_sameLabels(labels, r.customLabels)) {
      return (const ['변경된 라벨이 없습니다'], null);
    }
    if (labels.isEmpty) {
      return (
        const [],
        _mutateLabels(
          '커스텀 라벨 전체 삭제',
          r,
          () => gh.setRunnerLabels(scope, r.id, const []),
        ),
      );
    }
    return (
      const [],
      _mutateLabels(
        '라벨 적용: ${labels.join(', ')}',
        r,
        () => gh.setRunnerLabels(scope, r.id, labels),
      ),
    );
  }

  static bool _sameLabels(Iterable<String> a, Iterable<String> b) {
    final setA = a.toSet();
    final setB = b.toSet();
    return setA.length == setB.length && setA.containsAll(setB);
  }

  /// [target]의 라벨 피커를 만든다.
  ///
  /// 항목은 스코프에 이미 쓰이는 커스텀 라벨의 합집합([pickerLabels])에
  /// [extra](방금 `n`으로 입력한 새 라벨)를 더한 것이고, [checked]가 체크
  /// 상태다 (기본값 = [target]의 현재 커스텀 라벨). [cursorOn]이 있으면 그
  /// 라벨에 커서를 둔다.
  MultiSelectModel _buildPicker(
    RunnerInfo target, {
    Iterable<String>? checked,
    Iterable<String> extra = const [],
    String? cursorOn,
  }) {
    final checkedSet = {...(checked ?? target.customLabels)};
    final names = {...pickerLabels(runners, target), ...extra}.toList()..sort();
    return MultiSelectModel(
      items: [
        for (final n in names)
          MultiSelectItem(label: n, selected: checkedSet.contains(n)),
      ],
      cursor: cursorOn == null
          ? 0
          : names.indexOf(cursorOn).clamp(0, names.length),
      height: layout.pickerRows,
      // 상태줄은 직접 그린다 — 기본 상태줄은 'n/m selected' 영문이라 나머지
      // 화면과 어긋난다.
      showStatusBar: false,
      styles: MultiSelectStyles(
        cursor: _fg(_cyan).bold(),
        selectedItem: _fg(_cyan),
        checkedBox: _fg(_green).bold(),
        uncheckedBox: _fg(_gray),
        statusBar: _fg(_gray),
      ),
    );
  }

  /// 열려 있는 피커를 [rows] 높이로 다시 만든다 (체크·커서 상태는 유지).
  /// [MultiSelectModel]에는 공개 copyWith가 없어 필드를 옮겨 담는다.
  static MultiSelectModel _resizePicker(MultiSelectModel p, int rows) =>
      MultiSelectModel(
        items: p.items,
        cursor: p.cursor,
        title: p.title,
        height: rows,
        showStatusBar: p.showStatusBar,
        wrap: p.wrap,
        styles: p.styles,
      );

  /// register-runner.sh 실행을 준비한다.
  ///
  /// 러너는 이름별 하위 디렉토리 `<root>/<이름>`에 설치한다. [name]이 없으면
  /// (이름 미지정 등록) `{컴퓨터이름}-{랜덤 공룡}` 조합으로 기존 러너와 겹치지
  /// 않는 이름을 만들어 쓴다. 반환하는 [newLocal]은 방금 만든 러너를 가리키도록
  /// [local.dir]을 갱신한 것으로, 이후 상태 조회·서비스·해제가 이 러너를 향한다.
  (List<String> logLines, Cmd? cmd, LocalRunner? newLocal) _registerScript({
    String? name,
    String? labels,
  }) {
    final script = LocalRunner.findScript('register-runner.sh');
    if (script == null) {
      return (
        const ['register-runner.sh를 찾지 못했습니다 (co-package 레포 안에서 실행하세요)'],
        null,
        null,
      );
    }
    final runnerName = (name != null && name.isNotEmpty)
        ? name
        : generateRunnerName(hostSlug(), {for (final r in runners) r.name});
    final dir = local.dirFor(runnerName);
    final args = registerArgs(scope, dir, name: runnerName, labels: labels);

    // 방금 만든 러너를 로컬 추적 대상으로 삼고 설정에 저장한다.
    final newLocal = local.withDir(dir);
    TuiConfig(scope: scope, runnerDir: dir, runnersRoot: local.root).save();

    return (
      ['\$ register-runner.sh ${args.join(' ')}'],
      execProcess(
        script,
        args,
        inheritStdio: true,
        onExit: (code) => _ScriptExitMsg('register-runner.sh', code),
      ),
      newLocal,
    );
  }

  // ─── 라이프사이클 ────────────────────────────────────────────────────────

  @override
  Cmd? init() => batch([
    setWindowTitle('co-arc runners'),
    () => requestWindowSize(),
    _fetchRunners(),
    _fetchLocal(),
    // 이 변경 이전에 서비스로 등록해둔 러너 — 지금 돌고 있는 것까지 —
    // 를 TUI를 켜는 것만으로 따라잡는다.
    _hardenInstalled(),
    _refreshTimer(),
  ]);

  @override
  (Model, Cmd?) update(Msg msg) {
    switch (msg) {
      case WindowSizeMsg(:final width, :final height):
        final next = Layout.forTerminal(width, height);
        final p = picker;
        return (
          copyWith(
            width: width,
            height: height,
            table: _buildTable(runners, next, cursor: table.cursor),
            // 열려 있는 피커도 새 높이로 다시 만든다. 생성 시점 높이를 그대로
            // 두면 창을 줄였을 때 항목이 화면 밖으로 넘쳐 프레임이 밀린다.
            picker: p == null ? null : _resizePicker(p, next.pickerRows),
          ),
          // diff 렌더러는 리사이즈를 모른다 — 터미널이 스스로 버퍼를 리플로우해도
          // `_lastLines` 캐시는 그대로라, "이전 프레임과 같다"고 판단한 행을
          // 건너뛰어 옛 레이아웃 조각이 화면에 남는다. 캐시를 버리게 해서 다음
          // 프레임을 전면 재도색시킨다.
          () => clearScreen(),
        );

      case _RunnersLoadedMsg(:final scope, :final runners):
        // 스코프 전환 직전에 나간 요청의 늦은 응답은 무시
        if (scope.apiBase != this.scope.apiBase) return (this, null);
        final next = copyWith(
          runners: runners,
          table: _buildTable(runners, layout, cursor: table.cursor),
          loading: false,
          clearError: true,
          lastUpdated: DateTime.now(),
        );
        // 첫 로드(목록이 비어 커서 러너가 없던 시점)나 목록 변동으로 커서
        // 러너가 바뀌었으면 그 러너의 로컬 상태를 조회한다.
        return (
          next,
          next.selected?.name != localStatusFor ? next._fetchLocal() : null,
        );

      case _RunnersFailedMsg(:final scope, :final error):
        if (scope.apiBase != this.scope.apiBase) return (this, null);
        return (copyWith(loading: false, error: error), null);

      case _LocalStatusMsg(:final runnerName, :final status):
        // 커서가 이미 다른 러너로 옮겨간 뒤 도착한 늦은 응답은 버린다 — 그
        // 러너의 조회는 커서 이동 시점에 따로 나가 있다.
        if (runnerName != selected?.name) return (this, null);
        return (
          copyWith(
            localStatus: status,
            localStatusFor: runnerName,
            // 대상 러너가 없었으면(목록이 빈 스코프) 이전 러너 이름을 남기지
            // 않는다. 남겨두면 그 러너로 돌아왔을 때 재조회 없이 빈 상태를
            // 그 이름에 붙여 '설치되지 않음'으로 오표시한다.
            clearLocalStatusFor: runnerName == null,
          ),
          null,
        );

      case _SvcDoneMsg():
        return (copyWith(svcBusy: false), null);

      case _LogMsg(:final lines):
        final next = [...log, ...lines];
        return (
          copyWith(
            log: next.length > 200 ? next.sublist(next.length - 200) : next,
          ),
          null,
        );

      case _RefreshTickMsg():
        final fetch = (mode == _Mode.normal && !loading)
            ? batch([_fetchRunners(), _fetchLocal()])
            : null;
        return (
          loading ? this : copyWith(loading: fetch != null),
          batch([fetch, _refreshTimer()]),
        );

      case _ScriptExitMsg(:final label, :final exitCode):
        return (
          copyWith(log: [...log, '\$ $label → exit $exitCode'], loading: true),
          // 자식이 끝난 이 시점에 커서키 모드를 되돌린다 — DECCKM이 켜진 채로
          // 남으면 방향키가 SS3로 바뀌어 러너 선택 이동이 죽는다. 조회와는
          // 무관한 작업이라 batch 안 순서에는 의미가 없다.
          //
          // register-runner.sh가 --service로 서비스를 새로 깔았을 수 있어
          // 하드닝도 함께 돌린다 (이미 적용된 러너는 건너뛴다).
          batch([
            _resetCursorKeys(),
            _fetchRunners(),
            _fetchLocal(),
            _hardenInstalled(),
          ]),
        );

      case TickMsg():
        final (next, cmd) = spinner.update(msg);
        return (copyWith(spinner: next as SpinnerModel), cmd);

      case KeyMsg(:final key):
        return _onKey(key, msg);

      // 붙여넣기는 KeyMsg가 아니라 PasteMsg로 온다 (bracketed paste가 기본
      // 활성). 이걸 처리하지 않아 프롬프트에 붙여넣기가 통째로 무시됐다.
      case PasteMsg(:final content):
        return (_pasteIntoInput(content), null);

      default:
        return (this, null);
    }
  }

  /// 붙여넣은 [content]를 입력 커서 자리에 끼워 넣는다.
  ///
  /// 한 줄 입력이므로 개행·탭은 공백으로 접는다 — 터미널에서 복사하면 끝에
  /// 개행이 딸려오기 마련인데, 그대로 넣으면 라벨 이름에 섞여 들어간다.
  AppModel _pasteIntoInput(String content) {
    if (!mode.isTextInput) return this;
    final text = content.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (text.isEmpty) return this;
    final chars = input.value.characters.toList();
    final pos = input.cursorPos.clamp(0, chars.length);
    return copyWith(
      input: input.copyWith(
        value: [...chars.take(pos), text, ...chars.skip(pos)].join(),
        cursorPos: pos + text.characters.length,
      ),
    );
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
          // 이 머신의 로컬 러너면 API 삭제 대신 remove-runner.sh로 로컬 구성까지
          // 정리한다 (GitHub만 지우면 stale .runner가 남아 재등록이 막힌다).
          // 추적 중인 러너인지가 아니라 커서 러너의 설치 여부로 판단한다 —
          // 이 머신의 러너라도 추적 대상이 아니면 로컬 정리를 건너뛰게 된다.
          final localDir = selectedLocalDir;
          if (localDir != null) {
            final (lines, cmd) = _removeLocalScript(localDir);
            return (
              copyWith(
                mode: _Mode.normal,
                loading: cmd != null,
                log: [...log, ...lines],
              ),
              cmd,
            );
          }
          return (
            copyWith(mode: _Mode.normal, loading: true),
            sequence([_deleteRunner(target), _fetchRunners()]),
          );
        }
        return (copyWith(mode: _Mode.normal), null);

      case _Mode.scopeInput:
        return _onScopeInputKey(key, msg);

      case _Mode.registerInput:
        return _onRegisterInputKey(key, msg);

      case _Mode.labelPicker:
        return _onLabelPickerKey(key, msg);

      case _Mode.labelNewInput:
        return _onLabelNewInputKey(key, msg);

      case _Mode.normal:
        return _onNormalKey(key, msg);
    }
  }

  /// 커서 이동·단어 삭제·글자 입력 등 편집 키를 [TextInputModel]에 넘긴다.
  /// (esc·enter처럼 모드마다 뜻이 다른 키는 각 핸들러가 먼저 가로챈다.)
  (Model, Cmd?) _editInput(KeyMsg msg) {
    final (next, cmd) = input.update(msg);
    return (copyWith(input: next as TextInputModel), cmd);
  }

  static TextInputModel _newInput([String value = '']) =>
      TextInputModel(value: value, cursorPos: value.characters.length);

  (Model, Cmd?) _onScopeInputKey(String key, KeyMsg msg) {
    switch (key) {
      case 'esc':
        return (copyWith(mode: _Mode.normal, input: _newInput()), null);
      case 'enter':
        final trimmed = input.value.trim();
        if (trimmed.isEmpty) {
          return (copyWith(mode: _Mode.normal, input: _newInput()), null);
        }
        final next = Scope.parse(trimmed);
        TuiConfig(
          scope: next,
          runnerDir: local.dir,
          runnersRoot: local.root,
        ).save();
        return (
          copyWith(
            scope: next,
            mode: _Mode.normal,
            input: _newInput(),
            loading: true,
            runners: const [],
            table: _buildTable(const [], layout, cursor: 0),
            log: [...log, '스코프 변경: ${next.label}'],
          ),
          _fetchRunnersFor(next),
        );
      default:
        return _editInput(msg);
    }
  }

  (Model, Cmd?) _onRegisterInputKey(String key, KeyMsg msg) {
    switch (key) {
      case 'esc':
        return (copyWith(mode: _Mode.normal, input: _newInput()), null);
      case 'enter':
        final (name, labels) = parseRegisterInput(input.value);
        final (lines, cmd, newLocal) = _registerScript(
          name: name,
          labels: labels,
        );
        return (
          copyWith(
            mode: _Mode.normal,
            input: _newInput(),
            log: [...log, ...lines],
            local: newLocal,
          ),
          cmd,
        );
      default:
        return _editInput(msg);
    }
  }

  /// 라벨 피커(`l`)의 키. 이동·토글은 [MultiSelectModel]에 맡기고 여기서는
  /// 피커를 여닫는 키(적용/취소/새 라벨)만 다룬다.
  (Model, Cmd?) _onLabelPickerKey(String key, KeyMsg msg) {
    final target = labelTarget;
    final current = picker;
    if (target == null || current == null) return (_closePicker(), null);

    switch (key) {
      case 'esc':
        return (_closePicker(), null);

      case 'n':
        return (copyWith(mode: _Mode.labelNewInput, input: _newInput()), null);

      case 'enter':
        final (lines, cmd) = _labelReplacePlan(
          target,
          current.selectedValues.toList()..sort(),
        );
        return (
          // 적용할 게 없으면 loading은 건드리지 않는다 — false로 덮으면 이미
          // 떠 있던 다른 조회의 스피너가 꺼진다.
          _closePicker(
            log: [...log, ...lines],
            loading: cmd == null ? null : true,
          ),
          cmd == null ? null : sequence([cmd, _fetchRunners()]),
        );

      default:
        final (next, cmd) = current.update(msg);
        return (copyWith(picker: next as MultiSelectModel), cmd);
    }
  }

  AppModel _closePicker({List<String>? log, bool? loading}) => copyWith(
    mode: _Mode.normal,
    input: _newInput(),
    clearPicker: true,
    clearLabelTarget: true,
    log: log,
    loading: loading,
  );

  /// 피커에 없는 새 라벨 입력(`n`)의 키. 확정하면 피커로 돌아간다 —
  /// GitHub 호출은 피커에서 Enter를 누를 때 한 번에 나간다.
  (Model, Cmd?) _onLabelNewInputKey(String key, KeyMsg msg) {
    final target = labelTarget;
    final current = picker;
    if (target == null || current == null) return (_closePicker(), null);

    switch (key) {
      case 'esc':
        return (copyWith(mode: _Mode.labelPicker, input: _newInput()), null);

      case 'enter':
        final (editable, skipped) = splitEditableLabels(
          splitLabelsCsv(input.value),
          target.readOnlyLabels,
        );
        final lines = <String>[
          if (skipped.isNotEmpty)
            'read-only 라벨은 편집 불가, 건너뜀: ${skipped.join(', ')}',
        ];
        if (editable.isEmpty) {
          return (
            copyWith(
              mode: _Mode.labelPicker,
              input: _newInput(),
              log: [...log, ...lines],
            ),
            null,
          );
        }
        return (
          copyWith(
            mode: _Mode.labelPicker,
            input: _newInput(),
            picker: _buildPicker(
              target,
              checked: {...current.selectedValues, ...editable},
              // 지금 목록에 있는 항목을 모두 다시 넘긴다 — pickerLabels는 스코프의
              // 러너들이 쓰는 라벨만 알기 때문에, 앞서 n으로 추가한 라벨은 여기서
              // 넘기지 않으면 두 번째 n에서 소리 없이 사라진다.
              extra: [...current.items.map((i) => i.label), ...editable],
              // 방금 추가한 라벨 위에 커서를 둔다 — 목록이 이름순이라 새 라벨이
              // 어디로 끼어들었는지 눈으로 찾게 두면 추가한 티가 안 난다.
              cursorOn: editable.first,
            ),
            log: [...log, ...lines],
          ),
          null,
        );

      default:
        return _editInput(msg);
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
        return (copyWith(mode: _Mode.scopeInput, input: _newInput()), null);

      case 'd':
        if (selected == null) return (this, null);
        return (copyWith(mode: _Mode.confirmDelete), null);

      case 'a':
        final (lines, cmd, newLocal) = _registerScript();
        return (copyWith(log: [...log, ...lines], local: newLocal), cmd);

      case 'A':
        return (copyWith(mode: _Mode.registerInput, input: _newInput()), null);

      case 'l':
        final target = selected;
        if (target == null) return (this, null);
        return (
          copyWith(
            mode: _Mode.labelPicker,
            labelTarget: target,
            picker: _buildPicker(target),
          ),
          null,
        );

      case 's':
        if (selected == null) return (this, null);
        if (svcBusy) {
          return (
            copyWith(log: [...log, '이전 svc.sh 실행이 끝나기를 기다리는 중입니다']),
            null,
          );
        }
        final svcDir = selectedLocalDir;
        if (svcDir == null) return (copyWith(log: _notLocalLog()), null);
        return (
          copyWith(svcBusy: true),
          sequence([
            _toggleSvcIn(svcDir),
            _fetchLocal(),
            // 반드시 시퀀스 마지막 — svcBusy는 이 신호로만 풀린다.
            () async => _SvcDoneMsg(),
          ]),
        );

      case 'c':
      case 'C':
        if (selected == null) return (this, null);
        final cleanupDir = selectedLocalDir;
        if (cleanupDir == null) return (copyWith(log: _notLocalLog()), null);
        final script = LocalRunner.findScript('cleanup-work.sh');
        if (script == null) {
          return (copyWith(log: [...log, 'cleanup-work.sh를 찾지 못했습니다']), null);
        }
        final args = ['--dir', cleanupDir, if (key == 'c') '--dry-run'];
        return (
          this,
          sequence([
            _runLogged('cleanup-work.sh ${args.join(' ')}', script, args),
            _fetchLocal(),
          ]),
        );

      default:
        final (next, cmd) = table.update(msg);
        final nextTable = next as TableModel;
        final moved = nextTable.cursor != table.cursor;
        final nextModel = copyWith(table: nextTable);
        // 커서가 다른 러너로 옮겨갔으면 하단 '로컬:' 줄을 그 러너 기준으로
        // 다시 조회한다 (조회는 새 커서 위치를 반영한 모델에서 만들어야 한다).
        return (nextModel, moved ? batch([cmd, nextModel._fetchLocal()]) : cmd);
    }
  }

  /// 커서 러너가 이 머신 소속이 아닐 때 남길 로그. 기대한 설치 경로를 함께
  /// 보여줘 왜 로컬이 아닌지 바로 확인할 수 있게 한다.
  List<String> _notLocalLog() {
    final r = selected;
    if (r == null) return log;
    return [
      ...log,
      '${r.name}은(는) 이 머신에 설치된 러너가 아닙니다 '
          '(${local.dirFor(r.name)} 없음) — 해당 머신에서 실행하세요',
    ];
  }

  // ─── 뷰 ──────────────────────────────────────────────────────────────────

  /// 프레임은 반드시 [fitFrame]을 거쳐 나간다 — 어떤 화면이든 터미널보다
  /// 크면 렌더러의 절대 좌표 쓰기가 어긋나 레이아웃이 영구히 밀린다.
  @override
  View view() {
    final l = layout;
    if (mode == _Mode.help) return newView(fitFrame(_helpView(l), l));
    if (mode == _Mode.labelPicker || mode == _Mode.labelNewInput) {
      return newView(fitFrame(_labelPickerView(l), l));
    }

    final b = StringBuffer();
    b.writeln(_headerLine(l));
    if (l.showSpacers) b.writeln();

    if (error != null) {
      // gh 오류 본문은 길이를 알 수 없다. 표가 쓰던 몫(헤더·구분선 2줄 +
      // 데이터 행) 안으로 묶어, 긴 오류가 아래 패널과 푸터를 밀어내지 않게 한다.
      final lines = error!.split('\n');
      final budget = l.tableRows + 1;
      for (final line in lines.take(budget)) {
        b.writeln(_fg(_red).render(l.clip(' gh 오류: $line')));
      }
      final hidden = lines.length - budget;
      b.writeln(
        _fg(_gray).render(
          l.clip(
            hidden > 0
                ? ' …외 $hidden줄 · gh auth status를 확인하세요. r로 재시도.'
                : ' gh auth status를 확인하세요. r로 재시도.',
          ),
        ),
      );
    } else if (runners.isEmpty && !loading) {
      b.writeln(_fg(_gray).render(l.clip(' 등록된 러너가 없습니다. a를 눌러 이 머신을 등록하세요.')));
    } else {
      b.writeln(table.view().content);
    }

    if (l.showSpacers) b.writeln();
    b.writeln(_localLine(l));
    b.writeln(_fg(_gray).render('─' * l.contentWidth));
    for (final line in _logTail(l.logLines)) {
      b.writeln(_fg(_gray).render(l.clip(' $line')));
    }
    if (l.showSpacers) b.writeln();
    b.write(_footerLine(l));
    return newView(fitFrame(b.toString(), l));
  }

  String _headerLine(Layout l) {
    final title = const Style().bold().render(' co-arc runners');
    final spin = loading ? ' ${spinner.view().content}' : '';
    final updated = lastUpdated == null
        ? ''
        : ' · ${lastUpdated!.hour.toString().padLeft(2, '0')}:'
              '${lastUpdated!.minute.toString().padLeft(2, '0')}:'
              '${lastUpdated!.second.toString().padLeft(2, '0')} 갱신';
    final online = runners.where((r) => r.online).length;
    final info = _fg(
      _cyan,
    ).render('${scope.label} · ${runners.length}대 (온라인 $online)$updated');
    return l.clip('$title$spin   $info');
  }

  /// 커서 러너의 로컬 상태 줄. `s`·`c`/`C`·`d`가 대상으로 삼는 러너가 바로
  /// 여기 표시된 러너다.
  String _localLine(Layout l) {
    final r = selected;
    if (r == null) return l.clip(' 로컬: ${_fg(_gray).render('(러너 없음)')}');

    final name = const Style().bold().render(r.name);
    // 아직 이 러너의 상태를 조회하지 못했다면(커서 이동 직후) 이전 러너의
    // 상태를 이 이름 옆에 붙이지 않는다.
    if (localStatusFor != r.name) {
      return l.clip(' 로컬: $name · ${_fg(_gray).render('확인 중…')}');
    }

    final s = localStatus;
    final parts = <String>[name];
    if (!s.configured) {
      parts.add(_fg(_gray).render('이 머신에 설치되지 않음'));
    } else {
      parts.add(
        s.listenerRunning
            ? _fg(_green).render('listener 실행 중')
            : _fg(_red).render('listener 중지'),
      );
      parts.add(
        s.svcInstalled
            ? _fg(_gray).render('launchd 등록됨')
            : _fg(_gray).render('launchd 미등록'),
      );
      // 하드닝은 자동으로 걸리므로(_hardenInstalled) 이 경고가 보인다면
      // 적용에 실패한 것이다 — 조용히 넘어가면 재부팅 뒤에야 알게 된다.
      if (s.svcHardened == false) {
        parts.add(_fg(_yellow).render('KeepAlive 없음'));
      }
      if (s.workUsage != null) {
        parts.add(_fg(_gray).render('_work ${s.workUsage}'));
      }
    }
    return l.clip(' 로컬: ${parts.join(' · ')}');
  }

  /// 라벨 피커 화면 (`l`). 새 라벨 입력(`n`) 중에도 같은 화면 위에서
  /// 하단 줄만 입력 프롬프트로 바뀐다 — 무엇을 골라뒀는지 보면서 타이핑한다.
  String _labelPickerView(Layout l) {
    final target = labelTarget;
    final p = picker;
    if (target == null || p == null) return ' (라벨 편집 대상 없음)';

    final b = StringBuffer();
    b.writeln(const Style().bold().render(l.clip(' 라벨 편집 — ${target.name}')));
    final readOnly = target.readOnlyLabels;
    if (readOnly.isNotEmpty) {
      b.writeln(
        _fg(_gray).render(l.clip(' read-only(편집 불가): ${readOnly.join(', ')}')),
      );
    }
    if (l.showSpacers) b.writeln();

    if (p.items.isEmpty) {
      b.writeln(
        _fg(_gray).render(l.clip(' 스코프에 등록된 커스텀 라벨이 없습니다 — n으로 새 라벨을 추가하세요.')),
      );
    } else {
      // 항목 줄은 이미 스타일이 입혀져 나오므로 줄 단위로 잘라 넣는다.
      for (final line in p.view().content.split('\n')) {
        b.writeln(l.clip(line));
      }
      if (l.showSpacers) b.writeln();
      b.writeln(
        _fg(
          _gray,
        ).render(l.clip(' ${p.selectedValues.length}/${p.items.length} 선택됨')),
      );
    }

    if (l.showSpacers) b.writeln();
    b.writeln(_fg(_gray).render('─' * l.contentWidth));
    b.write(
      mode == _Mode.labelNewInput
          ? l.clip(
              ' ${_fg(_cyan).render('새 라벨>')} ${_renderInput()}'
              '${_fg(_gray).render('   (CSV로 여러 개 · Enter 추가 · Esc 취소)')}',
            )
          : _fg(_gray).render(
              l.clip(
                ' ↑↓ 이동 · space 토글 · a 전체 토글 · n 새 라벨 · Enter 적용 · Esc 취소',
              ),
            ),
    );
    return b.toString();
  }

  /// 한 줄 입력을 렌더한다 — 커서 자리의 글자를 반전시켜 위치를 보여준다.
  /// (텍스트 끝에는 반전할 글자가 없으므로 공백 블록을 붙인다.)
  String _renderInput() {
    final cursor = const Style().reverse();
    final chars = input.value.characters.toList();
    final pos = input.cursorPos.clamp(0, chars.length);
    final before = chars.take(pos).join();
    if (pos >= chars.length) return '$before${cursor.render(' ')}';
    return '$before${cursor.render(chars[pos])}${chars.skip(pos + 1).join()}';
  }

  /// 로그 패널에 그릴 마지막 [n]줄. [n]이 0이면 (세로가 좁아 로그를 포기한
  /// 경우) 아무 줄도 내주지 않는다 — '(로그 없음)' 안내조차 자리를 뺏는다.
  List<String> _logTail(int n) {
    if (n <= 0) return const [];
    if (log.isEmpty) return const ['(로그 없음)'];
    return log.length <= n ? log : log.sublist(log.length - n);
  }

  String _footerLine(Layout l) {
    switch (mode) {
      case _Mode.confirmDelete:
        final r = selected;
        // 확인 문구와 실제 동작이 갈리지 않도록 실행부(_onKey의 confirmDelete)와
        // 같은 기준으로 판단한다.
        final howto = selectedLocalDir != null
            ? '이 머신에서 해제(서비스 중지 + 로컬 구성 정리)할까요?'
            : 'GitHub에서 해제할까요?';
        return _fg(
          _yellow,
        ).render(l.clip(" '${r?.name}' (id ${r?.id}) 러너를 $howto [y/N]"));
      case _Mode.scopeInput:
        return l.clip(
          ' ${_fg(_cyan).render('scope>')} ${_renderInput()}'
          '${_fg(_gray).render('   (org 이름 또는 owner/repo · Enter 확정 · Esc 취소)')}',
        );
      case _Mode.registerInput:
        return l.clip(
          ' ${_fg(_cyan).render('register>')} ${_renderInput()}'
          '${_fg(_gray).render('   (이름 [라벨1,라벨2,...] · 빈 입력=기본값 · Enter 등록 · Esc 취소)')}',
        );
      default:
        return _fg(_gray).render(
          l.clip(
            ' ↑↓ 이동 · r 갱신 · a 등록 · A 이름지정등록 · l 라벨 · d 해제 · s 서비스 · c/C 정리 · g 스코프 · ? 도움말 · q 종료',
          ),
        );
    }
  }

  String _helpView(Layout l) {
    const rows = <(String, String)>[
      ('↑/↓, j/k', '러너 선택 이동'),
      ('r', 'GitHub 러너 목록 + 로컬 상태 새로고침 (15초마다 자동)'),
      ('a', '이 머신을 러너로 등록 — scripts/register-runner.sh 실행 (TUI 일시 중단)'),
      (
        'A',
        '이름/라벨을 직접 입력해 등록 — "이름 라벨1,라벨2" (빈 입력은 a와 동일). '
            '이름이 이미 스코프에 있으면 -2, -3 ...으로 자동 회피',
      ),
      (
        'l',
        '선택 러너의 커스텀 라벨 편집 — 스코프의 모든 러너가 쓰는 라벨이 체크박스로 뜬다. '
            'space 토글 · a 전체 토글 · n 새 라벨 입력(CSV) · Enter 적용 · Esc 취소. '
            '체크한 집합이 그대로 커스텀 라벨이 된다 (self-hosted 등 read-only 라벨은 편집 불가)',
      ),
      ('d', '선택한 러너를 GitHub에서 해제 (오프라인 러너만 가능)'),
      (
        's',
        '선택 러너의 서비스 시작/중지 (svc.sh) — 이 머신에 설치된 러너만. '
            '실행 중(launchd·포그라운드 무관)이면 stop, 안 떠 있고 서비스 '
            '미설치(재부팅 등으로 사라졌거나 등록한 적 없음)면 install 후 '
            '자동으로 start, 설치돼 있으면 start. 켤 때 plist에 KeepAlive를 심어 '
            '러너가 죽어도 되살아나게 하고, 재부팅 자동 복귀를 막는 머신 '
            '설정(자동 로그인·FileVault·절전)을 점검해 로그에 남긴다',
      ),
      (
        'c / C',
        '선택 러너의 _work 정리 — c는 dry-run, C는 실제 삭제 '
            '(scripts/cleanup-work.sh, 이 머신에 설치된 러너만)',
      ),
      ('g', '스코프 전환 — org 이름(coco-de) 또는 owner/repo 입력'),
      ('q, ctrl+c', '종료'),
    ];

    final keys = [
      for (final (k, desc) in rows)
        l.clip('  ${_fg(_cyan).render(k.padRight(12))} $desc'),
    ];
    final info = [
      _fg(
        _gray,
      ).render(l.clip(' 현재 스코프: ${scope.label} · 러너 디렉토리: ${local.dir}')),
      _fg(
        _gray,
      ).render(l.clip(' 온라인 러너 해제는 해당 머신에서 scripts/remove-runner.sh를 사용하세요.')),
    ];

    // 우선순위: 제목 > 키 목록 > 돌아가기 안내 > 부가 정보 > 여백.
    // 창이 작으면 뒤 순위부터 버리되, 키 목록을 잘라냈으면 몇 개를 못 보여줬는지
    // 안내 문구로 밝힌다 — 조용히 잘라내면 그게 전부인 줄 알게 된다.
    final lines = <String>[
      const Style().bold().render(l.clip(' co-arc runner TUI — 도움말')),
    ];
    var remaining = l.height - 2; // 제목 1줄 + 마지막 안내 1줄을 뺀 나머지
    if (l.showSpacers && remaining > 0) {
      lines.add('');
      remaining--;
    }

    final shown = remaining < keys.length
        ? keys.take(remaining < 0 ? 0 : remaining).toList()
        : keys;
    lines.addAll(shown);
    remaining -= shown.length;
    final dropped = keys.length - shown.length;

    final infoNeed = info.length + (l.showSpacers ? 1 : 0);
    if (remaining >= infoNeed) {
      if (l.showSpacers) lines.add('');
      lines.addAll(info);
      remaining -= infoNeed;
    }

    if (l.showSpacers && remaining > 0) lines.add('');
    lines.add(
      _fg(_gray).render(
        l.clip(
          dropped > 0
              ? ' 아무 키나 누르면 돌아갑니다. (창을 키우면 나머지 키 $dropped개도 보입니다)'
              : ' 아무 키나 누르면 돌아갑니다.',
        ),
      ),
    );
    return lines.join('\n');
  }
}

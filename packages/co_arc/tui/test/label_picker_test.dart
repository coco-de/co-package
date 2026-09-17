import 'package:coarc_tui/coarc_tui.dart';
import 'package:dart_tui/dart_tui.dart';
import 'package:test/test.dart';

RunnerInfo _runner(String name, List<String> custom) => RunnerInfo(
      id: name.hashCode,
      name: name,
      os: 'macOS',
      status: 'online',
      busy: false,
      labels: ['self-hosted', 'macOS', ...custom],
      customLabels: custom,
    );

final _runners = [
  _runner('kentrosaurus', ['flutter', 'ios']),
  _runner('oviraptor', ['serverpod']),
];

AppModel _model({int cursor = 0}) => AppModel(
      scope: const Scope.org('coco-de'),
      local: LocalRunner(dir: '/tmp/x', root: '/tmp'),
      runners: _runners,
      table: TableModel(
        columns: const [TableColumn(title: 'NAME', width: 26)],
        rows: [
          for (final r in _runners) [r.name],
        ],
        height: 10,
        cursor: cursor,
      ),
    );

Msg _key(String text) => KeyPressMsg(TeaKey(code: KeyCode.rune, text: text));

Msg _named(KeyCode code) => KeyPressMsg(TeaKey(code: code));

/// [msgs]를 차례로 흘려보낸 뒤 최종 모델. 커맨드는 버린다 — 이 테스트가 보는
/// 건 모델 상태 전이뿐이고, 실제 GitHub 호출은 커맨드 안에 있다.
AppModel _run(AppModel start, List<Msg> msgs) {
  var model = start;
  for (final msg in msgs) {
    model = model.update(msg).$1 as AppModel;
  }
  return model;
}

void main() {
  group('라벨 피커 (l)', () {
    test('스코프 전체 라벨을 올리고 대상 러너 라벨만 체크한다', () {
      final m = _run(_model(), [_key('l')]);

      expect(m.labelTarget?.name, 'kentrosaurus');
      expect(
        m.picker!.items.map((i) => i.label),
        ['flutter', 'ios', 'serverpod'],
      );
      expect(m.picker!.selectedValues, ['flutter', 'ios']);
    });

    test('space로 라벨을 켜고 끈다', () {
      // 커서는 'flutter'(체크됨) → space로 해제, 아래로 두 칸 내려 serverpod 체크.
      final m = _run(_model(), [
        _key('l'),
        _named(KeyCode.space),
        _named(KeyCode.down),
        _named(KeyCode.down),
        _named(KeyCode.space),
      ]);
      expect(m.picker!.selectedValues, ['ios', 'serverpod']);
    });

    test('Esc는 대상과 피커를 버린다', () {
      final m = _run(_model(), [_key('l'), _named(KeyCode.escape)]);
      expect(m.picker, isNull);
      expect(m.labelTarget, isNull);
    });

    test('러너가 없으면 피커를 열지 않는다', () {
      final empty = AppModel(
        scope: const Scope.org('coco-de'),
        local: LocalRunner(dir: '/tmp/x', root: '/tmp'),
      );
      expect(_run(empty, [_key('l')]).picker, isNull);
    });

    test('변경 없이 Enter를 누르면 GitHub 호출 없이 닫힌다', () {
      final (model, cmd) =
          _run(_model(), [_key('l')]).update(_named(KeyCode.enter));
      expect(cmd, isNull);
      expect((model as AppModel).log.last, '변경된 라벨이 없습니다');
      expect(model.picker, isNull);
    });

    test('체크를 바꾸고 Enter를 누르면 적용 커맨드가 나간다', () {
      final picked = _run(_model(), [_key('l'), _named(KeyCode.space)]);
      final (model, cmd) = picked.update(_named(KeyCode.enter));
      expect(cmd, isNotNull);
      expect((model as AppModel).loading, isTrue);
      expect(model.picker, isNull);
    });
  });

  group('새 라벨 입력 (n)', () {
    test('입력한 라벨이 체크된 채로 목록에 들어가고 커서가 그 위에 선다', () {
      // 한 글자씩 흘려보낸다 — 실제 타이핑과 같은 경로.
      final done = _run(_model(), [
        _key('l'),
        _key('n'),
        for (final c in 'android'.split('')) _key(c),
        _named(KeyCode.enter),
      ]);

      expect(
        done.picker!.items.map((i) => i.label),
        ['android', 'flutter', 'ios', 'serverpod'],
      );
      expect(done.picker!.selectedValues, ['android', 'flutter', 'ios']);
      expect(done.picker!.cursor, 0); // 'android'
    });

    test('CSV로 여러 개를 한 번에 추가한다', () {
      final m = _run(_model(), [
        _key('l'),
        _key('n'),
        for (final c in 'web,linux'.split('')) _key(c),
        _named(KeyCode.enter),
      ]);
      expect(m.picker!.selectedValues, ['flutter', 'ios', 'linux', 'web']);
    });

    test('두 번 연속 추가해도 먼저 추가한 라벨이 남는다', () {
      // 피커를 다시 만들 때 기존 항목을 넘기지 않으면, pickerLabels가 아는
      // 라벨(=스코프의 러너들이 쓰는 것)만 남아 앞서 추가한 라벨이 사라진다.
      final m = _run(_model(), [
        _key('l'),
        _key('n'),
        for (final c in 'android'.split('')) _key(c),
        _named(KeyCode.enter),
        _key('n'),
        for (final c in 'linux'.split('')) _key(c),
        _named(KeyCode.enter),
      ]);
      expect(
        m.picker!.items.map((i) => i.label),
        ['android', 'flutter', 'ios', 'linux', 'serverpod'],
      );
      expect(m.picker!.selectedValues, ['android', 'flutter', 'ios', 'linux']);
    });

    test('read-only 라벨은 걸러내고 사유를 로그로 남긴다', () {
      final m = _run(_model(), [
        _key('l'),
        _key('n'),
        for (final c in 'self-hosted'.split('')) _key(c),
        _named(KeyCode.enter),
      ]);
      expect(
          m.picker!.items.map((i) => i.label), isNot(contains('self-hosted')));
      expect(m.log.last, contains('read-only'));
    });

    test('Esc는 피커로 되돌아가고 체크 상태를 유지한다', () {
      final m = _run(_model(), [
        _key('l'),
        _named(KeyCode.space), // flutter 해제
        _key('n'),
        for (final c in 'oops'.split('')) _key(c),
        _named(KeyCode.escape),
      ]);
      expect(m.picker!.items.map((i) => i.label), isNot(contains('oops')));
      expect(m.picker!.selectedValues, ['ios']);
    });
  });

  group('텍스트 입력', () {
    test('붙여넣기가 커서 자리에 들어간다', () {
      // bracketed paste는 KeyMsg가 아니라 PasteMsg로 도착한다 — 이걸 처리하지
      // 않아 프롬프트에 붙여넣기가 통째로 무시되던 게 이 작업의 출발점이다.
      final m = _run(_model(), [_key('l'), _key('n'), PasteMsg('flutter')]);
      expect(m.input.value, 'flutter');
      expect(m.input.cursorPos, 7);
    });

    test('붙여넣기의 개행·탭은 공백으로 접고 양끝은 잘라낸다', () {
      final m =
          _run(_model(), [_key('l'), _key('n'), PasteMsg('  a,\n\tb \n')]);
      expect(m.input.value, 'a, b');
    });

    test('스코프·등록 프롬프트에서도 붙여넣기가 된다', () {
      expect(
          _run(_model(), [_key('g'), PasteMsg('coco-de/co-arc')]).input.value,
          'coco-de/co-arc');
      expect(
          _run(_model(), [_key('A'), PasteMsg('runner-1 flutter')]).input.value,
          'runner-1 flutter');
    });

    test('피커·일반 모드의 붙여넣기는 무시한다', () {
      expect(_run(_model(), [PasteMsg('junk')]).input.value, isEmpty);
      expect(
          _run(_model(), [_key('l'), PasteMsg('junk')]).input.value, isEmpty);
    });

    test('커서를 옮겨 중간에 글자를 넣는다', () {
      final m = _run(_model(), [
        _key('l'),
        _key('n'),
        for (final c in 'flutter'.split('')) _key(c),
        _named(KeyCode.left),
        _named(KeyCode.left),
        _key('X'),
      ]);
      expect(m.input.value, 'fluttXer');
    });

    test('ctrl+a로 맨 앞, ctrl+e로 맨 뒤', () {
      final typed = _run(_model(), [
        _key('l'),
        _key('n'),
        for (final c in 'abc'.split('')) _key(c),
      ]);
      final home = _run(typed, [
        KeyPressMsg(const TeaKey(
            code: KeyCode.rune, text: 'a', modifiers: {KeyMod.ctrl})),
      ]);
      expect(home.input.cursorPos, 0);

      final end = _run(home, [
        KeyPressMsg(const TeaKey(
            code: KeyCode.rune, text: 'e', modifiers: {KeyMod.ctrl})),
      ]);
      expect(end.input.cursorPos, 3);
    });

    test('프롬프트를 열 때마다 입력이 비어 있다', () {
      final dirty = _run(_model(), [_key('g'), PasteMsg('coco-de')]);
      expect(_run(dirty, [_named(KeyCode.escape), _key('g')]).input.value,
          isEmpty);
    });
  });
}

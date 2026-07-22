import 'dart:async';

// ─── 바이트 상수 ──────────────────────────────────────────────────────────────
const int _esc = 0x1b; // ESC
const int _o = 0x4f; // 'O' — SS3 introducer의 두 번째 바이트
const int _bracket = 0x5b; // '[' — CSI introducer의 두 번째 바이트
const int _arrowLo = 0x41; // 'A' (up)
const int _arrowHi = 0x44; // 'D' (left)

/// application cursor key 모드(DECCKM)에서 방향키가 보내는 SS3 시퀀스
/// (`ESC O A`~`ESC O D`)를 dart_tui가 이해하는 CSI 형태(`ESC [ A`~`ESC [ D`)로
/// 바꾼다.
///
/// 왜 필요한가: 자식 스크립트(config.sh)·멀티플렉서·재접속 등 무엇이든 DECCKM을
/// 켜면 방향키가 `ESC [ A`가 아니라 `ESC O A`를 보낸다. dart_tui 1.4.0의 SS3
/// 파서는 home·end·F1~F4만 알고 화살표(A~D)는 `unknown`으로 버려, 러너 선택
/// 이동이 죽는다. #17의 `rmkx` 리셋은 "자식이 켠 경우"만 되돌리므로, 처음부터
/// application 모드로 뜨는 터미널까지 덮으려면 입력단에서 재매핑해야 한다.
///
/// [Ss3ArrowRemapper]는 스트림·타이머와 분리된 **동기 순수 변환기**다 —
/// 스트림 배선은 [remapSs3ArrowKeys]가 감싸고, 이 클래스는 바이트 규칙만
/// 담당해 그대로 단위 테스트할 수 있다.
final class Ss3ArrowRemapper {
  /// 청크 끝에 걸친 미완성 선두(`ESC` 또는 `ESC O`). 세 번째 바이트를 봐야
  /// 화살표인지 아닌지 판정할 수 있어, 다음 [feed]까지 여기 보관한다.
  final List<int> _pending = <int>[];

  /// 아직 판정을 못 내린 미완성 선두 바이트가 남아 있는지 (lone ESC 포함).
  bool get hasPending => _pending.isNotEmpty;

  /// [chunk]를 받아 즉시 내보낼 바이트열을 돌려준다. 화살표 SS3는 CSI로 바꾸고,
  /// 그 외 바이트는 순서·값 그대로 통과시킨다. 끝에 걸친 미완성 `ESC`/`ESC O`는
  /// 내보내지 않고 [_pending]에 보관한다 — 다음 [feed]가 이어 붙여 판정하거나,
  /// 이어지지 않으면 [flush]가 원형 그대로 배출한다.
  List<int> feed(List<int> chunk) {
    final buf = _pending.isEmpty
        ? chunk
        : <int>[..._pending, ...chunk];
    _pending.clear();

    final out = <int>[];
    var i = 0;
    while (i < buf.length) {
      final b = buf[i];
      if (b != _esc) {
        out.add(b);
        i++;
        continue;
      }

      // ESC 뒤 한 바이트가 아직 없다 — 트레일링 ESC로 보관.
      if (i + 1 >= buf.length) {
        _pending.add(_esc);
        break;
      }

      // ESC O 가 아니면(CSI·기타) ESC만 통과시키고 다음 바이트부터 다시 스캔한다.
      // — ESC [ (CSI)·bracketed paste 마커 등은 여기서 손대지 않고 흘려보낸다.
      if (buf[i + 1] != _o) {
        out.add(_esc);
        i++;
        continue;
      }

      // ESC O 까지는 왔는데 세 번째 바이트가 아직 없다 — 둘 다 보관.
      if (i + 2 >= buf.length) {
        _pending
          ..add(_esc)
          ..add(_o);
        break;
      }

      final third = buf[i + 2];
      if (third >= _arrowLo && third <= _arrowHi) {
        // ESC O [A-D] → ESC [ [A-D]
        out
          ..add(_esc)
          ..add(_bracket)
          ..add(third);
      } else {
        // ESC O H/F/P~S 등 — dart_tui가 이미 올바로 처리하므로 원형 통과.
        out
          ..add(_esc)
          ..add(_o)
          ..add(third);
      }
      i += 3;
    }
    return out;
  }

  /// 보관 중인 미완성 선두를 원형 그대로 돌려주고 비운다. 스트림 종료 시, 또는
  /// 트레일링 `ESC`가 화살표 조각이 아니라 lone Escape였을 때(타이머 만료) 호출해
  /// 그 바이트를 흘려보낸다.
  List<int> flush() {
    if (_pending.isEmpty) return const [];
    final out = List<int>.of(_pending);
    _pending.clear();
    return out;
  }
}

/// [source](보통 stdin)의 바이트 스트림에서 SS3 화살표를 CSI로 재매핑한 새
/// 스트림을 만든다. dart_tui `Program`의 `withInput`으로 넘겨 쓴다.
///
/// 미완성 선두를 보관했다가([Ss3ArrowRemapper]) 다음 청크로 이어 붙이므로,
/// 화살표 시퀀스가 읽기 청크 경계에서 갈라져 들어와도(`[ESC]`+`[O,A]` 등)
/// 올바로 합쳐 판정한다.
///
/// [flushDelay]: 트레일링 `ESC`(또는 `ESC O`)를 얼마나 기다렸다 흘려보낼지.
/// lone Escape 키를 무한정 물고 있으면 스코프·등록·피커 취소가 다음 키까지
/// 묻히므로, 이어지는 바이트가 없으면 이 시간 뒤 원형으로 배출한다. dart_tui
/// 자신도 lone-esc를 10ms 타이머로 처리하며, 여기 기본 20ms는 갈라진 화살표를
/// 이어 받기에 충분하면서 Escape 지연을 체감하기 어려운 값이다.
Stream<List<int>> remapSs3ArrowKeys(
  Stream<List<int>> source, {
  Duration flushDelay = const Duration(milliseconds: 20),
}) {
  final remapper = Ss3ArrowRemapper();
  final controller = StreamController<List<int>>();
  StreamSubscription<List<int>>? sub;
  Timer? flushTimer;

  void cancelTimer() {
    flushTimer?.cancel();
    flushTimer = null;
  }

  void flushPending() {
    cancelTimer();
    final rest = remapper.flush();
    if (rest.isNotEmpty) controller.add(rest);
  }

  void onData(List<int> chunk) {
    cancelTimer();
    final out = remapper.feed(chunk);
    if (out.isNotEmpty) controller.add(out);
    // 미완성 선두가 남았으면(트레일링 ESC/ESC O) 잠깐 기다렸다가, 이어지는
    // 바이트가 없으면 lone Escape로 보고 원형 배출한다.
    if (remapper.hasPending) flushTimer = Timer(flushDelay, flushPending);
  }

  controller.onListen = () {
    sub = source.listen(
      onData,
      onError: controller.addError,
      onDone: () {
        flushPending();
        controller.close();
      },
      cancelOnError: false,
    );
  };
  controller.onCancel = () {
    cancelTimer();
    final s = sub;
    sub = null;
    return s?.cancel();
  };

  return controller.stream;
}

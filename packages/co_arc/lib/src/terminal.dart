import 'dart:io';

/// 터미널을 normal cursor key 모드로 되돌리는 시퀀스 (terminfo `rmkx`).
///
/// `\x1b[?1l`은 DECCKM(application cursor key 모드) 해제, `\x1b>`는 keypad를
/// numeric 모드로 되돌린다. 둘 다 폭 0에 커서를 움직이지 않으므로 렌더링
/// 도중에 끼어들어도 화면을 망가뜨리지 않는다 — [resetCursorKeyMode]가 화면
/// 갱신과 무관하게 아무 때나 쓸 수 있는 이유다.
const String normalCursorKeysSequence = '\x1b[?1l\x1b>';

/// 자식 프로세스가 켜 놓고 되돌리지 않은 application cursor key 모드(DECCKM)를
/// 해제한다. [out] 미지정 시 stdout에 쓴다.
///
/// `a`(등록)·`d`(해제)는 `execProcess(inheritStdio: true)`로 스크립트를 실행하고,
/// register-runner.sh는 그 안에서 .NET 콘솔 앱인 `config.sh`를 돌린다. .NET은
/// 터미널 입력을 초기화할 때 terminfo `smkx`(=`\x1b[?1h\x1b=`)를 내보내 DECCKM을
/// 켜는데, `Environment.Exit`이나 시그널 종료 등 정상 종료 경로가 아니면 `rmkx`로
/// 되돌리지 않아 그 모드가 부모 TUI까지 살아남는다.
///
/// DECCKM이 켜져 있으면 방향키가 `\x1b[A`(CSI)가 아니라 `\x1bOA`(SS3)를 보낸다.
/// dart_tui의 SS3 파서는 home·end·F1~F4만 알고 화살표(A~D)는 `unknown` 키로
/// 버리기 때문에, 등록 직후 방향키로 러너 선택을 옮길 수 없게 된다 (글자키인
/// j/k·q·r은 SS3를 거치지 않아 멀쩡하다 — 이 비대칭이 증상의 정체다).
///
/// dart_tui는 DECCKM을 켜지도 끄지도 않는다. `restoreTerminal()`은 termios의
/// echo/line 모드만 되돌리는데 DECCKM은 터미널 에뮬레이터 쪽 모드라 영향을 받지
/// 않고, 렌더러의 release/restore도 alt-screen·마우스·focus·bracketed paste만
/// 다룬다. 그래서 앱이 직접 되돌린다.
void resetCursorKeyMode([StringSink? out]) =>
    (out ?? stdout).write(normalCursorKeysSequence);

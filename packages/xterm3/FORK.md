# xterm3 — Cocode 포크

[klc/xterm3](https://github.com/klc/xterm3) 6.3.4 의 포크다. 데스크톱 입력기 결함을 고치려고 포크했다.
결함은 macOS 2-Set Korean 에서 `한글테스트` 가 `ㅎㅏㄴㄱㅡㄹㅌㅔㅅㅡㅌㅡ` 로 셸에 가는 증상이다.
cocode ADE 터미널(coco-de/cocode#452)과 Lumide(SoFluffyOS/lumide#64)에서 같은 증상이 나왔다.
pub.dev 배포 이름은 `co_xterm3`다. 사용자는 `package:co_xterm3/xterm.dart`를 import한다.

## 기준선

- pub.dev `xterm3` 6.3.4 아카이브를 바이트 그대로 들였다(첫 커밋).
  - `lib/` · `test/` 는 업스트림 태그 `v6.3.4`(`d5b87a89d7`)와 같다.
- 업스트림의 `example/`는 들이지 않았다. 이 포크는 터미널 뷰 예제만 제공한다.
  - 아카이브에서 assets · fonts 가 빠져 빌드할 수 없다.
  - `pub get` 이 dartssh2 · flutter_pty2 · file_picker 를 끌어온다.

## 포크의 변경

기존 Git 릴리스는 `6.3.4+cocode.1`이고, `co_xterm3`의 첫 pub.dev 버전은 `6.3.4`다. 상세는 [CHANGELOG.md](CHANGELOG.md)를 참고한다.

| 파일 | 무엇 |
|---|---|
| `lib/src/terminal_view.dart` | 글자를 내는 평문 키를 플랫폼 텍스트 입력(입력기)에 넘긴다 · 입력기가 조합 뒤 넘긴 Esc/방향키/Tab 을 터미널에 전달 |
| `lib/src/ui/custom_text_edit.dart` | 데스크톱에서 편집 값을 조합이 끝난 즉시가 아니라 입력기가 조합 중일 수 없는 지점에서 비운다 · 보낸 확정 텍스트를 내용으로 추적 · 연결이 닫히면 조합을 버린다 |
| `test/_support/macos_text_input.dart` | macOS 임베더의 편집 모델 · 메시지 순서와 두벌식 입력기를 모사한다 |
| `test/src/ui/desktop_ime_input_test.dart` | 키 이벤트부터 구동하는 입력기 테스트 24건. 수정 전 lib 에서는 20건이 실패한다 |
| `pubspec.yaml` | 공개 패키지 이름, 버전, 설명, 저장소 및 이슈 링크 |
| `FORK.md` · `CHANGELOG.md` 맨 위 항목 | 이 문서와 포크 릴리스 노트 |

- 업스트림 PR: klc/xterm3 에 같은 수정을 보낸다. 진행 기록은 coco-de/cocode#452 에 남긴다.
- 업스트림이 머지해 릴리스하면 이 포크를 지우고 pub.dev `xterm3` 로 되돌린다.

## 쓰는 법

```yaml
dependencies:
  co_xterm3: ^6.3.4
```

release-please는 `co_xterm3-v<version>` 태그를 생성한다. 기존 Git 릴리스
`xterm3-v6.3.4+cocode.1`은 `xterm3` 이름을 사용한다.

## 업스트림 동기화

1. 새 업스트림 릴리스의 pub.dev 아카이브로 `packages/xterm3` 를 덮어쓴다.
   - `example/` 는 빼고 옮긴다.
   - `.gitignore` · `FORK.md` · `CHANGELOG.md` 의 포크 항목 · `pubspec.yaml` 의 포크 필드는 보존한다.
2. 포크 수정 커밋을 다시 적용한다. `package:xterm3/` 참조는 `package:co_xterm3/`로 바꾼다.
3. `flutter pub get && dart format --output=none --set-exit-if-changed . && flutter analyze --fatal-infos && flutter test` 를 돌린다.
   - macOS 에서 돌린다. 골든 4장이 macOS 에서 렌더됐다.
4. 동기화한 업스트림 버전을 changelog에 기록하고 release-please에서 포크 버전을 발행한다.

## 워크스페이스 밖에 두는 이유

co-package 의 다른 패키지와 달리 루트 `pubspec.yaml` 의 `workspace:` 에 넣지 않는다. 그래서 melos 스크립트가 보지 않는다.

- 업스트림 dev 의존(`lints: ^3.0.0` · `mockito` · `build_runner`)이 루트 `lints: ^6.0.0` 과 한 lockfile 에서 풀리지 않는다.
- 별도 lockfile을 사용하면 업스트림 의존성에 맞춰 동기화하고 시험할 수 있다.

대신 `.github/workflows/ci.yml` 의 `xterm3` 잡이 업스트림 CI 와 같은 검사를 macOS 에서 돌린다.

## 라이선스

co-package 루트의 BSD-3-Clause 와 별개다. 업스트림 라이선스를 그대로 따른다.

- `LICENSE`: GNU AGPL-3.0-or-later.
- `LICENSE.MIT`: 선행 작업(`xterm` · `xterm2`)의 MIT 고지.
- `NOTICE`: 업스트림 저작권 · 파생 관계 고지.

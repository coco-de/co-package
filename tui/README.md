# coarc — self-hosted 러너 관리 TUI

co-arc 러너를 터미널에서 한눈에 보고 관리하는 Dart TUI입니다.
[`dart_tui`](https://pub.dev/packages/dart_tui) (Bubble Tea 스타일 Model–Update–View) 기반이며,
GitHub 조회는 `gh` CLI, 등록/정리는 이 레포의 [`scripts/`](../scripts/)를 그대로 사용합니다.

```
 co-arc runners   org coco-de · 3대 (온라인 2) · 14:02:31 갱신

 ST    │ NAME                       │ JOB   │ OS     │ LABELS
 ──────┼────────────────────────────┼───────┼────────┼──────────────────────
›● on  │ cody-macbook-local         │ busy  │ macos  │ self-hosted,macos,flutter
 ● on  │ mini-runner-01             │ idle  │ macos  │ self-hosted,macos,flutter
 ○ off │ old-laptop                 │ idle  │ macos  │ self-hosted,macos

 로컬: cody-macbook-local · listener 실행 중 · launchd 등록됨 · _work 3.2G
 ────────────────────────────────────────────────────────────────────────
 (로그 없음)

 ↑↓ 이동 · r 갱신 · a 등록 · A 이름지정등록 · l 라벨 · d 해제 · s 서비스 · c/C 정리 · g 스코프 · ? 도움말 · q 종료
```

`l`을 누르면 라벨 피커가 열립니다. 스코프의 러너들이 이미 쓰는 라벨이 모두 올라오므로,
CSV를 손으로 다시 타이핑하지 않고 체크만 하면 됩니다.

```
 라벨 편집 — cody-macbook-local
 read-only(편집 불가): self-hosted, macos, ARM64

›[x] flutter
 [x] ios
 [ ] serverpod
 [ ] web

 2/4 선택됨
 ────────────────────────────────────────────────────────────────────────
 ↑↓ 이동 · space 토글 · a 전체 토글 · n 새 라벨 · Enter 적용 · Esc 취소
```

## 설치

레포를 clone하지 않고 git 소스에서 바로 전역 설치하는 게 가장 빠릅니다:

```bash
dart pub global activate --source git https://github.com/coco-de/co-arc.git --git-path tui
coarc
```

`~/.pub-cache/bin`이 `PATH`에 있어야 `coarc` 명령이 바로 실행됩니다 (Dart SDK 설치 시 보통 자동으로 잡힙니다). 최신 버전으로 갱신하려면 같은 `activate` 명령을 다시 실행하세요 — git 소스는 자동 업데이트되지 않습니다.

이미 레포를 clone해뒀다면 로컬 경로로 설치해도 됩니다:

```bash
cd tui
dart pub global activate --source path .
coarc
```

## 실행

```bash
coarc                        # 마지막 스코프 기억 (기본: org coco-de)
coarc --org coco-de          # org 스코프
coarc --repo coco-de/<repo>  # repo 스코프
coarc --root <path>          # 러너 설치 루트 지정 (기본: ~/actions)
coarc --dir <path>           # 추적할 러너 디렉토리 지정 (기본: <root>)
coarc list                   # TUI 없이 목록만 출력
```

레포 안에서 설치 없이 바로 실행하려면(개발 중 등):

```bash
cd tui
dart pub get
dart run coarc_tui:coarc
```

## 사전 준비

- **gh CLI** 로그인 필수. org 스코프 조회/해제에는 `admin:org`가 필요합니다:
  `gh auth refresh -h github.com -s admin:org`
- repo 스코프는 해당 레포 admin 권한(`repo` 스코프)이면 됩니다.

## 키

| 키 | 동작 |
|---|---|
| `↑`/`↓`, `j`/`k` | 러너 선택 |
| `r` | 새로고침 (15초마다 자동) |
| `a` | 이 머신을 러너로 등록 — `scripts/register-runner.sh` 실행 (TUI 일시 중단 후 복귀). 이름 미지정이므로 `{컴퓨터이름}-{랜덤 공룡}`(예: `cocode-m2-ultra-raptor`)으로 기존 러너와 겹치지 않는 이름을 자동 생성 |
| `A` | 이름/라벨을 직접 입력해 등록 — `이름 라벨1,라벨2,...` 형식 (빈 입력은 `a`와 동일). 같은 스코프에 이름이 이미 있으면 `-2`, `-3` ...으로 자동 회피 |
| `l` | 선택 러너의 커스텀 라벨 편집 — **라벨 피커**를 연다. 스코프의 러너들이 이미 쓰는 라벨이 체크박스로 뜨고, 대상 러너의 라벨은 체크된 채로 시작한다. `↑↓`/`jk` 이동, `space`/`x` 토글, `a` 전체 토글, `n` 새 라벨 입력(CSV로 여러 개 한 번에), `Enter` 적용, `Esc` 취소. 체크한 집합이 그대로 커스텀 라벨이 된다. `self-hosted` 등 read-only 라벨은 편집 불가라 목록에 뜨지 않는다 |
| `d` | 선택 러너를 GitHub에서 해제 (오프라인만 가능, `y` 확인) |
| `s` | **선택 러너**의 서비스 시작/중지 (`svc.sh`) — 이 머신에 설치된 러너만. 실행 중이면(launchd·포그라운드 무관) `stop`, 안 떠 있고 서비스 미설치(재부팅 등으로 launchd 등록이 사라졌거나 애초에 등록한 적 없음)면 `install` 후 자동으로 `start`까지 이어서 실행, 이미 설치돼 있으면 `start`. **`start` 직전에 plist에 `KeepAlive`를 심어** 러너가 비정상 종료돼도 launchd가 되살리게 하고, `start` 후에는 재부팅 자동 복귀를 막는 머신 설정(자동 로그인·FileVault·절전)을 점검해 경고를 로그에 남긴다. 다른 머신의 러너를 선택했으면 아무 명령도 실행하지 않고 그 사실만 로그로 남김 |
| `c` / `C` | **선택 러너**의 `_work` 정리 — `c` dry-run, `C` 실제 삭제 (`scripts/cleanup-work.sh`, 이 머신에 설치된 러너만) |
| `g` | 스코프 전환 — `coco-de`(org) 또는 `owner/repo` 입력 |
| `?` | 도움말 |
| `q` | 종료 |

## 설정

마지막 스코프·러너 설치 루트·추적 중인 러너 디렉토리는 `~/.config/co-arc/tui.json`에
저장됩니다. 설치 루트 기본값은 `~/actions`이며(`--root`로 변경), 새 러너는
`~/actions/{러너이름}`처럼 이름별 하위 디렉토리에 독립 설치됩니다.

로컬 패널과 로컬 전용 조작(`s`·`c`/`C`·`d`)의 대상은 **커서가 가리키는 러너**입니다.
설치 경로는 이름별 디렉토리(`~/actions/{러너이름}`)에서 찾고, 거기 없으면 설정에
저장된 추적 디렉토리(`--dir`로 지정했거나 이름별 설치 규칙 이전에 등록한 러너)도
확인합니다. 목록에는 다른 머신의 러너도 함께 뜨므로, 이 머신에 설치돼 있지 않은
러너를 선택하면 로컬 조작은 실행되지 않습니다.

## 개발

```bash
dart analyze
dart test
```

- `lib/src/app.dart` — TUI 모델 (Model–Update–View)
- `lib/src/gh.dart` — `gh api` 래퍼 (러너 목록/해제/라벨 변경)
- `lib/src/labels.dart` — 라벨 피커 후보 수집(스코프 전체 커스텀 라벨 합집합) + read-only 라벨 필터
- `lib/src/local.dart` — 로컬 에이전트 상태 (`.runner`, listener 프로세스, launchd, `_work` 용량)
- `lib/src/register.dart` — 등록 입력 파싱 + `register-runner.sh` 인자 구성
- `lib/src/scope.dart` — org/repo 스코프 + 설정 저장

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

 ↑↓ 이동 · r 새로고침 · a 등록 · d 해제 · s 서비스 시작/중지 · c 정리(dry) · C 정리 · g 스코프 · ? 도움말 · q 종료
```

## 실행

```bash
cd tui
dart pub get

dart run coarc_tui:coarc                        # 마지막 스코프 기억 (기본: org coco-de)
dart run coarc_tui:coarc --repo coco-de/<repo>  # repo 스코프
dart run coarc_tui:coarc list                   # TUI 없이 목록만 출력

# 전역 설치
dart pub global activate --source path .
coarc
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
| `a` | 이 머신을 러너로 등록 — `scripts/register-runner.sh` 실행 (TUI 일시 중단 후 복귀) |
| `d` | 선택 러너를 GitHub에서 해제 (오프라인만 가능, `y` 확인) |
| `s` | 로컬 launchd 서비스 시작/중지 (`svc.sh`) |
| `c` / `C` | `_work` 정리 — `c` dry-run, `C` 실제 삭제 (`scripts/cleanup-work.sh`) |
| `g` | 스코프 전환 — `coco-de`(org) 또는 `owner/repo` 입력 |
| `?` | 도움말 |
| `q` | 종료 |

## 설정

마지막 스코프와 러너 디렉토리는 `~/.config/co-arc/tui.json`에 저장됩니다.
러너 디렉토리 기본값은 `~/actions-runner`이며 `--dir`로 바꿀 수 있습니다.

## 개발

```bash
dart analyze
dart test
```

- `lib/src/app.dart` — TUI 모델 (Model–Update–View)
- `lib/src/gh.dart` — `gh api` 래퍼 (러너 목록/해제)
- `lib/src/local.dart` — 로컬 에이전트 상태 (`.runner`, listener 프로세스, launchd, `_work` 용량)
- `lib/src/scope.dart` — org/repo 스코프 + 설정 저장

#!/usr/bin/env bash
#
# remove-runner.sh — 이 머신의 self-hosted 러너 등록 해제
#
# 사용법:
#   ./remove-runner.sh --repo coco-de/<repo>
#   ./remove-runner.sh --org coco-de
#
# 옵션:
#   --dir <path>   러너 설치 경로 (기본: ~/actions-runner)
#   --purge        해제가 끝난 뒤 러너 폴더까지 지웁니다 (_work 의 도구 캐시·체크아웃 포함).
#                  해제만 하면 폴더가 그대로 남아 디스크를 계속 씁니다 — 2026-11-13 실측: 해제된 러너 폴더
#                  하나가 29GB 였고, 등록 정보(.runner)가 없는 폴더는 자동 정리 스크립트도 못 찾습니다.
#                  등록 정보가 남아 있거나 그 폴더를 쓰는 프로세스가 있으면 지우지 않습니다.
#
set -euo pipefail

SCOPE_TYPE="" SCOPE=""
RUNNER_DIR="${HOME}/actions-runner"
PURGE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo) SCOPE_TYPE="repo"; SCOPE="$2"; shift 2 ;;
    --org)  SCOPE_TYPE="org";  SCOPE="$2"; shift 2 ;;
    --dir)  RUNNER_DIR="$2"; shift 2 ;;
    --purge) PURGE=true; shift ;;
    *) echo "unknown option: $1" >&2; exit 1 ;;
  esac
done

if [[ -z "$SCOPE_TYPE" ]]; then
  echo "usage: $0 --repo coco-de/<repo> | --org coco-de [--dir <path>] [--purge]" >&2
  exit 1
fi

command -v gh >/dev/null || { echo "error: gh CLI가 필요합니다" >&2; exit 1; }
cd "$RUNNER_DIR" || { echo "error: 러너 디렉토리가 없습니다: $RUNNER_DIR" >&2; exit 1; }

# 서비스로 돌고 있으면 먼저 내림
if [[ -x ./svc.sh ]] && ./svc.sh status 2>/dev/null | grep -qi "started\|running"; then
  echo "==> launchd 서비스 중지/제거"
  ./svc.sh stop
  ./svc.sh uninstall
fi

if [[ "$SCOPE_TYPE" == "repo" ]]; then
  API_PATH="repos/${SCOPE}/actions/runners/remove-token"
else
  API_PATH="orgs/${SCOPE}/actions/runners/remove-token"
fi

echo "==> 제거 토큰 발급 후 해제"
RM_TOKEN="$(gh api -X POST "$API_PATH" --jq .token)"
./config.sh remove --token "$RM_TOKEN"

# 해제 뒤 폴더 처리 — 지우지 않으면 _work 의 도구 캐시·체크아웃이 그대로 남아 디스크를 쓴다.
RUNNER_DIR_ABS="$(pwd -P)"
SIZE="$(du -sh "$RUNNER_DIR_ABS" 2>/dev/null | cut -f1)"

if $PURGE; then
  # 엉뚱한 폴더를 지우지 않게 — 홈·루트 자체이거나, 등록 정보가 남았거나, 쓰는 프로세스가 있으면 멈춘다.
  case "$RUNNER_DIR_ABS" in
    ""|/|"$HOME"|"$HOME"/) echo "error: 지울 수 없는 경로입니다: ${RUNNER_DIR_ABS}" >&2; exit 1 ;;
  esac
  if [[ -e ./.runner || -e ./.credentials ]]; then
    echo "error: 등록 정보(.runner/.credentials)가 남아 있어 폴더를 지우지 않습니다 — 해제가 끝났는지 확인하세요" >&2
    exit 1
  fi
  # pgrep -f 는 이 스크립트 자신(--dir 인자에 같은 경로가 있다)도 잡을 수 있어 자기 pid 는 뺀다
  OTHERS="$(pgrep -f "${RUNNER_DIR_ABS}/" 2>/dev/null | grep -vx "$$" || true)"
  if [[ -n "$OTHERS" ]]; then
    echo "error: 이 폴더를 쓰는 프로세스가 남아 있어 지우지 않습니다 (pid: $(echo "$OTHERS" | tr '\n' ' ')) — 끝난 뒤 rm -rf ${RUNNER_DIR_ABS}" >&2
    exit 1
  fi
  cd "$(dirname "$RUNNER_DIR_ABS")"
  rm -rf "$RUNNER_DIR_ABS"
  echo "완료. 러너 폴더를 지웠습니다 (논리 ${SIZE:-?} — 다른 러너와 블록을 나눠 쓰던 복제 사본이면 실제로 돌려받는 양은 더 적습니다)."
else
  echo "완료. 러너 폴더에 ${SIZE:-?} 가 남아 있습니다 (도구 캐시·체크아웃 포함 — 등록만 해제됐고 디스크는 계속 쓰입니다)."
  echo "      지우려면: rm -rf ${RUNNER_DIR}    (다음부터는 --purge 로 해제와 함께 지울 수 있습니다)"
fi

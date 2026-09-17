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
#
set -euo pipefail

SCOPE_TYPE="" SCOPE=""
RUNNER_DIR="${HOME}/actions-runner"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo) SCOPE_TYPE="repo"; SCOPE="$2"; shift 2 ;;
    --org)  SCOPE_TYPE="org";  SCOPE="$2"; shift 2 ;;
    --dir)  RUNNER_DIR="$2"; shift 2 ;;
    *) echo "unknown option: $1" >&2; exit 1 ;;
  esac
done

if [[ -z "$SCOPE_TYPE" ]]; then
  echo "usage: $0 --repo coco-de/<repo> | --org coco-de [--dir <path>]" >&2
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

echo "완료. 러너 파일을 지우려면: rm -rf ${RUNNER_DIR}"

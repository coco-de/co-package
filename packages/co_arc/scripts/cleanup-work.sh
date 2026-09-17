#!/usr/bin/env bash
#
# cleanup-work.sh — 러너 _work 디렉토리 정리 (체크아웃/빌드 산출물 누적 방지)
#
# 사용법:
#   ./cleanup-work.sh                # 7일 이상 지난 잡 디렉토리 삭제
#   ./cleanup-work.sh --days 3       # 3일 기준
#   ./cleanup-work.sh --all          # _work 전체 삭제 (러너 정지 상태에서만)
#   ./cleanup-work.sh --dry-run      # 지울 대상만 출력
#
set -euo pipefail

RUNNER_DIR="${HOME}/actions-runner"
DAYS=7
ALL=false
DRY=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dir)     RUNNER_DIR="$2"; shift 2 ;;
    --days)    DAYS="$2"; shift 2 ;;
    --all)     ALL=true; shift ;;
    --dry-run) DRY=true; shift ;;
    *) echo "unknown option: $1" >&2; exit 1 ;;
  esac
done

WORK="${RUNNER_DIR}/_work"
[[ -d "$WORK" ]] || { echo "_work 디렉토리가 없습니다: $WORK"; exit 0; }

echo "==> 정리 전 사용량: $(du -sh "$WORK" 2>/dev/null | cut -f1)"

if $ALL; then
  if pgrep -f "Runner.Listener" >/dev/null 2>&1; then
    echo "error: 러너가 실행 중입니다. 먼저 정지하세요 (./svc.sh stop)" >&2
    exit 1
  fi
  if $DRY; then
    echo "[dry-run] rm -rf ${WORK:?}/*"
  else
    rm -rf "${WORK:?}"/*
  fi
else
  # _work 바로 아래(레포별 디렉토리) 중 오래된 것 삭제. _actions/_temp/_tool은 유지
  find "$WORK" -mindepth 1 -maxdepth 1 -type d \
       ! -name '_actions' ! -name '_temp' ! -name '_tool' ! -name '_PipelineMapping' \
       -mtime "+${DAYS}" -print | while read -r d; do
    if $DRY; then
      echo "[dry-run] rm -rf $d"
    else
      echo "삭제: $d"
      rm -rf "$d"
    fi
  done
fi

$DRY || echo "==> 정리 후 사용량: $(du -sh "$WORK" 2>/dev/null | cut -f1)"

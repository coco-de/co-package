#!/usr/bin/env bash
#
# register-runner.sh — 이 머신을 GitHub Actions self-hosted 러너로 등록
#
# 사용법:
#   ./register-runner.sh --repo coco-de/<repo>   # repo 레벨 러너
#   ./register-runner.sh --org coco-de           # org 레벨 러너 (admin:org 필요)
#
# 옵션:
#   --labels <csv>   러너 라벨 (기본: self-hosted,macos,flutter)
#   --name <name>    러너 이름 (기본: $(hostname)-local)
#   --dir <path>     러너 설치 경로 (기본: ~/actions-runner)
#   --service        구성 후 launchd 서비스로 바로 등록/시작
#
set -euo pipefail

SCOPE_TYPE="" SCOPE=""
LABELS="self-hosted,macos,flutter"
RUNNER_NAME="$(hostname)-local"
RUNNER_DIR="${HOME}/actions-runner"
AS_SERVICE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)    SCOPE_TYPE="repo"; SCOPE="$2"; shift 2 ;;
    --org)     SCOPE_TYPE="org";  SCOPE="$2"; shift 2 ;;
    --labels)  LABELS="$2"; shift 2 ;;
    --name)    RUNNER_NAME="$2"; shift 2 ;;
    --dir)     RUNNER_DIR="$2"; shift 2 ;;
    --service) AS_SERVICE=true; shift ;;
    *) echo "unknown option: $1" >&2; exit 1 ;;
  esac
done

if [[ -z "$SCOPE_TYPE" ]]; then
  echo "usage: $0 --repo coco-de/<repo> | --org coco-de [--labels ...] [--name ...] [--service]" >&2
  exit 1
fi

command -v gh >/dev/null || { echo "error: gh CLI가 필요합니다 (brew install gh && gh auth login)" >&2; exit 1; }
gh auth status >/dev/null 2>&1 || { echo "error: gh auth login 먼저 실행하세요" >&2; exit 1; }

# ---- 1. 러너 에이전트 다운로드 (최신 버전, arch 자동 감지) -------------------
OS="osx"; [[ "$(uname -s)" == "Linux" ]] && OS="linux"
ARCH="x64"; [[ "$(uname -m)" == "arm64" || "$(uname -m)" == "aarch64" ]] && ARCH="arm64"

VER="$(gh api repos/actions/runner/releases/latest --jq '.tag_name' | sed 's/^v//')"
PKG="actions-runner-${OS}-${ARCH}-${VER}.tar.gz"

mkdir -p "$RUNNER_DIR"
cd "$RUNNER_DIR"

if [[ ! -x ./config.sh ]]; then
  echo "==> 러너 에이전트 v${VER} 다운로드 (${OS}-${ARCH})"
  curl -fSL -o "$PKG" \
    "https://github.com/actions/runner/releases/download/v${VER}/${PKG}"
  tar xzf "$PKG" && rm -f "$PKG"
else
  echo "==> 기존 러너 에이전트 사용 ($RUNNER_DIR)"
fi

# ---- 2. 등록 토큰 발급 (1시간 유효) ------------------------------------------
if [[ "$SCOPE_TYPE" == "repo" ]]; then
  API_PATH="repos/${SCOPE}/actions/runners/registration-token"
  URL="https://github.com/${SCOPE}"
else
  API_PATH="orgs/${SCOPE}/actions/runners/registration-token"
  URL="https://github.com/${SCOPE}"
fi

echo "==> 등록 토큰 발급 (${SCOPE_TYPE}: ${SCOPE})"
TOKEN="$(gh api -X POST "$API_PATH" --jq .token)"

# ---- 3. 러너 구성 ------------------------------------------------------------
echo "==> 러너 구성: name=${RUNNER_NAME} labels=${LABELS}"
./config.sh \
  --url "$URL" \
  --token "$TOKEN" \
  --name "$RUNNER_NAME" \
  --labels "$LABELS" \
  --unattended

# ---- 4. 실행 -----------------------------------------------------------------
if $AS_SERVICE; then
  echo "==> launchd 서비스 등록/시작"
  ./svc.sh install
  ./svc.sh start
  ./svc.sh status
else
  cat <<EOF

등록 완료. 실행 방법:

  포그라운드 테스트 :  cd ${RUNNER_DIR} && ./run.sh
  상시 서비스       :  cd ${RUNNER_DIR} && ./svc.sh install && ./svc.sh start

EOF
fi

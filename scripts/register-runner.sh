#!/usr/bin/env bash
#
# register-runner.sh — 이 머신을 GitHub Actions self-hosted 러너로 등록
#
# 사용법:
#   ./register-runner.sh --repo coco-de/<repo>   # repo 레벨 러너
#   ./register-runner.sh --org coco-de           # org 레벨 러너 (admin:org 필요)
#
# 옵션:
#   --labels <csv>        러너 라벨 (기본: self-hosted,macOS,flutter). macOS는
#                          GitHub가 실제 실행 바이너리 아키텍처를 보고 자동으로
#                          ARM64/X64 라벨도 붙여주지만, 터미널이 Rosetta로 떠
#                          있으면 arm64 맥인데도 x64로 등록될 수 있으니 실행 후
#                          반드시 아래 "아키텍처 확인" 출력을 확인하세요.
#   --name <name>          러너 이름 (기본: $(hostname)-local). 같은 스코프에
#                          동일 이름이 이미 등록돼 있으면(config.sh --unattended는
#                          이름 충돌 시 프롬프트 없이 실패) -2, -3 ... 접미사를
#                          자동으로 붙여 고유한 이름으로 등록합니다.
#   --dir <path>           러너 설치 경로 (기본: ~/actions-runner)
#   --runner-group <name>  러너 그룹 (기본: 조직 기본 그룹)
#   --tool-cache <path>    여러 인스턴스가 Flutter/JDK 등 tool-cache를 공유하도록
#                          .env에 RUNNER_TOOL_CACHE=<path>를 설정. 한 머신에
#                          여러 러너를 띄울 때 매 인스턴스가 SDK를 중복 캐싱하는
#                          걸 막아줍니다 (자세한 배경은 docs/self-hosted-runner.md
#                          "공유 tool-cache" 절 참고).
#   --service              구성 후 launchd 서비스로 바로 등록/시작
#
# 여러 인스턴스를 한 머신에 띄우려면 --dir/--name을 인스턴스별로 다르게 지정해
# 반복 실행하세요 (예: --dir ~/actions-runner-01 --name action-01).
#
# Idempotent: $RUNNER_DIR/.runner가 이미 있으면(=이미 등록됨) 재등록을 건너뛰고
# --service 지정 시 서비스 설치/시작만 수행합니다. 그 디렉토리에서 수동으로
# ./run.sh를 포그라운드 실행 중이던 러너도 이 방식으로 안전하게 launchd
# 서비스로 전환할 수 있습니다 (전환 전 기존 run.sh 프로세스를 종료합니다).
#
set -euo pipefail

SCOPE_TYPE="" SCOPE=""
LABELS="self-hosted,macOS,flutter"
RUNNER_NAME="$(hostname)-local"
RUNNER_DIR="${HOME}/actions-runner"
RUNNER_GROUP=""
TOOL_CACHE=""
AS_SERVICE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)          SCOPE_TYPE="repo"; SCOPE="$2"; shift 2 ;;
    --org)           SCOPE_TYPE="org";  SCOPE="$2"; shift 2 ;;
    --labels)        LABELS="$2"; shift 2 ;;
    --name)          RUNNER_NAME="$2"; shift 2 ;;
    --dir)           RUNNER_DIR="$2"; shift 2 ;;
    --runner-group)  RUNNER_GROUP="$2"; shift 2 ;;
    --tool-cache)    TOOL_CACHE="$2"; shift 2 ;;
    --service)       AS_SERVICE=true; shift ;;
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

# 아키텍처 확인 — uname -m은 Rosetta로 뜬 터미널에서 x86_64를 반환할 수 있어
# 실제 다운로드된 바이너리를 직접 확인한다 (arm64 맥인데 x64 러너가 등록되는
# 사고를 예방).
if command -v lipo >/dev/null; then
  ACTUAL_ARCH="$(lipo -archs ./bin/Runner.Listener 2>/dev/null || echo unknown)"
  echo "==> 다운로드된 바이너리 아키텍처: ${ACTUAL_ARCH} (요청: ${ARCH})"
fi

# ---- 2~3. 등록 토큰 발급 및 러너 구성 (이미 등록된 러너면 건너뜀) -----------
if [[ -f "${RUNNER_DIR}/.runner" ]]; then
  echo "==> 이미 등록된 러너입니다 (${RUNNER_DIR}/.runner 존재) — 재등록 없이 다음 단계로 진행"
else
  if [[ "$SCOPE_TYPE" == "repo" ]]; then
    API_PATH="repos/${SCOPE}/actions/runners/registration-token"
    LIST_API="repos/${SCOPE}/actions/runners"
    URL="https://github.com/${SCOPE}"
  else
    API_PATH="orgs/${SCOPE}/actions/runners/registration-token"
    LIST_API="orgs/${SCOPE}/actions/runners"
    URL="https://github.com/${SCOPE}"
  fi

  # 이름 충돌 자동 회피: 같은 스코프에 동일 이름의 러너가 이미 있으면
  # config.sh --unattended가 프롬프트 없이 그냥 실패한다. 기존 이름 목록을
  # 조회해 충돌하면 -2, -3 ... 접미사를 붙여 고유한 이름을 찾는다.
  EXISTING_NAMES="$(gh api "${LIST_API}?per_page=100" --jq '.runners[].name' 2>/dev/null || true)"
  if [[ -n "$EXISTING_NAMES" ]] && grep -qxF "$RUNNER_NAME" <<<"$EXISTING_NAMES"; then
    BASE_NAME="$RUNNER_NAME"
    n=2
    while grep -qxF "${BASE_NAME}-${n}" <<<"$EXISTING_NAMES"; do
      n=$((n + 1))
    done
    RUNNER_NAME="${BASE_NAME}-${n}"
    echo "==> 이름 충돌 감지 (${SCOPE_TYPE} ${SCOPE}에 '${BASE_NAME}' 이미 존재) → '${RUNNER_NAME}'로 자동 지정"
  fi

  echo "==> 등록 토큰 발급 (${SCOPE_TYPE}: ${SCOPE})"
  TOKEN="$(gh api -X POST "$API_PATH" --jq .token)"

  echo "==> 러너 구성: name=${RUNNER_NAME} labels=${LABELS}${RUNNER_GROUP:+ group=$RUNNER_GROUP}"
  CONFIG_ARGS=(--url "$URL" --token "$TOKEN" --name "$RUNNER_NAME" --labels "$LABELS" --unattended)
  [[ -n "$RUNNER_GROUP" ]] && CONFIG_ARGS+=(--runnergroup "$RUNNER_GROUP")
  ./config.sh "${CONFIG_ARGS[@]}"
fi

# 공유 tool-cache 설정 (.env에 RUNNER_TOOL_CACHE 기록)
if [[ -n "$TOOL_CACHE" ]]; then
  mkdir -p "$TOOL_CACHE"
  if grep -q "^RUNNER_TOOL_CACHE=" .env 2>/dev/null; then
    echo "==> .env에 RUNNER_TOOL_CACHE 이미 설정됨, 건너뜀"
  else
    echo "RUNNER_TOOL_CACHE=${TOOL_CACHE}" >> .env
    echo "==> .env에 RUNNER_TOOL_CACHE=${TOOL_CACHE} 추가"
  fi
fi

# ---- 4. 실행 -----------------------------------------------------------------
if $AS_SERVICE; then
  # 같은 디렉토리에서 ./run.sh로 이미 수동(포그라운드) 실행 중이면 서비스와
  # 충돌하므로 먼저 정리한다 (수동 러너 → launchd 서비스 전환 경로).
  mapfile -t RUNNING_PIDS < <(pgrep -f "${RUNNER_DIR}/bin/Runner.Listener" || true)
  if [[ ${#RUNNING_PIDS[@]} -gt 0 ]]; then
    echo "==> 기존 수동 실행(run.sh) 프로세스 종료: pid=${RUNNING_PIDS[*]}"
    kill "${RUNNING_PIDS[@]}"
    sleep 2
  fi

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

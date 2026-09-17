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
#   --name <name>          러너 이름 (기본: {컴퓨터이름}-{랜덤 공룡}, 예:
#                          cocode-m2-ultra-raptor). 같은 스코프에 동일 이름이
#                          이미 등록돼 있으면(config.sh --unattended는 이름 충돌
#                          시 프롬프트 없이 실패) -2, -3 ... 접미사를 자동으로
#                          붙여 고유한 이름으로 등록합니다.
#   --dir <path>           러너 설치 경로 (기본: ~/actions/{러너이름}). 러너마다
#                          이름별 하위 디렉토리에 독립 설치됩니다.
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
# 이미 launchd 서비스로 돌고 있던 러너에 --service를 다시 실행해도 안전합니다
# (설치를 건너뛰고 재적용 후 재시작).
#
# --service로 서비스를 켤 때 launchd plist에 KeepAlive를 자동으로 심고
# (=크래시 시 자동 복구), 재부팅 후 무인 복귀를 막는 머신 설정을 점검해
# 안내합니다. 자세한 배경은 docs/self-hosted-runner.md "재부팅 후에도
# 백그라운드로 유지하기" 참고.
#
set -euo pipefail

SCOPE_TYPE="" SCOPE=""
LABELS="self-hosted,macOS,flutter"
# 이름/설치 경로는 미지정 시 아래에서 파생한다 (빈 문자열 = 미지정).
RUNNER_NAME=""
RUNNER_DIR=""
RUNNER_GROUP=""
TOOL_CACHE=""
AS_SERVICE=false

# 이름 미지정 등록 시 붙일 영어 공룡 이름 풀 (lib/src/naming.dart와 동일).
DINOS=(raptor trex stego triceratops brachio ankylo velociraptor diplodocus \
  allosaurus spinosaurus pterodactyl brontosaurus compsognathus gallimimus \
  iguanodon megalosaurus ornithomimus parasaurolophus protoceratops utahraptor \
  carnotaurus dilophosaurus giganotosaurus maiasaura pachycephalosaurus \
  plateosaurus therizinosaurus troodon archaeopteryx baryonyx coelophysis \
  deinonychus edmontosaurus kentrosaurus ceratosaurus oviraptor styracosaurus \
  apatosaurus nodosaurus gorgosaurus)

# 컴퓨터 이름을 러너/디렉토리 이름에 쓸 수 있게 정규화 (소문자·.local 제거·영숫자만).
host_slug() {
  hostname | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/\.local$//; s/[^a-z0-9]+/-/g; s/^-+//; s/-+$//'
}

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

# 이름 미지정이면 {컴퓨터이름}-{랜덤 공룡}으로 만든다. 설치 경로 미지정이면
# 러너 이름별 하위 디렉토리(~/actions/{러너이름})에 설치한다 — 한 머신에 여러
# 러너를 겹치지 않게 두기 위함. (이름은 아래 등록 단계에서 GitHub 러너 목록과
# 충돌 시 -2, -3 접미사로 최종 유일화된다.)
if [[ -z "$RUNNER_NAME" ]]; then
  RUNNER_NAME="$(host_slug)-${DINOS[$((RANDOM % ${#DINOS[@]}))]}"
fi
if [[ -z "$RUNNER_DIR" ]]; then
  RUNNER_DIR="${HOME}/actions/${RUNNER_NAME}"
fi

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

# 이 러너의 launchd plist 경로. svc.sh install이 설치 시점의 정확한 경로를
# `<러너디렉토리>/.service`에 남기므로 그 기록을 그대로 쓴다 (플래그가 아니라
# 파일에서 읽어야 이름/스코프 조합을 다시 조립하지 않는다). 미설치면 빈 문자열.
runner_plist_path() {
  local dir="$1" path
  [[ -f "${dir}/.service" ]] || return 0
  path="$(cat "${dir}/.service")"
  [[ -n "$path" && -f "$path" ]] || return 0
  printf '%s' "$path"
}

# launchd plist에 KeepAlive를 심는다 (멱등 — 이미 적용돼 있으면 건드리지 않음).
#
# 평범한 `KeepAlive: true`가 아니라 `{SuccessfulExit: false}`인 이유: 러너의
# bin/RunnerService.js는 listener 종료코드를 직접 해석해서 2(retryable)·3·4
# (자체 업데이트)는 스스로 5초 뒤 재기동하고, 0(정상)·1(terminated)·5(세션
# 충돌)는 `stopping = true`로 서비스를 내리며 exit 0으로 끝낸다. `true`로 걸면
# 러너가 "멈춰야 한다"고 판단한 상황 — 특히 같은 등록을 두 프로세스가 잡은
# 세션 충돌 — 에서 launchd가 무한 재기동시켜 정면 충돌한다.
# `SuccessfulExit: false`는 비정상 종료(크래시·OOM·강제 kill)만 되살린다.
#
# 반드시 svc.sh start(=launchctl load) '전에' 실행해야 한다. launchd는 로드
# 시점에 plist를 읽으므로, 이미 로드된 뒤에 파일만 고치면 다음 로드까지
# 적용되지 않는다.
harden_service_plist() {
  local plist="$1"
  local pb=/usr/libexec/PlistBuddy

  [[ -n "$plist" ]] || { echo "warn: launchd plist를 찾지 못해 KeepAlive 설정을 건너뜁니다" >&2; return 0; }
  [[ -x "$pb" ]] || { echo "warn: PlistBuddy가 없어 KeepAlive 설정을 건너뜁니다" >&2; return 0; }

  if [[ "$("$pb" -c 'Print :KeepAlive:SuccessfulExit' "$plist" 2>/dev/null)" == "false" ]]; then
    echo "==> KeepAlive 이미 적용됨 — 그대로 둡니다"
    return 0
  fi

  # Add는 키가 이미 있으면 실패하므로 Delete를 먼저 낸다 (키가 없을 때의
  # Delete 실패는 정상 경로라 무시).
  "$pb" -c 'Delete :KeepAlive' "$plist" >/dev/null 2>&1 || true
  if "$pb" -c 'Add :KeepAlive dict' \
           -c 'Add :KeepAlive:SuccessfulExit bool false' "$plist"; then
    echo "==> KeepAlive(SuccessfulExit=false) 적용 — 비정상 종료 시 launchd가 러너를 되살립니다"
  else
    echo "warn: KeepAlive 설정 실패 (${plist}) — 크래시 자동 복구 없이 진행합니다" >&2
  fi
}

# `pmset -g custom` 출력에서 AC 전원 구간의 설정값을 읽는다. 배터리 구간에도
# 같은 키가 있어서 구간을 구분해야 한다 — 러너는 전원이 연결된 상태를
# 전제하므로 AC 값만 본다. 기종이 지원하지 않는 키는 빈 문자열.
#
# 설정 줄은 `키 값` 두 토큰이다(NF == 2). `Sleep On Power Button 1`처럼 이름에
# 공백이 들어간 줄을 값으로 잘못 읽지 않도록 토큰 수까지 본다.
# (같은 판정을 lib/src/local.dart의 `pmsetAcValue`가 TUI 경로에서 수행한다.)
pmset_ac_value() {
  awk -v key="$1" '
    /^[^ ]/ { in_ac = ($0 ~ /^AC Power/); next }
    in_ac && NF == 2 && $1 == key { print $2; exit }
  ' <<<"$2"
}

# 서비스는 켰지만 "재부팅하면 알아서 돌아온다"를 막는 머신 레벨 조건을 점검한다.
#
# 여기서 자동으로 고치지 않는 이유: 전부 sudo가 필요하고, FileVault 해제는
# 디스크 전체 복호화라는 비가역 작업이다. 러너 하나 서비스로 켜는 부수효과로
# 머신 정책을 바꿀 일이 아니라서, 무엇이 막고 있는지와 명령만 알려준다.
boot_readiness_report() {
  local warned=false auto_login filevault pmset_out value

  auto_login="$(defaults read /Library/Preferences/com.apple.loginwindow autoLoginUser 2>/dev/null || true)"
  filevault="$(fdesetup status 2>/dev/null || true)"
  pmset_out="$(pmset -g custom 2>/dev/null || true)"

  echo
  echo "==> 재부팅 자동 복귀 점검"

  # LaunchAgent는 '부팅 시'가 아니라 'GUI 로그인 시' 로드된다 — 로그인 세션이
  # 자동으로 생기지 않으면 재부팅 후 러너는 계속 오프라인이다.
  if [[ -z "$auto_login" ]]; then
    warned=true
    if [[ "$filevault" == *"FileVault is On"* ]]; then
      echo "  ⚠️  자동 로그인 꺼짐 + FileVault On — 재부팅 후 디스크 잠금해제(=로그인) 전까지 러너가 뜨지 않습니다"
      echo "      · 무인 재부팅  : sudo fdesetup authrestart   (이번 부팅 1회만 잠금해제를 건너뜀)"
      echo "      · 완전 무인화  : 전용기라면 FileVault를 끄고 시스템 설정 > 사용자 및 그룹 > 자동 로그인 지정"
    else
      echo "  ⚠️  자동 로그인 꺼짐 — 재부팅 후 로그인해야 러너가 뜹니다 (LaunchAgent는 GUI 로그인 시 로드)"
      echo "      · 시스템 설정 > 사용자 및 그룹 > 자동 로그인에서 이 계정을 지정하세요"
    fi
  fi

  value="$(pmset_ac_value sleep "$pmset_out")"
  if [[ -n "$value" && "$value" != "0" ]]; then
    warned=true
    echo "  ⚠️  전원 연결 상태에서 ${value}분 뒤 잠듭니다 — 잠들면 잡이 배정되지 않고 대기합니다"
    echo "      · sudo pmset -c sleep 0 disksleep 0"
  fi

  # autorestart를 지원하지 않는 기종에서는 키 자체가 없다 — 없으면 경고하지 않는다.
  value="$(pmset_ac_value autorestart "$pmset_out")"
  if [[ -n "$value" && "$value" != "1" ]]; then
    warned=true
    echo "  ⚠️  정전 후 자동 부팅 꺼짐 — sudo pmset -c autorestart 1"
  fi

  $warned || echo "  ✅ 로그인 세션·전원 설정 모두 자동 복귀에 문제 없습니다"
}

if $AS_SERVICE; then
  PLIST="$(runner_plist_path "$RUNNER_DIR")"

  if [[ -n "$PLIST" ]]; then
    # 이미 서비스로 등록된 러너. svc.sh install은 plist가 있으면 그대로
    # 실패하므로(`error: exists`) 건너뛴다. 새 설정을 반영하려면 언로드가
    # 필요해서 먼저 내린다 — 이미 멈춰 있으면 unload가 실패하지만 정상 경로다.
    echo "==> 기존 launchd 서비스 감지 — 중지 후 재적용 (${PLIST})"
    ./svc.sh stop || true
  fi

  # 같은 디렉토리에서 ./run.sh로 수동(포그라운드) 실행 중이면 서비스와 충돌하므로
  # 정리한다 (수동 러너 → launchd 서비스 전환 경로). 위 stop 다음에 두는 이유:
  # 서비스로 떠 있던 listener는 unload가 이미 정리했으므로 여기 남아 있는 건
  # launchd가 모르는 포그라운드 프로세스뿐이다.
  # macOS 기본 bash는 3.2라 mapfile(bash 4+)을 쓸 수 없다 — 명령 치환의 단어
  # 분리로 배열을 만든다 (pid는 공백을 포함하지 않아 안전).
  # shellcheck disable=SC2207
  RUNNING_PIDS=($(pgrep -f "${RUNNER_DIR}/bin/Runner.Listener" || true))
  if [[ ${#RUNNING_PIDS[@]} -gt 0 ]]; then
    echo "==> 남아 있는 Runner.Listener 종료: pid=${RUNNING_PIDS[*]}"
    kill "${RUNNING_PIDS[@]}"
    sleep 2
  fi

  if [[ -z "$PLIST" ]]; then
    echo "==> launchd 서비스 등록"
    ./svc.sh install
    PLIST="$(runner_plist_path "$RUNNER_DIR")"
  fi

  harden_service_plist "$PLIST"

  echo "==> launchd 서비스 시작"
  ./svc.sh start
  ./svc.sh status
  boot_readiness_report
else
  cat <<EOF

등록 완료. 실행 방법:

  포그라운드 테스트 :  cd ${RUNNER_DIR} && ./run.sh
  상시 서비스       :  $0 ${SCOPE_TYPE:+--$SCOPE_TYPE $SCOPE} --dir ${RUNNER_DIR} --service

상시 서비스는 svc.sh를 직접 부르지 말고 위 명령(--service)을 쓰세요. svc.sh만
실행하면 크래시 자동 복구(KeepAlive)가 빠지고, 재부팅 자동 복귀 점검도 건너뜁니다.

EOF
fi
